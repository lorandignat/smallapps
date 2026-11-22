import Darwin
import Foundation
import Network
import XCTest
@testable import PlayTwo

/// The `GET /info` JSON contract, the routing table, and the live exchange
/// over a real socket (TASK-016).
///
/// The live test drives a `ReceiverListener` whose `connectionHandler` is
/// `HAPServer.handle`, so the chain exercised is the production one: an
/// accepted connection reaches the HAP server. It binds a free ephemeral port
/// through the kernel rather than reading `listener.port` off an `.any`-bound
/// `NWListener` — the port handed to `ReceiverListener` is the real number
/// `listener.port` reports, so there is no SDK difference to record.
final class HAPServerTests: XCTestCase {

    /// Services of the pairing stores the tests build; deleted in teardown so
    /// the app's real entry is never touched.
    private var pairingServices: [String] = []

    override func tearDown() {
        for service in pairingServices {
            HAPPairingStore(service: service).delete()
        }
        pairingServices.removeAll()
        super.tearDown()
    }

    /// A pairing-store service string unique to this test, recorded for
    /// teardown deletion.
    private func freshPairingService() -> String {
        let service = "com.lorand.playtwo.hap-pairing.\(UUID().uuidString)"
        pairingServices.append(service)
        return service
    }

    // MARK: - Criterion 1

    func testParseReturnsMethodPathAndBody() {
        let request = HAPServer.parse(Data("GET /info HTTP/1.1\r\nContent-Length: 0\r\n\r\n".utf8))
        XCTAssertEqual(request?.method, "GET")
        XCTAssertEqual(request?.path, "/info")
        XCTAssertEqual(
            request?.body.count,
            0,
            "a `GET /info` with `Content-Length: 0` must have an empty body"
        )
        XCTAssertEqual(request?.body, Data())
    }

    // MARK: - Criterion 2

    func testParseReadsTheContentLengthBody() {
        let request = HAPServer.parse(Data("POST /pair-setup HTTP/1.1\r\nContent-Length: 11\r\n\r\nhello world".utf8))
        XCTAssertEqual(request?.method, "POST")
        XCTAssertEqual(request?.path, "/pair-setup")
        XCTAssertEqual(request?.body, Data("hello world".utf8))
    }

    // MARK: - Criterion 3

    func testParseReturnsNilOnMalformedInput() {
        XCTAssertNil(HAPServer.parse(Data("no request line and no header block".utf8)))
        XCTAssertNil(HAPServer.parse(Data("GET\r\n\r\n".utf8)), "a request line without method and path is malformed")
        XCTAssertNil(
            HAPServer.parse(Data("POST /x HTTP/1.1\r\nContent-Length: 10\r\n\r\nshort".utf8)),
            "a body shorter than `Content-Length` is incomplete"
        )
    }

    // MARK: - Criterion 4

    func testRouteInfoReturns200WithNameCategoryAndPaired() {
        let response = HAPServer().route(HAPServer.Request(method: "GET", path: "/info", body: Data()))
        XCTAssertEqual(response.status, 200)
        let body = String(decoding: response.body, as: UTF8.self)
        XCTAssertTrue(body.contains("\"name\": \"PlayTwo\""), "unexpected info body: \(body)")
        XCTAssertTrue(body.contains("\"category\": \"speaker\""), "unexpected info body: \(body)")
        XCTAssertTrue(body.contains("\"paired\": false"), "unexpected info body: \(body)")
    }

    func testRouteOtherPathReturns404() {
        XCTAssertEqual(
            HAPServer().route(HAPServer.Request(method: "GET", path: "/other", body: Data())).status,
            404
        )
    }

    func testRoutePostPairSetupReturns404() {
        let server = HAPServer()
        XCTAssertEqual(
            server.route(HAPServer.Request(method: "POST", path: "/info", body: Data())).status,
            404
        )
        XCTAssertEqual(
            server.route(HAPServer.Request(method: "POST", path: "/pair-setup", body: Data())).status,
            404
        )
    }

    // MARK: - TASK-018 — `POST /pair-setup` starts the exchange

