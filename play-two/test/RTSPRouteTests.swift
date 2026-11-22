import Darwin
import Foundation
import Network
import XCTest
@testable import PlayTwo

/// RTSP routing on the AirPlay port (TASK-024).
///
/// The router is installed as the connection handler on an ephemeral port.
/// RTSP requests are detected by request-line protocol token and routed to
/// RTSP handlers; HTTP/1.1 requests still reach the HAP server unchanged.
final class RTSPRouteTests: XCTestCase {

    // MARK: - Criterion 1

    func testOptionsRequestGetsRTSP200WithCSeq() throws {
        let (listener, connection) = try startRouter()

        let response = try send(
            "OPTIONS * RTSP/1.0\r\nCSeq: 7\r\n\r\n",
            over: connection
        )
        stop(listener)

        let text = String(decoding: response, as: UTF8.self)
        XCTAssertTrue(
            text.hasPrefix("RTSP/1.0 200 OK\r\n"),
            "RTSP OPTIONS must answer RTSP/1.0 200 OK, got: \(text)"
        )
        XCTAssertTrue(
            text.contains("CSeq: 7\r\n"),
            "RTSP OPTIONS response must echo CSeq: 7, got: \(text)"
        )
    }

    // MARK: - Criterion 2

    func testHTTPInfoRequestStillReachesHAPServer() throws {
        let (listener, connection) = try startRouter()

        let response = try send(
            "GET /info HTTP/1.1\r\nContent-Length: 0\r\n\r\n",
            over: connection
        )
        stop(listener)

        let text = String(decoding: response, as: UTF8.self)
        XCTAssertTrue(
            text.contains("HTTP/1.1 200"),
            "HTTP/1.1 GET /info must still answer 200, got: \(text)"
        )
        XCTAssertTrue(
            text.contains("\"category\": \"speaker\""),
            "HTTP/1.1 GET /info must preserve the HAP info body, got: \(text)"
        )
    }

    // MARK: - Live helpers

    /// Starts a router-backed listener on a free ephemeral port and returns a
    /// connected client connection. The router owns HTTP and RTSP dispatch.
    private func startRouter() throws -> (NWListenerOwner, NWConnection) {
        let server = HAPServer()
        let router = RTSPRouter(server: server)
        let listener = ReceiverListener(port: try freePort())
        listener.connectionHandler = router.handle

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

        let connection = NWConnection(host: "127.0.0.1", port: listener.port, using: .tcp)
        connection.start(queue: DispatchQueue.global(qos: .utility))
        return (NWListenerOwner(listener: listener, cancelled: cancelled), connection)
    }

    private func stop(_ owner: NWListenerOwner) {
        owner.listener.stop()
        wait(for: [owner.cancelled], timeout: 5)
    }

    /// Sends `request` over `connection` and returns the first received chunk.
    private func send(_ request: String, over connection: NWConnection) throws -> Data {
        let semaphore = DispatchSemaphore(value: 0)
        let lock = NSLock()
        var data = Data()
        var received = false
        connection.receive(minimumIncompleteLength: 1, maximumLength: 8192) { chunk, _, _, _ in
            lock.lock()
            if !received, let chunk, !chunk.isEmpty {
                data = chunk
                received = true
                lock.unlock()
                semaphore.signal()
            } else {
                lock.unlock()
            }
        }
        connection.send(
            content: Data(request.utf8),
            contentContext: .defaultMessage,
            isComplete: true,
            completion: .contentProcessed { _ in }
        )

        XCTAssertEqual(
            semaphore.wait(timeout: .now() + 5),
            .success,
            "the router never answered the request"
        )
        connection.cancel()
        lock.lock()
        defer { lock.unlock() }
        return data
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

/// Holds a listener and its cancelled expectation so tests can stop it
/// deterministically and release the port.
private struct NWListenerOwner {
    let listener: ReceiverListener
    let cancelled: XCTestExpectation
}

private struct SocketError: Error {
    let code: Int32
}
