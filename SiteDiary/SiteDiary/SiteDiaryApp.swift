import SwiftUI

@main
struct SiteDiaryApp: App {
    @UIApplicationDelegateAdaptor(DiaryNotificationDelegate.self) private var notifications
    private let repository: any SiteDiaryRepository = CoreDataSiteDiaryRepository()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.siteDiaryRepository, repository)
        }
    }
}
