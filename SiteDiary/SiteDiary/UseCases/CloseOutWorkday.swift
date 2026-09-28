import Foundation

enum CloseOutWorkdayError: Error, Equatable {
    case diaryNotOpen
    case dayAlreadyClosed
    case knockOffDefectsStillOpen(count: Int, locations: [String])
    case crewStillOnSite(count: Int, names: [String])

    var whatWentWrong: String {
        switch self {
        case .diaryNotOpen:
            return "There is no diary open for this day."
        case .dayAlreadyClosed:
            return "This day's diary is already closed."
        case .knockOffDefectsStillOpen(let count, _):
            let defects = count == 1 ? "defect is" : "defects are"
            return "\(count) knock-off \(defects) still open."
        case .crewStillOnSite(let count, _):
            let people = count == 1 ? "person is" : "people are"
            return "\(count) \(people) still signed on."
        }
    }

    var whatToDoNext: String {
        switch self {
        case .diaryNotOpen:
            return "Open the day before you close it out."
        case .dayAlreadyClosed:
            return "Leave it closed. Open a diary for another date if the job continues."
        case .knockOffDefectsStillOpen(_, let locations):
            return "Clear them before you close the day. Still open: \(locations.joined(separator: "; "))."
        case .crewStillOnSite(_, let names):
            return "Sign them off before you close the day. Still on site: \(names.joined(separator: ", "))."
        }
    }
}

struct CloseOutWorkday {
    var repository: any SiteDiaryRepository

    func close(on day: Date = Date()) throws -> Workday {
        guard var workday = try repository.workday(on: day) else {
            throw CloseOutWorkdayError.diaryNotOpen
        }
        guard workday.status == .open else {
            throw CloseOutWorkdayError.dayAlreadyClosed
        }
        let stillOpen = try repository.openKnockOffDefects(on: day)
        if !stillOpen.isEmpty {
            throw CloseOutWorkdayError.knockOffDefectsStillOpen(
                count: stillOpen.count,
                locations: stillOpen.map(\.location)
            )
        }
        let stillOnSite = try repository.crew(for: workday.id).filter(\.isOnSite)
        if !stillOnSite.isEmpty {
            throw CloseOutWorkdayError.crewStillOnSite(
                count: stillOnSite.count,
                names: stillOnSite.map(\.workerName)
            )
        }

        workday.status = .closed
        try repository.save(workday)
        return workday
    }
}
