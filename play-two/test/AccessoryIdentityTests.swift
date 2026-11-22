import XCTest
@testable import PlayTwo

/// Keychain-persisted Ed25519 accessory identity (TASK-015).
///
/// Every test builds `AccessoryIdentity` instances on a unique service and
/// deletes the entry in teardown, so the app's real entry
/// (`com.lorand.playtwo.hap-identity`) is never touched and no entries leak
/// into later runs.
final class AccessoryIdentityTests: XCTestCase {
    private var services: [String] = []

    override func tearDown() {
        for service in services {
            AccessoryIdentity.deleteEntry(service: service)
        }
        services.removeAll()
        super.tearDown()
    }

    /// A service string unique to this test, recorded for teardown deletion.
    private func freshService() -> String {
        let service = "com.lorand.playtwo.hap-identity.\(UUID().uuidString)"
        services.append(service)
        return service
    }

    /// Criterion 1: with nothing stored, the identity generates a key pair
    /// whose public key is exactly 32 bytes and non-zero, and the seed is
    /// stored.
    func testGeneratesNonZeroPublicKey() {
        let service = freshService()
        let identity = AccessoryIdentity(service: service)
        XCTAssertEqual(identity.publicKey.count, 32)
        XCTAssertFalse(identity.publicKey.allSatisfy { $0 == 0 })
        XCTAssertNotNil(AccessoryIdentity.storedSeed(service: service))
    }

    /// Criterion 2 (reload form): a second instance on the same service
    /// returns the byte-identical public key — the stored key pair is
    /// reloaded, not regenerated (a fresh random key would differ).
    func testSecondInstanceReloadsStoredPublicKey() {
        let service = freshService()
        let first = AccessoryIdentity(service: service)
        XCTAssertNotNil(AccessoryIdentity.storedSeed(service: service))
        let second = AccessoryIdentity(service: service)
        XCTAssertEqual(first.publicKey, second.publicKey)
    }

    /// Criterion 2 (singleton form): `loadOrCreate()` called again in the
    /// same process returns the same public key.
    func testLoadOrCreateTwiceReturnsSamePublicKey() {
        let first = AccessoryIdentity.loadOrCreate()
        let second = AccessoryIdentity.loadOrCreate()
        XCTAssertEqual(first.publicKey, second.publicKey)
    }

    /// Criterion 4: after the Keychain entry is deleted, the next identity
    /// on the same service generates a new key pair — stored again — whose
    /// public key differs from the deleted one.
    func testDeletedEntryGeneratesAndStoresANewKey() {
        let service = freshService()
        let first = AccessoryIdentity(service: service)
        let firstPublicKey = first.publicKey

        AccessoryIdentity.deleteEntry(service: service)
        XCTAssertNil(AccessoryIdentity.storedSeed(service: service))

        let second = AccessoryIdentity(service: service)
        XCTAssertNotEqual(second.publicKey, firstPublicKey)
        XCTAssertNotNil(AccessoryIdentity.storedSeed(service: service))
    }
}
