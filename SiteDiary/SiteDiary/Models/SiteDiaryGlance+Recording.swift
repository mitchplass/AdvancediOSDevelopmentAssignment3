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
            hasDiary: true
        )
    }
}
