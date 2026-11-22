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
    /// Keychain services seeded by the restart-survival test, deleted in teardown.
    private var services: [String] = []

    override func setUp() {
        super.setUp()
        spy = SpyAdvertiser()
        appState = AppState(advertiser: spy)
    }

    override func tearDown() {
        for service in services {
            HAPPairingStore(service: service).delete()
        }
        services.removeAll()
        spy = nil
        appState = nil
        super.tearDown()
    }

    /// A Keychain service unique to this test, tracked for teardown deletion so
    /// the app's real pairing entry is never touched.
    private func freshService() -> String {
        let service = "com.lorand.playtwo.hap-pairing.task021.\(UUID().uuidString)"
        services.append(service)
        return service
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

    // MARK: - Criterion 1 & 2 (TASK-021): restart survival
    func testStatusIsPairedWhenThePairingIsStored() {
        // The default (unpaired) store still reads .idle at launch.
        let unpaired = AppState(
            advertiser: SpyAdvertiser(),
            pairingStore: HAPPairingStore(service: freshService())
        )
        XCTAssertEqual(unpaired.status, .idle, "an unpaired store must read .idle at launch")

        // A stored pairing makes the relaunched app read .paired.
        let service = freshService()
        HAPPairingStore(service: service).save(record: HAPPairingStore.Record(
            salt: Data(repeating: 0xC3, count: 16),
            verifier: Data(repeating: 0xD4, count: 384),
            paired: true
        ))
        let store = HAPPairingStore(service: service)
        let pairedSpy = SpyAdvertiser()
        let pairedState = AppState(advertiser: pairedSpy, pairingStore: store)

        XCTAssertEqual(pairedState.status, .paired, "a stored pairing must make the app launch .paired")
        XCTAssertEqual(
            pairedState.status.statusText(name: AppInfo.displayName),
            "Paired",
            "the paired status must render as Paired"
        )

        // Advertising must not overwrite the paired status: map(.advertising)
        // stays .paired while the store records paired: true.
        pairedSpy.state = .stopped
        pairedState.scenePhaseChanged(.active)
        XCTAssertEqual(pairedSpy.startCount, 1, "the advertiser must report .advertising on .active")
        XCTAssertEqual(pairedState.status, .paired, "advertising must not replace the paired status")
    }
}