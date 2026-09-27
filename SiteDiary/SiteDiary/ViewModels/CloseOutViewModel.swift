import Foundation
import Observation

@Observable
final class CloseOutViewModel {
    var remaining: [Defect] = []
    var isClosed = false
    var hasOpenDiary = false
    var notice: DiaryNotice?

    var canClose: Bool {
        hasOpenDiary && remaining.isEmpty
    }

    private let repository: any SiteDiaryRepository

    init(repository: any SiteDiaryRepository) {
        self.repository = repository
    }

    func load() {
        do {
            guard let workday = try repository.workday(on: Date()) else {
                remaining = []
                isClosed = false
                hasOpenDiary = false
                return
            }
            isClosed = workday.status == .closed
            hasOpenDiary = workday.status == .open
            remaining = isClosed ? [] : try repository.openKnockOffDefects(on: Date())
        } catch {
            notice = DiaryFeedback.couldNotReadDiary
        }
    }

    func closeOut() {
        notice = nil
        do {
            _ = try CloseOutWorkday(repository: repository).close()
            load()
        } catch let error as CloseOutWorkdayError {
            notice = DiaryNotice(whatWentWrong: error.whatWentWrong, whatToDoNext: error.whatToDoNext)
        } catch {
            notice = DiaryFeedback.couldNotSaveDiary
        }
    }
}
