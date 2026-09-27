import Foundation

enum SignCrewError: Error, Equatable {
    case workerNameMissing
    case tradeMissing
    case diaryNotOpen
    case crewNotFound

    var whatWentWrong: String {
        switch self {
        case .workerNameMissing:
            return "This sign-on has no name."
        case .tradeMissing:
            return "This sign-on has no trade."
        case .diaryNotOpen:
            return "There is no diary open for this day."
        case .crewNotFound:
            return "That worker is not on today's crew list."
        }
    }

    var whatToDoNext: String {
        switch self {
        case .workerNameMissing:
            return "Enter the worker's name so you know who is on site."
        case .tradeMissing:
            return "Enter the trade, such as electrical or formwork."
        case .diaryNotOpen:
            return "Open the day before you sign the crew on."
        case .crewNotFound:
            return "Sign them on before you sign them off."
        }
    }
}

struct SignCrew {
    var repository: any SiteDiaryRepository

    func signOn(
        workerName: String,
        trade: String,
        on day: Date = Date(),
        at signedOnAt: Date = Date()
    ) throws -> CrewPresence {
        let trimmedName = workerName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedTrade = trade.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            throw SignCrewError.workerNameMissing
        }
        guard !trimmedTrade.isEmpty else {
            throw SignCrewError.tradeMissing
        }
        guard let workday = try repository.workday(on: day) else {
            throw SignCrewError.diaryNotOpen
        }

        let presence = CrewPresence(
            id: UUID(),
            workdayID: workday.id,
            workerName: trimmedName,
            trade: trimmedTrade,
            signedOnAt: signedOnAt,
            signedOffAt: nil
        )
        try repository.save(presence)
        return presence
    }

    func signOff(presenceID: UUID, at signedOffAt: Date = Date()) throws -> CrewPresence {
        guard var presence = try repository.crewPresence(id: presenceID) else {
            throw SignCrewError.crewNotFound
        }
        presence.signedOffAt = signedOffAt
        try repository.save(presence)
        return presence
    }
}
