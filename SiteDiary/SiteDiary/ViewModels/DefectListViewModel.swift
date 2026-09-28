import Foundation
import Observation

@Observable
final class DefectListViewModel {
    var knockOffDefects: [Defect] = []
    var otherDefects: [Defect] = []
    var canRecord = false
    var notice: DiaryNotice?

    let day: Date
    private let repository: any SiteDiaryRepository

    init(repository: any SiteDiaryRepository, day: Date) {
        self.repository = repository
        self.day = day
    }

    func load() {
        do {
            guard let workday = try repository.workday(on: day) else {
                knockOffDefects = []
                otherDefects = []
                canRecord = false
                return
            }
            canRecord = workday.status == .open
            let defects = try repository.defects(for: workday.id)
            knockOffDefects = defects.filter { $0.mustClearBeforeKnockOff && $0.status == .open }
            otherDefects = defects.filter { !knockOffDefects.map(\.id).contains($0.id) }
        } catch {
            notice = DiaryFeedback.couldNotReadDiary
        }
    }
}
