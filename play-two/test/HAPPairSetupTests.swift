import CryptoKit
import Foundation
import XCTest
@testable import PlayTwo

/// The `POST /pair-setup` SRP exchange state machine (TASK-018): request 1
/// starts it and persists `HAPPairingStore.Record(salt: verifier: paired:
/// false)`; request 2 — the client proof `M4 = H(A ‖ B ‖ K)` — completes it
/// through `complete(clientM4:)`, which returns `(M5, M6, K)` and marks the
/// record paired; a tampered proof returns nil.
///
/// `SRP.generateEphemeral` takes ~27 s (TASK-013) and `SRP.verify` ~125 s
/// (TASK-014); the heavy calls run on `DispatchQueue.global()` and the waits
/// use the `SRPTests` timeouts (300 s for the verify legs).
final class HAPPairSetupTests: XCTestCase {

    /// Services of the pairing stores the tests build; deleted in teardown
    /// so the app's real entry is never touched.
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

    // MARK: - Criterion 1

    /// `start` returns the accessory key — `SRP.nByteCount` bytes — and the
    /// salt (≥ 16 bytes); the exchange is started.
    func testStartReturnsTheAccessoryKeyAndTheSalt() {
        let exp = expectation(description: "start")
        DispatchQueue.global().async {
            let pairSetup = HAPPairSetup(store: HAPPairingStore(service: self.freshService()))
            guard let result = pairSetup.start(clientA: self.clientPublicKey().A) else {
                XCTFail("start returned nil")
                exp.fulfill()
                return
            }
            XCTAssertEqual(result.B.count, SRP.nByteCount, "the accessory key is the 384-byte B")
            XCTAssertGreaterThanOrEqual(result.salt.count, 16, "the salt is at least 16 bytes")
            XCTAssertTrue(pairSetup.isStarted, "request 2 follows request 1")
            exp.fulfill()
        }
        wait(for: [exp], timeout: 180)
    }

    // MARK: - Criterion 2

    /// A genuine client proof — `M4 = H(A ‖ B ‖ K)` computed by the client
    /// from the response values (`clientHandshake`) — makes `complete`
    /// return `(M5, M6, K)`: `M5` is the accessory proof `H(A ‖ M4 ‖ K)`,
    /// `M6` is `K[0..<16]` and the accessory K is byte-identical to the
    /// client K; `store.paired` is true.
    func testCompleteReturnsProofAndKeyAndMarksPaired() {
        let exp = expectation(description: "complete")
        DispatchQueue.global().async {
            let store = HAPPairingStore(service: self.freshService())
            let pairSetup = HAPPairSetup(store: store)
            let client = self.clientPublicKey()
            guard let started = pairSetup.start(clientA: client.A) else {
                XCTFail("start returned nil")
                exp.fulfill()
                return
            }
            guard let proof = self.clientHandshake(
                A: client.A, aClient: client.aClient, B: started.B,
                salt: started.salt, code: HAPServer.setupCode
            ) else {
                XCTFail("clientHandshake returned nil")
                exp.fulfill()
                return
            }
            guard let result = pairSetup.complete(clientM4: proof.M4) else {
                XCTFail("complete returned nil for the genuine proof")
                exp.fulfill()
                return
            }
            var m5Input = Data()
            m5Input.append(contentsOf: client.A)
            m5Input.append(contentsOf: proof.M4)
            m5Input.append(contentsOf: result.K)
            XCTAssertEqual(result.M5, SRP.sha512(m5Input), "M5 must be H(A ‖ M4 ‖ K)")
            XCTAssertEqual(result.M6, proof.K[0..<16], "M6 must be the client K's first 16 bytes")
            XCTAssertEqual(result.K, proof.K, "the accessory K must be byte-identical to the client K")
            XCTAssertTrue(store.paired, "the record must be marked paired after a verified proof")
            exp.fulfill()
        }
        wait(for: [exp], timeout: 300)
    }

    // MARK: - Criterion 3

    /// A tampered M4 makes `complete` return nil and `store.paired` stay
    /// false.
    func testCompleteReturnsNilWhenTheProofIsTampered() {
        let exp = expectation(description: "complete")
        DispatchQueue.global().async {
            let store = HAPPairingStore(service: self.freshService())
            let pairSetup = HAPPairSetup(store: store)
            let client = self.clientPublicKey()
            guard let started = pairSetup.start(clientA: client.A) else {
                XCTFail("start returned nil")
                exp.fulfill()
                return
            }
            guard let proof = self.clientHandshake(
                A: client.A, aClient: client.aClient, B: started.B,
                salt: started.salt, code: HAPServer.setupCode
            ) else {
                XCTFail("clientHandshake returned nil")
                exp.fulfill()
                return
            }
            var tampered = proof.M4
            tampered[0] ^= 0xFF
            XCTAssertNil(pairSetup.complete(clientM4: tampered), "a tampered proof must not verify")
            XCTAssertFalse(store.paired, "the record must stay unpaired")
            exp.fulfill()
        }
        wait(for: [exp], timeout: 300)
    }

