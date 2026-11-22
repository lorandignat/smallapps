import XCTest
@testable import PlayTwo

/// Keychain-persisted pairing state (TASK-017).
///
/// Every test builds `HAPPairingStore` instances on a unique service and
/// deletes the entry in teardown, so the app's real entry
/// (`com.lorand.playtwo.hap-pairing`) is never touched and no entries leak
/// into later runs.
final class HAPPairingStoreTests: XCTestCase {
    private var services: [String] = []

    override func tearDown() {
        for service in services {
            HAPPairingStore(service: service).delete()
        }
        services.removeAll()
        super.tearDown()
    }

    /// A service string unique to this test, recorded for teardown deletion.
    private func freshService() -> String {
        let service = "com.lorand.playtwo.hap-pairing.\(UUID().uuidString)"
        services.append(service)
        return service
    }

    /// Criterion 1: with nothing stored, the store has no record and reads
    /// unpaired.
    func testFreshStoreHasNoRecordAndIsUnpaired() {
        let store = HAPPairingStore(service: freshService())
        XCTAssertNil(store.record)
        XCTAssertFalse(store.paired)
    }

    /// Criterion 1 (reload form): after saving a record with a 16-byte salt,
    /// a new instance on the same service reloads the equal record, and it is
    /// unpaired.
    func testSaveAndReloadAcrossInstances() {
        let service = freshService()
        let saved = HAPPairingStore.Record(
            salt: Data(repeating: 0xA1, count: 16),
            verifier: Data(repeating: 0xB2, count: 384),
            paired: false
        )
        HAPPairingStore(service: service).save(record: saved)
        let reloaded = HAPPairingStore(service: service)
        XCTAssertEqual(reloaded.record, saved, "the record must reload from the Keychain")
        XCTAssertFalse(reloaded.paired, "the saved record is unpaired")
    }

    /// Criterion 2 (restart survival): a saved record with `paired: true`
    /// reloads as paired on a new instance on the same service.
    func testPairedStateReloadsAcrossInstances() {
        let service = freshService()
        HAPPairingStore(service: service).save(record: HAPPairingStore.Record(
            salt: Data(repeating: 0xC3, count: 16),
            verifier: Data(repeating: 0xD4, count: 384),
            paired: true
        ))
        XCTAssertTrue(HAPPairingStore(service: service).paired)
    }

    /// A second `save` replaces the stored record: a new instance reads the
    /// replacement, not the first record.
    func testSaveReplacesTheRecord() {
        let service = freshService()
        let store = HAPPairingStore(service: service)
        store.save(record: HAPPairingStore.Record(
            salt: Data(repeating: 0x01, count: 16),
            verifier: Data(repeating: 0x02, count: 384),
            paired: false
        ))
        let replacement = HAPPairingStore.Record(
            salt: Data(repeating: 0x03, count: 16),
            verifier: Data(repeating: 0x04, count: 384),
            paired: true
        )
        store.save(record: replacement)
        XCTAssertEqual(HAPPairingStore(service: service).record, replacement)
    }

    /// Criterion: after `delete()`, a new instance on the same service has no
    /// record and reads unpaired.
    func testDeleteClearsTheRecord() {
        let service = freshService()
        let store = HAPPairingStore(service: service)
        store.save(record: HAPPairingStore.Record(
            salt: Data(repeating: 0x05, count: 16),
            verifier: Data(repeating: 0x06, count: 384),
            paired: true
        ))
        XCTAssertNotNil(store.record)
        store.delete()
        XCTAssertNil(HAPPairingStore(service: service).record)
        XCTAssertFalse(HAPPairingStore(service: service).paired)
    }
}
