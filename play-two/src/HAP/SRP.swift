import CryptoKit
import Foundation

/// SRP-3072 password-verifier derivation, the HAP variant (TASK-012).
///
/// HAP uses the standard SRP-3072 group of RFC 3526, section 4: the modulus N
/// (little-endian `UInt32` limbs in `N`) and the generator g = 2. The SRP
/// multiplier is the standard one: k = H(N || g), with H = SHA-512. The
/// verifier is v = g^x mod N, where x = SHA512(salt || setupCode): the
/// SHA-512 digest read as a big integer, salt bytes first then the 8 ASCII
/// digits of the setup code — the digest's first byte is x's most significant
/// byte. `deriveVerifier` returns v as its full 384 big-endian bytes; it
/// never truncates or hashes v, so 1 <= v < N always holds for a genuine
/// derivation.
///
/// Big integers here are `[UInt32]` little-endian limbs. Montgomery-domain
/// multiplications go through `redc` (Koç et al., "Analyzing and Comparing
/// Montgomery Multiplication Algorithms", 1995).
enum SRP {
    /// RFC 3526, section 4, 3072-bit prime N, little-endian limbs.
    static let N: [UInt32] = [
        0xFFFFFFFF, 0xFFFFFFFF, 0xA93AD2CA, 0x4B82D120, 0xE0FD108E, 0x43DB5BFC, 0x74E5AB31, 0x08E24FA0,
        0xBAD946E2, 0x770988C0, 0x7A615D6C, 0xBBE11757, 0x177B200C, 0x521F2B18, 0x3EC86A64, 0xD8760273,
        0xD98A0864, 0xF12FFA06, 0x1AD2EE6B, 0xCEE3D226, 0x4A25619D, 0x1E8C94E0, 0xDB0933D7, 0xABF5AE8C,
        0xA6E1E4C7, 0xB3970F85, 0x5D060C7D, 0x8AEA7157, 0x58DBEF0A, 0xECFB8504, 0xDF1CBA64, 0xA85521AB,
        0x04507A33, 0xAD33170D, 0x8AAAC42D, 0x15728E5A, 0x98FA0510, 0x15D22618, 0xEA956AE5, 0x3995497C,
        0x95581718, 0xDE2BCBF6, 0x6F4C52C9, 0xB5C55DF0, 0xEC07A28F, 0x9B2783A2, 0x180E8603, 0xE39E772C,
        0x2E36CE3B, 0x32905E46, 0xCA18217C, 0xF1746C08, 0x4ABC9804, 0x670C354E, 0x7096966D, 0x9ED52907,
        0x208552BB, 0x1C62F356, 0xDCA3AD96, 0x83655D23, 0xFD24CF5F, 0x69163FA8, 0x1C55D39A, 0x98DA4836,
        0xA163BF05, 0xC2007CB8, 0xECE45B3D, 0x49286651, 0x7C4B1FE6, 0xAE9F2411, 0x5A899FA5, 0xEE386BFB,
        0xF406B7ED, 0x0BFF5CB6, 0xA637ED6B, 0xF44C42E9, 0x625E7EC6, 0xE485B576, 0x6D51C245, 0x4FE1356D,
        0xF25F1437, 0x302B0A6D, 0xCD3A431B, 0xEF9519B3, 0x8E3404DD, 0x514A0879, 0x3B139B22, 0x020BBEA6,
        0x8A67CC74, 0x29024E08, 0x80DC1CD1, 0xC4C6628B, 0x2168C234, 0xC90FDAA2, 0xFFFFFFFF, 0xFFFFFFFF,
    ]

    /// Byte length of the canonical verifier v.
    static let nByteCount = 384

    /// The generator of the RFC 3526 group, in its one-byte encoding.
    static let g = Data([0x02])

    /// SRP multiplier: H(N || g), H = SHA-512, computed once and reused.
    private static let cachedK: Data = {
        var input = Self.NData
        input.append(contentsOf: Self.g)
        return Self.sha512(input)
    }()

    static func k() -> Data {
        Self.cachedK
    }

    /// Derives v = g^x mod N for `setupCode` and `salt`, or `nil` when the
    /// setup code is not 8 digits (dashes stripped first).
    static func deriveVerifier(setupCode: String, salt: Data) -> Data? {
        guard let code = Self.validatedCode(setupCode) else {
            return nil
        }
        let exponent = Self.x(salt: salt, code: code)
        let v = Self.modExp(Self.limbs(from: Self.g), Self.limbs(from: exponent))
        return Self.data(fromLimbs: v, byteCount: Self.nByteCount)
    }

