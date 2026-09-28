import CoreData
import Foundation

struct CoreDataSiteDiaryRepository: SiteDiaryRepository {
    private let context: NSManagedObjectContext

    init(persistence: PersistenceController = .shared) {
        context = persistence.container.viewContext
        try? publishTodaysGlance()
    }

    func workday(on day: Date) throws -> Workday? {
        let matches = try fetchWorkdays(on: day)
        if let openDay = matches.first(where: { $0.status == .open }) {
            return openDay
        }
        return matches.first
    }

    func allWorkdays() throws -> [Workday] {
        let request = WorkdayRecord.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "calendarDate", ascending: false)]
        return try context.fetch(request).map { try map($0) }
    }

    func save(_ workday: Workday) throws {
        let record = try workdayRecord(id: workday.id) ?? WorkdayRecord(context: context)
        record.id = workday.id
        record.siteName = workday.siteName
        record.calendarDate = SiteCalendar.startOfDay(for: workday.calendarDate)
        record.knockOffTime = workday.knockOffTime
        record.status = workday.status.rawValue
        try saveContext()
    }

    func defect(id: UUID) throws -> Defect? {
        guard let record = try defectRecord(id: id) else { return nil }
        return try map(record)
    }

    func defects(for workdayID: UUID) throws -> [Defect] {
        let request = DefectRecord.fetchRequest()
        request.predicate = NSPredicate(format: "workday.id == %@", workdayID as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(key: "recordedAt", ascending: true)]
        return try context.fetch(request).map { try map($0) }
    }

    func openKnockOffDefects(on day: Date) throws -> [Defect] {
        guard let interval = SiteCalendar.dayInterval(containing: day) else { return [] }
        let request = DefectRecord.fetchRequest()
        request.predicate = NSPredicate(
            format: "mustClearBeforeKnockOff == YES AND status == %@ AND workday.status == %@ AND workday.calendarDate >= %@ AND workday.calendarDate < %@",
            DefectStatus.open.rawValue,
            WorkdayStatus.open.rawValue,
            interval.start as NSDate,
            interval.end as NSDate
        )
        request.sortDescriptors = [NSSortDescriptor(key: "recordedAt", ascending: true)]
        return try context.fetch(request).map { try map($0) }
    }

    func save(_ defect: Defect) throws {
        guard let workday = try workdayRecord(id: defect.workdayID) else {
            throw SiteDiaryStoreError.workdayNotFound
        }
        let record = try defectRecord(id: defect.id) ?? DefectRecord(context: context)
        record.id = defect.id
        record.title = defect.title
        record.location = defect.location
        record.detail = defect.detail
        record.mustClearBeforeKnockOff = defect.mustClearBeforeKnockOff
        record.status = defect.status.rawValue
        record.recordedAt = defect.recordedAt
        record.clearedAt = defect.clearedAt
        record.workday = workday
        try saveContext()
    }

    func crewPresence(id: UUID) throws -> CrewPresence? {
        guard let record = try crewRecord(id: id) else { return nil }
        return try map(record)
    }

    func crew(for workdayID: UUID) throws -> [CrewPresence] {
        let request = CrewPresenceRecord.fetchRequest()
        request.predicate = NSPredicate(format: "workday.id == %@", workdayID as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(key: "signedOnAt", ascending: true)]
        return try context.fetch(request).map { try map($0) }
    }

    func save(_ presence: CrewPresence) throws {
        guard let workday = try workdayRecord(id: presence.workdayID) else {
            throw SiteDiaryStoreError.workdayNotFound
        }
        let record = try crewRecord(id: presence.id) ?? CrewPresenceRecord(context: context)
        record.id = presence.id
        record.workerName = presence.workerName
        record.trade = presence.trade
        record.signedOnAt = presence.signedOnAt
        record.signedOffAt = presence.signedOffAt
        record.workday = workday
        try saveContext()
    }

    private func fetchWorkdays(on day: Date) throws -> [Workday] {
        guard let interval = SiteCalendar.dayInterval(containing: day) else { return [] }
        let request = WorkdayRecord.fetchRequest()
        request.predicate = NSPredicate(
            format: "calendarDate >= %@ AND calendarDate < %@",
            interval.start as NSDate,
            interval.end as NSDate
        )
        request.sortDescriptors = [NSSortDescriptor(key: "calendarDate", ascending: true)]
        return try context.fetch(request).map { try map($0) }
    }

    private func workdayRecord(id: UUID) throws -> WorkdayRecord? {
        let request = WorkdayRecord.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return try context.fetch(request).first
    }

    private func defectRecord(id: UUID) throws -> DefectRecord? {
        let request = DefectRecord.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return try context.fetch(request).first
    }

    private func crewRecord(id: UUID) throws -> CrewPresenceRecord? {
        let request = CrewPresenceRecord.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return try context.fetch(request).first
    }

    private func map(_ record: WorkdayRecord) throws -> Workday {
        guard let id = record.id,
              let siteName = record.siteName,
              let calendarDate = record.calendarDate,
              let knockOffTime = record.knockOffTime,
              let statusRaw = record.status,
              let status = WorkdayStatus(rawValue: statusRaw) else {
            throw SiteDiaryStoreError.unreadableRecord
        }
        return Workday(
            id: id,
            siteName: siteName,
            calendarDate: calendarDate,
            knockOffTime: knockOffTime,
            status: status
        )
    }

    private func map(_ record: DefectRecord) throws -> Defect {
        guard let id = record.id,
              let title = record.title,
              let location = record.location,
              let statusRaw = record.status,
              let status = DefectStatus(rawValue: statusRaw),
              let recordedAt = record.recordedAt,
              let workdayID = record.workday?.id else {
            throw SiteDiaryStoreError.unreadableRecord
        }
        return Defect(
            id: id,
            workdayID: workdayID,
            title: title,
            location: location,
            detail: record.detail ?? "",
            mustClearBeforeKnockOff: record.mustClearBeforeKnockOff,
            status: status,
            recordedAt: recordedAt,
            clearedAt: record.clearedAt
        )
    }

    private func map(_ record: CrewPresenceRecord) throws -> CrewPresence {
        guard let id = record.id,
              let workerName = record.workerName,
              let trade = record.trade,
              let signedOnAt = record.signedOnAt,
              let workdayID = record.workday?.id else {
            throw SiteDiaryStoreError.unreadableRecord
        }
        return CrewPresence(
            id: id,
            workdayID: workdayID,
            workerName: workerName,
            trade: trade,
            signedOnAt: signedOnAt,
            signedOffAt: record.signedOffAt
        )
    }

    private func saveContext() throws {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                throw SiteDiaryStoreError.saveFailed
            }
        }
        try publishTodaysGlance()
    }

    private func publishTodaysGlance() throws {
        let today = Date()
        let workday = try workday(on: today)
        let knockOffDefects: [Defect]
        let crewOnSite: [CrewPresence]
        if let workday {
            knockOffDefects = try openKnockOffDefects(on: today)
            crewOnSite = try crew(for: workday.id)
        } else {
            knockOffDefects = []
            crewOnSite = []
        }
        try SiteDiaryGlanceStore.write(
            SiteDiaryGlance.recording(workday: workday, knockOffDefects: knockOffDefects, crew: crewOnSite)
        )
    }
}
