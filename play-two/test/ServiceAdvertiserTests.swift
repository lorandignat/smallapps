import Network
import XCTest
@testable import PlayTwo

/// The published service descriptor and the refusal paths (TASK-004, FEAT-001
/// S1a/S1d).
///
/// Every advertiser here binds an ephemeral port (`.any`), never 7000: macOS
/// ControlCenter owns 7000 on the test host, so a listener on it never becomes
/// ready there and no registration appears (`DEC-011`, `DEC-012`). The
/// registration itself is real mDNSResponder work even so; the real port is
/// device evidence (`DEC-012`).
final class ServiceAdvertiserTests: XCTestCase {

    /// A valid device id, written out here rather than taken from the record
    /// under test.
    private static let deviceID = "0A:1B:2C:3D:4E:5F"

    /// Advertisers a test started, stopped in `tearDown` so no registration
    /// outlives its test.
    private var tracked: [ServiceAdvertiser] = []

    override func tearDown() {
        for advertiser in tracked {
            // A refused start made no listener, so there is no socket and no
            // state change to wait for.
            guard advertiser.listener != nil else { continue }
            let stopped = expectation(description: "advertiser reports stopped")
            advertiser.onStateChange = { state in
                if state == .stopped { stopped.fulfill() }
            }
            advertiser.stop()
            wait(for: [stopped], timeout: 5)
        }
        tracked.removeAll()
        super.tearDown()
    }

    // MARK: - Criterion 1

    func testStartPublishesTheAirPlayServiceForAValidDeviceID() {
        // The app passes neither port nor name, so the defaults are the
        // contract and are asserted, not assumed (`DEC-011`).
        let defaults = ServiceAdvertiser(deviceID: Self.deviceID)
        XCTAssertEqual(
            defaults.port.rawValue,
            7000,
            "the service must point at the AirPlay 2 port"
        )
        XCTAssertEqual(defaults.name, "PlayTwo", "the instance name must be the app's name")

        let advertiser = startAdvertising()

        guard let service = advertiser.listener?.service else {
            return XCTFail("the advertiser has no listener service")
        }
        XCTAssertEqual(service.type, "_airplay._tcp", "the Apple TV browses _airplay._tcp")
        XCTAssertEqual(service.name, "PlayTwo", "the instance name must be the app's name")
        XCTAssertEqual(
            service.txtRecordObject?.dictionary ?? [:],
            [
                "deviceid": Self.deviceID,
                "features": "0x3C356BD04A7FCA00",
                "model": "AudioAccessory1,1",
                "srcvers": "366.0",
                "sf": "0",
                "vv": "2",
            ],
            "the registered TXT values are the TASK-002 record plus the TASK-020 `sf` flag"
        )
        XCTAssertEqual(advertiser.state, .advertising)
    }

    // MARK: - Criterion 2

    func testStartReachesAdvertisingWithinTwoSeconds() {
        let advertiser = ServiceAdvertiser(name: "PlayTwo", port: .any, deviceID: Self.deviceID)
        let advertising = expectation(description: "advertiser reports advertising")
        advertiser.onStateChange = { state in
            if state == .advertising { advertising.fulfill() }
        }
        tracked.append(advertiser)
        advertiser.start()

        wait(for: [advertising], timeout: 2)

        XCTAssertEqual(advertiser.state, .advertising)
        XCTAssertNotNil(advertiser.listener, "advertising without a listener is not publishing")
    }

    // MARK: - Criterion 3

    func testLongNameFailsWith63AndPublishesNothing() {
        // 64 UTF-8 bytes: one byte over Bonjour's limit for an instance name.
        assertRefusedForLongName(String(repeating: "a", count: 64))

        // The same 64 bytes written as 32 two-byte characters: the limit is
        // UTF-8 bytes, not characters.
        let multibyte = String(repeating: "é", count: 32)
        XCTAssertEqual(multibyte.utf8.count, 64)
        XCTAssertEqual(multibyte.count, 32)
        assertRefusedForLongName(multibyte)

        // The other input that cannot be published intact: a device id that
        // makes no TXT record (`AirPlayTXTRecord.init?` requires its caller to
        // refuse rather than publish a malformed record).
        let invalid = ServiceAdvertiser(name: "PlayTwo", port: .any, deviceID: "not-a-device-id")
        invalid.start()
        guard case .failed = invalid.state else {
            return XCTFail("expected .failed for an invalid device id, got \(invalid.state)")
        }
        XCTAssertNil(invalid.listener, "nothing may be published for an invalid device id")
    }

    // MARK: - Rework: a denied local-network permission becomes `.failed`

    /// A denied Bonjour registration surfaces as `kDNSServiceErr_PolicyDenied`
    /// (-72008) from a listener that has reached `.waiting`, which
    /// ``ReceiverListener`` forwards as `.failed`. The advertiser must leave
    /// `.advertising` and say why: on a device without the required
    /// `project.yml` declarations the registration is refused silently, and
    /// the simulator never enforces the permission, so this is the only state
    /// a tester can see.
    func testPolicyDeniedRegistrationFailsInsteadOfStayingAdvertising() {
        let advertiser = ServiceAdvertiser(name: "PlayTwo", port: .any, deviceID: Self.deviceID)
        advertiser.listenerChanged(.listening)
        XCTAssertEqual(
            advertiser.state,
            .advertising,
            "precondition: the listener had reached .listening, i.e. .advertising"
        )

        advertiser.listenerChanged(.failed(.dns(-72008)))

        guard case .failed(let message) = advertiser.state else {
            return XCTFail(
                "a policy-denied registration must report .failed, got \(advertiser.state)"
            )
        }
        XCTAssertTrue(
            message.contains("Local Network"),
            "the message must point at the Local Network permission, got \"\(message)\""
        )
        XCTAssertTrue(
            message.contains("denied"),
            "the message must say the permission was denied, got \"\(message)\""
        )
    }

    // MARK: - Helpers

    /// Starts an advertiser on an ephemeral port and waits until it reports
    /// `.advertising`.
    private func startAdvertising(timeout: TimeInterval = 5) -> ServiceAdvertiser {
        let advertiser = ServiceAdvertiser(name: "PlayTwo", port: .any, deviceID: Self.deviceID)
        let advertising = expectation(description: "advertiser reports advertising")
        advertiser.onStateChange = { state in
            if state == .advertising { advertising.fulfill() }
        }
        tracked.append(advertiser)
        advertiser.start()
        wait(for: [advertising], timeout: timeout)
        return advertiser
    }

    /// Starts an advertiser whose `name` is over the limit and asserts the start
    /// was refused, that the message names the 63-byte limit, and that nothing
    /// was published — truncated or otherwise.
    private func assertRefusedForLongName(_ name: String) {
        let advertiser = ServiceAdvertiser(name: name, port: .any, deviceID: Self.deviceID)
        advertiser.start()

        guard case .failed(let message) = advertiser.state else {
            return XCTFail(
                "expected .failed for a \(name.utf8.count)-byte name, got \(advertiser.state)"
            )
        }
        XCTAssertTrue(
            message.contains("63"),
            "the failure must name the 63-byte limit, got \"\(message)\""
        )
        XCTAssertNil(advertiser.listener, "nothing may be published, truncated or otherwise")
    }
}
