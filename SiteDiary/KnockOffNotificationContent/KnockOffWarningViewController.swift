import SwiftUI
import UIKit
import UserNotifications
import UserNotificationsUI

final class KnockOffWarningViewController: UIViewController, UNNotificationContentExtension {
    private let host = UIHostingController(rootView: KnockOffWarningView(glance: nil))

    override func viewDidLoad() {
        super.viewDidLoad()
        addChild(host)
        host.view.translatesAutoresizingMaskIntoConstraints = false
        host.view.backgroundColor = .clear
        view.addSubview(host.view)
        NSLayoutConstraint.activate([
            host.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            host.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            host.view.topAnchor.constraint(equalTo: view.topAnchor),
            host.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        host.didMove(toParent: self)
    }

    func didReceive(_ notification: UNNotification) {
        host.rootView = KnockOffWarningView(glance: SiteDiaryGlanceStore.read())
        let width = max(view.bounds.width, 320)
        let height = host.sizeThatFits(in: CGSize(width: width, height: .greatestFiniteMagnitude)).height
        preferredContentSize = CGSize(width: width, height: max(height, 120))
    }
}

struct KnockOffWarningView: View {
    var glance: SiteDiaryGlance?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let glance, glance.hasDiary {
                header(glance)
                situation(glance)
            } else {
                Text("Open the site diary to see what is still open.")
                    .font(.subheadline)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func header(_ glance: SiteDiaryGlance) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                DiarySymbol(name: DiarySymbols.site)
                    .foregroundStyle(.secondary)
                Text(glance.siteName)
                    .font(.headline)
                    .lineLimit(1)
            }
            Text(glance.calendarDate.formatted(date: .complete, time: .omitted))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private func situation(_ glance: SiteDiaryGlance) -> some View {
        if glance.knockOffDefectCount == 0, glance.crewOnSiteCount == 0 {
            Label("Nothing is left open, and the crew has signed off.", systemImage: DiarySymbols.cleared)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        } else {
            if glance.knockOffDefectCount > 0 {
                defects(glance)
            }
            if glance.crewOnSiteCount > 0 {
                crew(glance)
            }
        }
    }

    private func defects(_ glance: SiteDiaryGlance) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(glance.knockOffDefectCount == 1 ? "1 knock-off defect is still open" : "\(glance.knockOffDefectCount) knock-off defects are still open")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            ForEach(Array(glance.knockOffLines.enumerated()), id: \.offset) { _, line in
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    DiarySymbol(name: DiarySymbols.defect)
                        .foregroundStyle(.orange)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(line.title)
                            .font(.subheadline)
                        HStack(spacing: 4) {
                            DiarySymbol(name: DiarySymbols.location)
                            Text(line.location)
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private func crew(_ glance: SiteDiaryGlance) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(glance.crewOnSiteCount == 1 ? "1 person is still signed on" : "\(glance.crewOnSiteCount) people are still signed on")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            ForEach(Array(glance.crewLines.enumerated()), id: \.offset) { _, line in
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    DiarySymbol(name: DiarySymbols.crew)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(line.name)
                            .font(.subheadline)
                        Text(line.trade)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}
