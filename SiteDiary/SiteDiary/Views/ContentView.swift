import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            TodayOnSiteScreen()
                .navigationDestination(for: SiteDiaryPage.self) { page in
                    switch page {
                    case .defects:
                        DefectListScreen()
                    case .crew:
                        CrewOnSiteScreen()
                    case .closeOut:
                        CloseOutScreen()
                    }
                }
        }
    }
}

#Preview {
    ContentView()
}
