import Foundation

enum DiaryAppGroup {
    static let identifier = "group.com.iosdev.SiteDiary"

    static func storeURL() -> URL {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: identifier
        ) else {
            fatalError("App Group \(identifier) is unavailable. The diary has to live there so the widget can read it.")
        }
        return containerURL.appendingPathComponent("SiteDiary.sqlite")
    }
}
