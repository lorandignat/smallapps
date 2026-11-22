import Foundation
import Network

/// Accepts TCP connections on a port and hands each to ``connectionHandler``
/// (TASK-016: `HAPServer.handle`).
///
/// The listener owns the socket and the port; it parses nothing — the handler
/// is the whole server now. `ServiceAdvertiser` wires the handler, so in the
/// app the HAP server answers every accepted connection. With no handler set,
/// accepted connections are started and closed immediately.
final class ReceiverListener {

    /// The port this listener binds, 7000 unless the caller passed another.
    ///
    /// 7000 is fixed by the AirPlay 2 service definition and is what the app
    /// always gets: no call site passes a port. The parameter exists so the unit
    /// tests can bind a free ephemeral port instead, because macOS ControlCenter
    /// owns TCP 7000 on the test host (`DEC-011`).
    let port: NWEndpoint.Port

    /// The Bonjour service to register with the port, or `nil` for a plain TCP
    /// listener.
    ///
    /// One `NWListener` carries both, so the advertised port and the answering
    /// port cannot drift apart (TASK-004, `DEC-012`).
    let service: NWListener.Service?

    /// Called on the listener's private queue for every accepted connection.
    ///
    /// The connection is not started or read here: the handler owns it, so it
    /// can be served or closed as it sees fit. `ServiceAdvertiser` sets it to
    /// `HAPServer.handle`, so in the app the HAP server receives every
    /// accepted connection. With no handler, accepted connections are started
    /// and closed immediately.
    var connectionHandler: ((NWConnection) -> Void)?

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

    /// Creates a listener on `port`, defaulting to 7000 (`DEC-011`), that
    /// registers `service` when it starts, if one is given.
    init(port: NWEndpoint.Port = .init(rawValue: 7000)!, service: NWListener.Service? = nil) {
        self.port = port
        self.service = service
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
            // The registration, if any, rides on this listener: no second
            // socket, and the service advertises this listener's port.
            listener.service = service
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

    /// Delegates to ``connectionHandler``; the connection is never read by the
    /// listener itself. With no handler, the connection is started and closed
    /// immediately.
    private func answer(_ connection: NWConnection) {
        if let connectionHandler = connectionHandler {
            connectionHandler(connection)
        } else {
            connection.start(queue: queue)
            connection.cancel()
        }
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
