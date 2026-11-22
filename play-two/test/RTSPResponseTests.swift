import XCTest
@testable import PlayTwo

final class RTSPResponseTests: XCTestCase {

    func testOptionsResponseHasStatusCSeqAndTerminator() {
        let raw = "OPTIONS * RTSP/1.0\r\nCSeq: 2\r\n\r\n"
        let request = RTSPRequest.parse(Data(raw.utf8))!

        let response = RTSPResponse.options(for: request)
        let text = String(decoding: response, as: UTF8.self)

        XCTAssertTrue(text.hasPrefix("RTSP/1.0 200 OK\r\n"))
        XCTAssertTrue(text.contains("CSeq: 2\r\n"))
        XCTAssertTrue(text.hasSuffix("\r\n\r\n"))
    }

    func testOptionsResponseEchoesRequestCSeq() {
        let raw = "OPTIONS * RTSP/1.0\r\nCSeq: 7\r\n\r\n"
        let request = RTSPRequest.parse(Data(raw.utf8))!

        let response = RTSPResponse.options(for: request)
        let text = String(decoding: response, as: UTF8.self)

        XCTAssertTrue(text.contains("CSeq: 7\r\n"))
        XCTAssertFalse(text.contains("CSeq: 2\r\n"))
    }

    func testOptionsResponseAdvertisesPublicMethods() {
        // Pinned to the Unofficial AirPlay Protocol Specification
        // (https://nto.github.io/AirPlay.html, section 5.1 "OPTIONS"), which
        // shows the RAOP/AirPlay RTSP OPTIONS response:
        //   RTSP/1.0 200 OK
        //   Public: ANNOUNCE, SETUP, RECORD, PAUSE, FLUSH, TEARDOWN, OPTIONS, GET_PARAMETER, SET_PARAMETER, POST, GET
        //   Server: AirTunes/130.14
        //   CSeq: 3
        // We pin the Public method-advertising header name/value exactly; if
        // device evidence requires a different value, re-cut TASK-023 rather than
        // silently changing this fixture.
        let raw = "OPTIONS * RTSP/1.0\r\nCSeq: 1\r\n\r\n"
        let request = RTSPRequest.parse(Data(raw.utf8))!

        let response = RTSPResponse.options(for: request)
        let text = String(decoding: response, as: UTF8.self)

        XCTAssertTrue(
            text.contains("Public: ANNOUNCE, SETUP, RECORD, PAUSE, FLUSH, TEARDOWN, OPTIONS, GET_PARAMETER, SET_PARAMETER, POST, GET\r\n")
        )
    }
}
