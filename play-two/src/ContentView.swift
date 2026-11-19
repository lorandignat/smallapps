import SwiftUI
import UIKit

struct ContentView: View {
    /// The receiver's state, mirrored from ``AppState`` (TASK-005).
    var status: ReceiverStatus = .idle

    /// The diagnostic log the export writes (TASK-008): the app passes
    /// ``AppState/eventLog``; previews and other direct constructions get a
    /// fresh log.
    var eventLog: EventLog = EventLog()

    /// The file the last successful export wrote; `nil` until then.
    @State private var exportedFile: ExportedFile?

    /// The text of the last failed export — the screen's `Export failed:
    /// …` line; `nil` when nothing failed.
    @State private var exportError: String?

    var body: some View {
        VStack(spacing: 8) {
            Text(AppInfo.displayName)
                .font(.title2)
            Text(status.statusText(name: AppInfo.displayName))
                .foregroundColor(.secondary)
            if let exportError = exportError {
                Text(exportError)
                    .foregroundColor(.red)
            }
            Button("Export Log") {
                didTapExport()
            }
        }
        .padding()
        .sheet(item: $exportedFile) { file in
            ShareSheet(fileURL: file.url)
        }
    }

    /// The one action the owner gives the screen (TASK-008): write the log to
    /// `airplay-receiver-log.txt` and hand it to the system's share sheet —
    /// or report the write failure as `Export failed: <message>`. The status
    /// text is never changed by the export.
    private func didTapExport() {
        exportError = nil
        let entries = eventLog.entries.map(\.text)
        switch EventLogExport.export(entries, to: FileManager.default.temporaryDirectory) {
        case .success(let url):
            exportedFile = ExportedFile(url: url)
        case .failure(let error):
            exportError = "Export failed: \(error.message)"
        }
    }
}

/// The exported file, so it can be the ``ContentView/exportedFile`` item.
private struct ExportedFile: Identifiable {
    let url: URL
    var id: URL { url }
}

/// Presents the iOS share sheet (TASK-008): the system's one-tap way to hand
/// the exported file to the user — Mail, Messages, the Files app — with no
/// third-party library.
private struct ShareSheet: UIViewControllerRepresentable {
    let fileURL: URL

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
