import Foundation
import Observation

@Observable
final class RecordDefectViewModel {
    var title = ""
    var location = ""
    var detail = ""
    var mustClearBeforeKnockOff = true
    var notice: DiaryNotice?

    private let day: Date
    private let repository: any SiteDiaryRepository

    init(repository: any SiteDiaryRepository, day: Date) {
        self.repository = repository
        self.day = day
    }

    func record() -> Bool {
        notice = nil
        do {
            _ = try TrackDefect(repository: repository).record(
                title: title,
                location: location,
                detail: detail,
                mustClearBeforeKnockOff: mustClearBeforeKnockOff,
                on: day
            )
            return true
        } catch let error as TrackDefectError {
            notice = DiaryNotice(whatWentWrong: error.whatWentWrong, whatToDoNext: error.whatToDoNext)
            return false
        } catch {
            notice = DiaryFeedback.couldNotSaveDiary
            return false
        }
    }
}
