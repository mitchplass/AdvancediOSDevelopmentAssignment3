import Foundation

enum DefectStatus: String, Equatable {
    case open
    case cleared
}

struct Defect: Identifiable, Equatable {
    var id: UUID
    var workdayID: UUID
    var title: String
    var location: String
    var detail: String
    var mustClearBeforeKnockOff: Bool
    var status: DefectStatus
    var recordedAt: Date
    var clearedAt: Date?
}
