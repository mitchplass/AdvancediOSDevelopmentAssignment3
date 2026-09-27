import Foundation

enum TrackDefectError: Error, Equatable {
    case titleMissing
    case locationMissing
    case diaryNotOpen
    case dayAlreadyClosed
    case defectNotFound
    case defectAlreadyCleared

    var whatWentWrong: String {
        switch self {
        case .titleMissing:
            return "This defect has no title."
        case .locationMissing:
            return "This defect has no location."
        case .diaryNotOpen:
            return "There is no diary open for this day."
        case .dayAlreadyClosed:
            return "This day's diary is already closed."
        case .defectNotFound:
            return "That defect is not in the diary."
        case .defectAlreadyCleared:
            return "This defect is already cleared."
        }
    }

    var whatToDoNext: String {
        switch self {
        case .titleMissing:
            return "Name what is wrong so the crew knows what to fix."
        case .locationMissing:
            return "Add the location, such as level and grid, so the crew can find it."
        case .diaryNotOpen:
            return "Open the day before you record a defect."
        case .dayAlreadyClosed:
            return "Record the defect on a day that is still open."
        case .defectNotFound:
            return "Record it first, then mark it cleared."
        case .defectAlreadyCleared:
            return "Leave it cleared. Record a new defect if the problem has come back."
        }
    }
}

struct TrackDefect {
    var repository: any SiteDiaryRepository

    func record(
        title: String,
        location: String,
        detail: String = "",
        mustClearBeforeKnockOff: Bool,
        on day: Date = Date(),
        recordedAt: Date = Date()
    ) throws -> Defect {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedLocation = location.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else {
            throw TrackDefectError.titleMissing
        }
        guard !trimmedLocation.isEmpty else {
            throw TrackDefectError.locationMissing
        }
        guard let workday = try repository.workday(on: day) else {
            throw TrackDefectError.diaryNotOpen
        }
        guard workday.status == .open else {
            throw TrackDefectError.dayAlreadyClosed
        }

        let defect = Defect(
            id: UUID(),
            workdayID: workday.id,
            title: trimmedTitle,
            location: trimmedLocation,
            detail: detail.trimmingCharacters(in: .whitespacesAndNewlines),
            mustClearBeforeKnockOff: mustClearBeforeKnockOff,
            status: .open,
            recordedAt: recordedAt,
            clearedAt: nil
        )
        try repository.save(defect)
        return defect
    }

    func clear(defectID: UUID, at clearedAt: Date = Date()) throws -> Defect {
        guard var defect = try repository.defect(id: defectID) else {
            throw TrackDefectError.defectNotFound
        }
        guard defect.status == .open else {
            throw TrackDefectError.defectAlreadyCleared
        }
        defect.status = .cleared
        defect.clearedAt = clearedAt
        try repository.save(defect)
        return defect
    }
}
