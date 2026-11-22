import CryptoKit
import Foundation
import Security

/// The HAP long-term accessory identity (TASK-015).
///
/// An Ed25519 key pair generated on first run and persisted in the Keychain,
/// so the 32-byte public key is stable across launches.
/// `AccessoryIdentity.shared` is the single identity the app uses;
/// `loadOrCreate()` returns it.
///
/// Persistence (SPEC §7): service `com.lorand.playtwo.hap-identity`, account
/// `accessory`, `kSecClassGenericPassword`,
/// `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`. On first run the raw
/// 32-byte private key (the `rawRepresentation` seed) is stored as the
/// password data; later runs reload the seed and re-derive the same key pair
/// (`Curve25519.Signing.PrivateKey(rawRepresentation:)`), so `publicKey` is
/// byte-identical. The seed is never stored anywhere else — not in
/// `UserDefaults`, not in a file.
final class AccessoryIdentity {
    /// Keychain service holding the identity seed (TASK-015, SPEC §7).
    static let defaultService = "com.lorand.playtwo.hap-identity"

    /// Keychain account holding the identity seed.
    static let account = "accessory"

    /// The app's shared identity. Swift static stored properties are lazy, so
    /// the key pair is generated on first access to this property.
    static let shared = AccessoryIdentity()

    /// Returns the app's identity (`shared`), generating and storing the key
    /// pair when the Keychain has none yet.
    static func loadOrCreate() -> AccessoryIdentity {
        shared
    }

    /// The Ed25519 public key, exactly 32 bytes.
    let publicKey: Data

    /// Creates the identity on `service`: reloads the stored seed when the
    /// Keychain has an entry, otherwise generates a key pair and stores its
    /// seed. Tests pass a unique service per test and delete the entry in
    /// teardown, so they never touch the app's real entry.
    init(service: String = AccessoryIdentity.defaultService) {
        if let seed = Self.storedSeed(service: service),
            let keyPair = try? Curve25519.Signing.PrivateKey(rawRepresentation: seed) {
            self.publicKey = keyPair.publicKey.rawRepresentation
        } else {
            let keyPair = Curve25519.Signing.PrivateKey()
            Self.storeSeed(keyPair.rawRepresentation, service: service)
            self.publicKey = keyPair.publicKey.rawRepresentation
        }
    }

    /// The stored seed for `service`, or nil when the entry is absent or
    /// unreadable.
    static func storedSeed(service: String = AccessoryIdentity.defaultService) -> Data? {
        var query = Self.query(service: service)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let seed = result as? Data else {
            return nil
        }
        return seed
    }

    /// Deletes the Keychain entry for `service`; tests call this in teardown.
    static func deleteEntry(service: String = AccessoryIdentity.defaultService) {
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

    private static func storeSeed(_ seed: Data, service: String) {
        var attributes = Self.query(service: service)
        attributes[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        // Replace any stale entry before adding the new seed.
        SecItemDelete(attributes as CFDictionary)
        attributes[kSecValueData as String] = seed
        SecItemAdd(attributes as CFDictionary, nil)
    }
}
