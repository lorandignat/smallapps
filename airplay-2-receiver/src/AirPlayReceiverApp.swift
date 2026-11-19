import SwiftUI

/// Facts about the app that the rest of the code needs.
///
/// `displayName` is the name the receiver advertises itself under by default and
/// the name the state screen shows (FEAT-001, SPEC §1), so both read it from
/// here instead of repeating the string.
enum AppInfo {
    static let displayName = "AirPlay Receiver"
}

@main
struct AirPlayReceiverApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
