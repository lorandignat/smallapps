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

    // MARK: - Pairing state

    /// The store whose `paired` flag the info body reports (TASK-017).
    let pairingStore: HAPPairingStore

    /// The pair-setup exchange state machine (TASK-018).
    let pairSetup: HAPPairSetup

    /// The pair-verify exchange state (TASK-019): the session request 1
    /// starts, set when `POST /pair-verify` receives the client's
    /// ephemeral public key.
    var pairVerifySession: HAPPairVerify.Session?

    /// Creates a server reading the accessory facts and the pairing state
    /// from `pairingStore` (TASK-017); `pairSetup` on this server carries
    /// the exchange state from the first `POST /pair-setup` (TASK-018).
    init(pairingStore: HAPPairingStore = HAPPairingStore.shared) {
        self.pairingStore = pairingStore
        self.pairSetup = HAPPairSetup(store: pairingStore)
    }

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
    /// JSON; `POST /pair-setup` starts or completes the SRP exchange —
    /// request 1 (the client's public value A, TLV type 4) answers 200 with
    /// the accessory public value B (TLV type 3) and the salt (TLV type 6);
    /// request 2 (the client proof M4, TLV type 4) answers 200 with the
    /// accessory proof M5 (TLV type 5) and the session start M6 (TLV type
    /// 7), or 400 when the proof does not verify; `POST /pair-verify`
    /// (TASK-019) starts the encrypted session — request 1 (the client's
    /// ephemeral public key A_e, TLV type 1) answers 200 with the accessory
    /// ephemeral public key B_e (TLV type 2) and sets `pairVerifySession`;
    /// request 2 (the client proof T, TLV type 4) answers 200 with the
    /// server proof (TLV type 3) or 400 when the proof does not verify;
    /// every other method or path answers 404.
    func route(_ request: Request) -> Response {
        if request.method == "GET", request.path == "/info" {
            return Response(status: 200, body: infoBody)
        }
        if request.method == "POST", request.path == "/pair-setup" {
            return pairSetupResponse(for: request)
        }
        if request.method == "POST", request.path == "/pair-verify" {
            return pairVerifyResponse(for: request)
        }
        return Response(status: 404, body: Data("Not Found".utf8))
    }

    /// The `POST /pair-setup` route (TASK-018): dispatches on the exchange
    /// state — request 1 while `pairSetup` is not started, request 2 after.
    private func pairSetupResponse(for request: Request) -> Response {
        guard let entries = TLV8.decode(request.body) else {
            return Response(status: 404, body: Data("Not Found".utf8))
        }
        let a = entries.first(where: { $0.type == 4 })
        if pairSetup.isStarted {
            guard let clientM4 = a?.value,
                  let result = pairSetup.complete(clientM4: clientM4) else {
                return Response(status: 400, body: Data("Bad Request".utf8))
            }
            return Response(
                status: 200,
                body: TLV8.encode([
                    TLV8Entry(type: 5, value: result.M5),
                    TLV8Entry(type: 7, value: result.M6),
                ])
            )
        }
        guard let a, a.value.count == 32,
              let result = pairSetup.start(clientA: a.value) else {
            return Response(status: 404, body: Data("Not Found".utf8))
        }
        return Response(
            status: 200,
            body: TLV8.encode([
                TLV8Entry(type: 3, value: result.B),
                TLV8Entry(type: 6, value: result.salt),
            ])
        )
    }

    /// The `POST /pair-verify` route (TASK-019): dispatches on the exchange
    /// state — request 1 while `pairVerifySession` is nil (the client's
    /// ephemeral public key `A_e`, TLV type 1), request 2 after (the client
    /// proof `T`, TLV type 4).
    private func pairVerifyResponse(for request: Request) -> Response {
        guard let entries = TLV8.decode(request.body) else {
            return Response(status: 404, body: Data("Not Found".utf8))
        }
        if let session = pairVerifySession {
            // Request 2: the client proof T.
            guard let clientT = entries.first(where: { $0.type == 4 })?.value,
                let salt = pairingStore.record?.salt,
                let proof = session.verify(
                    clientT: clientT,
                    accessoryPublicKey: AccessoryIdentity.shared.publicKey,
                    salt: salt
                ) else {
                return Response(status: 400, body: Data("Bad Request".utf8))
            }
            return Response(
                status: 200,
                body: TLV8.encode([
                    TLV8Entry(type: 3, value: proof),
                ])
            )
        }
        // Request 1: the client's ephemeral public key A_e.
        guard let clientA = entries.first(where: { $0.type == 1 })?.value else {
            return Response(status: 400, body: Data("Bad Request".utf8))
        }
        let session = HAPPairVerify.Session(clientA: clientA)
        pairVerifySession = session
        return Response(
            status: 200,
            body: TLV8.encode([
                TLV8Entry(type: 2, value: session.b),
            ])
        )
    }

    /// The `GET /info` body: the accessory info as JSON, with the pairing
    /// state read from the store (TASK-017).
    var infoBody: Data {
        Data(
            "{\"name\": \"\(Self.accessoryName)\", \"category\": \"\(Self.accessoryCategory)\", \"paired\": \(pairingStore.paired)}"
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
        let phrase = response.status == 200 ? "OK" : response.status == 400 ? "Bad Request" : "Not Found"
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
