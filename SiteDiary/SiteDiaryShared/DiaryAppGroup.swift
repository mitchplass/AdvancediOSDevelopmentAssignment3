import Foundation

enum DiaryAppGroup {
    static let identifier = "group.com.iosdev.SiteDiary"

    static func containerURL() -> URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier)
    }

    static func storeURL() -> URL {
        guard let containerURL = containerURL() else {
            fatalError("App Group \(identifier) is unavailable. The diary has to live there so the widget can read it.")
        }
        return containerURL.appendingPathComponent("SiteDiary.sqlite")
    }

    static func glanceURL() -> URL? {
        containerURL()?.appendingPathComponent("SiteDiaryGlance.json")
    }
}
