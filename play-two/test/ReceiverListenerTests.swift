import Darwin
import Foundation
import Network
import XCTest
@testable import PlayTwo

/// The reply contract and the stop/port-in-use paths (TASK-003, FEAT-001 S1d).
///
/// No test binds port 7000: macOS ControlCenter owns it on the test host, so
/// every test asks the kernel for a free ephemeral port and drives the listener
/// on that number (`DEC-011`). The 7000 default is asserted on its own, without
/// binding it, in ``testDefaultPortIs7000()``.
final class ReceiverListenerTests: XCTestCase {

    /// Serial queue for client callbacks. One per test instance, like the
    /// listener's own queue.
    private let queue = DispatchQueue(label: "ReceiverListenerTests")

    /// Listeners a test started, with the cancellation signal to wait on before
    /// the next test runs. `nil` means the listener never took a port (the
    /// criterion-3 failure path), so there is no state change to wait for.
    private var tracked: [(listener: ReceiverListener, cancelled: CancellationSignal?)] = []

    override func tearDown() {
        for item in tracked {
            item.listener.stop()
            if let cancelled = item.cancelled {
                XCTAssertTrue(
                    cancelled.wait(timeout: 5),
                    "the listener did not report .cancelled, so its port was not released"
                )
            }
        }
        tracked.removeAll()
        super.tearDown()
    }

    // MARK: - Criterion 5

    func testDefaultPortIs7000() {
        let listener = ReceiverListener()
        XCTAssertEqual(
            listener.port.rawValue,
            7000,
            "the listener must default to the AirPlay 2 port, 7000"
        )
    }

    // MARK: - Criterion 1

    func testConnectionReceivesTheFixedResponseAndTheReceiveCompletes() throws {
        let session = try startListener()

        let responded = expectation(description: "received the fixed response")
        let body = Box(Data())
        let completed = Box(false)

        let connection = receiveResponse(on: session.port) { data, isComplete in
            body.value = data
            completed.value = isComplete
            responded.fulfill()
        }
        wait(for: [responded], timeout: 5)
        connection.cancel()

        XCTAssertEqual(
            body.value,
            Data(ReceiverListener.response.utf8),
            "the reply must be exactly `RTSP/1.0 200 OK`, `Content-Length: 0` and an empty body"
        )
        XCTAssertTrue(completed.value, "the receive did not complete after the response")
    }

    // MARK: - Criterion 2

    func testTwoSequentialConnectionsBothReceiveTheFullResponse() throws {
        let session = try startListener()

        let responded = expectation(description: "both connections answered")
        responded.expectedFulfillmentCount = 2
        let bodies = Box<[Data]>([])
        let connections = Box<[NWConnection]>([])

        func connectOnce() {
            let connection = receiveResponse(on: session.port) { data, _ in
                bodies.value.append(data)
                responded.fulfill()
                if bodies.value.count == 1 {
                    connectOnce()
                }
            }
            connections.value.append(connection)
        }

        connectOnce()
        wait(for: [responded], timeout: 10)

        XCTAssertEqual(bodies.value.count, 2, "the listener answered only \(bodies.value.count) of 2 connections")
        for (index, body) in bodies.value.enumerated() {
            XCTAssertEqual(body, Data(ReceiverListener.response.utf8), "connection \(index + 1) got \(body)")
        }
    }

    // MARK: - Criterion 3

    func testStartReportsFailureWhenPortIsAlreadyBound() throws {
        // Hold a free port on both wildcard addresses with plain sockets, then
        // start the listener on that same number: the bind must fail, not
        // silently take over. Both are needed because Network.framework binds
        // `::` as well as `0.0.0.0`, and occupying only one leaves it a free
        // socket.
        let occupied = try occupyFreePort()
        defer { occupied.sockets.forEach { close($0) } }

        let listener = ReceiverListener(port: occupied.port)
        let failed = expectation(description: "listener reports failure")
        let reported = Box<NWError?>(nil)
        // `.waiting` is mapped to `.failed` by the listener; tolerate both
        // without fulfilling the expectation twice.
        let fulfilled = Box(false)

        listener.onStateChange = { state in
            guard case .failed(let error) = state, !fulfilled.value else { return }
            fulfilled.value = true
            reported.value = error
            failed.fulfill()
        }
        tracked.append((listener, nil))
        listener.start()
        wait(for: [failed], timeout: 5)

        guard case .posix(let code)? = reported.value else {
            return XCTFail("expected a POSIX error, got \(String(describing: reported.value))")
        }
        XCTAssertEqual(code, .EADDRINUSE)
    }

    // MARK: - Criterion 4