    /// `POST /pair-setup` starts the SRP exchange: request 1 — the client's
    /// public value A (TLV type 4) — answers 200 with the accessory public
    /// value (TLV type 3, `SRP.nByteCount`) and the salt (TLV type 6,
    /// ≥ 16 bytes); request 2 — the client proof in TLV type 4 — answers
    /// 400 when it does not verify and leaves the store unpaired.
    func testRoutePostPairSetupStartsTheExchange() {
        let store = HAPPairingStore(service: freshPairingService())
        let server = HAPServer(pairingStore: store)

        // Request 1: the client's public value, 32 bytes.
        let request1 = HAPServer.Request(
            method: "POST",
            path: "/pair-setup",
            body: TLV8.encode([TLV8Entry(type: 4, value: Data(repeating: 0x42, count: 32))])
        )
        var response1: HAPServer.Response?
        let exp1 = expectation(description: "pair-setup request 1")
        DispatchQueue.global().async {
            response1 = server.route(request1)
            exp1.fulfill()
        }
        wait(for: [exp1], timeout: 300)
        XCTAssertEqual(response1?.status, 200, "request 1 must start the exchange")
        let entries1 = response1.flatMap { TLV8.decode($0.body) }
        XCTAssertNotNil(
            entries1?.first(where: { $0.type == 3 && $0.value.count == SRP.nByteCount }),
            "the response must carry the accessory key (type 3)")
        XCTAssertNotNil(
            entries1?.first(where: { $0.type == 6 && $0.value.count >= 16 }),
            "the response must carry the salt (type 6)")

        // Request 2: a mismatched proof — it does not verify.
        let request2 = HAPServer.Request(
            method: "POST",
            path: "/pair-setup",
            body: TLV8.encode([TLV8Entry(type: 4, value: Data(repeating: 0x00, count: 64))])
        )
        var response2: HAPServer.Response?
        let exp2 = expectation(description: "pair-setup request 2")
        DispatchQueue.global().async {
            response2 = server.route(request2)
            exp2.fulfill()
        }
        wait(for: [exp2], timeout: 300)
        XCTAssertEqual(response2?.status, 400, "a non-verifying proof must answer 400")
        XCTAssertFalse(store.paired, "the store must stay unpaired")
    }

    // MARK: - TASK-019 — `POST /pair-verify` starts the encrypted session

    /// TASK-019: `POST /pair-verify` request 1 — the client's ephemeral
    /// public key `A_e` (TLV type 1) — answers 200 with the accessory
    /// ephemeral public key `B_e` (TLV type 2, 32 bytes) and sets
    /// `server.pairVerifySession`.
    func testRoutePostPairVerifyReturnsTheAccessoryKey() throws {
        let store = HAPPairingStore(service: freshPairingService())
        store.save(record: HAPPairingStore.Record(
            salt: Data(repeating: 9, count: 16),
            verifier: Data(repeating: 4, count: 384),
            paired: false
        ))
        let server = HAPServer(pairingStore: store)
        let request = HAPServer.Request(
            method: "POST",
            path: "/pair-verify",
            body: TLV8.encode([TLV8Entry(type: 1, value: Data(repeating: 0x22, count: 32))])
        )
        let response = server.route(request)
        XCTAssertEqual(response.status, 200, "request 1 must start the exchange")
        let entries = try XCTUnwrap(TLV8.decode(response.body))
        let bE = try XCTUnwrap(
            entries.first(where: { $0.type == 2 })?.value,
            "the response must carry the accessory ephemeral public key (type 2)"
        )
        XCTAssertEqual(bE.count, 32, "the accessory ephemeral public key is 32 bytes")
        XCTAssertNotNil(server.pairVerifySession, "request 1 must set `pairVerifySession`")
        XCTAssertEqual(bE, server.pairVerifySession?.b, "the TLV key is the session's ephemeral public key")
    }

    /// TASK-017: `GET /info` reports the pairing state read from the store
    /// the server was built with (`HAPPairingStore.shared` elsewhere).
    func testInfoReportsThePairedStateFromTheStore() {
        let store = HAPPairingStore(service: freshPairingService())
        store.save(record: HAPPairingStore.Record(
            salt: Data(repeating: 1, count: 16),
            verifier: Data(repeating: 2, count: 384),
            paired: true
        ))
        let response = HAPServer(pairingStore: store)
            .route(HAPServer.Request(method: "GET", path: "/info", body: Data()))
        XCTAssertEqual(response.status, 200)
        XCTAssertTrue(
            String(decoding: response.body, as: UTF8.self).contains("\"paired\": true"),
            "unexpected info body"
        )
    }

