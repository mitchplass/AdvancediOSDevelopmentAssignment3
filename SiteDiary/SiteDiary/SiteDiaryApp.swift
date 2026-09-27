import SwiftUI

@main
struct SiteDiaryApp: App {
    private let repository: any SiteDiaryRepository = CoreDataSiteDiaryRepository()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.siteDiaryRepository, repository)
        }
    }
}
