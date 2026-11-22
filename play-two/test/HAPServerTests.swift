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
