import XCTest
@testable import PlayTwo

final class RTSPRequestTests: XCTestCase {

    func testParsesOptionsRequestLineAndCSeq() {
        let raw = "OPTIONS * RTSP/1.0\r\nCSeq: 1\r\n\r\n"
        let data = Data(raw.utf8)

        let request = RTSPRequest.parse(data)

        XCTAssertEqual(request?.method, "OPTIONS")
        XCTAssertEqual(request?.target, "*")
        XCTAssertEqual(request?.cseq, 1)
    }

    func testParsesBodyExactlyToContentLength() {
        let body = Data([0x01, 0x02, 0x03, 0x04])
        var raw = Data("SETUP rtsp://example/stream RTSP/1.0\r\nCSeq: 2\r\nContent-Length: 4\r\n\r\n".utf8)
        raw.append(body)
        raw.append(Data([0x99, 0xAA])) // trailing bytes must not leak into body

        let request = RTSPRequest.parse(raw)

        XCTAssertEqual(request?.body, body)
        XCTAssertEqual(request?.body.count, 4)
    }

    func testReturnsNilForMalformedRequests() {
        let missingRequestLine = Data("\r\nCSeq: 1\r\n\r\n".utf8)
        let unknownProtocol = Data("OPTIONS * HTTP/1.1\r\nCSeq: 1\r\n\r\n".utf8)
        let truncatedBody = Data("ANNOUNCE * RTSP/1.0\r\nCSeq: 3\r\nContent-Length: 5\r\n\r\nabc".utf8)

        XCTAssertNil(RTSPRequest.parse(missingRequestLine))
        XCTAssertNil(RTSPRequest.parse(unknownProtocol))
        XCTAssertNil(RTSPRequest.parse(truncatedBody))
    }
}
