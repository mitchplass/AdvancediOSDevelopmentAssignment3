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
                defects(glance)
            } else {
                Text("Open the site diary to see what still has to be cleared.")
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
    private func defects(_ glance: SiteDiaryGlance) -> some View {
        if glance.knockOffLines.isEmpty {
            Label("Nothing left to clear before knock-off", systemImage: DiarySymbols.cleared)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        } else {
            Text("Still to clear before knock-off")
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
            if glance.knockOffDefectCount > glance.knockOffLines.count {
                let remaining = glance.knockOffDefectCount - glance.knockOffLines.count
                Text(remaining == 1 ? "1 more in the diary" : "\(remaining) more in the diary")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
