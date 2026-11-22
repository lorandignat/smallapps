import XCTest
@testable import PlayTwo

final class ReceiverStatusTests: XCTestCase {
    func testIdle() {
        XCTAssertEqual(
            ReceiverStatus.idle.statusText(name: AppInfo.displayName),
            "Idle"
        )
    }

    func testAdvertising() {
        XCTAssertEqual(
            ReceiverStatus.advertising.statusText(name: AppInfo.displayName),
            "Advertising as PlayTwo"
        )
    }

    func testFailed() {
        XCTAssertEqual(
            ReceiverStatus.failed("port 7000 in use").statusText(name: AppInfo.displayName),
            "Error: port 7000 in use"
        )
    }

    func testStopped() {
        XCTAssertEqual(
            ReceiverStatus.stopped.statusText(name: AppInfo.displayName),
            "Stopped"
        )
    }

    func testPaired() {
        XCTAssertEqual(
            ReceiverStatus.paired.statusText(name: AppInfo.displayName),
            "Paired"
        )
    }
}
