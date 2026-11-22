import CryptoKit
import Foundation

/// Errors thrown by `HAPPairVerify.Session.seal` and `HAPPairVerify.Session.open`.
enum HAPPairVerifyError: Error, Equatable {
    /// The session key is armed only by request 2; sealing or opening before
    /// that has nothing to encrypt or decrypt with.
    case keyNotArmed
}

/// The accessory-side `POST /pair-verify` state (TASK-019).
///
/// One `Session` per exchange: the route's request-1 branch constructs
/// `Session(clientA:)` and answers with `b` (TLV type 2); the request-2
/// branch runs `verify(clientT:accessoryPublicKey:salt:)` and, on success,
/// the route answers with `proof` (TLV type 3) and `key` is armed.
/// `seal`/`open` round-trip through CryptoKit's `ChaChaPoly` on the armed
/// key.
final class HAPPairVerify {

    /// One `POST /pair-verify` exchange between the accessory and the phone.
    ///
    /// The client's ephemeral public key `A_e` arrives on request 1 (TLV
    /// type 1); the accessory's ephemeral key pair is generated on
    /// construction and `b` (the accessory ephemeral public key, TLV type 2,
    /// 32 bytes) is the route's answer. Request 2 — the client proof `T`
    /// (TLV type 4) — verifies against `H(A_e ‖ B_e ‌‌‖ accessoryPublicKey ‌‌‖
    /// salt)`; on success `proof` is the server proof
    /// `H(A_e ‖ B_e ‌‌‖ accessoryPublicKey ‌‌‖ T)` (TLV type 3) and `key` is
    /// armed; on failure the route answers 400 and nothing is armed.
    final class Session {

        /// The accessory's ephemeral public key `B_e` — the route answers
        /// it on request 1 (TLV type 2, 32 bytes).
        let b: Data

        /// The server proof `H(A_e ‖ B_e ‌‌‖ accessoryPublicKey ‌‌‖ T)` —
        /// set on request 2; empty until then.
        var proof: Data

        /// The session key, the first 32 bytes of the client proof `T` —
        /// armed on request 2, `nil` until then.
        var key: Data?

        /// The client's ephemeral public key `A_e` from request 1 — the
        /// `A_e` of the two digests; held for request 2's verification.
        private let a: Data

        /// The accessory's ephemeral key pair, held internally.
        private let ephemeral: Curve25519.KeyAgreement.PrivateKey

        /// Creates the session for request 1: generates the accessory
        /// ephemeral key pair, keeps `clientA`, and derives `b`.
        init(clientA: Data) {
            ephemeral = Curve25519.KeyAgreement.PrivateKey()
            a = clientA
            b = Data(ephemeral.publicKey.rawRepresentation)
            proof = Data()
        }

        /// Request 2: verify the client proof `T` against
        /// `H(A_e ‖ B_e ‌‌‖ accessoryPublicKey ‌‌‖ salt)`; on success arm the
        /// session key and set `proof` to the server proof, returning it.
        /// Nil when `T` does not verify — the session stays unverified.
        func verify(clientT: Data, accessoryPublicKey: Data, salt: Data) -> Data? {
            var expected = Data()
            expected.append(contentsOf: a)
            expected.append(contentsOf: b)
            expected.append(contentsOf: accessoryPublicKey)
            expected.append(contentsOf: salt)
            guard SRP.sha512(expected) == clientT else { return nil }
            var proofInput = Data()
            proofInput.append(contentsOf: a)
            proofInput.append(contentsOf: b)
            proofInput.append(contentsOf: accessoryPublicKey)
            proofInput.append(contentsOf: clientT)
            proof = SRP.sha512(proofInput)
            key = Data(clientT.prefix(32))
            return proof
        }

        /// Encrypts `plaintext` into a sealed payload through
        /// `ChaChaPoly` on the armed key. Throws
        /// `HAPPairVerifyError.keyNotArmed` before request 2 armed the key.
        func seal(_ plaintext: Data) throws -> Data {
            guard let key else { throw HAPPairVerifyError.keyNotArmed }
            return try ChaChaPoly.seal(plaintext, using: SymmetricKey(data: key)).combined
        }

        /// Decrypts a payload sealed by `seal` through `ChaChaPoly` on the
        /// armed key. Throws `HAPPairVerifyError.keyNotArmed` before
        /// request 2 armed the key; other failures (bytes that are not a
        /// sealed box) are CryptoKit's own errors.
        func open(_ sealed: Data) throws -> Data {
            guard let key else { throw HAPPairVerifyError.keyNotArmed }
            let box = try ChaChaPoly.SealedBox(combined: sealed)
            return try ChaChaPoly.open(box, using: SymmetricKey(data: key))
        }
    }
}
