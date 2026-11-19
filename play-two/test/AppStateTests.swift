import Network
import SwiftUI
import XCTest
@testable import PlayTwo

final class SpyAdvertiser: ServiceAdvertiserProtocol {
    let name: String
    var state: ServiceAdvertiser.State
    var onStateChange: ((ServiceAdvertiser.State) -> Void)?
    private(set) var startCount = 0
    private(set) var stopCount = 0
    var stopError: NWError?

    init(name: String = "PlayTwo") {
        self.name = name
        self.state = .idle
    }

    func start() {
        startCount += 1
        state = .advertising
        onStateChange?(.advertising)
    }

    func stop() {
        stopCount += 1
        if let error = stopError {
            let failed = ServiceAdvertiser.failure(for: error)
            state = failed
            onStateChange?(failed)
        } else {
            state = .stopped
            onStateChange?(.stopped)
        }
    }
}

final class AppStateTests: XCTestCase {
    private var spy: SpyAdvertiser!
    private var appState: AppState!

    override func setUp() {
        super.setUp()
        spy = SpyAdvertiser()
        appState = AppState(advertiser: spy)
    }

    override func tearDown() {
        spy = nil
        appState = nil
        super.tearDown()
    }

    // MARK: - Criterion 1
    func testBackgroundStopsAdvertiser() {
        appState.status = .advertising
        spy.state = .advertising

        appState.handleScenePhase(.background)

        XCTAssertEqual(spy.stopCount, 1, "stop() must be called exactly once")
        XCTAssertEqual(appState.status, .stopped, "status must be .stopped after backgrounding")
    }

    // MARK: - Criterion 2
    func testActiveRestartsAdvertiser() {
        appState.status = .stopped
        spy.state = .stopped

        appState.handleScenePhase(.active)

        XCTAssertEqual(spy.startCount, 1, "start() must be called once")
        XCTAssertEqual(spy.name, "PlayTwo", "start() must use the same service name")
        XCTAssertEqual(appState.status, .advertising, "status must be .advertising after returning")
    }

    // MARK: - Criterion 3
    func testInactiveDoesNotStopAdvertiser() {
        appState.status = .advertising
        spy.state = .advertising

        appState.handleScenePhase(.inactive)

        XCTAssertEqual(spy.stopCount, 0, "stop() must not be called on .inactive")
        XCTAssertEqual(appState.status, .advertising, "status must stay .advertising on .inactive")
    }

    // MARK: - Criterion 4
    func testStopFailureReportsFailed() {
        spy.stopError = .posix(.EADDRINUSE)
        appState.status = .advertising
        spy.state = .advertising

        appState.handleScenePhase(.background)

        XCTAssertEqual(spy.stopCount, 1, "stop() must be called once")
        guard case .failed = appState.status else {
            return XCTFail("expected .failed, got \(appState.status)")
        }
        XCTAssertTrue(
            appState.status.statusText(name: AppInfo.displayName).hasPrefix("Error:"),
            "failed status must render as Error: …"
        )
    }
}