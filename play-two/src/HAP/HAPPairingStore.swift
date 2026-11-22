import Foundation
import Security

/// The HAP pairing state (TASK-017).
///
/// Holds the pairing record the phone needs to pair with the accessory
/// (`salt`, `verifier`, `paired`), persisted in the Keychain as JSON in
/// `kSecValueData` — the same shape as `AccessoryIdentity` (SPEC §7): keyed by
/// `service` + `account`, `kSecClassGenericPassword`,
/// `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`. A new instance on the
/// same service reloads the record from the Keychain, so the pairing
/// survives a relaunch; `HAPServer.route` reads `paired` through it.
final class HAPPairingStore {

    /// Keychain service holding the pairing record (TASK-017).
    static let defaultService = "com.lorand.playtwo.hap-pairing"

    /// The app's shared pairing state. Swift static stored properties are
    /// lazy, so the Keychain entry is read on first access.
    static let shared = HAPPairingStore()

    /// Keychain account holding the pairing record.
    static let account = "pairing"

    /// The stored pairing record: the SRP salt and verifier and the paired
    /// flag `GET /info` reports.
    struct Record: Codable, Equatable {
        /// The SRP salt, 16 bytes.
        let salt: Data
        /// The SRP-3072 verifier, 384 bytes.
        let verifier: Data
        /// Whether the accessory is paired with the phone.
        let paired: Bool
    }

    /// The Keychain service this store reads and writes.
    let service: String

    /// Creates a store on `service`: it reads the Keychain as it is — no
    /// generation, no write. Tests pass a unique service per test and delete
    /// the entry in teardown, so they never touch the app's real entry.
    init(service: String = HAPPairingStore.defaultService) {
        self.service = service
    }

    /// The stored record, or nil when the Keychain has none (or the entry is
    /// unreadable).
    var record: Record? {
        guard let data = Self.storedRecordData(service: service) else { return nil }
        return try? JSONDecoder().decode(Record.self, from: data)
    }

    /// Whether the accessory is paired: the stored record's flag, false when
    /// there is no record yet.
    var paired: Bool {
        record?.paired ?? false
    }

    /// Saves `record` to the Keychain, replacing any stale entry first.
    func save(record: Record) {
        guard let data = try? JSONEncoder().encode(record) else { return }
        var attributes = Self.query(service: service)
        attributes[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        attributes[kSecValueData as String] = data
        // Replace any stale entry before adding the new record.
        SecItemDelete(attributes as CFDictionary)
        SecItemAdd(attributes as CFDictionary, nil)
    }

    /// Deletes the Keychain entry for this store's service; tests call this
    /// in teardown.
    func delete() {
        SecItemDelete(Self.query(service: service) as CFDictionary)
    }

    // MARK: - Keychain

    private static func query(service: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
    }

    private static func storedRecordData(service: String) -> Data? {
        var query = Self.query(service: service)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
            let data = result as? Data else {
            return nil
        }
        return data
    }
}
