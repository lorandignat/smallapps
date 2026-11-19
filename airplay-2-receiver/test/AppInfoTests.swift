import XCTest
@testable import AirPlayReceiver

final class AppInfoTests: XCTestCase {
    /// The advertised name is the app's public identity on the network and on
    /// the state screen, so the exact string is a contract (FEAT-001, S1).
    func testDisplayNameIsTheAdvertisedName() {
        XCTAssertFalse(AppInfo.displayName.isEmpty)
        XCTAssertEqual(AppInfo.displayName, "AirPlay Receiver")
    }
}
