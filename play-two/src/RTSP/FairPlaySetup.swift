import Foundation

/// FairPlay-relevant fields extracted from an RTSP SETUP request.
///
/// Narrow parser for FEAT-005: only the fields TASK-027/028 need. No FairPlay
/// crypto, no key table, no network I/O.
struct FairPlaySetup: Equatable {
    /// Raw 16-byte challenge carried by the `Apple-Challenge` RTSP header.
    let challenge: Data

    /// Encrypted key material carried by the SETUP body (`ekey`).
    let encryptedKeyMaterial: Data

    /// Parses FairPlay fields from an RTSP SETUP request.
    ///
    /// Field form (synthetic fixture choice, recorded for TASK-027/028):
    /// - `Apple-Challenge`: RTSP header, base64-encoded 16 bytes. This matches
    ///   AirPlay 2/RAOP RTSP reference behavior where the challenge is transported
    ///   as an RTSP header value.
    /// - `ekey`: binary plist body field (Content-Type application/x-apple-binary-plist)
    ///   containing the encrypted key material as `Data`. Looked up at top level,
    ///   then inside any `streams` array dictionary, to stay narrow while accepting
    ///   the common AirPlay 2 SETUP bplist shape.
    ///
    /// Returns `nil` when required fields are missing, empty, malformed, or the
    /// body is not a readable binary plist.
    static func parse(from request: RTSPRequest) -> FairPlaySetup? {
        guard let challenge = parseChallenge(from: request) else { return nil }
        guard let encryptedKeyMaterial = parseEncryptedKeyMaterial(from: request) else { return nil }
        return FairPlaySetup(challenge: challenge, encryptedKeyMaterial: encryptedKeyMaterial)
    }

    private static func parseChallenge(from request: RTSPRequest) -> Data? {
        guard let raw = request.header("Apple-Challenge") else { return nil }
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        guard let data = Data(base64Encoded: trimmed) else { return nil }
        guard data.count == 16 else { return nil }
        return data
    }

    private static func parseEncryptedKeyMaterial(from request: RTSPRequest) -> Data? {
        guard !request.body.isEmpty else { return nil }
        guard let plist = try? PropertyListSerialization.propertyList(from: request.body, format: nil) else {
            return nil
        }
        guard let dict = plist as? [String: Any] else { return nil }
        guard let data = findEKey(in: dict) else { return nil }
        guard !data.isEmpty else { return nil }
        return data
    }

    private static func findEKey(in dict: [String: Any]) -> Data? {
        if let data = dict["ekey"] as? Data {
            return data
        }
        guard let streams = dict["streams"] as? [[String: Any]] else { return nil }
        for stream in streams {
            if let data = stream["ekey"] as? Data {
                return data
            }
        }
        return nil
    }
}
