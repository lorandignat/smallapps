import Foundation

/// The failure `EventLogExport.export` returns when the log file cannot be
/// written: `message` is the underlying write error's `localizedDescription`,
/// so the screen shows it verbatim as `Export failed: <message>`.
struct EventLogExportError: Error, Equatable {
    let message: String
}

/// The export of the diagnostic log to a file (TASK-008): one file, one line
/// per log entry, for the system's share sheet. The file is the evidence QA
/// and the human need when the Apple TV does not list the phone.
enum EventLogExport {

    /// The file the export writes, in whichever directory it is given.
    static let fileName = "airplay-receiver-log.txt"

    /// Writes `entries` to `directory`/``fileName``: every entry is one line,
    /// in the same order, each terminated by one `\n` (two entries `a`, `b`
    /// produce `a\nb\n`; an empty log produces a 0-byte file). Every call
    /// overwrites the file — there is no history, the session log is the
    /// record (TASK-008).
    ///
    /// Returns the file's URL on success. When the directory cannot be
    /// written, returns `.failure` carrying ``EventLogExportError`` with the
    /// underlying message.
    static func export(_ entries: [String], to directory: URL) -> Result<URL, EventLogExportError> {
        let fileURL = directory.appendingPathComponent(fileName)
        // `joined(separator:)` on `[String]` returns `String` (as
        // `DeviceIdentity.generate()` relies on), so the `.utf8` view exists.
        let contents = Data(entries.map { $0 + "\n" }.joined(separator: "").utf8)
        do {
            try contents.write(to: fileURL, options: [.atomic])
            return .success(fileURL)
        } catch {
            return .failure(EventLogExportError(message: (error as NSError).localizedDescription))
        }
    }
}
