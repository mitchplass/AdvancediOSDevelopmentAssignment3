import Foundation
@testable import SiteDiary

@MainActor
final class MockSiteDiaryRepository: SiteDiaryRepository {
    private(set) var workdays: [Workday] = []
    private(set) var defects: [Defect] = []
    private(set) var crew: [CrewPresence] = []

    func workday(on day: Date) throws -> Workday? {
        let start = SiteCalendar.startOfDay(for: day)
        let matches = workdays.filter { SiteCalendar.startOfDay(for: $0.calendarDate) == start }
        return matches.first { $0.status == .open } ?? matches.first
    }

    func save(_ workday: Workday) throws {
        if let index = workdays.firstIndex(where: { $0.id == workday.id }) {
            workdays[index] = workday
        } else {
            workdays.append(workday)
        }
    }

    func defect(id: UUID) throws -> Defect? {
        defects.first { $0.id == id }
    }

    func defects(for workdayID: UUID) throws -> [Defect] {
        defects.filter { $0.workdayID == workdayID }
    }

    func openKnockOffDefects(on day: Date) throws -> [Defect] {
        guard let workday = try workday(on: day), workday.status == .open else { return [] }
        return defects.filter {
            $0.workdayID == workday.id && $0.mustClearBeforeKnockOff && $0.status == .open
        }
    }

    func save(_ defect: Defect) throws {
        guard workdays.contains(where: { $0.id == defect.workdayID }) else {
            throw SiteDiaryStoreError.workdayNotFound
        }
        if let index = defects.firstIndex(where: { $0.id == defect.id }) {
            defects[index] = defect
        } else {
            defects.append(defect)
        }
    }

    func crewPresence(id: UUID) throws -> CrewPresence? {
        crew.first { $0.id == id }
    }

    func crew(for workdayID: UUID) throws -> [CrewPresence] {
        crew.filter { $0.workdayID == workdayID }
    }

    func save(_ presence: CrewPresence) throws {
        guard workdays.contains(where: { $0.id == presence.workdayID }) else {
            throw SiteDiaryStoreError.workdayNotFound
        }
        if let index = crew.firstIndex(where: { $0.id == presence.id }) {
            crew[index] = presence
        } else {
            crew.append(presence)
        }
    }
}
