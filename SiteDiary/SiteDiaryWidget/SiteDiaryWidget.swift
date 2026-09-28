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
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct SiteDiaryGlanceEntry: TimelineEntry {
    var date: Date
    var glance: SiteDiaryGlance?
}

struct SiteDiaryGlanceProvider: TimelineProvider {
    func placeholder(in context: Context) -> SiteDiaryGlanceEntry {
        SiteDiaryGlanceEntry(date: Date(), glance: nil)
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
        crewOnSiteCount: 4,
        dayIsOpen: true,
        hasDiary: true
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

    private func diary(_ glance: SiteDiaryGlance) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                Text(glance.siteName)
                    .font(.headline)
                    .lineLimit(1)
                Spacer(minLength: 8)
                Text(glance.dayIsOpen ? "Open" : "Closed")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(glance.calendarDate.formatted(date: .abbreviated, time: .omitted))
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(knockOffLine(glance))
                .font(family == .systemSmall ? .subheadline : .body)
                .lineLimit(2)
            if family == .systemMedium, let location = glance.firstKnockOffLocation, glance.knockOffDefectCount > 0 {
                Text(location)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            Spacer(minLength: 0)
            Text(crewLine(glance))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
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
