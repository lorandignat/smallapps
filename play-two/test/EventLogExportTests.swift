import XCTest
@testable import PlayTwo

/// The TASK-008 unit tests for `EventLogExport`: the file the screen shares.
final class EventLogExportTests: XCTestCase {

    /// The file the export writes into the temporary directory.
    private var exportedFileURL: URL {
        FileManager.default.temporaryDirectory.appendingPathComponent(EventLogExport.fileName)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: exportedFileURL)
        super.tearDown()
    }

    // MARK: - Criterion 1: two entries → the file, in order, one trailing \n

    func testExportWritesTheTwoEntriesAsLinesInOrder() {
        let entries = [
            "2026-11-19 10:00:00.000 Restart",
            "2026-11-19 10:00:01.000 Advertising as PlayTwo",
        ]
        let result = EventLogExport.export(entries, to: FileManager.default.temporaryDirectory)
        guard case .success(let url) = result else {
            return XCTFail("export of two entries should succeed")
        }
        XCTAssertEqual(url.lastPathComponent, EventLogExport.fileName, "the file is named airplay-receiver-log.txt")
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path), "the file exists in the temporary directory")
        guard let contents = try? Data(contentsOf: url) else {
            return XCTFail("the exported file is readable")
        }
        XCTAssertEqual(
            String(data: contents, encoding: .utf8),
            entries[0] + "\n" + entries[1] + "\n",
            "the entries are the file's lines in the same order, joined by one newline"
        )
    }

    // MARK: - Criterion 2: an empty log → a 0-byte file

    func testExportOfAnEmptyLogReturnsAZeroByteFile() {
        let result = EventLogExport.export([], to: FileManager.default.temporaryDirectory)
        guard case .success(let url) = result else {
            return XCTFail("export of an empty log should still return the file")
        }
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path), "the file exists")
        let contents = try? Data(contentsOf: url)
        XCTAssertEqual(contents?.count, 0, "the file is 0 bytes")
    }

    // MARK: - Criterion 3: the directory cannot be written → .failure

    func testExportFailsWhenTheDirectoryCannotBeWritten() {
        let blocked = FileManager.default.temporaryDirectory
            .appendingPathComponent("EventLogExportTests-blocked-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: blocked, withIntermediateDirectories: false)
        try? FileManager.default.setAttributes([.posixPermissions: 0o500], ofItemAtPath: blocked.path)
        defer {
            try? FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: blocked.path)
            try? FileManager.default.removeItem(at: blocked)
        }
        let result = EventLogExport.export(["2026-11-19 10:00:00.000 Restart"], to: blocked)
        guard case .failure(let error) = result else {
            return XCTFail("export into an unwritable directory should fail")
        }
        XCTAssertFalse(error.message.isEmpty, "the failure carries the underlying message")
    }
}
