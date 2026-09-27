import Foundation

enum TrackDefectError: Error, Equatable {
    case titleMissing
    case diaryNotOpen
    case defectNotFound

    var whatWentWrong: String {
        switch self {
        case .titleMissing:
            return "This defect has no title."
        case .diaryNotOpen:
            return "There is no diary open for this day."
        case .defectNotFound:
            return "That defect is not in the diary."
        }
    }

    var whatToDoNext: String {
        switch self {
        case .titleMissing:
            return "Name what is wrong so the crew knows what to fix."
        case .diaryNotOpen:
            return "Open the day before you record a defect."
        case .defectNotFound:
            return "Record it first, then mark it cleared."
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
        guard !trimmedTitle.isEmpty else {
            throw TrackDefectError.titleMissing
        }
        guard let workday = try repository.workday(on: day) else {
            throw TrackDefectError.diaryNotOpen
        }

        let defect = Defect(
            id: UUID(),
            workdayID: workday.id,
            title: trimmedTitle,
            location: location.trimmingCharacters(in: .whitespacesAndNewlines),
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
        defect.status = .cleared
        defect.clearedAt = clearedAt
        try repository.save(defect)
        return defect
    }
}
