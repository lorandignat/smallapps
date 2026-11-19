import Foundation

/// The receiver's stable AirPlay device identity.
///
/// iOS hides the hardware MAC address, so the identity is a 48-bit value
/// generated once, on first read, and persisted in `UserDefaults`. It is not the
/// HAP pairing identity: that arrives with pairing in increment 2 and belongs in
/// the Keychain (TASK-002 notes, `DEC-002`).
enum DeviceIdentity {

    /// Fixed `UserDefaults` key. Never rename it: a new key reads as a fresh
    /// install, so the receiver would advertise a second identity.
    static let storageKey = "com.lorand.playtwo.device-id"

    /// The identity of this install, created lazily on the first read.
    ///
    /// The first read persists the value under `storageKey` before returning;
    /// every later read in the process finds that stored value, so there is
    /// exactly one identity per install.
    static var current: String {
        Store().deviceID
    }

    /// The read-and-create half of the identity, over one `UserDefaults`
    /// domain.
    ///
    /// Injected so tests can use a throw-away suite. The app uses `.standard`
    /// through ``current``.
    struct Store {
        private let defaults: UserDefaults

        init(defaults: UserDefaults = .standard) {
            self.defaults = defaults
        }

        /// The stored identity, or a freshly generated one that is stored
        /// before it is returned.
        var deviceID: String {
            // Serialised so two first reads cannot each generate a value: the
            // first one stores its value before the second enters.
            DeviceIdentity.lock.lock()
            defer { DeviceIdentity.lock.unlock() }

            if let stored = defaults.string(forKey: DeviceIdentity.storageKey),
               DeviceIdentity.isValidDeviceID(stored) {
                return stored
            }
            let generated = DeviceIdentity.generate()
            defaults.set(generated, forKey: DeviceIdentity.storageKey)
            return generated
        }
    }

    private static let lock = NSLock()

    /// Whether `value` is the canonical `AA:BB:CC:DD:EE:FF` form.
    ///
    /// Only the upper-case spelling is accepted. A lower-case or otherwise
    /// different id is rejected rather than re-cased silently, so the value that
    /// is advertised is exactly the value that was checked.
    ///
    /// The character test is deliberately byte-level ASCII `0`–`9` and `A`–`F`,
    /// not `Character.isHexDigit`: that property follows Unicode and accepts
    /// look-alikes such as fullwidth `０`…`９` and `Ａ`…`Ｆ`, which would let a
    /// malformed id through (TASK-002 review, finding 1).
    static func isValidDeviceID(_ value: String) -> Bool {
        let groups = value.split(separator: ":", omittingEmptySubsequences: false)
        guard groups.count == 6 else { return false }
        return groups.allSatisfy { group in
            guard group.count == 2 else { return false }
            return group.allSatisfy { character in
                guard let ascii = character.asciiValue else { return false }
                switch ascii {
                case UInt8(ascii: "0")...UInt8(ascii: "9"),
                     UInt8(ascii: "A")...UInt8(ascii: "F"):
                    return true
                default:
                    return false
                }
            }
        }
    }

    /// A random, MAC-shaped 48-bit value.
    ///
    /// The first octet is forced to a valid unicast, locally administered
    /// address, so the result cannot collide with a real vendor prefix.
    static func generate() -> String {
        var octets = (0..<6).map { _ in UInt8.random(in: UInt8.min...UInt8.max) }
        octets[0] = (octets[0] | 0x02) & 0xFE
        return octets.map { String(format: "%02X", $0) }.joined(separator: ":")
    }
}
