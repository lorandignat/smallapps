import XCTest
@testable import PlayTwo

final class TLV8Tests: XCTestCase {

    /// Criterion 1: entries with values of at most 255 bytes round-trip,
    /// including empty values, repeated types and a 255-byte value.
    func testRoundTripsEntriesWithValuesUpTo255Bytes() {
        let entries = [
            TLV8Entry(type: 1, value: Data()),
            TLV8Entry(type: 2, value: Data("A".utf8)),
            TLV8Entry(type: 3, value: Data("hello".utf8)),
            TLV8Entry(type: 3, value: Data(repeating: 0x42, count: 255)),
            TLV8Entry(type: 2, value: Data("world".utf8)),
        ]
        assertRoundTrip(entries)
    }

    /// Criterion 2: a 300-byte value is split on the wire into fragments of
    /// 255 and 45 bytes with a zero-length terminator of the same type, and
    /// it round-trips.
    func testEncodes300ByteValueWithContinuationForm() {
        let value = Data(repeating: 0x42, count: 300)
        let wire = TLV8.encode([TLV8Entry(type: 9, value: value)])

        XCTAssertEqual(wire.count, 306)
        XCTAssertEqual(wire[0], 9)
        XCTAssertEqual(wire[1], 255)
        XCTAssertEqual(wire[257], 9)
        XCTAssertEqual(wire[258], 45)
        XCTAssertEqual(wire[304], 9)
        XCTAssertEqual(wire[305], 0)

        assertDecodes(wire, to: [TLV8Entry(type: 9, value: value)])
    }

    /// Criterion 3: truncated input decodes to nil rather than a partial entry.
    func testDecodeReturnsNilWhenTruncated() {
        XCTAssertNil(TLV8.decode(data(1, 2, 65)))     // value cut mid-entry
        XCTAssertNil(TLV8.decode(data(1, 2)))         // header without a value
        XCTAssertNil(TLV8.decode(data(1)))            // header cut
        XCTAssertNil(TLV8.decode(data(9, 255, 65)))  // fragmented entry, value cut
    }

    /// Criterion 4: two entries with the same type stay two separate entries.
    func testTwoEntriesWithSameTypeStaySeparate() {
        let entries = [
            TLV8Entry(type: 5, value: Data("alpha".utf8)),
            TLV8Entry(type: 5, value: Data("beta".utf8)),
        ]
        assertRoundTrip(entries)
    }

    /// Boundary: values just past 255 fragment on the wire and come back unchanged.
    func testRoundTripsValuesJustPast255Bytes() {
        assertRoundTrip([TLV8Entry(type: 4, value: Data(repeating: 0x41, count: 256))])
        assertRoundTrip([TLV8Entry(type: 4, value: Data(repeating: 0x41, count: 511))])
        assertRoundTrip([TLV8Entry(type: 4, value: Data(repeating: 0x41, count: 512))])
    }

    private func data(_ bytes: UInt8...) -> Data {
        Data(bytes)
    }

    private func assertRoundTrip(
        _ entries: [TLV8Entry],
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        assertDecodes(TLV8.encode(entries), to: entries, file: file, line: line)
    }

    private func assertDecodes(
        _ wire: Data,
        to expected: [TLV8Entry],
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        guard let decoded = TLV8.decode(wire) else {
            XCTFail("TLV8.decode returned nil", file: file, line: line)
            return
        }
        XCTAssertEqual(decoded, expected, file: file, line: line)
    }
}
