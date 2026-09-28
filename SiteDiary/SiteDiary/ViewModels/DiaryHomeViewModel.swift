import Foundation
import Observation

@Observable
final class DiaryHomeViewModel {
    var days: [Workday] = []
    var siteName = ""
    var diaryDate: Date
    var knockOffTime: Date
    var notice: DiaryNotice?

    private let repository: any SiteDiaryRepository

    init(repository: any SiteDiaryRepository, now: Date = Date()) {
        self.repository = repository
        diaryDate = SiteCalendar.startOfDay(for: now)
        knockOffTime = Self.defaultKnockOffTime(on: now)
    }

    func load() {
        do {
            days = try repository.allWorkdays()
        } catch {
            notice = DiaryFeedback.couldNotReadDiary
        }
    }

    func openTheDay() -> Date? {
        notice = nil
        let day = SiteCalendar.startOfDay(for: diaryDate)
        do {
            _ = try OpenTodaysDiary(repository: repository).open(
                siteName: siteName,
                knockOffTime: Self.knockOffTime(on: day, clock: knockOffTime),
                on: day
            )
            load()
            return day
        } catch let error as OpenTodaysDiaryError {
            notice = DiaryNotice(whatWentWrong: error.whatWentWrong, whatToDoNext: error.whatToDoNext)
            return nil
        } catch {
            notice = DiaryFeedback.couldNotSaveDiary
            return nil
        }
    }

    private static func defaultKnockOffTime(on day: Date) -> Date {
        knockOffTime(on: day, hour: 15, minute: 30)
    }

    private static func knockOffTime(on day: Date, clock: Date) -> Date {
        let time = SiteCalendar.calendar.dateComponents([.hour, .minute], from: clock)
        return knockOffTime(on: day, hour: time.hour ?? 15, minute: time.minute ?? 30)
    }

    private static func knockOffTime(on day: Date, hour: Int, minute: Int) -> Date {
        var components = SiteCalendar.calendar.dateComponents([.year, .month, .day], from: day)
        components.hour = hour
        components.minute = minute
        return SiteCalendar.calendar.date(from: components) ?? day
    }
}
