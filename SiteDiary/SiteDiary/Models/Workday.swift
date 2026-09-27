import Foundation

enum WorkdayStatus: String, Equatable {
    case open
    case closed
}

struct Workday: Identifiable, Equatable {
    var id: UUID
    var siteName: String
    var calendarDate: Date
    var knockOffTime: Date
    var status: WorkdayStatus
}
