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

final class AppState: ObservableObject {
    @Published var status: ReceiverStatus = .idle
}
