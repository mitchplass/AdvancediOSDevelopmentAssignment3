import Foundation

struct SiteDiaryGlance: Codable, Equatable {
    static let widgetKind = "SiteDiaryGlance"

    var siteName: String
    var calendarDate: Date
    var knockOffDefectCount: Int
    var firstKnockOffLocation: String?
    var crewOnSiteCount: Int
    var dayIsOpen: Bool
    var hasDiary: Bool
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
