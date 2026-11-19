import SwiftUI

struct ContentView: View {
    var status: ReceiverStatus = .idle

    var body: some View {
        VStack(spacing: 8) {
            Text(AppInfo.displayName)
                .font(.title2)
            Text(status.statusText(name: AppInfo.displayName))
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
