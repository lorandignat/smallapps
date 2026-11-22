import Foundation
import Network

/// The HAP accessory's HTTP surface (TASK-016).
///
/// Replaces the increment-1 fixed 38-byte reply: `GET /info` answers the
/// accessory info as JSON; every other method or path answers 404
/// (TASK-018 extends `POST /pair-setup`). `ReceiverListener.answer` calls
/// this server's ``handle(_:)`` for each accepted connection; the listener
/// itself parses nothing.
final class HAPServer {

    // MARK: - Accessory facts

    /// The name the Home app shows for the accessory.
    static let accessoryName = AppInfo.displayName

    /// The accessory category string for a speaker (HAP 2.0).
    static let accessoryCategory = "speaker"

    /// The fixed setup code, generated earlier (`FEAT-003`'s fixed-code note).
    static let setupCode = "00102003"

    /// Whether the accessory is paired, as reported by `GET /info`.
    ///
    /// There is no pairing store yet — `TASK-017` "Expose the pairing state
    /// in the pairing store" owns it. Pre-pairing the accessory answers
    /// `false`, so the Home app lists the phone as unpaired until the pairing
    /// state lands.
    static let paired = false

    // MARK: - Request and response

    /// A parsed HTTP request line and body.
    struct Request {
        /// The method, upper-cased (`GET`, `POST`).
        let method: String
        /// The request path, e.g. `/info`.
        let path: String
        /// The body: exactly the `Content-Length` bytes.
        let body: Data
    }

    /// An HTTP response: a status code and a body.
    struct Response {
        /// The status code, e.g. `200` or `404`.
        let status: Int
        /// The response body bytes.
        let body: Data
    }

    // MARK: - Parsing

    /// Parses a request from its raw bytes.
    ///
    /// Returns `nil` when the bytes are not a complete, well-formed
    /// request: no header block terminator, no method or path on the
    /// request line, or a body shorter than the `Content-Length` header.
    static func parse(_ data: Data) -> Request? {
        guard let found = Self.separatorIndex(in: data) else { return nil }
        let header = data.subdata(in: 0..<found)
        let lines = String(decoding: header, as: UTF8.self).components(separatedBy: "\r\n")

        guard let requestLine = lines.first, !requestLine.isEmpty else { return nil }
        let parts = requestLine.split(separator: " ", omittingEmptySubsequences: false)
        guard parts.count >= 2, !parts[1].isEmpty else { return nil }
        let method = String(parts[0]).uppercased()
        let path = String(parts[1])

        var contentLength = 0
        for line in lines.dropFirst() {
            let pieces = line.split(separator: ":", maxSplits: 1)
            guard pieces.count == 2,
                String(pieces[0]).trimmingCharacters(in: .whitespaces).lowercased() == "content-length"
            else { continue }
            contentLength = Int(String(pieces[1]).trimmingCharacters(in: .whitespaces)) ?? 0
        }

        let bodyStart = found + 4
        guard data.count - bodyStart >= contentLength else { return nil }
        return Request(
            method: method,
            path: path,
            body: data.subdata(in: bodyStart..<(bodyStart + contentLength))
        )
    }

    /// The byte index of the first `\r\n\r\n` in `data`, or `nil` when there
    /// is none — the end of the header block.
    private static func separatorIndex(in data: Data) -> Int? {
        let separator: [UInt8] = [0x0D, 0x0A, 0x0D, 0x0A]
        guard data.count >= separator.count else { return nil }
        for index in 0...(data.count - separator.count) {
            var matched = true
            for offset in 0..<separator.count {
                if data[index + offset] != separator[offset] {
                    matched = false
                    break
                }
            }
            if matched { return index }
        }
        return nil
    }

    // MARK: - Routing

    /// Routes a request: `GET /info` answers 200 with the accessory info as
    /// JSON; every other method or path answers 404.
    func route(_ request: Request) -> Response {
        if request.method == "GET", request.path == "/info" {
            return Response(status: 200, body: Self.infoBody)
        }
        return Response(status: 404, body: Data("Not Found".utf8))
    }

    /// The `GET /info` body: the accessory info as JSON.
    static var infoBody: Data {
        Data(
            "{\"name\": \"\(Self.accessoryName)\", \"category\": \"\(Self.accessoryCategory)\", \"paired\": \(Self.paired)}"
                .utf8
        )
    }

    // MARK: - Serving

    /// Handles one accepted connection: reads a request, routes it, sends the
    /// response and closes the connection.
    func handle(_ connection: NWConnection) {
        connection.start(queue: queue)
        var received = Data()
        func receiveMore() {
            connection.receive(minimumIncompleteLength: 1, maximumLength: 8192) { data, _, isComplete, error in
                guard error == nil else {
                    connection.cancel()
                    return
                }
                if let data, !data.isEmpty {
                    received.append(data)
                }
                if let request = Self.parse(received) {
                    self.sendResponse(for: request, on: connection)
                } else if isComplete || data == nil {
                    connection.cancel()
                } else {
                    receiveMore()
                }
            }
        }
        receiveMore()
    }

    private func sendResponse(for request: Request, on connection: NWConnection) {
        let response = route(request)
        let phrase = response.status == 200 ? "OK" : "Not Found"
        var head = "HTTP/1.1 \(response.status) \(phrase)\r\n"
        head += "Content-Length: \(response.body.count)\r\n\r\n"
        var payload = Data(head.utf8)
        payload.append(response.body)
        connection.send(
            content: payload,
            contentContext: .defaultMessage,
            isComplete: true,
            completion: .contentProcessed { _ in
                connection.cancel()
            }
        )
    }

    /// The serial queue connections are served on.
    private let queue = DispatchQueue(label: "com.lorand.playtwo.hap-server")
}
