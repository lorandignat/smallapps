import Foundation
import Network
import XCTest
@testable import PlayTwo

/// The AirPlay identity and TXT record contract (TASK-002, FEAT-001).
final class AirPlayTXTRecordTests: XCTestCase {

    /// Criterion 1: two reads in the same process return one identity, and only
    /// that one value is stored under the fixed key.
    func testCurrentIsStableAndStoredOnce() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: DeviceIdentity.storageKey)

        let first = DeviceIdentity.current
        let second = DeviceIdentity.current

        XCTAssertEqual(first, second)
        XCTAssertEqual(first.count, 17)
        XCTAssertTrue(DeviceIdentity.isValidDeviceID(first), first)
        XCTAssertTrue(defaults.object(forKey: DeviceIdentity.storageKey) is String)
        XCTAssertEqual(defaults.string(forKey: DeviceIdentity.storageKey), first)
    }

    /// Criterion 1, persistence half: a second store over the same domain finds
    /// the identity the first one generated, so a later launch is unchanged. The
    /// domain holds exactly one key.
    func testIdentityIsReusedAcrossStoreInstances() throws {
        let suiteName = "DeviceIdentityTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        defaults.removePersistentDomain(forName: suiteName)

        let first = DeviceIdentity.Store(defaults: defaults).deviceID
        let second = DeviceIdentity.Store(defaults: defaults).deviceID

        XCTAssertEqual(first, second)
        XCTAssertEqual(first.count, 17)

        let persisted = defaults.persistentDomain(forName: suiteName) ?? [:]
        XCTAssertEqual(persisted.count, 1)
        XCTAssertEqual(persisted[DeviceIdentity.storageKey] as? String, first)
    }

    /// Criterion 2: exactly the six required keys — `deviceid`, `features`,
    /// `model`, `srcvers`, `sf` and `vv` — with `deviceid` unchanged, `vv` `2`,
    /// a 64-bit `features` value with bit 38 set, and the unpaired record
    /// publishing `sf == "0"` (TASK-020).
    func testTXTRecordHasTheRequiredKeysAndValues() throws {
        let deviceID = "0A:1B:2C:3D:4E:5F"
        let record = try XCTUnwrap(AirPlayTXTRecord(deviceID: deviceID))
        let dictionary = record.dictionary

        XCTAssertEqual(
            Set(dictionary.keys),
            ["deviceid", "features", "model", "srcvers", "sf", "vv"]
        )
        XCTAssertEqual(dictionary["deviceid"], deviceID)
        XCTAssertEqual(dictionary["vv"], "2")
        XCTAssertEqual(dictionary["model"], AirPlayTXTRecord.model)
        XCTAssertEqual(dictionary["srcvers"], AirPlayTXTRecord.srcvers)
        XCTAssertEqual(dictionary["sf"], "0")

        let features = try XCTUnwrap(dictionary["features"])
        XCTAssertTrue(features.hasPrefix("0x"), features)
        let mask = try XCTUnwrap(UInt64(features.dropFirst(2), radix: 16), features)
        XCTAssertNotEqual(mask & (UInt64(1) << 38), 0, "bit 38 not set in \(features)")
    }

    /// Criterion 3: encoding through `NWTXTRecord` and reading it back changes
    /// no value — no truncation, no case change.
    func testTXTRecordRoundTripsThroughNWTXTRecord() throws {
        let record = try XCTUnwrap(AirPlayTXTRecord(deviceID: "0A:1B:2C:3D:4E:5F"))
        let decoded = record.txtRecord.dictionary

        XCTAssertEqual(decoded, record.dictionary)
        XCTAssertEqual(Set(decoded.keys), Set(record.dictionary.keys))
        XCTAssertEqual(decoded["deviceid"], "0A:1B:2C:3D:4E:5F")
        XCTAssertEqual(decoded["features"], record.dictionary["features"])
    }

    /// TASK-020: the paired flag reaches the TXT record as the `sf` status
    /// flag — `"0"` unpaired (the default), `"1"` paired — and is readable
    /// through `statusFlags`.
    func testPairedStatusAppearsInTheSFFlag() throws {
        let deviceID = "0A:1B:2C:3D:4E:5F"

        let unpaired = try XCTUnwrap(AirPlayTXTRecord(deviceID: deviceID, paired: false))
        XCTAssertEqual(unpaired.dictionary["sf"], "0")
        XCTAssertEqual(unpaired.statusFlags, 0)

        // The default is the unpaired flag.
        let defaulted = try XCTUnwrap(AirPlayTXTRecord(deviceID: deviceID))
        XCTAssertEqual(defaulted.dictionary["sf"], "0")

        let paired = try XCTUnwrap(AirPlayTXTRecord(deviceID: deviceID, paired: true))
        XCTAssertEqual(paired.dictionary["sf"], "1")
        XCTAssertNotEqual(paired.statusFlags & AirPlayTXTRecord.statusFlagPaired, 0)
    }

    /// Criterion 4: an empty or malformed device id produces no record.
    func testInvalidDeviceIDsProduceNoRecord() {
        let invalid = [
            "",
            "0A:1B:2C:3D:4E",
            "0A:1B:2C:3D:4E:5F:60",
            "GG:1B:2C:3D:4E:5F",
            "0a:1b:2c:3d:4e:5f",
        ]
        for deviceID in invalid {
            XCTAssertNil(AirPlayTXTRecord(deviceID: deviceID), deviceID)
        }
    }

    /// Criterion 4, fullwidth digits: `Character.isHexDigit` accepts U+FF10…U+FF19,
    /// so an id spelled with them used to build a record instead of `nil`
    /// (TASK-002 review, finding 1). Only ASCII `0`–`9` may be accepted.
    func testFullwidthDigitsProduceNoRecord() {
        let invalid = [
            "\u{FF10}A:1B:2C:3D:4E:5F",
            "0\u{FF11}:1B:2C:3D:4E:5F",
            "\u{FF10}\u{FF11}:\u{FF12}\u{FF13}:\u{FF14}\u{FF15}:\u{FF16}\u{FF17}:\u{FF18}\u{FF19}:AB",
        ]
        for deviceID in invalid {
            XCTAssertFalse(DeviceIdentity.isValidDeviceID(deviceID), deviceID)
            XCTAssertNil(AirPlayTXTRecord(deviceID: deviceID), deviceID)
        }
    }

    /// Criterion 4, fullwidth letters: U+FF21…U+FF26 are the Unicode look-alikes
    /// of `A`–`F` and are `isHexDigit`; they must not be accepted either.
    func testFullwidthLettersProduceNoRecord() {
        let invalid = [
            "\u{FF21}A:1B:2C:3D:4E:5F",
            "A\u{FF21}:1B:2C:3D:4E:5F",
            "\u{FF21}\u{FF22}:\u{FF23}\u{FF24}:\u{FF25}\u{FF26}:1B:2C:3D:4E:5F",
        ]
        for deviceID in invalid {
            XCTAssertFalse(DeviceIdentity.isValidDeviceID(deviceID), deviceID)
            XCTAssertNil(AirPlayTXTRecord(deviceID: deviceID), deviceID)
        }
    }
}
