import Foundation
import Network

/// Publishes this receiver as one `_airplay._tcp` Bonjour service.
///
/// The registration does not own a socket of its own: it rides on the same
/// ``ReceiverListener`` and `NWListener` that answers the AirPlay port, so the
/// port a browser resolves is the port that answers (TASK-004, FEAT-001
/// S1a/S1d, `DEC-012`). The advertiser owns that listener and translates its
/// states; it wires the listener's ``ReceiverListener/connectionHandler`` to
/// `HAPServer.handle` so the HAP server answers connections, and parses
/// nothing itself.
final class ServiceAdvertiser {

    /// The service type an AirPlay 2 receiver publishes.
    ///
    /// `_raop._tcp` is AirPlay 1 and is not published: increment 1 is AP2 only
    /// (FEAT-001 "In scope").
    static let serviceType = "_airplay._tcp"

    /// Bonjour's limit for a service instance name, in UTF-8 bytes.
    ///
    /// A longer name is refused instead of being truncated: a shortened name is
    /// a different receiver to the Apple TV, and a silent one hides the bug
    /// (TASK-004 criterion 3).
    static let maximumNameBytes = 63

    /// What the advertiser is doing, for the state screen (TASK-005).
    ///
    /// `failed` carries a message, not an `NWError`, because the failures that
    /// are not the system's own — a name too long, a device id that cannot make
    /// a TXT record — have no `NWError`, and the screen shows one kind of
    /// string.
    enum State: Equatable {
        case idle
        case advertising
        case failed(String)
        case stopped
    }

    /// The instance name the Apple TV shows. `PlayTwo` for the app.
    let name: String

    /// The TCP port the service points at: 7000 unless the caller passed
    /// another (`DEC-011`).
    let port: NWEndpoint.Port

    /// The device id carried in the TXT record.
    let deviceID: String

    /// The listener that carries both the registration and the port.
    ///
    /// `nil` until ``start()``, and `nil` after a start that was refused before
    /// a listener was made. So "no listener" is what "published nothing" looks
    /// like, which is what criterion 3 asserts.
    private(set) var listener: ReceiverListener?

    /// Called on every state change: on the listener's private queue once the
    /// listener exists, on the caller's thread when a start is refused before
    /// one is made. Set it before ``start()``.
    var onStateChange: ((State) -> Void)?

    private let lock = NSLock()
    private var storedState: State = .idle

    /// The last state reported. Safe to read from any thread.
    var state: State {
        lock.lock()
        defer { lock.unlock() }
        return storedState
    }

    /// Creates the advertiser without starting anything.
    ///
    /// - Parameters:
    ///   - name: the Bonjour instance name; defaults to ``AppInfo/displayName``.
    ///   - port: the port to advertise and answer on; defaults to 7000, which
    ///     is the AirPlay 2 port. The parameter exists so the unit tests can use
    ///     an ephemeral port, because macOS ControlCenter owns 7000 on the test
    ///     host (`DEC-011`, `DEC-012`).
    ///   - deviceID: the TXT record's device id; defaults to this install's
    ///     identity (`DeviceIdentity`).
    init(
        name: String = AppInfo.displayName,
        port: NWEndpoint.Port = .init(rawValue: 7000)!,
        deviceID: String = DeviceIdentity.current
    ) {
        self.name = name
        self.port = port
        self.deviceID = deviceID
    }

    /// Validates the inputs and starts the listener with the service attached.
    ///
    /// A name longer than 63 UTF-8 bytes or a device id that cannot make a TXT
    /// record reports `.failed` and creates no listener: nothing is published,
    /// truncated or otherwise (`AirPlayTXTRecord.init?` requires its caller to
    /// refuse rather than publish a malformed record). Calling `start()` on a
    /// running advertiser does nothing.
    func start() {
        guard listener == nil else { return }

        let byteCount = name.utf8.count
        guard byteCount <= Self.maximumNameBytes else {
            report(.failed(
                "the service name is \(byteCount) UTF-8 bytes; "
                    + "Bonjour allows at most \(Self.maximumNameBytes)"
            ))
            return
        }
        guard let record = AirPlayTXTRecord(
            deviceID: deviceID,
            paired: HAPPairingStore.shared.paired
        ) else {
            report(.failed("the device id \(deviceID) cannot make a TXT record"))
            return
        }

        let service = NWListener.Service(
            name: name,
            type: Self.serviceType,
            txtRecord: record.txtRecord
        )
        let listener = ReceiverListener(port: port, service: service)
        // TASK-016: the HAP server is the server behind the socket — every
        // connection the listener accepts reaches it.
        let server = HAPServer()
        listener.connectionHandler = server.handle
        listener.onStateChange = { [weak self] state in
            self?.listenerChanged(state)
        }
        self.listener = listener
        listener.start()
    }

    /// Closes the port and withdraws the registration; `.stopped` follows.
    ///
    /// The app does not call this yet: TASK-006 owns withdrawing the
    /// advertisement when the app leaves the foreground. The tests call it to
    /// release the port, as `ReceiverListenerTests` does.
    func stop() {
        listener?.stop()
    }

    /// `kDNSServiceErr_PolicyDenied` from `<dns_sd.h>`: the local network
    /// permission was refused, so Bonjour registration is blocked. Spelled out
    /// as a number because the `Network` module does not re-export the
    /// header's constants.
    static let policyDeniedDNSError: Int32 = -72008

    /// Maps the listener's view onto the advertiser's, so the screen has one
    /// state to render.
    ///
    /// Internal rather than private so the tests can drive the policy-denial
    /// branch: no simulator produces it, because the simulator does not
    /// enforce the local network permission, and a device only produces it
    /// once per install.
    ///
    /// A denied registration arrives as the listener's `.waiting`
    /// (`ReceiverListener` reports that as `.failed`), and it must replace
    /// `.advertising` with a `.failed` that says why. Sitting in `.advertising`
    /// while nothing is registered is the failure this task exists to make
    /// visible.
    func listenerChanged(_ state: ReceiverListener.State) {
        switch state {
        case .idle:
            report(.idle)
        case .listening:
            report(.advertising)
        case .failed(let error):
            report(Self.failure(for: error))
        case .cancelled:
            self.listener = nil
            report(.stopped)
        }
    }

    /// The advertiser's `.failed` state for one listener error.
    static func failure(for error: NWError) -> State {
        if case .dns(let code) = error, code == policyDeniedDNSError {
            return .failed(
                "the local network permission was denied, so iOS blocked the "
                    + "_airplay._tcp registration (DNS-SD \(code)); allow "
                    + "PlayTwo in Settings > Privacy & Security > Local Network"
            )
        }
        return .failed("the listener failed: \(error)")
    }

    private func report(_ state: State) {
        lock.lock()
        storedState = state
        lock.unlock()
        onStateChange?(state)
    }
}
