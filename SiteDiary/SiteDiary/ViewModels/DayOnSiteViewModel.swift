import Foundation
import Observation

@Observable
final class DayOnSiteViewModel {
    var workday: Workday?
    var knockOffDefectCount = 0
    var crewOnSiteCount = 0
    var notice: DiaryNotice?

    let day: Date
    private let repository: any SiteDiaryRepository

    init(repository: any SiteDiaryRepository, day: Date) {
        self.repository = repository
        self.day = day
    }

    func load() {
        do {
            workday = try repository.workday(on: day)
            if let workday {
                knockOffDefectCount = try repository.openKnockOffDefects(on: day).count
                crewOnSiteCount = try repository.crew(for: workday.id).filter(\.isOnSite).count
            } else {
                knockOffDefectCount = 0
                crewOnSiteCount = 0
            }
        } catch {
            notice = DiaryFeedback.couldNotReadDiary
        }
    }
}
