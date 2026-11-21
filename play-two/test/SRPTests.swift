import XCTest
import CryptoKit
@testable import PlayTwo

/// SRP-3072 verifier derivation (TASK-012) and server ephemeral B (TASK-013).
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
        let exp = expectation(description: "derive")
        DispatchQueue.global().async {
            XCTAssertEqual(SRP.deriveVerifier(setupCode: "00102003", salt: self.salt),
                           SRP.deriveVerifier(setupCode: "00102003", salt: self.salt))
            exp.fulfill()
        }
        wait(for: [exp], timeout: 120)
    }

    /// Criterion 2: the same code with two different salts derives
    /// different verifiers.
    func testVerifierChangesWithSalt() {
        let exp = expectation(description: "derive")
        DispatchQueue.global().async {
            XCTAssertNotEqual(SRP.deriveVerifier(setupCode: "00102003", salt: self.salt),
                              SRP.deriveVerifier(setupCode: "00102003",
                                                 salt: self.otherSalt))
            exp.fulfill()
        }
        wait(for: [exp], timeout: 120)
    }

    /// Criterion 3: the derived v is the genuine full verifier, 1 <= v < N.
    func testVerifierIsInRange() {
        let exp = expectation(description: "derive")
        DispatchQueue.global().async {
            guard let v = SRP.deriveVerifier(setupCode: "00102003", salt: self.salt) else {
                XCTFail("deriveVerifier returned nil")
                exp.fulfill()
                return
            }
            XCTAssertTrue(SRP.isInRange(v))
            exp.fulfill()
        }
        wait(for: [exp], timeout: 120)
    }

    /// Criterion 4 (independent vector): x is SHA512(salt || "00102003"),
    /// the digest read as a big integer (first digest byte = x's MSB).
    func testXByteOrderMatchesIndependentVector() {
        // x() is a hash, not a derivation; safe on any thread, but keep heavy
        // callers off the main thread per DEC-017 anyway.
        let exp = expectation(description: "x")
        DispatchQueue.global().async {
            XCTAssertEqual(SRP.x(salt: self.salt, code: "00102003"),
                           self.data(fromHex: self.expectedXHex))
            exp.fulfill()
        }
        wait(for: [exp], timeout: 60)
    }

    /// Criterion 4 (independent vector): the derived v matches the
    /// independently computed g^x mod N, byte for byte.
    func testDerivedVerifierMatchesIndependentVector() {
        let exp = expectation(description: "derive")
        DispatchQueue.global().async {
            XCTAssertEqual(SRP.deriveVerifier(setupCode: "00102003", salt: self.salt),
                           self.data(fromHex: self.expectedVHex))
            exp.fulfill()
        }
        wait(for: [exp], timeout: 120)
    }

    /// Criterion 5 (companion): k = H(N || g) with H = SHA-512.
    func testKIsHashOfNAndG() {
        let exp = expectation(description: "k")
        DispatchQueue.global().async {
            XCTAssertEqual(SRP.k(), self.data(fromHex: self.expectedKHex))
            exp.fulfill()
        }
        wait(for: [exp], timeout: 60)
    }

    /// Setup codes must be 8 digits after dashes are stripped.
    func testDeriveVerifierRejectsNonEightDigitCodes() {
        // No heavy derivation here; validation only.
        XCTAssertNil(SRP.deriveVerifier(setupCode: "1234", salt: salt))
        XCTAssertNil(SRP.deriveVerifier(setupCode: "123456789", salt: salt))
        XCTAssertNil(SRP.deriveVerifier(setupCode: "1234567A", salt: salt))
        XCTAssertNil(SRP.deriveVerifier(setupCode: "", salt: salt))
    }

    /// Dashes are stripped before validation ("00-10-20-03" == "00102003").
    func testDeriveVerifierStripsDashes() {
        let exp = expectation(description: "derive")
        DispatchQueue.global().async {
            XCTAssertEqual(SRP.deriveVerifier(setupCode: "00-10-20-03", salt: self.salt),
                           SRP.deriveVerifier(setupCode: "00102003", salt: self.salt))
            exp.fulfill()
        }
        wait(for: [exp], timeout: 120)
    }

    // MARK: - TASK-013: server generates salt and ephemeral B

    /// Criterion 1: generateEphemeral returns a salt (>= 16 bytes) and B
    /// with 1 <= B < N.
    func testGenerateEphemeralReturnsSaltAndBInRange() {
        let exp = expectation(description: "gen")
        DispatchQueue.global().async {
            guard let v = SRP.deriveVerifier(setupCode: "00102003", salt: self.salt) else {
                XCTFail("deriveVerifier returned nil")
                exp.fulfill()
                return
            }
            guard let session = SRP.generateEphemeral(v: v) else {
                XCTFail("generateEphemeral returned nil")
                exp.fulfill()
                return
            }
            XCTAssertGreaterThanOrEqual(session.salt.count, 16)
            XCTAssertTrue(SRP.isInRange(session.B))
            exp.fulfill()
        }
        wait(for: [exp], timeout: 180)
    }

    /// Criterion 2: two calls with the same verifier produce different salts
    /// and B values.
    func testGenerateEphemeralRandomness() {
        let exp = expectation(description: "gen")
        DispatchQueue.global().async {
            guard let v = SRP.deriveVerifier(setupCode: "00102003", salt: self.salt) else {
                XCTFail("deriveVerifier returned nil")
                exp.fulfill()
                return
            }
            guard let s1 = SRP.generateEphemeral(v: v),
                  let s2 = SRP.generateEphemeral(v: v) else {
                XCTFail("generateEphemeral returned nil")
                exp.fulfill()
                return
            }
            XCTAssertNotEqual(s1.salt, s2.salt)
            XCTAssertNotEqual(s1.B, s2.B)
            exp.fulfill()
        }
        wait(for: [exp], timeout: 240)
    }

    /// Criterion 3: the returned session retains a and v.
    func testGenerateEphemeralRetainsAAndV() {
        let exp = expectation(description: "gen")
        DispatchQueue.global().async {
            guard let v = SRP.deriveVerifier(setupCode: "00102003", salt: self.salt) else {
                XCTFail("deriveVerifier returned nil")
                exp.fulfill()
                return
            }
            guard let session = SRP.generateEphemeral(v: v) else {
                XCTFail("generateEphemeral returned nil")
                exp.fulfill()
                return
            }
            XCTAssertEqual(session.v, v)
            XCTAssertEqual(session.a.count, 32)
            XCTAssertTrue(session.a.contains(where: { $0 != 0 }))
            exp.fulfill()
        }
        wait(for: [exp], timeout: 180)
    }

    // MARK: - TASK-014: server verifies client proof

    /// Client side of SRP-6a, built from the same big-int helpers. Returns the
    /// client's public value A, proof M1, expected M2 and session key K.
    private func clientHandshake(session: SRPServerSession,
                                setupSalt: Data,
                                code: String) -> (A: Data, M1: Data, M2: Data, K: Data)? {
        guard let v = SRP.deriveVerifier(setupCode: code, salt: setupSalt) else {
            return nil
        }
        var aClient = Data()
        repeat {
            aClient = SymmetricKey(size: .bits256).withUnsafeBytes { Data($0) }
        } while !aClient.contains(where: { $0 != 0 })

        let gLimbs = SRP.limbs(from: SRP.g)
        let aClientLimbs = SRP.limbs(from: aClient)
        let A_limbs = SRP.modExp(gLimbs, aClientLimbs)
        let A_data = SRP.data(fromLimbs: A_limbs, byteCount: SRP.nByteCount)

        let kLimbs = SRP.limbs(from: SRP.k())
        let vLimbs = SRP.limbs(from: v)
        let kvLimbs = SRP.redc(SRP.mulmont(SRP.montgomery(kLimbs),
                                             SRP.montgomery(vLimbs)))

        let B_limbs = SRP.limbs(from: session.B)
        var baseLimbs: [UInt32]
        if SRP.compare(B_limbs, kvLimbs) >= 0 {
            baseLimbs = B_limbs
            SRP.subtractInPlace(&baseLimbs, kvLimbs)
        } else {
            var nMinusKv = SRP.N
            SRP.subtractInPlace(&nMinusKv, kvLimbs)
            baseLimbs = SRP.addMod(B_limbs, nMinusKv)
        }

        let xData = SRP.x(salt: setupSalt, code: code)
        let xLimbs = SRP.limbs(from: xData)

        var uInput = Data()
        uInput.append(contentsOf: A_data)
        uInput.append(contentsOf: session.B)
        let uData = SRP.sha512(uInput)
        let uLimbs = SRP.limbs(from: uData)

        let term1 = SRP.modExp(baseLimbs, aClientLimbs)
        let baseU = SRP.modExp(baseLimbs, uLimbs)
        let term2 = SRP.modExp(baseU, xLimbs)
        let S_limbs = SRP.redc(SRP.mulmont(SRP.montgomery(term1),
                                             SRP.montgomery(term2)))
        let S_data = SRP.data(fromLimbs: S_limbs, byteCount: SRP.nByteCount)
        let K = SRP.sha512(S_data)

        var m1Input = Data()
        m1Input.append(contentsOf: A_data)
        m1Input.append(contentsOf: session.B)
        m1Input.append(contentsOf: K)
        let M1 = SRP.sha512(m1Input)

        var m2Input = Data()
        m2Input.append(contentsOf: A_data)
        m2Input.append(contentsOf: M1)
        m2Input.append(contentsOf: K)
        let M2 = SRP.sha512(m2Input)

        return (A_data, M1, M2, K)
    }

    /// Criterion 1 & 3: valid proof returns M2 and K; keys agree.
    func testVerifyRoundTrip() {
        let exp = expectation(description: "verify")
        DispatchQueue.global().async {
            guard let v = SRP.deriveVerifier(setupCode: "00102003", salt: self.salt) else {
                XCTFail("deriveVerifier returned nil")
                exp.fulfill()
                return
            }
            guard let session = SRP.generateEphemeral(v: v) else {
                XCTFail("generateEphemeral returned nil")
                exp.fulfill()
                return
            }
            guard let client = self.clientHandshake(session: session,
                                                   setupSalt: self.salt,
                                                   code: "00102003") else {
                XCTFail("client handshake failed")
                exp.fulfill()
                return
            }
            guard let result = SRP.verify(session: session,
                                         clientA: client.A,
                                         clientM1: client.M1) else {
                XCTFail("verify returned nil for valid proof")
                exp.fulfill()
                return
            }
            XCTAssertEqual(result.M2, client.M2)
            XCTAssertEqual(result.K, client.K)
            exp.fulfill()
        }
        wait(for: [exp], timeout: 300)
    }

    /// Criterion 2: tampered M1 returns nil.
    func testVerifyTamperedM1ReturnsNil() {
        let exp = expectation(description: "verify")
        DispatchQueue.global().async {
            guard let v = SRP.deriveVerifier(setupCode: "00102003", salt: self.salt) else {
                XCTFail("deriveVerifier returned nil")
                exp.fulfill()
                return
            }
            guard let session = SRP.generateEphemeral(v: v) else {
                XCTFail("generateEphemeral returned nil")
                exp.fulfill()
                return
            }
            guard let client = self.clientHandshake(session: session,
                                                   setupSalt: self.salt,
                                                   code: "00102003") else {
                XCTFail("client handshake failed")
                exp.fulfill()
                return
            }
            var tampered = client.M1
            tampered[0] ^= 0x01
            XCTAssertNil(SRP.verify(session: session,
                                   clientA: client.A,
                                   clientM1: tampered))
            exp.fulfill()
        }
        wait(for: [exp], timeout: 300)
    }

    /// Criterion 4: A == 0 or A % N == 0 aborts.
    func testVerifyRejectsDegenerateA() {
        let zeroA = Data(repeating: 0, count: SRP.nByteCount)
        let nA = SRP.NData
        let dummy = SRPServerSession(a: Data(), v: Data(), B: Data(), salt: Data())
        XCTAssertNil(SRP.verify(session: dummy, clientA: zeroA,
                                clientM1: Data(repeating: 0, count: 64)))
        XCTAssertNil(SRP.verify(session: dummy, clientA: nA,
                                clientM1: Data(repeating: 0, count: 64)))
    }
}
