import Combine
import SwiftUI

enum ReceiverStatus: Equatable {
    case idle
    case advertising
    case paired
    case failed(String)
    case stopped

    func statusText(name: String) -> String {
        switch self {
        case .idle:
            return "Idle"
        case .advertising:
            return "Advertising as \(name)"
        case .paired:
            return "Paired"
        case .failed(let message):
            return "Error: \(message)"
        case .stopped:
            return "Stopped"
        }
    }

    static func statusText(_ status: ReceiverStatus, name: String) -> String {
        status.statusText(name: name)
    }

    static func statusText(status: ReceiverStatus, name: String) -> String {
        status.statusText(name: name)
    }
}

/// The advertiser surface `AppState` depends on. `ServiceAdvertiser` conforms
/// to it; tests substitute a spy.
protocol ServiceAdvertiserProtocol: AnyObject {
    var name: String { get }
    var state: ServiceAdvertiser.State { get }
    var onStateChange: ((ServiceAdvertiser.State) -> Void)? { get set }
    func start()
    func stop()
}

typealias ServiceAdvertising = ServiceAdvertiserProtocol
typealias Advertiser = ServiceAdvertiserProtocol

extension ServiceAdvertiser: ServiceAdvertiserProtocol {}

final class AppState: ObservableObject {
    @Published var status: ReceiverStatus = .idle

    /// Scene phase mirrored for SwiftUI binding; setting it drives the
    /// lifecycle handling so tests can drive it without an environment.
    var scenePhase: ScenePhase = .active {
        didSet { handleScenePhase(scenePhase) }
    }

    private let advertiser: ServiceAdvertiserProtocol

    /// The store whose `paired` flag drives the launch and advertising status
    /// (TASK-021). Injected so tests can simulate a stored pairing; the default
    /// keeps existing callers (and the app) on the shared store.
    private let pairingStore: HAPPairingStore

    /// The diagnostic log every advertisement event leaves a line in
    /// (TASK-007): the launch `Restart` marker, then the advertising,
    /// stopped and failure lines. Memory-only — TASK-008 exports it. Read by
    /// tests through `@testable`; the log itself writes nothing.
    let eventLog = EventLog()

    init(advertiser: ServiceAdvertiserProtocol, pairingStore: HAPPairingStore = .shared) {
        self.advertiser = advertiser
        self.pairingStore = pairingStore
        // Restart survival (TASK-021): a stored pairing launches as .paired,
        // not .idle, so the state screen reads "Paired" on relaunch.
        status = pairingStore.paired ? .paired : .idle
        eventLog.record("Restart")
        advertiser.onStateChange = { [weak self] newState in
            self?.handleAdvertiserState(newState)
        }
    }

    /// Records the event the advertiser just reported (TASK-007), then
    /// mirrors it into ``status``: a start line when the service is
    /// advertising, a stop line when it is stopped, a failure line on any
    /// failure.
    private func handleAdvertiserState(_ newState: ServiceAdvertiser.State) {
        let mapped = map(newState)
        switch mapped {
        case .advertising, .paired:
            eventLog.record("Advertising as \(advertiser.name)")
        case .stopped:
            eventLog.record("Stopped")
        case .failed:
            // The message itself is not logged: it can name the device id
            // (the TXT-record refusal in `ServiceAdvertiser.start`), and the
            // log is exported and shared (TASK-008). Outcome only.
            eventLog.record("Advertiser failed")
        case .idle:
            break
        }
        if Thread.isMainThread {
            status = mapped
        } else {
            DispatchQueue.main.async { self.status = mapped }
        }
    }

    func handleScenePhase(_ phase: ScenePhase) {
        switch phase {
        case .background:
            if status == .advertising || advertiser.state == .advertising {
                advertiser.stop()
            }
        case .active:
            if status == .stopped || advertiser.state == .stopped {
                advertiser.start()
            }
        case .inactive:
            break
        @unknown default:
            break
        }
    }

    func scenePhaseChanged(_ phase: ScenePhase) {
        handleScenePhase(phase)
    }

    func updateScenePhase(_ phase: ScenePhase) {
        handleScenePhase(phase)
    }

    private func map(_ state: ServiceAdvertiser.State) -> ReceiverStatus {
        switch state {
        case .idle:
            return .idle
        case .advertising:
            // While paired, advertising must not replace the paired status
            // (TASK-021); the advertiser state is still logged above.
            return pairingStore.paired ? .paired : .advertising
        case .failed(let message):
            return .failed(message)
        case .stopped:
            return .stopped
        }
    }
}