    // MARK: - Restart

    /// A restart reuses the stored verifier: the second `start` on a fresh
    /// `HAPPairSetup` returns the record's salt and the stored verifier is
    /// still the one the client derives from it.
    func testRestartReusesTheStoredVerifier() {
        let exp = expectation(description: "restart")
        DispatchQueue.global().async {
            let store = HAPPairingStore(service: self.freshService())
            let client = self.clientPublicKey()
            let first = HAPPairSetup(store: store)
            guard first.start(clientA: client.A) != nil else {
                XCTFail("start returned nil")
                exp.fulfill()
                return
            }
            let firstRecord = store.record
            XCTAssertNotNil(firstRecord, "the record must be saved on request 1")
            let second = HAPPairSetup(store: store)
            guard second.start(clientA: client.A) != nil else {
                XCTFail("restart start returned nil")
                exp.fulfill()
                return
            }
            XCTAssertEqual(store.record?.verifier, firstRecord?.verifier, "the restart must reuse the stored verifier")
            XCTAssertTrue(second.isStarted)
            exp.fulfill()
        }
        wait(for: [exp], timeout: 300)
    }

    // MARK: - Client helpers (TASK-014 construction, as in `SRPTests`)

    /// The client's public key: `A = g^aClient mod N`, with the secret `aClient`.
    private struct ClientPublicKey: Equatable {
        let A: Data
        let aClient: Data
    }

    /// A fresh random client public key (the client picks a random `aClient`).
    private func clientPublicKey() -> ClientPublicKey {
        var aClient = Data()
        repeat {
            aClient = SymmetricKey(size: .bits256).withUnsafeBytes { Data($0) }
        } while !aClient.contains(where: { $0 != 0 })
        let A = SRP.data(
            fromLimbs: SRP.modExp(SRP.limbs(from: SRP.g), SRP.limbs(from: aClient)),
            byteCount: SRP.nByteCount
        )
        return ClientPublicKey(A: A, aClient: aClient)
    }

    /// One client-side handshake (TASK-014): from the accessory's response
    /// values (`B`, `salt`) computes the proof `M4 = H(A ‖ B ‖ K)` and the
    /// session key `K`.
    private struct ClientProof: Equatable {
        let M4: Data
        let K: Data
    }

    /// The client proof `M4` and session key `K` — the construction of
    /// `SRPTests.clientHandshake` (TASK-014), with `A` the client public key.
    private func clientHandshake(A: Data, aClient: Data, B: Data, salt: Data, code: String) -> ClientProof? {
        guard let v = SRP.deriveVerifier(setupCode: code, salt: salt) else {
            return nil
        }
        // k·v, Montgomery form — as in `SRPTests.clientHandshake`.
        let kLimbs = SRP.limbs(from: SRP.k())
        let vLimbs = SRP.limbs(from: v)
        let kvLimbs = SRP.redc(SRP.mulmont(SRP.montgomery(kLimbs), SRP.montgomery(vLimbs)))
        // t = B − k·v — the server's base value (t = g^a_server mod N).
        let B_limbs = SRP.limbs(from: B)
        var baseLimbs: [UInt32]
        if SRP.compare(B_limbs, kvLimbs) >= 0 {
            baseLimbs = B_limbs
            SRP.subtractInPlace(&baseLimbs, kvLimbs)
        } else {
            var nMinusKv = SRP.N
            SRP.subtractInPlace(&nMinusKv, kvLimbs)
            baseLimbs = SRP.addMod(B_limbs, nMinusKv)
        }
        // u = H(A ‖ B); x = H(salt ‖ code).
        var uInput = Data()
        uInput.append(contentsOf: A)
        uInput.append(contentsOf: B)
        let uData = SRP.sha512(uInput)
        let uLimbs = SRP.limbs(from: uData)
        let xLimbs = SRP.limbs(from: SRP.x(salt: salt, code: code))
        // S = t^aClient · t^(u·x) — the client session key input (TASK-014).
        let aClientLimbs = SRP.limbs(from: aClient)
        let term1 = SRP.modExp(baseLimbs, aClientLimbs)
        let baseU = SRP.modExp(baseLimbs, uLimbs)
        let term2 = SRP.modExp(baseU, xLimbs)
        let S_limbs = SRP.redc(SRP.mulmont(SRP.montgomery(term1), SRP.montgomery(term2)))
        let S = SRP.data(fromLimbs: S_limbs, byteCount: SRP.nByteCount)
        let K = SRP.sha512(S)
        var m4Input = Data()
        m4Input.append(contentsOf: A)
        m4Input.append(contentsOf: B)
        m4Input.append(contentsOf: K)
        return ClientProof(M4: SRP.sha512(m4Input), K: K)
    }
}
