import Foundation

enum SiteCalendar {
    static var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        return calendar
    }

    static func startOfDay(for date: Date) -> Date {
        calendar.startOfDay(for: date)
    }

    static func dayInterval(containing date: Date) -> DateInterval? {
        calendar.dateInterval(of: .day, for: date)
    }
}
