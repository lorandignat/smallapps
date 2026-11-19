import Combine
import SwiftUI

enum ReceiverStatus: Equatable {
    case idle
    case advertising
    case failed(String)
    case stopped

    func statusText(name: String) -> String {
        switch self {
        case .idle:
            return "Idle"
        case .advertising:
            return "Advertising as \(name)"
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

    init(advertiser: ServiceAdvertiserProtocol) {
        self.advertiser = advertiser
        advertiser.onStateChange = { [weak self] newState in
            let mapped = AppState.map(newState)
            if Thread.isMainThread {
                self?.status = mapped
            } else {
                DispatchQueue.main.async { self?.status = mapped }
            }
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

    private static func map(_ state: ServiceAdvertiser.State) -> ReceiverStatus {
        switch state {
        case .idle:
            return .idle
        case .advertising:
            return .advertising
        case .failed(let message):
            return .failed(message)
        case .stopped:
            return .stopped
        }
    }
}