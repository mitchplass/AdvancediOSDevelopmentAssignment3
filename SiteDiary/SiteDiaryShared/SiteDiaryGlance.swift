import Foundation

struct KnockOffGlanceLine: Codable, Equatable {
    var title: String
    var location: String
}

struct CrewGlanceLine: Codable, Equatable {
    var name: String
    var trade: String
}

struct SiteDiaryGlance: Codable, Equatable {
    static let widgetKind = "SiteDiaryGlance"

    var siteName: String
    var calendarDate: Date
    var knockOffDefectCount: Int
    var firstKnockOffLocation: String?
    var crewOnSiteCount: Int
    var dayIsOpen: Bool
    var hasDiary: Bool
    var knockOffLines: [KnockOffGlanceLine]
    var crewLines: [CrewGlanceLine]

    init(
        siteName: String,
        calendarDate: Date,
        knockOffDefectCount: Int,
        firstKnockOffLocation: String?,
        crewOnSiteCount: Int,
        dayIsOpen: Bool,
        hasDiary: Bool,
        knockOffLines: [KnockOffGlanceLine] = [],
        crewLines: [CrewGlanceLine] = []
    ) {
        self.siteName = siteName
        self.calendarDate = calendarDate
        self.knockOffDefectCount = knockOffDefectCount
        self.firstKnockOffLocation = firstKnockOffLocation
        self.crewOnSiteCount = crewOnSiteCount
        self.dayIsOpen = dayIsOpen
        self.hasDiary = hasDiary
        self.knockOffLines = knockOffLines
        self.crewLines = crewLines
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        siteName = try container.decode(String.self, forKey: .siteName)
        calendarDate = try container.decode(Date.self, forKey: .calendarDate)
        knockOffDefectCount = try container.decode(Int.self, forKey: .knockOffDefectCount)
        firstKnockOffLocation = try container.decodeIfPresent(String.self, forKey: .firstKnockOffLocation)
        crewOnSiteCount = try container.decode(Int.self, forKey: .crewOnSiteCount)
        dayIsOpen = try container.decode(Bool.self, forKey: .dayIsOpen)
        hasDiary = try container.decode(Bool.self, forKey: .hasDiary)
        knockOffLines = try container.decodeIfPresent([KnockOffGlanceLine].self, forKey: .knockOffLines) ?? []
        crewLines = try container.decodeIfPresent([CrewGlanceLine].self, forKey: .crewLines) ?? []
    }
}

enum SiteDiaryGlanceStore {
    static func read() -> SiteDiaryGlance? {
        guard let url = DiaryAppGroup.glanceURL() else { return nil }
        return read(from: url)
    }

    static func write(_ glance: SiteDiaryGlance) throws {
        guard let url = DiaryAppGroup.glanceURL() else { return }
        try write(glance, to: url)
    }

    static func read(from url: URL) -> SiteDiaryGlance? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? decoder.decode(SiteDiaryGlance.self, from: data)
    }

    static func write(_ glance: SiteDiaryGlance, to url: URL) throws {
        let data = try encoder.encode(glance)
        try data.write(to: url, options: .atomic)
    }

    private static var encoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }

    private static var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
