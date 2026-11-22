import Foundation
import XCTest
@testable import PlayTwo

/// `POST /pair-verify` — the accessory-side exchange: request 1 answers with
/// the accessory ephemeral public key `B_e` (TLV type 2), request 2 verifies
/// the client proof `T` (TLV type 4) and arms the session key (TASK-019).
final class HAPPairVerifyTests: XCTestCase {

    /// Services of the pairing stores the tests build; deleted in teardown
    /// so the app's real entry is never touched.
    private var pairingServices: [String] = []

    override func tearDown() {
        for service in pairingServices {
            HAPPairingStore(service: service).delete()
        }
        pairingServices.removeAll()
        super.tearDown()
    }

    /// A pairing-store service string unique to this test, recorded for
    /// teardown deletion.
    private func freshPairingService() -> String {
        let service = "com.lorand.playtwo.hap-pairing.\(UUID().uuidString)"
        pairingServices.append(service)
        return service
    }

    // MARK: - Criterion 1, 2 — request 1 carries the accessory key; request 2 verifies

    /// Request 1 — the client's ephemeral public key `A_e` (TLV type 1) —
    /// answers 200 with the accessory ephemeral public key `B_e` (TLV type
    /// 2, 32 bytes) and sets `HAPServer.pairVerifySession`. Request 2 — the
    /// client proof `T = H(A_e ‖ B_e ‌‌‖ accessoryIdentityPublicKey ‌‌‖
    /// pairingSalt)` (TLV type 4) — answers 200 with the server proof
    /// `H(A_e ‖ B_e ‌‌‖ accessoryIdentityPublicKey ‌‌‖ T)` (TLV type 3) and
    /// arms `Session.key`.
    func testRequestOneCarriesTheAccessoryKeyAndRequestTwoVerifies() throws {
        let salt = Data(repeating: 0xAB, count: 16)
        let clientA = Data(repeating: 0x11, count: 32)
        let (server, response1, session, bE) = try startExchange(salt: salt, clientA: clientA)
        XCTAssertEqual(response1.status, 200, "request 1 must answer 200")
        XCTAssertEqual(bE.count, 32, "the accessory ephemeral public key is 32 bytes")
        XCTAssertEqual(bE, session.b, "the TLV key is the session's ephemeral public key")
        XCTAssertNil(session.key, "the session key is armed only on request 2")

        // Request 2: the client computes the proof T from the response
        // values — the digest of A_e, B_e, the accessory identity public key
        // and the pairing salt.
        let (response2, clientT) = try routeRequestTwo(
            server: server,
            session: session,
            clientA: clientA,
            salt: salt
        )
        XCTAssertEqual(response2.status, 200, "request 2 with a verifying proof must answer 200")
        let serverProof = try XCTUnwrap(
            TLV8.decode(response2.body)?.first(where: { $0.type == 3 })?.value,
            "the response must carry the server proof (type 3)"
        )
        XCTAssertEqual(
            session.proof,
            serverProof,
            "`Session.proof` is the contract for the server proof"
        )
        XCTAssertNotNil(session.key, "the session's key must be armed")
        XCTAssertEqual(session.key, Data(clientT.prefix(32)), "the agreed key is T[0..<32]")
        // The server proof itself: H(A_e ‖ B_e ‌‌‖ accessoryIdentityPublicKey ‌‌‖ T).
        var expectedProof = Data()
        expectedProof.append(contentsOf: clientA)
        expectedProof.append(contentsOf: bE)
        expectedProof.append(contentsOf: AccessoryIdentity.shared.publicKey)
        expectedProof.append(contentsOf: clientT)
        XCTAssertEqual(
            serverProof,
            SRP.sha512(expectedProof),
            "the server proof must be H(A_e ‖ B_e ‌‌‖ accessoryIdentityPublicKey ‌‌‖ T)"
        )
    }

    // MARK: - Criterion 3 — a tampered proof verifies nothing

    /// A tampered client proof (TLV type 4) — one flipped bit — routes to
    /// 400 and arms nothing: `key` stays nil and `proof` stays empty.
    func testTamperedProofVerifiesNothing() throws {
        let salt = Data(repeating: 0xCD, count: 16)
        let clientA = Data(repeating: 0x22, count: 32)
        let (server, _, session, _) = try startExchange(salt: salt, clientA: clientA)
        var clientT = proofFor(clientA: clientA, bE: session.b, salt: salt)
        clientT[0] ^= 0x01

        let response = server.route(HAPServer.Request(
            method: "POST",
            path: "/pair-verify",
            body: TLV8.encode([TLV8Entry(type: 4, value: clientT)])
        ))
        XCTAssertEqual(response.status, 400, "a tampered proof must answer 400")
        XCTAssertNil(session.key, "a tampered proof must arm nothing")
        XCTAssertTrue(session.proof.isEmpty, "a tampered proof must set no server proof")
    }