    func testConnectionIsRefusedWithinOneSecondAfterStop() throws {
        let session = try startListener()
        let cancelled = tracked.last?.cancelled

        XCTAssertEqual(
            connectToReceiver(on: session.port),
            .connected,
            "the listener must accept a connection before stop()"
        )

        let stoppedAt = Date()
        session.listener.stop()
        if let cancelled = cancelled {
            XCTAssertTrue(cancelled.wait(timeout: 1), "the listener did not report .cancelled within 1 s")
        }

        let outcome = connectToReceiver(on: session.port)
        let elapsed = Date().timeIntervalSince(stoppedAt)

        XCTAssertEqual(outcome, .refused, "expected a refused connection, got \(outcome)")
        XCTAssertLessThan(elapsed, 1.0, "the port was still answerable \(elapsed) s after stop()")
    }

    // MARK: - Listener helpers

    /// Starts a listener on a free ephemeral port and waits until it reports
    /// `.listening`. Its cancellation signal goes into ``tracked``, so
    /// `tearDown` releases the port for the next test.
    private func startListener() throws -> (listener: ReceiverListener, port: NWEndpoint.Port) {
        let port = try freePort()
        let listener = ReceiverListener(port: port)
        let ready = expectation(description: "listener reports listening")
        let cancelled = CancellationSignal()
        listener.onStateChange = { state in
            switch state {
            case .listening:
                ready.fulfill()
            case .cancelled:
                cancelled.signal()
            default:
                break
            }
        }
        tracked.append((listener, cancelled))
        listener.start()
        wait(for: [ready], timeout: 5)
        return (listener, port)
    }

    // MARK: - Port helpers

    /// Asks the kernel for a free TCP port: bind port 0, read the assigned
    /// number, close. The number is then handed to `ReceiverListener(port:)`.
    private func freePort() throws -> NWEndpoint.Port {
        let descriptor = try streamSocket(family: AF_INET)
        defer { close(descriptor) }

        var address = ipv4Wildcard(port: 0)
        try bindAndListen(descriptor, ipv4: &address)
        return try boundPort(of: descriptor)
    }

    /// Binds and listens on one free port on both wildcard addresses, so the
    /// listener started on top of it cannot take either. Returns the number and
    /// the sockets; the caller closes them.
    private func occupyFreePort() throws -> (port: NWEndpoint.Port, sockets: [Int32]) {
        let ipv4 = try streamSocket(family: AF_INET)
        var ipv6 = Int32(-1)
        do {
            var wildcard4 = ipv4Wildcard(port: 0)
            try bindAndListen(ipv4, ipv4: &wildcard4)
            let port = try boundPort(of: ipv4)

            ipv6 = try streamSocket(family: AF_INET6)
            // `NWListener` binds `::` dual-stack. Keeping this socket IPv6-only
            // stops the two blockers from fighting each other over the v4 port.
            try setIPv6Only(ipv6)
            var wildcard6 = ipv6Wildcard(port: port.rawValue)
            try bindAndListen(ipv6, ipv6: &wildcard6)
            return (port, [ipv4, ipv6])
        } catch {
            if ipv6 >= 0 { close(ipv6) }
            close(ipv4)
            throw error
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

    // MARK: - Client helpers

    /// Opens a client connection to `127.0.0.1` on `port` and collects
    /// everything the listener sends until the receive completes. `completion`
    /// runs once, on ``queue``, with the bytes received and whether the receive
    /// completed.
    private func receiveResponse(
        on port: NWEndpoint.Port,
        _ completion: @escaping (Data, Bool) -> Void
    ) -> NWConnection {
        let connection = NWConnection(host: "127.0.0.1", port: port, using: .tcp)
        let received = Box(Data())
        let finished = Box(false)

        func finish(_ isComplete: Bool) {
            guard !finished.value else { return }
            finished.value = true
            completion(received.value, isComplete)
        }

        func receiveMore() {
            connection.receive(minimumIncompleteLength: 1, maximumLength: 65_536) { data, _, isComplete, _ in
                if let data = data, !data.isEmpty {
                    received.value.append(data)
                }
                if isComplete {
                    finish(true)
                } else if data == nil || data?.isEmpty == true {
                    finish(false)
                } else {
                    receiveMore()
                }
            }
        }

        connection.stateUpdateHandler = { state in
            switch state {
            case .ready:
                receiveMore()
            case .failed, .cancelled:
                // After a good response the test can cancel the connection; the
                // guard in `finish` keeps that from reporting an empty body.
                finish(false)
            default:
                break
            }
        }
        connection.start(queue: queue)
        return connection
    }

    /// Connects to `127.0.0.1` on `port` with a blocking POSIX call, so
    /// "refused" is the syscall's answer rather than a state that may or may not
    /// arrive.
    private func connectToReceiver(on port: NWEndpoint.Port) -> ConnectOutcome {
        let descriptor = socket(AF_INET, SOCK_STREAM, 0)
        guard descriptor >= 0 else { return .failed(errno) }
        defer { close(descriptor) }

        var address = ipv4Address(host: "127.0.0.1", port: port.rawValue)
        let result = withUnsafePointer(to: &address) { pointer in
            pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) { socketAddress in
                connect(descriptor, socketAddress, socklen_t(MemoryLayout<sockaddr_in>.size))
            }
        }
        if result == 0 { return .connected }
        return errno == ECONNREFUSED ? .refused : .failed(errno)
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

    private func setIPv6Only(_ descriptor: Int32) throws {
        var ipv6Only: Int32 = 1
        guard setsockopt(
            descriptor,
            IPPROTO_IPV6,
            IPV6_V6ONLY,
            &ipv6Only,
            socklen_t(MemoryLayout<Int32>.size)
        ) == 0 else {
            throw SocketError(code: errno)
        }
    }

    private func bindAndListen(_ descriptor: Int32, ipv4 address: inout sockaddr_in) throws {
        try withUnsafePointer(to: &address) { pointer in
            try pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) { socketAddress in
                try bindAndListen(descriptor, socketAddress, socklen_t(MemoryLayout<sockaddr_in>.size))
            }
        }
    }

    private func bindAndListen(_ descriptor: Int32, ipv6 address: inout sockaddr_in6) throws {
        try withUnsafePointer(to: &address) { pointer in
            try pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) { socketAddress in
                try bindAndListen(descriptor, socketAddress, socklen_t(MemoryLayout<sockaddr_in6>.size))
            }
        }
    }

