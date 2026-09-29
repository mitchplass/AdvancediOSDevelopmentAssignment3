import SwiftUI
import WidgetKit

@main
struct SiteDiaryWidgetBundle: WidgetBundle {
    var body: some Widget {
        SiteDiaryGlanceWidget()
    }
}

struct SiteDiaryGlanceWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: SiteDiaryGlance.widgetKind, provider: SiteDiaryGlanceProvider()) { entry in
            SiteDiaryGlanceView(entry: entry)
        }
        .configurationDisplayName("Site diary")
        .description("Knock-off defects and who is still on site for the day you have open.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct SiteDiaryGlanceEntry: TimelineEntry {
    var date: Date
    var glance: SiteDiaryGlance?
}

struct SiteDiaryGlanceProvider: TimelineProvider {
    func placeholder(in context: Context) -> SiteDiaryGlanceEntry {
        SiteDiaryGlanceEntry(date: Date(), glance: SiteDiaryGlanceStore.read() ?? Self.gallerySample)
    }

    func getSnapshot(in context: Context, completion: @escaping (SiteDiaryGlanceEntry) -> Void) {
        let glance = SiteDiaryGlanceStore.read() ?? (context.isPreview ? Self.gallerySample : nil)
        completion(SiteDiaryGlanceEntry(date: Date(), glance: glance))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SiteDiaryGlanceEntry>) -> Void) {
        let entry = SiteDiaryGlanceEntry(date: Date(), glance: SiteDiaryGlanceStore.read())
        let refresh = Date().addingTimeInterval(15 * 60)
        completion(Timeline(entries: [entry], policy: .after(refresh)))
    }

    private static let gallerySample = SiteDiaryGlance(
        siteName: "Riverside tower",
        calendarDate: Date(),
        knockOffDefectCount: 2,
        firstKnockOffLocation: "Level 2, grid C4",
        crewOnSiteCount: 2,
        dayIsOpen: true,
        hasDiary: true,
        knockOffLines: [
            KnockOffGlanceLine(title: "Exposed starter bars", location: "Level 2, grid C4"),
            KnockOffGlanceLine(title: "Missing handrail", location: "Level 3 stair")
        ],
        crewLines: [
            CrewGlanceLine(name: "Alex", trade: "Electrical"),
            CrewGlanceLine(name: "Sam", trade: "Formwork")
        ]
    )
}

struct SiteDiaryGlanceView: View {
    @Environment(\.widgetFamily) private var family
    var entry: SiteDiaryGlanceEntry

    var body: some View {
        Group {
            if let glance = entry.glance, glance.hasDiary {
                diary(glance)
            } else {
                empty
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }

    private var empty: some View {
        VStack(alignment: .leading, spacing: 6) {
            DiarySymbol(name: DiarySymbols.site)
                .font(.title3)
                .foregroundStyle(.secondary)
            Text("Site diary")
                .font(.headline)
            Text("No day is open.")
                .font(.subheadline)
            Text("Open a day before you walk the site.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    @ViewBuilder
    private func diary(_ glance: SiteDiaryGlance) -> some View {
        if family == .systemLarge {
            largeDiary(glance)
        } else {
            compactDiary(glance)
        }
    }

    private func compactDiary(_ glance: SiteDiaryGlance) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            header(glance)
            fact(
                knockOffLine(glance),
                symbol: glance.knockOffDefectCount == 0 ? DiarySymbols.cleared : DiarySymbols.defect,
                tint: glance.knockOffDefectCount == 0 ? .secondary : .orange
            )
            .font(family == .systemSmall ? .subheadline : .body)
            if family == .systemMedium, let location = glance.firstKnockOffLocation, glance.knockOffDefectCount > 0 {
                fact(location, symbol: DiarySymbols.location, tint: .secondary)
                    .font(.subheadline)
            }
            Spacer(minLength: 0)
            fact(
                crewLine(glance),
                symbol: glance.crewOnSiteCount == 0 ? DiarySymbols.crewOff : DiarySymbols.crew,
                tint: .secondary
            )
            .font(.caption)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func largeDiary(_ glance: SiteDiaryGlance) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            header(glance)
            fact(
                knockOffLine(glance),
                symbol: glance.knockOffDefectCount == 0 ? DiarySymbols.cleared : DiarySymbols.defect,
                tint: glance.knockOffDefectCount == 0 ? .secondary : .orange
            )
            .font(.headline)
            Text(knockOffDetail(glance))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(4)
            fact(
                crewLine(glance),
                symbol: glance.crewOnSiteCount == 0 ? DiarySymbols.crewOff : DiarySymbols.crew,
                tint: .secondary
            )
            .font(.headline)
            Text(crewDetail(glance))
                .font(.subheadline)
                .lineLimit(4)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func knockOffDetail(_ glance: SiteDiaryGlance) -> String {
        if !glance.knockOffLines.isEmpty {
            let shown = glance.knockOffLines.prefix(3).map { "\($0.title) — \($0.location)" }
            let extra = glance.knockOffDefectCount - shown.count
            return extra > 0 ? (shown + ["\(extra) more"]).joined(separator: "\n") : shown.joined(separator: "\n")
        }
        if let location = glance.firstKnockOffLocation, glance.knockOffDefectCount > 0 {
            return location
        }
        return " "
    }

    private func crewDetail(_ glance: SiteDiaryGlance) -> String {
        guard !glance.crewLines.isEmpty else { return " " }
        let shown = glance.crewLines.prefix(3).map { "\($0.name), \($0.trade)" }
        let extra = glance.crewOnSiteCount - shown.count
        return extra > 0 ? (shown + ["\(extra) more"]).joined(separator: "\n") : shown.joined(separator: "\n")
    }

    private func header(_ glance: SiteDiaryGlance) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .firstTextBaseline) {
                DiarySymbol(name: DiarySymbols.site)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(glance.siteName)
                    .font(.headline)
                    .lineLimit(1)
                Spacer(minLength: 8)
                if family == .systemSmall {
                    Image(systemName: glance.dayIsOpen ? DiarySymbols.openDay : DiarySymbols.closedDay)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .accessibilityLabel(glance.dayIsOpen ? "Open" : "Closed")
                } else {
                    Label(
                        glance.dayIsOpen ? "Open" : "Closed",
                        systemImage: glance.dayIsOpen ? DiarySymbols.openDay : DiarySymbols.closedDay
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .labelStyle(.titleAndIcon)
                }
            }
            Text(glance.calendarDate.formatted(date: family == .systemLarge ? .complete : .abbreviated, time: .omitted))
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }

    private func fact(_ title: String, symbol: String, tint: Color) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            DiarySymbol(name: symbol)
                .font(.caption)
                .foregroundStyle(tint)
            Text(title)
                .lineLimit(2)
        }
    }

    private func knockOffLine(_ glance: SiteDiaryGlance) -> String {
        if family == .systemSmall {
            switch glance.knockOffDefectCount {
            case 0:
                return "Clear to knock off"
            case 1:
                return "1 to clear"
            default:
                return "\(glance.knockOffDefectCount) to clear"
            }
        }
        switch glance.knockOffDefectCount {
        case 0:
            return "Nothing to clear before knock-off"
        case 1:
            return "1 knock-off defect"
        default:
            return "\(glance.knockOffDefectCount) knock-off defects"
        }
    }

    private func crewLine(_ glance: SiteDiaryGlance) -> String {
        switch glance.crewOnSiteCount {
        case 0:
            return "Crew signed off"
        case 1:
            return "1 on site"
        default:
            return "\(glance.crewOnSiteCount) on site"
        }
    }
}