    // MARK: - Criterion 4a — the sealed session round trips

    /// With the session armed, `seal`/`open` round-trip: the sealed payload
    /// does not read as the plaintext and `open` recovers it.
    func testTheSealedSessionRoundTrips() throws {
        let salt = Data(repeating: 0xEF, count: 16)
        let clientA = Data(repeating: 0x33, count: 32)
        let (server, _, session, _) = try startExchange(salt: salt, clientA: clientA)
        let (response, _) = try routeRequestTwo(
            server: server,
            session: session,
            clientA: clientA,
            salt: salt
        )
        XCTAssertEqual(response.status, 200, "the proof must verify")
        XCTAssertNotNil(session.key)

        let plaintext = Data("play two".utf8)
        let sealed = try session.seal(plaintext)
        XCTAssertNotEqual(sealed, plaintext, "the sealed payload must not read as the plaintext")
        XCTAssertEqual(try session.open(sealed), plaintext, "`open` must recover the plaintext")
    }

    // MARK: - Criterion 4b — seal fails before request 2 arms the key

    /// Sealing or opening before request 2 arms the key throws
    /// `HAPPairVerifyError.keyNotArmed`.
    func testSealFailsBeforeVerify() throws {
        let salt = Data(repeating: 0x77, count: 16)
        let clientA = Data(repeating: 0x44, count: 32)
        let (_, _, session, _) = try startExchange(salt: salt, clientA: clientA)
        XCTAssertNil(session.key, "the key is armed only on request 2")
        XCTAssertThrowsError(try session.seal(Data("play two".utf8))) { error in
            XCTAssertEqual(error as? HAPPairVerifyError, .keyNotArmed)
        }
        XCTAssertThrowsError(try session.open(Data("payload".utf8))) { error in
            XCTAssertEqual(error as? HAPPairVerifyError, .keyNotArmed)
        }
    }

    // MARK: - Helpers

    /// The client proof `T = H(A_e ‖ B_e ‌‌‖ AccessoryIdentity.shared.publicKey ‌‌‖ salt)`
    /// — what the phone sends as TLV type 4 on request 2.
    private func proofFor(clientA: Data, bE: Data, salt: Data) -> Data {
        var input = Data()
        input.append(contentsOf: clientA)
        input.append(contentsOf: bE)
        input.append(contentsOf: AccessoryIdentity.shared.publicKey)
        input.append(contentsOf: salt)
        return SRP.sha512(input)
    }

    /// Builds a server with a saved pairing record on a fresh service and
    /// routes request 1 — the client's ephemeral public key `A_e` (TLV type
    /// 1) — returning the server, the response, the session and the
    /// accessory's ephemeral public key `B_e`.
    private func startExchange(
        salt: Data,
        clientA: Data
    ) throws -> (server: HAPServer, response: HAPServer.Response, session: HAPPairVerify.Session, bE: Data) {
        let store = HAPPairingStore(service: freshPairingService())
        store.save(record: HAPPairingStore.Record(
            salt: salt,
            verifier: Data(repeating: 2, count: 384),
            paired: false
        ))
        let server = HAPServer(pairingStore: store)
        let response = server.route(HAPServer.Request(
            method: "POST",
            path: "/pair-verify",
            body: TLV8.encode([TLV8Entry(type: 1, value: clientA)])
        ))
        let session = try XCTUnwrap(server.pairVerifySession)
        let bE = try XCTUnwrap(
            TLV8.decode(response.body)?.first(where: { $0.type == 2 })?.value
        )
        return (server, response, session, bE)
    }

    /// Routes request 2 — the client proof `T` (TLV type 4) — against
    /// `session`; returns the response and the proof the client computed.
    private func routeRequestTwo(
        server: HAPServer,
        session: HAPPairVerify.Session,
        clientA: Data,
        salt: Data
    ) throws -> (response: HAPServer.Response, clientT: Data) {
        let clientT = proofFor(clientA: clientA, bE: session.b, salt: salt)
        let response = server.route(HAPServer.Request(
            method: "POST",
            path: "/pair-verify",
            body: TLV8.encode([TLV8Entry(type: 4, value: clientT)])
        ))
        return (response, clientT)
    }
}
