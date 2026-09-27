import Foundation

struct CrewPresence: Identifiable, Equatable {
    var id: UUID
    var workdayID: UUID
    var workerName: String
    var trade: String
    var signedOnAt: Date
    var signedOffAt: Date?

    var isOnSite: Bool {
        signedOffAt == nil
    }
}
