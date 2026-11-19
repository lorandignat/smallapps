import SwiftUI

/// The app's one screen.
///
/// A static placeholder for now: TASK-005 replaces the body with the receiver
/// state (`Idle`, `Advertising`, `Stopped`, error text) and the advertised name.
struct ContentView: View {
    var body: some View {
        VStack(spacing: 8) {
            Text(AppInfo.displayName)
                .font(.title2)
            Text("Not advertising yet")
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
