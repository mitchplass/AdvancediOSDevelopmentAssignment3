import Foundation

extension SiteDiaryGlance {
    static func recording(
        workday: Workday?,
        knockOffDefects: [Defect],
        crew: [CrewPresence]
    ) -> SiteDiaryGlance {
        guard let workday else {
            return SiteDiaryGlance(
                siteName: "",
                calendarDate: SiteCalendar.startOfDay(for: Date()),
                knockOffDefectCount: 0,
                firstKnockOffLocation: nil,
                crewOnSiteCount: 0,
                dayIsOpen: false,
                hasDiary: false
            )
        }

        return SiteDiaryGlance(
            siteName: workday.siteName,
            calendarDate: workday.calendarDate,
            knockOffDefectCount: knockOffDefects.count,
            firstKnockOffLocation: knockOffDefects.first?.location,
            crewOnSiteCount: crew.filter(\.isOnSite).count,
            dayIsOpen: workday.status == .open,
            hasDiary: true,
            knockOffLines: knockOffDefects.prefix(6).map {
                KnockOffGlanceLine(title: $0.title, location: $0.location)
            },
            crewLines: crew.filter(\.isOnSite).prefix(8).map {
                CrewGlanceLine(name: $0.workerName, trade: $0.trade)
            }
        )
    }

    static func workingWorkday(among days: [Workday], preferring preferredDay: Date?, openOnly: Bool) -> Workday? {
        if let preferredDay {
            let start = SiteCalendar.startOfDay(for: preferredDay)
            if let match = days.first(where: { SiteCalendar.startOfDay(for: $0.calendarDate) == start }) {
                if !openOnly || match.status == .open {
                    return match
                }
            }
        }
        return days.filter { $0.status == .open }.max { $0.calendarDate < $1.calendarDate }
    }
}
