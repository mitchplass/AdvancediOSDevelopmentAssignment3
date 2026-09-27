import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "No diary for today yet",
                systemImage: "hammer",
                description: Text("Open the day before you walk the site.")
            )
            .navigationTitle("Today on site")
        }
    }
}

#Preview {
    ContentView()
}
