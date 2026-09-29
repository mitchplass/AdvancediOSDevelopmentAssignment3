import SwiftUI

enum DiarySymbols {
    static let site = "building.2"
    static let calendar = "calendar"
    static let knockOff = "clock"
    static let defect = "exclamationmark.triangle"
    static let cleared = "checkmark.circle"
    static let crew = "person.2"
    static let crewOff = "person.2.slash"
    static let location = "mappin.and.ellipse"
    static let openDay = "lock.open"
    static let closedDay = "lock"
    static let closeOut = "checkmark.seal"
    static let signOn = "person.badge.plus"
    static let signOff = "person.badge.minus"
    static let notice = "exclamationmark.circle"
    static let record = "plus"
}

struct DiarySymbol: View {
    var name: String

    var body: some View {
        Image(systemName: name)
            .accessibilityHidden(true)
    }
}
