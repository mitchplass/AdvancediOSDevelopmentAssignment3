import SwiftUI

private struct SiteDiaryRepositoryKey: EnvironmentKey {
    static let defaultValue: any SiteDiaryRepository = CoreDataSiteDiaryRepository(
        persistence: PersistenceController(inMemory: true),
        publishesGlance: false
    )
}

extension EnvironmentValues {
    var siteDiaryRepository: any SiteDiaryRepository {
        get { self[SiteDiaryRepositoryKey.self] }
        set { self[SiteDiaryRepositoryKey.self] = newValue }
    }
}
