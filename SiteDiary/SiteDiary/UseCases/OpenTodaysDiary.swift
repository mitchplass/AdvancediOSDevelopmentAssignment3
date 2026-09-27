import Foundation

enum OpenTodaysDiaryError: Error, Equatable {
    case siteNameMissing

    var whatWentWrong: String {
        switch self {
        case .siteNameMissing:
            return "This diary has no site name."
        }
    }

    var whatToDoNext: String {
        switch self {
        case .siteNameMissing:
            return "Enter the site name before you open the day."
        }
    }
}

struct OpenTodaysDiary {
    var repository: any SiteDiaryRepository

    func open(siteName: String, knockOffTime: Date, on day: Date = Date()) throws -> Workday {
        let trimmedName = siteName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            throw OpenTodaysDiaryError.siteNameMissing
        }

        if let existing = try repository.workday(on: day) {
            return existing
        }

        let workday = Workday(
            id: UUID(),
            siteName: trimmedName,
            calendarDate: SiteCalendar.startOfDay(for: day),
            knockOffTime: knockOffTime,
            status: .open
        )
        try repository.save(workday)
        return workday
    }
}
