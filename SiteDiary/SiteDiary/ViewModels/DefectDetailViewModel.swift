import Foundation
import Observation

@Observable
final class DefectDetailViewModel {
    var defect: Defect?
    var notice: DiaryNotice?

    private let repository: any SiteDiaryRepository
    private let defectID: UUID

    init(repository: any SiteDiaryRepository, defectID: UUID) {
        self.repository = repository
        self.defectID = defectID
    }

    func load() {
        do {
            defect = try repository.defect(id: defectID)
            if defect == nil {
                notice = DiaryNotice(
                    whatWentWrong: TrackDefectError.defectNotFound.whatWentWrong,
                    whatToDoNext: TrackDefectError.defectNotFound.whatToDoNext
                )
            }
        } catch {
            notice = DiaryFeedback.couldNotReadDiary
        }
    }

    func markCleared() {
        notice = nil
        do {
            defect = try TrackDefect(repository: repository).clear(defectID: defectID)
        } catch let error as TrackDefectError {
            notice = DiaryNotice(whatWentWrong: error.whatWentWrong, whatToDoNext: error.whatToDoNext)
        } catch {
            notice = DiaryFeedback.couldNotSaveDiary
        }
    }
}
