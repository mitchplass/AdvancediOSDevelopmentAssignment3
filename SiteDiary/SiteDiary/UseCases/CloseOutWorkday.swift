import Foundation

enum CloseOutWorkdayError: Error, Equatable {
    case diaryNotOpen
    case dayAlreadyClosed

    var whatWentWrong: String {
        switch self {
        case .diaryNotOpen:
            return "There is no diary open for this day."
        case .dayAlreadyClosed:
            return "This day's diary is already closed."
        }
    }

    var whatToDoNext: String {
        switch self {
        case .diaryNotOpen:
            return "Open the day before you close it out."
        case .dayAlreadyClosed:
            return "Leave it closed. Open a diary for another date if the job continues."
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

        workday.status = .closed
        try repository.save(workday)
        return workday
    }
}