    /// x = SHA512(salt || utf8(code)): the digest, salt bytes first, the code
    /// bytes after. The digest's first byte is x's most significant byte.
    static func x(salt: Data, code: String) -> Data {
        var input = Data()
        input.append(contentsOf: salt)
        input.append(contentsOf: code.utf8)
        return Self.sha512(input)
    }

    /// Whether `v` is a genuine verifier: 1 <= v < N.
    static func isInRange(_ v: Data) -> Bool {
        let value = Self.limbs(from: v)
        if !value.contains(where: { $0 != 0 }) {
            return false  // v == 0
        }
        return Self.compare(value, N) < 0
    }

    /// Server-side step (TASK-013): given a verifier `v`, generate a fresh
    /// salt (>= 16 random bytes) and a random ephemeral secret `a`, compute
    /// `B = (k*v + g^a) mod N`, and return an in-memory session retaining
    /// `a`, `v`, `B` and `salt`. Nothing is persisted.
    static func generateEphemeral(v: Data) -> SRPServerSession? {
        // Cached multiplier (computed once).
        let kLimbs = Self.limbs(from: Self.k())

        var salt = Data()
        var sessionA = Data()
        var bData = Data()

        repeat {
            // Fresh salt, >= 16 random bytes.
            salt = SymmetricKey(size: .bits128).withUnsafeBytes { Data($0) }

            // Random ephemeral secret a (256 bits), nonzero.
            repeat {
                sessionA = SymmetricKey(size: .bits256).withUnsafeBytes { Data($0) }
            } while !sessionA.contains(where: { $0 != 0 })

            let vLimbs = Self.limbs(from: v)
            let kvLimbs = Self.redc(Self.mulmont(Self.montgomery(kLimbs),
                                                 Self.montgomery(vLimbs)))

            let gLimbs = Self.limbs(from: Self.g)
            let aLimbs = Self.limbs(from: sessionA)
            let gaLimbs = Self.modExp(gLimbs, aLimbs)

            let bLimbs = Self.addMod(kvLimbs, gaLimbs)
            bData = Self.data(fromLimbs: bLimbs, byteCount: Self.nByteCount)
        } while !Self.isInRange(bData)

        return SRPServerSession(a: sessionA, v: v, B: bData, salt: salt)
    }

    /// Server-side step (TASK-014): given the client's public value `A` and
    /// client proof `M1`, verify `M1`; on success derive the session key `K`
    /// and the server proof `M2`; on failure return nil. `A` must not be 0 or
    /// a multiple of N. The session's `a` and `v` are not retained beyond
    /// this call.
    static func verify(session: SRPServerSession, clientA: Data, clientM1: Data) -> (M2: Data, K: Data)? {
        // Abort on degenerate A.
        if Self.isZeroModN(clientA) {
            return nil
        }

        let A_limbs = Self.limbs(from: clientA)
        let B_data = session.B
        let vLimbs = Self.limbs(from: session.v)

        // u = H(A || B).
        var uInput = Data()
        uInput.append(contentsOf: clientA)
        uInput.append(contentsOf: B_data)
        let uData = Self.sha512(uInput)
        let uLimbs = Self.limbs(from: uData)

        // v^u mod N.
        let vu = Self.modExp(vLimbs, uLimbs)
        // A * v^u mod N.
        let aTimesVu = Self.redc(Self.mulmont(Self.montgomery(A_limbs),
                                                Self.montgomery(vu)))
        // S = (A * v^u)^a mod N.
        let aLimbs = Self.limbs(from: session.a)
        let S_limbs = Self.modExp(aTimesVu, aLimbs)
        let S_data = Self.data(fromLimbs: S_limbs, byteCount: Self.nByteCount)
        let K = Self.sha512(S_data)

        // Recomputed client proof.
        var m1Input = Data()
        m1Input.append(contentsOf: clientA)
        m1Input.append(contentsOf: B_data)
        m1Input.append(contentsOf: K)
        let m1Computed = Self.sha512(m1Input)
        guard m1Computed == clientM1 else {
            return nil
        }

        // M2 = H(A || M1 || K).
        var m2Input = Data()
        m2Input.append(contentsOf: clientA)
        m2Input.append(contentsOf: clientM1)
        m2Input.append(contentsOf: K)
        let M2 = Self.sha512(m2Input)

        return (M2: M2, K: K)
    }

    /// Whether `a` is 0 modulo N (covers A == 0 and A % N == 0).
    static func isZeroModN(_ a: Data) -> Bool {
        var d = Self.limbs(from: a)
        while d.count < 2 * L {
            d.append(0)
        }
        let r = Self.reduce(&d)
        return !r.contains(where: { $0 != 0 })
    }

    // MARK: - setup-code validation

