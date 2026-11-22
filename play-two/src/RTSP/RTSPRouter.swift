import Foundation
import Network

/// Routes connections on the AirPlay port by request-line protocol token.
///
/// RTSP/1.0 requests are answered by the RTSP handlers; HTTP/1.1 requests are
/// routed to the HAP server unchanged. Detection is based on the request-line
/// protocol token, not by port and not by trying HTTP first and falling back.
/// A request that is neither valid RTSP nor valid HTTP fails closed: the
/// connection is cancelled with no response, matching HAPServer behaviour for
/// unparsable input.
final class RTSPRouter {

    /// The HAP server that owns HTTP routes. HTTP requests are routed through
    /// it; its HTTP semantics are unchanged (DEC-018).
    let server: HAPServer

    private let queue = DispatchQueue(label: "com.lorand.playtwo.rtsp-router")

    init(server: HAPServer = HAPServer()) {
        self.server = server
    }

    /// Handles one accepted connection: reads until the protocol can be
    /// determined from the request line, then dispatches. The connection is
    /// never read by anyone else; the router owns it for its lifetime.
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
                guard let lineEnd = self.requestLineEnd(in: received) else {
                    if isComplete || data == nil {
                        // No complete request line: neither valid RTSP nor valid HTTP.
                        connection.cancel()
                    } else {
                        receiveMore()
                    }
                    return
                }
                let lineData = received[..<lineEnd]
                guard let line = String(data: lineData, encoding: .utf8) else {
                    connection.cancel()
                    return
                }
                let parts = line.split(separator: " ", omittingEmptySubsequences: false)
                guard parts.count == 3 else {
                    connection.cancel()
                    return
                }
                let version = String(parts[2])
                if version == "RTSP/1.0" {
                    self.handleRTSP(received: received, on: connection, isComplete: isComplete)
                } else if version == "HTTP/1.1" {
                    self.handleHTTP(received: received, on: connection, isComplete: isComplete)
                } else {
                    // Unknown protocol token: fail closed.
                    connection.cancel()
                }
            }
        }
        receiveMore()
    }

    // MARK: - RTSP

    private func handleRTSP(received: Data, on connection: NWConnection, isComplete: Bool) {
        var buffer = received
        var complete = isComplete
        func readUntilParsed() {
            if let request = RTSPRequest.parse(buffer) {
                respondRTSP(to: request, on: connection)
                return
            }
            if complete {
                connection.cancel()
                return
            }
            connection.receive(minimumIncompleteLength: 1, maximumLength: 8192) { data, _, done, error in
                guard error == nil else {
                    connection.cancel()
                    return
                }
                if let data, !data.isEmpty {
                    buffer.append(data)
                }
                complete = done
                if let request = RTSPRequest.parse(buffer) {
                    self.respondRTSP(to: request, on: connection)
                } else if done || data == nil {
                    connection.cancel()
                } else {
                    readUntilParsed()
                }
            }
        }
        readUntilParsed()
    }

    private func respondRTSP(to request: RTSPRequest, on connection: NWConnection) {
        // OPTIONS only for this task; no speculative SETUP/ANNOUNCE routes.
        guard request.method == "OPTIONS" else {
            connection.cancel()
            return
        }
        let payload = RTSPResponse.options(for: request)
        connection.send(
            content: payload,
            contentContext: .defaultMessage,
            isComplete: true,
            completion: .contentProcessed { _ in
                connection.cancel()
            }
        )
    }

    // MARK: - HTTP

    private func handleHTTP(received: Data, on connection: NWConnection, isComplete: Bool) {
        var buffer = received
        var complete = isComplete
        func readUntilParsed() {
            if let request = HAPServer.parse(buffer) {
                sendHTTPResponse(for: request, on: connection)
                return
            }
            if complete {
                connection.cancel()
                return
            }
            connection.receive(minimumIncompleteLength: 1, maximumLength: 8192) { data, _, done, error in
                guard error == nil else {
                    connection.cancel()
                    return
                }
                if let data, !data.isEmpty {
                    buffer.append(data)
                }
                complete = done
                if let request = HAPServer.parse(buffer) {
                    self.sendHTTPResponse(for: request, on: connection)
                } else if done || data == nil {
                    connection.cancel()
                } else {
                    readUntilParsed()
                }
            }
        }
        // The first chunk may already contain a complete HTTP request.
        readUntilParsed()
    }

    private func sendHTTPResponse(for request: HAPServer.Request, on connection: NWConnection) {
        let response = server.route(request)
        let phrase: String
        switch response.status {
        case 200:
            phrase = "OK"
        case 400:
            phrase = "Bad Request"
        default:
            phrase = "Not Found"
        }
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

    // MARK: - Request line

    /// The index of the first `\r\n` in `data`, or nil when no complete line
    /// is present yet. Detection uses the request line only.
    private func requestLineEnd(in data: Data) -> Int? {
        guard data.count >= 2 else { return nil }
        for index in 0..<(data.count - 1) {
            if data[index] == 0x0D, data[index + 1] == 0x0A {
                return index
            }
        }
        return nil
    }
}
