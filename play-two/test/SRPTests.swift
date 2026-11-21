import XCTest
@testable import PlayTwo

/// SRP-3072 verifier derivation (TASK-012).
///
/// The expected vectors below were computed independently in Python 3
/// (`hashlib.sha512`, `pow(2, x, N)` with the RFC 3526 section 4 modulus);
/// see journal/dev.md for the derivation.
final class SRPTests: XCTestCase {
    private let salt = Data([0x00, 0x11, 0x22, 0x33, 0x44, 0x55, 0x66, 0x77,
                             0x88, 0x99, 0xAA, 0xBB, 0xCC, 0xDD, 0xEE, 0xFF])
    private let otherSalt = Data([0xFF, 0xEE, 0xDD, 0xCC, 0xBB, 0xAA, 0x99,
                                  0x88, 0x77, 0x66, 0x55, 0x44, 0x33, 0x22,
                                  0x11, 0x00])

    /// x's expected value for the fixed `salt`: SHA512(salt || "00102003").
    private let expectedXHex = "dc5a21fe7aeaee950d6400f5e92b1e3e86cbb9bb9c7dd95f5edf95867f5b8f62" +
        "47e60c9b931919898fdf6a4449bcaf371b8b5321d888cff76905e9284e0f3cf5"

    /// v's expected value: the full 384-byte g^x mod N.
    private let expectedVHex = "1e97c2213ed87457424a98f615199ad2556dc3d4699ce72d01630c16c4f76421" +
        "dd106f228a69d07ed8c26c98caeae19c9c6f561ab36073129602fa80e0368eb8" +
        "8b2311a0e49b11b294ca028ab9f530cc9bb99b2827ae20a39cba87791531885b" +
        "5f510a4cb72e6ccb8d55897758f075050da71d334d535e9e9e7803b97e10eb5e" +
        "1e315f618e39cc0372373c7e48c8d8a38662941a67ce278e17a87d66d4a67d88" +
        "4231000711ff3a59cb4c8bd4c115447b7b9ecea9e59ba1b27b07b58524713d2a" +
        "14dcb4f986ceccc1270ad2b22d36ec1fd1f10ce33f9c7aaa3b3ca9b93958aad3" +
        "1f99082f8aac0f96f3b9316634ea8c5a2e558583d5f4d76f47264641659cd274" +
        "d21c268602c798fa048a9b0eea94f3f9ba09140e1c0becb8d19ee7adb86f9d54" +
        "aa572bbd5d114ed407bb5482a1ee10556beb7aaf059af5e8b810178e69647317" +
        "4edc4c1aec2a8e01f34d3cb5035874e0febe81136d2f07dc23871135b3e11292" +
        "0c1952a22172440973ee4efd34bef96a4076f0c3345a7fc27003bd055535d5aa"

    /// k's expected value: SHA512(N || 0x02).
    private let expectedKHex = "6fd1d7f83355655f68c5b42e3c883d40e41508d8171dab92b99a860bfd592e0f" +
        "fdf608379ce9765923a55eb64c7ba8f762124ff4694375e86bc61b6820f3b455"

    private func data(fromHex hex: String) -> Data {
        let chars = Array(hex)
        var out = Data()
        for i in stride(from: 0, to: chars.count, by: 2) {
            let byte = UInt8(String(chars[i...i + 1]), radix: 16)!
            out.append(byte)
        }
        return out
    }

    /// Criterion 1: deriving twice for the same code and salt is identical.
    func testDeriverIsDeterministic() {
        XCTAssertEqual(SRP.deriveVerifier(setupCode: "00102003", salt: salt),
                       SRP.deriveVerifier(setupCode: "00102003", salt: salt))
    }

    /// Criterion 2: the same code with two different salts derives
    /// different verifiers.
    func testVerifierChangesWithSalt() {
        XCTAssertNotEqual(SRP.deriveVerifier(setupCode: "00102003", salt: salt),
                          SRP.deriveVerifier(setupCode: "00102003",
                                             salt: otherSalt))
    }

    /// Criterion 3: the derived v is the genuine full verifier, 1 <= v < N.
    func testVerifierIsInRange() {
        guard let v = SRP.deriveVerifier(setupCode: "00102003", salt: salt) else {
            XCTFail("deriveVerifier returned nil")
            return
        }
        XCTAssertTrue(SRP.isInRange(v))
    }

    /// Criterion 4 (independent vector): x is SHA512(salt || "00102003"),
    /// the digest read as a big integer (first digest byte = x's MSB).
    func testXByteOrderMatchesIndependentVector() {
        XCTAssertEqual(SRP.x(salt: salt, code: "00102003"),
                       data(fromHex: expectedXHex))
    }

    /// Criterion 4 (independent vector): the derived v matches the
    /// independently computed g^x mod N, byte for byte.
    func testDerivedVerifierMatchesIndependentVector() {
        XCTAssertEqual(SRP.deriveVerifier(setupCode: "00102003", salt: salt),
                       data(fromHex: expectedVHex))
    }

    /// Criterion 5 (companion): k = H(N || g) with H = SHA-512.
    func testKIsHashOfNAndG() {
        XCTAssertEqual(SRP.k(), data(fromHex: expectedKHex))
    }

    /// Setup codes must be 8 digits after dashes are stripped.
    func testDeriveVerifierRejectsNonEightDigitCodes() {
        XCTAssertNil(SRP.deriveVerifier(setupCode: "1234", salt: salt))
        XCTAssertNil(SRP.deriveVerifier(setupCode: "123456789", salt: salt))
        XCTAssertNil(SRP.deriveVerifier(setupCode: "1234567A", salt: salt))
        XCTAssertNil(SRP.deriveVerifier(setupCode: "", salt: salt))
    }

    /// Dashes are stripped before validation ("00-10-20-03" == "00102003").
    func testDeriveVerifierStripsDashes() {
        XCTAssertEqual(SRP.deriveVerifier(setupCode: "00-10-20-03", salt: salt),
                       SRP.deriveVerifier(setupCode: "00102003", salt: salt))
    }
}
