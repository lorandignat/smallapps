import Foundation

/// An in-memory, bounded, thread-safe diagnostic log of advertisement events
/// (TASK-007).
///
/// Every start, stop and failure event leaves one timestamped line in the
/// log; ``AppState`` writes the launch marker (`Restart`) when the app comes
/// into existence, so the first line of every session's log is the launch
/// itself. The log is memory-only — TASK-008 exports it — and carries
/// message plus outcome only: never the TXT record contents, never the
/// device id.
final class EventLog {

    /// One recorded line: the UTC timestamp prefix and the message.
    struct Entry: Equatable {
        /// The timestamp prefix of the line, in ``timestampFormat``.
        let timestamp: String

        /// The message that follows the timestamp.
        let message: String

        /// The complete line: the timestamp, then the message.
        var text: String { timestamp + message }
    }

    /// The maximum number of entries the log holds; the oldest entry is
    /// dropped when a record would exceed it, so the log stays bounded.
    static let capacity = 2000

    /// The fixed line format every timestamp is rendered in: `yyyy-MM-dd
    /// HH:mm:ss.SSS` in `en_US_POSIX` and `UTC` — never the device locale —
    /// so TASK-008's export is diffable and the log lines up with the Apple
    /// TV's clock.
    static let timestampFormat = "yyyy-MM-dd HH:mm:ss.SSS"

    /// The formatter for ``timestampFormat``, built once. `DateFormatter` is
    /// not safe to share without a lock, so every timestamp is rendered
    /// while the log's lock is held.
    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.dateFormat = timestampFormat
        return formatter
    }()

    /// The entries the log holds right now, oldest first (a copy).
    var entries: [Entry] {
        lock.lock()
        defer { lock.unlock() }
        return storage
    }

    private var storage: [Entry] = []
    private let lock = NSLock()

    /// Appends one line: the timestamp of the moment and `message`. When the
    /// log is at capacity the oldest entry is dropped.
    func record(_ message: String) {
        lock.lock()
        defer { lock.unlock() }
        storage.append(Entry(timestamp: Self.formatter.string(from: Date()), message: message))
        if storage.count > Self.capacity {
            storage.removeFirst(storage.count - Self.capacity)
        }
    }
}
