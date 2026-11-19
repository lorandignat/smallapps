import XCTest
@testable import PlayTwo

final class EventLogTests: XCTestCase {

    /// A UTC `EventLog.timestampFormat` formatter, mirroring what the log
    /// writes so the tests can parse the timestamp prefix.
    private func utcTimestampFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.dateFormat = EventLog.timestampFormat
        return formatter
    }

    // MARK: - Criterion 1: a record leaves one timestamped line

    func testRecordAppendsTimestampedLine() {
        let log = EventLog()
        XCTAssertTrue(log.entries.isEmpty, "a new log starts empty")

        log.record("Advertising as PlayTwo")

        XCTAssertEqual(log.entries.count, 1, "one record leaves one entry")
        guard let entry = log.entries.first else {
            return XCTFail("expected the record to leave one entry")
        }
        XCTAssertEqual(entry.message, "Advertising as PlayTwo", "the entry's message is the recorded line")
        XCTAssertEqual(entry.text, entry.timestamp + "Advertising as PlayTwo", "the text is the message prefixed by its timestamp")

        let formatter = utcTimestampFormatter()
        guard let parsed = formatter.date(from: entry.timestamp) else {
            return XCTFail("the timestamp is not in the yyyy-MM-dd HH:mm:ss.SSS format")
        }
        XCTAssertLessThanOrEqual(
            abs(parsed.timeIntervalSinceNow),
            2,
            "the timestamp is within 2 seconds of the test's own clock"
        )
    }

    // MARK: - Criterion 2: capacity 2000, the oldest surviving is record 6

    func testCapacityIsBoundedAndOldestSurvivingIsRecordSix() {
        let log = EventLog()
        for number in 1...2005 {
            log.record("record \(number)")
        }

        XCTAssertEqual(log.entries.count, 2000, "entries.count == 2000 after 2005 records")
        XCTAssertEqual(log.entries.first?.message, "record 6", "the oldest surviving entry is record 6")
        XCTAssertEqual(log.entries.last?.message, "record 2005", "the newest record is the last entry")
    }

    // MARK: - Criterion 3: advertising then backgrounding leaves a Stopped line

    func testAdvertisingThenBackgroundingLeavesAdvertisingThenStopped() {
        let spy = SpyAdvertiser()
        let appState = AppState(advertiser: spy)
        appState.status = .stopped
        spy.state = .stopped

        appState.handleScenePhase(.active)    // start → advertising
        appState.handleScenePhase(.background) // background → stop

        let messages = appState.eventLog.entries.map(\.message)
        let advertising = messages.firstIndex { $0.hasPrefix("Advertising") && $0.contains("PlayTwo") }
        XCTAssertNotNil(advertising, "the log holds a line starting with Advertising naming the service: \(messages)")
        let stopped = messages.firstIndex { $0.hasPrefix("Stopped") }
        XCTAssertNotNil(stopped, "the log holds a line starting with Stopped: \(messages)")
        guard let advertising = advertising, let stopped = stopped else {
            return
        }
        XCTAssertLessThan(advertising, stopped, "the Stopped line comes after the Advertising line")
    }

    // MARK: - Criterion 4: the first entry of every launch is Restart

    func testRestartMarkerIsTheFirstEntryOfEveryLaunch() {
        let firstLaunch = AppState(advertiser: SpyAdvertiser())
        XCTAssertEqual(firstLaunch.eventLog.entries.first?.message, "Restart", "the first entry's message is exactly Restart")
        guard let entry = firstLaunch.eventLog.entries.first else {
            return XCTFail("the log starts with the Restart marker")
        }
        XCTAssertEqual(entry.text, entry.timestamp + "Restart", "nothing follows the timestamp: the marker is the whole message")

        let relaunch = AppState(advertiser: SpyAdvertiser())
        XCTAssertEqual(relaunch.eventLog.entries.first?.message, "Restart", "a relaunch's first entry is the same Restart marker")
    }

    // MARK: - Criterion 5: concurrent records are not lost or duplicated

    func testConcurrentRecordsProduceExactlyOneHundredEntries() {
        let log = EventLog()
        let group = DispatchGroup()
        for thread in 0..<4 {
            group.enter()
            DispatchQueue.global().async {
                defer { group.leave() }
                for record in 0..<25 {
                    log.record("concurrent \(thread) \(record)")
                }
            }
        }
        group.wait()

        XCTAssertEqual(log.entries.count, 100, "4 threads × 25 records: every record lands, no crash")
    }
}
