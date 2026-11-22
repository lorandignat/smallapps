import Foundation

/// Builds RTSP/1.0 responses.
///
/// Pure value type: request in, bytes out. No socket, no I/O. Later tasks route
/// live requests through this builder.
struct RTSPResponse {
    /// Minimal OPTIONS response for an RTSP request.
    ///
    /// Echoes the request CSeq and advertises the RTSP methods supported by the
    /// RAOP/AirPlay session shape we implement incrementally.
    static func options(for request: RTSPRequest) -> Data {
        let cseq = request.header("CSeq") ?? "0"
        // Public methods pinned to the Unofficial AirPlay Protocol Specification
        // (nto.github.io/AirPlay.html, section 5.1 "OPTIONS"), which records the
        // RTSP OPTIONS response Public header as:
        // ANNOUNCE, SETUP, RECORD, PAUSE, FLUSH, TEARDOWN, OPTIONS, GET_PARAMETER,
        // SET_PARAMETER, POST, GET.
        // If device evidence requires a different value, re-cut TASK-023 rather
        // than silently changing this fixture.
        let response = "RTSP/1.0 200 OK\r\n"
            + "CSeq: \(cseq)\r\n"
            + "Public: ANNOUNCE, SETUP, RECORD, PAUSE, FLUSH, TEARDOWN, OPTIONS, GET_PARAMETER, SET_PARAMETER, POST, GET\r\n"
            + "\r\n"
        return Data(response.utf8)
    }
}
