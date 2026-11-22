import XCTest
@testable import PlayTwo

/// TASK-026: parse FairPlay fields from an RTSP SETUP request.
///
/// Static fixture source (traceable, not device-captured, not real DRM/key material):
/// - Shape follows the AirPlay 2 RTSP SETUP form documented by the
///   openairplay/airplay2-receiver reference implementation: `Apple-Challenge`
///   is a base64 RTSP header (16-byte challenge), and `ekey` is an encrypted
///   key-material field in an `application/x-apple-binary-plist` body.
/// - The bytes below are static synthetic fixtures committed in this test,
///   shaped to that reference form for parser traceability. They were not
///   captured from an Apple TV and contain no proprietary Apple DRM material.
final class FairPlayFieldTests: XCTestCase {

    // Static recorded fixture bytes (base64) — see class comment for source/shape.
    private static let recordedSetupRequestBase64 =
        "U0VUVVAgcnRzcDovL2V4YW1wbGUvMTIzNDU2NyBSVFNQLzEuMA0KQ1NlcTogMw0K" +
        "QXBwbGUtQ2hhbGxlbmdlOiBBQUVDQXdRRkJnY0lDUW9MREEwT0R3PT0NCkNvbnRl" +
        "bnQtVHlwZTogYXBwbGljYXRpb24veC1hcHBsZS1iaW5hcnktcGxpc3QNCkNvbnRl" +
        "bnQtTGVuZ3RoOiAxMjYNCg0KYnBsaXN0MDDRAQJUZWtleU8QSAABAgMEBQYHCAkK" +
        "CwwNDg8QERITFBUWFxgZGhscHR4fICEiIyQlJicoKSorLC0uLzAxMjM0NTY3ODk6" +
        "Ozw9Pj9AQUJDREVGRwgLEAAAAAAAAAEBAAAAAAAAAAMAAAAAAAAAAAAAAAAAAABb"

    // Same fixture shape with required Apple-Challenge header removed.
    private static let missingChallengeRequestBase64 =
        "U0VUVVAgcnRzcDovL2V4YW1wbGUvMTIzNDU2NyBSVFNQLzEuMA0KQ1NlcTogMQ0K" +
        "Q29udGVudC1UeXBlOiBhcHBsaWNhdGlvbi94LWFwcGxlLWJpbmFyeS1wbGlzdA0K" +
        "Q29udGVudC1MZW5ndGg6IDEyNg0KDQpicGxpc3QwMNEBAlRla2V5TxBIAAECAwQF" +
        "BgcICQoLDA0ODxAREhMUFRYXGBkaGxwdHh8gISIjJCUmJygpKissLS4vMDEyMzQ1" +
        "Njc4OTo7PD0+P0BBQkNERUZHCAsQAAAAAAAAAQEAAAAAAAAAAwAAAAAAAAAAAAAA" +
        "AAAAAFs="

    // Same fixture shape with empty ekey Data in bplist body.
    private static let emptyEkeyRequestBase64 =
        "U0VUVVAgcnRzcDovL2V4YW1wbGUvMTIzNDU2NyBSVFNQLzEuMA0KQ1NlcTogMw0K" +
        "QXBwbGUtQ2hhbGxlbmdlOiBBQUVDQXdRRkJnY0lDUW9MREEwT0R3PT0NCkNvbnRl" +
        "bnQtVHlwZTogYXBwbGljYXRpb24veC1hcHBsZS1iaW5hcnktcGxpc3QNCkNvbnRl" +
        "bnQtTGVuZ3RoOiA1Mg0KDQpicGxpc3QwMNEBAlRla2V5QAgLEAAAAAAAAAEBAAAA" +
        "AAAAAAMAAAAAAAAAAAAAAAAAAAAR"

    // Same fixture shape with malformed (non-bplist) body bytes.
    private static let malformedBodyRequestBase64 =
        "U0VUVVAgcnRzcDovL2V4YW1wbGUvMTIzNDU2NyBSVFNQLzEuMA0KQ1NlcTogMw0K" +
        "QXBwbGUtQ2hhbGxlbmdlOiBBQUVDQXdRRkJnY0lDUW9MREEwT0R3PT0NCkNvbnRl" +
        "bnQtVHlwZTogYXBwbGljYXRpb24veC1hcHBsZS1iaW5hcnktcGxpc3QNCkNvbnRl" +
        "bnQtTGVuZ3RoOiA0DQoNCgABAgM="

    // Expected values encoded by the recorded static fixture above.
    private let expectedChallenge = Data([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15])
    private let expectedEncryptedKeyMaterial = Data((0..<72).map { UInt8($0) })

    func testParseChallengeFromAppleChallengeHeader() throws {
        let request = try request(fromBase64: Self.recordedSetupRequestBase64)

        let setup = FairPlaySetup.parse(from: request)

        let challenge = try XCTUnwrap(setup?.challenge)
        XCTAssertFalse(challenge.isEmpty)
        XCTAssertEqual(challenge, expectedChallenge)
    }

    func testParseEncryptedKeyMaterialFromBplistBody() throws {
        let request = try request(fromBase64: Self.recordedSetupRequestBase64)

        let setup = FairPlaySetup.parse(from: request)

        let encryptedKeyMaterial = try XCTUnwrap(setup?.encryptedKeyMaterial)
        XCTAssertFalse(encryptedKeyMaterial.isEmpty)
        XCTAssertEqual(encryptedKeyMaterial, expectedEncryptedKeyMaterial)
        XCTAssertEqual(encryptedKeyMaterial.count, 72)
    }

    func testMissingChallengeReturnsNilWithoutCrash() throws {
        // Malformed/missing-field case: required Apple-Challenge header absent.
        let request = try request(fromBase64: Self.missingChallengeRequestBase64)

        XCTAssertNil(FairPlaySetup.parse(from: request), "missing Apple-Challenge must not produce a partial model")
    }

    func testMalformedOrEmptyEncryptedKeyMaterialReturnsNilWithoutCrash() throws {
        let emptyRequest = try request(fromBase64: Self.emptyEkeyRequestBase64)
        XCTAssertNil(FairPlaySetup.parse(from: emptyRequest), "empty ekey must not produce a partial model")

        let malformedRequest = try request(fromBase64: Self.malformedBodyRequestBase64)
        XCTAssertNil(FairPlaySetup.parse(from: malformedRequest), "malformed bplist body must not crash")
    }

    // MARK: - Fixture decoding

    private func request(fromBase64 base64: String) throws -> RTSPRequest {
        let raw = try XCTUnwrap(Data(base64Encoded: base64), "static fixture must decode as base64")
        return try XCTUnwrap(RTSPRequest.parse(raw), "static fixture must parse as RTSP request")
    }
}