    func testLiveInfoExchangeAnswersOverAPort() throws {
        let server = HAPServer()
        let listener = ReceiverListener(port: try freePort())
        listener.connectionHandler = server.handle

        let ready = expectation(description: "listener reports listening")
        let cancelled = expectation(description: "listener reports cancelled")
        listener.onStateChange = { state in
            switch state {
            case .listening:
                ready.fulfill()
            case .cancelled:
                cancelled.fulfill()
            default:
                break
            }
        }
        listener.start()
        wait(for: [ready], timeout: 5)
        defer { listener.stop(); wait(for: [cancelled], timeout: 5) }

        let connection = NWConnection(host: "127.0.0.1", port: listener.port, using: .tcp)
        connection.start(queue: DispatchQueue.global(qos: .utility))

        let semaphore = DispatchSemaphore(value: 0)
        let lock = NSLock()
        var data = Data()
        connection.receive(minimumIncompleteLength: 1, maximumLength: 8192) { chunk, _, _, _ in
            lock.lock()
            if let chunk, !chunk.isEmpty {
                data = chunk
            }
            lock.unlock()
            semaphore.signal()
        }
        connection.send(
            content: Data("GET /info HTTP/1.1\r\nContent-Length: 0\r\n\r\n".utf8),
            contentContext: .defaultMessage,
            isComplete: true,
            completion: .contentProcessed { _ in }
        )

        XCTAssertEqual(
            semaphore.wait(timeout: .now() + 5),
            .success,
            "the listener's port never answered the live request"
        )
        connection.cancel()

        lock.lock()
        let text = String(decoding: data, as: UTF8.self)
        lock.unlock()
        XCTAssertTrue(text.contains("HTTP/1.1 200"), "the live exchange did not answer 200, got: \(text)")
        XCTAssertTrue(text.contains("\"name\": \"PlayTwo\""), "the live info body lacks the name, got: \(text)")
        XCTAssertTrue(text.contains("\"category\": \"speaker\""), "the live info body lacks the category, got: \(text)")
        XCTAssertTrue(text.contains("\"paired\": false"), "the live info body lacks the paired state, got: \(text)")
    }

    // MARK: - Port helper

    /// Asks the kernel for a free TCP port: bind port 0, read the assigned
    /// number, close. The number is then handed to `ReceiverListener(port:)`.
    private func freePort() throws -> NWEndpoint.Port {
        let descriptor = try streamSocket(family: AF_INET)
        defer { close(descriptor) }

        var address = ipv4Wildcard(port: 0)
        try bindAndListen(descriptor, ipv4: &address)
        return try boundPort(of: descriptor)
    }

    // MARK: - Socket helpers

    /// A TCP socket with `SO_REUSEADDR`, not yet bound or listening.
    private func streamSocket(family: Int32) throws -> Int32 {
        let descriptor = socket(family, SOCK_STREAM, 0)
        guard descriptor >= 0 else { throw SocketError(code: errno) }

        var reuse: Int32 = 1
        guard setsockopt(
            descriptor,
            SOL_SOCKET,
            SO_REUSEADDR,
            &reuse,
            socklen_t(MemoryLayout<Int32>.size)
        ) == 0 else {
            let code = errno
            close(descriptor)
            throw SocketError(code: code)
        }
        return descriptor
    }

    private func bindAndListen(_ descriptor: Int32, ipv4 address: inout sockaddr_in) throws {
        try withUnsafePointer(to: &address) { pointer in
            try pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) { socketAddress in
                guard bind(descriptor, socketAddress, socklen_t(MemoryLayout<sockaddr_in>.size)) == 0 else {
                    throw SocketError(code: errno)
                }
                guard listen(descriptor, 1) == 0 else {
                    throw SocketError(code: errno)
                }
            }
        }
    }

    /// The port a listening socket was bound to.
    private func boundPort(of descriptor: Int32) throws -> NWEndpoint.Port {
        var bound = sockaddr_in()
        var length = socklen_t(MemoryLayout<sockaddr_in>.size)
        let result = withUnsafeMutablePointer(to: &bound) { pointer in
            pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) { socketAddress in
                getsockname(descriptor, socketAddress, &length)
            }
        }
        guard result == 0 else { throw SocketError(code: errno) }
        return NWEndpoint.Port(rawValue: bound.sin_port.bigEndian)!
    }

    private func ipv4Wildcard(port: UInt16) -> sockaddr_in {
        var address = sockaddr_in()
        address.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        address.sin_family = sa_family_t(AF_INET)
        address.sin_port = port.bigEndian
        address.sin_addr = in_addr(s_addr: 0) // INADDR_ANY
        return address
    }
}

// MARK: - File-private types

private struct SocketError: Error {
    let code: Int32
}
