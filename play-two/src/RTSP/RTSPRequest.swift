import Foundation

/// A parsed RTSP/1.0 request.
///
/// Pure value type: no I/O, no socket, no state. Parsing preserves header
/// values as received (including `CSeq`) and exposes a `cseq` convenience
/// accessor for handlers that answer with the same sequence number.
struct RTSPRequest: Equatable {
    let method: String
    let target: String
    let headers: [String: String]
    let body: Data

    /// The `CSeq` header as an integer, when present and numeric.
    var cseq: Int? {
        guard let value = header("CSeq") else { return nil }
        return Int(value.trimmingCharacters(in: .whitespaces))
    }

    /// Case-insensitive header lookup.
    func header(_ name: String) -> String? {
        let needle = name.lowercased()
        return headers.first { $0.key.lowercased() == needle }?.value
    }

    /// Parses raw RTSP/1.0 request bytes.
    ///
    /// Returns `nil` for malformed input: a missing or malformed request line,
    /// an unknown protocol token, or a body shorter than `Content-Length`.
    static func parse(_ data: Data) -> RTSPRequest? {
        guard let separatorRange = data.range(of: Data([13, 10, 13, 10])) else {
            return nil
        }

        let headerSection = data[..<separatorRange.lowerBound]
        let bodyStart = separatorRange.upperBound
        let remainingBody = data[bodyStart...]

        guard let headerText = String(data: headerSection, encoding: .utf8) else {
            return nil
        }

        // RTSP lines are CRLF-delimited; tolerate a bare-LF split only by
        // normalizing CRLF first so we never invent header structure.
        let lines = headerText.components(separatedBy: "\r\n")
        guard let requestLine = lines.first, !requestLine.isEmpty else {
            return nil
        }

        let parts = requestLine.split(separator: " ", omittingEmptySubsequences: false)
        guard parts.count == 3 else { return nil }

        let method = String(parts[0])
        let target = String(parts[1])
        let version = String(parts[2])
        guard !method.isEmpty, !target.isEmpty, version == "RTSP/1.0" else {
            return nil
        }

        var headers: [String: String] = [:]
        for line in lines.dropFirst() {
            if line.isEmpty { continue }
            guard let colon = line.firstIndex(of: ":") else { return nil }
            let name = String(line[..<colon])
            guard !name.isEmpty else { return nil }
            let rawValue = line[line.index(after: colon)...]
            let value = rawValue.drop { $0 == " " || $0 == "\t" }
            headers[name] = String(value)
        }

        let body: Data
        if let contentLengthValue = headerValue("Content-Length", in: headers) {
            let trimmed = contentLengthValue.trimmingCharacters(in: .whitespaces)
            guard let contentLength = Int(trimmed), contentLength >= 0 else {
                return nil
            }
            guard remainingBody.count >= contentLength else {
                return nil
            }
            body = Data(remainingBody.prefix(contentLength))
        } else {
            body = Data(remainingBody)
        }

        return RTSPRequest(method: method, target: target, headers: headers, body: body)
    }

    private static func headerValue(_ name: String, in headers: [String: String]) -> String? {
        let needle = name.lowercased()
        return headers.first { $0.key.lowercased() == needle }?.value
    }
}