    /// Binds and listens `descriptor` on `address`, throwing the failing `errno`.
    private func bindAndListen(
        _ descriptor: Int32,
        _ address: UnsafePointer<sockaddr>,
        _ length: socklen_t
    ) throws {
        guard bind(descriptor, address, length) == 0 else {
            throw SocketError(code: errno)
        }
        guard listen(descriptor, 1) == 0 else {
            throw SocketError(code: errno)
        }
    }

    private func ipv4Wildcard(port: UInt16) -> sockaddr_in {
        var address = sockaddr_in()
        address.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        address.sin_family = sa_family_t(AF_INET)
        address.sin_port = port.bigEndian
        address.sin_addr = in_addr(s_addr: 0) // INADDR_ANY
        return address
    }

    private func ipv6Wildcard(port: UInt16) -> sockaddr_in6 {
        var address = sockaddr_in6()
        address.sin6_len = UInt8(MemoryLayout<sockaddr_in6>.size)
        address.sin6_family = sa_family_t(AF_INET6)
        address.sin6_port = port.bigEndian
        address.sin6_addr = in6_addr() // in6addr_any
        return address
    }

    private func ipv4Address(host: String, port: UInt16) -> sockaddr_in {
        var address = sockaddr_in()
        address.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        address.sin_family = sa_family_t(AF_INET)
        address.sin_port = port.bigEndian
        address.sin_addr = in_addr(s_addr: inet_addr(host))
        return address
    }
}

// MARK: - File-private types

private enum ConnectOutcome: Equatable, CustomStringConvertible {
    case connected
    case refused
    case failed(Int32)

    var description: String {
        switch self {
        case .connected:
            return "connected"
        case .refused:
            return "refused"
        case .failed(let code):
            return "failed (errno \(code))"
        }
    }
}

private struct SocketError: Error {
    let code: Int32
}

/// One-shot signal for "the listener reported `.cancelled`".
///
/// A `DispatchGroup` rather than an `XCTestExpectation`, because the wait
/// happens in `tearDown` (after the test method has returned) and a group that
/// has finished stays finished, so waiting on it twice is safe.
private final class CancellationSignal {
    private let group = DispatchGroup()
    private let lock = NSLock()
    private var signalled = false

    init() {
        group.enter()
    }

    func signal() {
        lock.lock()
        if signalled {
            lock.unlock()
            return
        }
        signalled = true
        lock.unlock()
        group.leave()
    }

    func wait(timeout: TimeInterval) -> Bool {
        group.wait(timeout: .now() + timeout) == .success
    }
}

/// Locked box for state shared with `NWConnection` callbacks. The callbacks run
/// on one serial queue, but the test thread reads the values as well.
private final class Box<Value> {
    private let lock = NSLock()
    private var stored: Value

    init(_ value: Value) {
        stored = value
    }

    var value: Value {
        get {
            lock.lock()
            defer { lock.unlock() }
            return stored
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            stored = newValue
        }
    }
}
