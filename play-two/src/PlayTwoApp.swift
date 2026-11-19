import SwiftUI

/// Facts about the app that the rest of the code needs.
///
/// `displayName` is the name the receiver advertises itself under by default and
/// the name the state screen shows (FEAT-001, SPEC §1), so both read it from
/// here instead of repeating the string.
enum AppInfo {
    static let displayName = "PlayTwo"
}

@main
struct PlayTwoApp: App {

    /// The one advertiser for the process.
    ///
    /// SwiftUI creates the `App` struct once at launch and keeps it for the
    /// lifetime of the process, so this stored reference does too: the
    /// `_airplay._tcp` registration lives exactly as long as the app does.
    /// Showing its state is TASK-005; withdrawing it when the app leaves the
    /// foreground is TASK-006.
    private let advertiser: ServiceAdvertiser

    init() {
        advertiser = ServiceAdvertiser()
        advertiser.start()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
