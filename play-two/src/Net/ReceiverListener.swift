import Foundation
import Network

/// Accepts TCP connections on a port and answers each with one fixed reply,
/// then closes the connection (TASK-003, FEAT-001 S1d).
///
/// The listener parses nothing: every connection gets the same constant reply,
/// because increment 1 only has to keep a sender that found the Bonjour service
/// from hanging (FEAT-001 "In scope"). TASK-004 publishes the service that
/// points here and is the first caller. Real RTSP handling is increment 3.
final class ReceiverListener {

    /// The reply every accepted connection receives before it is closed.
    ///
    /// Fixed by TASK-003, byte for byte; the tests compare the received data
    /// against this string, so no header may be added or removed here.
    static let response = "RTSP/1.0 200 OK\r\nContent-Length: 0\r\n\r\n"

    /// The port this listener binds, 7000 unless the caller passed another.
    ///
    /// 7000 is fixed by the AirPlay 2 service definition and is what the app
    /// always gets: no call site passes a port. The parameter exists so the unit
    /// tests can bind a free ephemeral port instead, because macOS ControlCenter
    /// owns TCP 7000 on the test host (`DEC-011`).
    let port: NWEndpoint.Port

    /// What the listener is doing. `failed` carries the `NWError` the system
    /// reported, so a caller can show it instead of guessing.
    enum State: Equatable {
        case idle
        case listening
        case failed(NWError)
        case cancelled
    }

    /// Called on the listener's private queue on every state change. Set it
    /// before ``start()``; the listener holds the only reference to the queue.
    var onStateChange: ((State) -> Void)?

    private let queue = DispatchQueue(label: "com.lorand.playtwo.receiver-listener")
    private var listener: NWListener?

    /// Creates a listener on `port`, defaulting to 7000 (`DEC-011`).
    init(port: NWEndpoint.Port = .init(rawValue: 7000)!) {
        self.port = port
    }

    /// Binds ``port`` and starts accepting connections.
    ///
    /// The outcome arrives through ``onStateChange``: `.listening` once the
    /// port is bound, `.failed` when it is not (because another socket holds
    /// it, for example). Calling `start()` on a running listener does nothing.
    func start() {
        guard listener == nil else { return }

        let parameters = NWParameters.tcp
        // Lets a restart after `stop()` bind while connections from the
        // previous run are still in TIME_WAIT (TASK-006 republishes when the
        // app returns to the foreground). It does not let a second listener
        // share a port that is actively bound.
        parameters.allowLocalEndpointReuse = true

        do {
            let listener = try NWListener(using: parameters, on: port)
            listener.stateUpdateHandler = { [weak self] state in
                self?.report(state)
            }
            listener.newConnectionHandler = { [weak self] connection in
                self?.answer(connection)
            }
            self.listener = listener
            listener.start(queue: queue)
        } catch let error as NWError {
            onStateChange?(.failed(error))
        } catch {
            // `NWListener` only throws `NWError`; keep the switch exhaustive
            // without crashing should that change.
            onStateChange?(.failed(.posix(.EINVAL)))
        }
    }

    /// Closes the listening socket. `.cancelled` follows once it is closed, so
    /// a caller that needs the port free waits for that state.
    func stop() {
        guard let listener = listener else { return }
        self.listener = nil
        listener.cancel()
    }

    /// Sends the fixed reply and closes the connection. The request is never
    /// read: increment 1 has nothing to answer yet.
    private func answer(_ connection: NWConnection) {
        connection.start(queue: queue)
        connection.send(
            content: Data(Self.response.utf8),
            contentContext: .defaultMessage,
            isComplete: true,
            completion: .contentProcessed { _ in
                connection.cancel()
            }
        )
    }

    private func report(_ state: NWListener.State) {
        switch state {
        case .setup:
            onStateChange?(.idle)
        case .waiting(let error):
            // There is no retry at this increment: a listener that is waiting
            // is not serving its port, so it reports the same failure a hard
            // failure would.
            onStateChange?(.failed(error))
        case .ready:
            onStateChange?(.listening)
        case .failed(let error):
            onStateChange?(.failed(error))
        case .cancelled:
            onStateChange?(.cancelled)
        @unknown default:
            break
        }
    }
}
