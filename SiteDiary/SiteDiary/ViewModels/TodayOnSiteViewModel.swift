import Foundation
import Observation

@Observable
final class TodayOnSiteViewModel {
    var siteName = ""
    var knockOffTime: Date
    var workday: Workday?
    var knockOffDefectCount = 0
    var crewOnSiteCount = 0
    var notice: DiaryNotice?

    private let repository: any SiteDiaryRepository

    init(repository: any SiteDiaryRepository, now: Date = Date()) {
        self.repository = repository
        knockOffTime = Self.defaultKnockOffTime(on: now)
    }

    func load() {
        do {
            let today = Date()
            workday = try repository.workday(on: today)
            if let workday {
                knockOffDefectCount = try repository.openKnockOffDefects(on: today).count
                crewOnSiteCount = try repository.crew(for: workday.id).filter(\.isOnSite).count
            } else {
                knockOffDefectCount = 0
                crewOnSiteCount = 0
            }
        } catch {
            notice = DiaryFeedback.couldNotReadDiary
        }
    }

    func openTheDay() {
        notice = nil
        do {
            workday = try OpenTodaysDiary(repository: repository).open(
                siteName: siteName,
                knockOffTime: knockOffTime
            )
            load()
        } catch let error as OpenTodaysDiaryError {
            notice = DiaryNotice(whatWentWrong: error.whatWentWrong, whatToDoNext: error.whatToDoNext)
        } catch {
            notice = DiaryFeedback.couldNotSaveDiary
        }
    }

    private static func defaultKnockOffTime(on day: Date) -> Date {
        var components = SiteCalendar.calendar.dateComponents([.year, .month, .day], from: day)
        components.hour = 15
        components.minute = 30
        return SiteCalendar.calendar.date(from: components) ?? day
    }
}
