import CryptoKit
import Foundation

/// The `POST /pair-setup` SRP exchange (TASK-018).
///
/// Request 1 — the client's public value `A` (TLV type 4) — starts the
/// exchange: `SRP.generateEphemeral` runs, the record
/// `HAPPairingStore.Record(salt: verifier: paired: false)` is persisted and
/// `start` returns the accessory public value `B` (the route's TLV type 3)
/// and the salt (the route's TLV type 6). A restart reuses the stored
/// verifier: the record's salt is kept, so the client derives the same
/// `v = g^x mod N` from the salt the route sends.
///
/// Request 2 — the client proof `M4 = H(A ‖ B ‖ K)` (TLV type 4) — is
/// verified by `SRP.verify`; on success `complete` returns the accessory
/// proof `M5 = H(A ‖ M4 ‖ K)` (the route's TLV type 5) and the accessory
/// session start `M6 = K[0..<16]` (the route's TLV type 7), and marks the
/// record paired. A tampered proof returns nil and leaves the record
/// unpaired.
///
/// `SRP.generateEphemeral` takes ~27 s (TASK-013) and `SRP.verify` ~125 s
/// (TASK-014); callers run them off the main thread, as the tests do.
final class HAPPairSetup {

    /// The store the record is persisted to (the app's shared store by
    /// default).
    let store: HAPPairingStore

    /// The in-memory exchange session, or nil until request 1.
    private var session: SRPServerSession?

    /// The client's public value from request 1 — the `A` in
    /// `SRP.verify(session:clientA:clientM1:)`.
    private var clientA: Data?

    /// Whether request 2 follows request 1: the exchange has been started.
    var isStarted: Bool {
        session != nil
    }

    /// Creates an exchange on `store`.
    init(store: HAPPairingStore = HAPPairingStore.shared) {
        self.store = store
    }

    /// Request 1: given the client's public value `A`, generate the
    /// ephemeral session, persist the record and return the accessory
    /// public value `B` and the salt to send in TLV type 6. Nil when the
    /// exchange is already started or the session cannot be generated.
    func start(clientA: Data) -> (B: Data, salt: Data)? {
        guard session == nil else { return nil }
        let salt: Data
        var v: Data?
        if let record = store.record, !record.verifier.isEmpty {
            // Restart: reuse the stored verifier and its salt, so the
            // client derives the same `v = g^x mod N` from the salt we send.
            salt = record.salt
            v = record.verifier
        } else {
            salt = Self.freshSalt()
            v = SRP.deriveVerifier(setupCode: HAPServer.setupCode, salt: salt)
        }
        guard let v, let generated = SRP.generateEphemeral(v: v) else { return nil }
        session = generated
        self.clientA = clientA
        store.save(record: HAPPairingStore.Record(salt: salt, verifier: v, paired: false))
        return (B: generated.B, salt: salt)
    }

    /// Request 2: given the client proof `M4`, verify it; on success return
    /// the accessory proof `M5 = H(A ‖ M4 ‖ K)` and the accessory session
    /// start `M6 = K[0..<16]` along with the session key `K`, and mark the
    /// record paired. Nil when the proof does not verify — the record stays
    /// unpaired.
    func complete(clientM4: Data) -> (M5: Data, M6: Data, K: Data)? {
        guard let serverSession = session, let clientA = clientA else { return nil }
        guard let result = SRP.verify(session: serverSession, clientA: clientA, clientM1: clientM4) else {
            return nil
        }
        // M5 = H(A ‖ M4 ‖ K); M6 = K[0..<16] — the accessory session start.
        var m5Input = Data()
        m5Input.append(contentsOf: clientA)
        m5Input.append(contentsOf: clientM4)
        m5Input.append(contentsOf: result.K)
        let M5 = SRP.sha512(m5Input)
        let M6 = result.K[0..<16]
        // The record was saved on request 1; flip it to paired.
        if let record = store.record {
            store.save(record: HAPPairingStore.Record(salt: record.salt, verifier: record.verifier, paired: true))
        }
        return (M5: M5, M6: M6, K: result.K)
    }

    /// A fresh 16-byte salt — `SymmetricKey(size: .bits128)`, as `SRP` does
    /// in `generateEphemeral`.
    private static func freshSalt() -> Data {
        SymmetricKey(size: .bits128).withUnsafeBytes { Data($0) }
    }
}