    /// The setup code with dashes stripped, or `nil` when the remainder is
    /// not exactly 8 digits.
    static func validatedCode(_ setupCode: String) -> String? {
        let stripped = String(setupCode.filter { $0 != "-" })
        guard stripped.count == 8,
              stripped.allSatisfy({ $0 >= "0" && $0 <= "9" }) else {
            return nil
        }
        return stripped
    }

    // MARK: - byte <-> int conversion

    /// `data` as little-endian `UInt32` limbs; values wider than N are
    /// truncated.
    static func limbs(from data: Data) -> [UInt32] {
        var out = [UInt32](repeating: 0, count: N.count)
        for i in 0..<data.count {
            let bit = i * 8
            let limb = bit / 32
            guard limb < out.count else {
                break
            }
            out[limb] |= UInt32(truncatingIfNeeded: data[data.count - 1 - i])
                << UInt32(bit % 32)
        }
        return out
    }

    /// `limbs` as `byteCount` big-endian bytes, zero-padded on the left.
    static func data(fromLimbs limbs: [UInt32], byteCount: Int) -> Data {
        var out = [UInt8](repeating: 0, count: byteCount)
        for j in 0..<limbs.count {
            for b in 0..<4 {
                let bytePos = 4 * j + b
                guard bytePos < byteCount else {
                    break
                }
                out[byteCount - 1 - bytePos] =
                    UInt8(truncatingIfNeeded: (limbs[j] >> UInt32(8 * b)) & 0xFF)
            }
        }
        return Data(out)
    }

    /// N as its canonical 384 big-endian bytes.
    static var NData: Data {
        Self.data(fromLimbs: N, byteCount: nByteCount)
    }

    // MARK: - SHA-512

    /// SHA-512 over `input` (CryptoKit `SHA512`).
    static func sha512(_ input: Data) -> Data {
        var out = Data()
        out.append(contentsOf: SHA512.hash(data: input))
        return out
    }

    // MARK: - modular arithmetic helpers

    /// (a + b) mod N for little-endian limb arrays.
    static func addMod(_ a: [UInt32], _ b: [UInt32]) -> [UInt32] {
        var sum = [UInt32](repeating: 0, count: L + 1)
        var carry: UInt64 = 0
        for i in 0..<L {
            let s = UInt64(a[i]) + UInt64(b[i]) + carry
            sum[i] = UInt32(truncatingIfNeeded: s)
            carry = s >> 32
        }
        sum[L] = UInt32(truncatingIfNeeded: carry)

        while sum[L] != 0 || Self.compare(Array(sum[0..<L]), N) >= 0 {
            var borrow: UInt64 = 0
            for i in 0..<L {
                let aVal = UInt64(sum[i])
                let bVal = UInt64(N[i]) + borrow
                if aVal >= bVal {
                    sum[i] = UInt32(truncatingIfNeeded: aVal - bVal)
                    borrow = 0
                } else {
                    sum[i] = UInt32(truncatingIfNeeded: aVal + (1 << 32) - bVal)
                    borrow = 1
                }
            }
            if borrow == 1 {
                sum[L] -= 1
            }
        }
        return Array(sum[0..<L])
    }

    // MARK: - exponentiation (Montgomery)

    /// v = base^exponent mod N, on Montgomery forms.
    static func modExp(_ base: [UInt32], _ exponent: [UInt32]) -> [UInt32] {
        let A = Self.montgomery(base)
        var Z = Self.montgomery([1])
        var i = Self.bitLength(exponent) - 1
        while i >= 0 {
            Z = Self.mulmont(Z, Z)
            if Self.bit(i, of: exponent) {
                Z = Self.mulmont(Z, A)
            }
            i -= 1
        }
        return Self.redc(Z)
    }

    /// Montgomery form of `raw`: raw·R mod N, via `reduce` of raw·R.
    static func montgomery(_ raw: [UInt32]) -> [UInt32] {
        var d = [UInt32](repeating: 0, count: 2 * L)
        for j in 0..<L {
            d[j + L] = j < raw.count ? raw[j] : 0
        }
        return Self.reduce(&d)
    }

    /// Montgomery product of Montgomery-form values: REDC(a·b).
    static func mulmont(_ a: [UInt32], _ b: [UInt32]) -> [UInt32] {
        var p = [UInt32](repeating: 0, count: 2 * L + 2)
        for i in 0..<L {
            var carry: UInt64 = 0
            for j in 0..<L {
                let s = UInt64(p[i + j]) + UInt64(a[j]) * UInt64(b[i]) + carry
                p[i + j] = UInt32(truncatingIfNeeded: s)
                carry = s >> 32
            }
            var k = i + L
            while carry != 0 {
                precondition(k < p.count)
                let s = UInt64(p[k]) + carry
                p[k] = UInt32(truncatingIfNeeded: s)
                carry = s >> 32
                k += 1
            }
        }
        return Self.redc(p)
    }

