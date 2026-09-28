import Foundation
import Observation

@Observable
final class CloseOutViewModel {
    var remaining: [Defect] = []
    var crewStillOnSite: [CrewPresence] = []
    var isClosed = false
    var hasOpenDiary = false
    var didClose = false
    var notice: DiaryNotice?

    var canClose: Bool {
        hasOpenDiary && remaining.isEmpty && crewStillOnSite.isEmpty
    }

    private let repository: any SiteDiaryRepository

    init(repository: any SiteDiaryRepository) {
        self.repository = repository
    }

    func load() {
        do {
            guard let workday = try repository.workday(on: Date()) else {
                remaining = []
                crewStillOnSite = []
                isClosed = false
                hasOpenDiary = false
                return
            }
            isClosed = workday.status == .closed
            hasOpenDiary = workday.status == .open
            remaining = isClosed ? [] : try repository.openKnockOffDefects(on: Date())
            crewStillOnSite = isClosed ? [] : try repository.crew(for: workday.id).filter(\.isOnSite)
        } catch {
            notice = DiaryFeedback.couldNotReadDiary
        }
    }

    func closeOut() {
        notice = nil
        do {
            _ = try CloseOutWorkday(repository: repository).close()
            didClose = true
            load()
        } catch let error as CloseOutWorkdayError {
            notice = DiaryNotice(whatWentWrong: error.whatWentWrong, whatToDoNext: error.whatToDoNext)
        } catch {
            notice = DiaryFeedback.couldNotSaveDiary
        }
    }
}
