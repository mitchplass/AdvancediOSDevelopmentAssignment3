import Foundation

enum SiteDiaryStoreError: Error, Equatable {
    case workdayNotFound
    case unreadableRecord
    case saveFailed
}

protocol SiteDiaryRepository {
    func workday(on day: Date) throws -> Workday?
    func save(_ workday: Workday) throws

    func defect(id: UUID) throws -> Defect?
    func defects(for workdayID: UUID) throws -> [Defect]
    func openKnockOffDefects(on day: Date) throws -> [Defect]
    func save(_ defect: Defect) throws

    func crewPresence(id: UUID) throws -> CrewPresence?
    func crew(for workdayID: UUID) throws -> [CrewPresence]
    func save(_ presence: CrewPresence) throws
}