    /// Montgomery reduction: T is a Montgomery-domain product; returns
    /// T·R^-1 mod N.
    static func redc(_ t: [UInt32]) -> [UInt32] {
        var T = t
        while T.count < 2 * L + 4 {
            T.append(0)
        }
        let invN0 = Self.modularInverse(N[0])
        for i in 0..<L {
            let m = (0 &- T[i]) &* invN0
            var carry: UInt64 = 0
            for j in 0..<L {
                let s = UInt64(T[i + j]) + UInt64(m) * UInt64(N[j]) + carry
                T[i + j] = UInt32(truncatingIfNeeded: s)
                carry = s >> 32
            }
            var k = i + L
            while carry != 0 {
                precondition(k < T.count)
                let s = UInt64(T[k]) + carry
                T[k] = UInt32(truncatingIfNeeded: s)
                carry = s >> 32
                k += 1
            }
        }
        var result = Array(T[L...])
        while Self.compare(result, N) >= 0 {
            Self.subtractInPlace(&result, N)
        }
        return result
    }

    /// D mod N: bit-by-bit long division over `d` (2L limbs).
    static func reduce(_ d: inout [UInt32]) -> [UInt32] {
        var rem = [UInt32](repeating: 0, count: L + 1)
        let bits = Self.bitLength(d)
        var i = bits - 1
        while i >= 0 {
            var carry: UInt32 = 0
            for j in rem.indices {
                let next = rem[j] >> 31
                rem[j] = (rem[j] &<< 1) | carry
                carry = next
            }
            if i < d.count * 32, ((d[i >> 5] >> UInt32(i & 31)) & 1) == 1 {
                rem[0] |= 1
            }
            if Self.compare(rem, N) >= 0 {
                Self.subtractInPlace(&rem, N)
            }
            i -= 1
        }
        return Array(rem[0..<L])
    }

    // MARK: - Montgomery helpers

    static var L: Int { N.count }

    static func bitLength(_ limbs: [UInt32]) -> Int {
        for j in stride(from: limbs.count - 1, through: 0, by: -1) {
            if limbs[j] != 0 {
                return j * 32 + (32 - Int(limbs[j].leadingZeroBitCount))
            }
        }
        return 0
    }

    static func bit(_ index: Int, of limbs: [UInt32]) -> Bool {
        guard index < limbs.count * 32 else {
            return false
        }
        return ((limbs[index >> 5] >> UInt32(index & 31)) & 1) == 1
    }

    static func compare(_ a: [UInt32], _ b: [UInt32]) -> Int {
        let width = max(a.count, b.count)
        if width == 0 {
            return 0
        }
        var av = [UInt32](repeating: 0, count: width)
        var bv = [UInt32](repeating: 0, count: width)
        for j in 0..<a.count {
            av[j] = a[j]
        }
        for j in 0..<b.count {
            bv[j] = b[j]
        }
        for j in stride(from: width - 1, through: 0, by: -1) {
            if av[j] != bv[j] {
                return av[j] < bv[j] ? -1 : 1
            }
        }
        return 0
    }

    static func subtractInPlace(_ a: inout [UInt32], _ b: [UInt32]) {
        var borrow: UInt64 = 0
        for j in a.indices {
            let aVal = UInt64(a[j])
            let bVal = UInt64(j < b.count ? b[j] : 0) + borrow
            if aVal >= bVal {
                a[j] = UInt32(truncatingIfNeeded: aVal - bVal)
                borrow = 0
            } else {
                a[j] = UInt32(truncatingIfNeeded: aVal + (1 << 32) - bVal)
                borrow = 1
            }
        }
        precondition(borrow == 0, "a < b")
    }

    /// Newton iteration for the inverse of the odd `a` modulo 2^32.
    static func modularInverse(_ a: UInt32) -> UInt32 {
        var x: UInt32 = 1
        for _ in 0..<5 {
            x = x &* (2 &- a &* x)
        }
        return x
    }

    // MARK: - session type (TASK-013)
    /// In-memory server-side SRP session. Holds the ephemeral secret `a`, the
    /// verifier `v`, the public value `B` and the salt. Never persisted.
    struct SRPServerSession {
        let a: Data
        let v: Data
        let B: Data
        let salt: Data
    }
}

/// Top-level alias so `SRPServerSession` resolves without the `SRP.` prefix.
typealias SRPServerSession = SRP.SRPServerSession
