import Foundation
import UserNotifications

enum KnockOffWarning {
    static let category = "KNOCK_OFF_WARNING"
    static let requestIdentifier = "knock-off-warning"
    static let leadTime: TimeInterval = 30 * 60
    static let nearTermDelay: TimeInterval = 60

    struct Plan: Equatable {
        var firesAt: Date
        var isNearTerm: Bool
    }

    static func plan(knockOffTime: Date, now: Date) -> Plan {
        let intended = knockOffTime.addingTimeInterval(-leadTime)
        if intended > now {
            return Plan(firesAt: intended, isNearTerm: false)
        }
        return Plan(firesAt: now.addingTimeInterval(nearTermDelay), isNearTerm: true)
    }
}

enum KnockOffWarningScheduler {
    private static var generation = 0

    static func schedule(for workday: Workday?, openKnockOffCount: Int, now: Date = Date()) {
        generation += 1
        let token = generation
        guard let workday, workday.status == .open, openKnockOffCount > 0 else {
            return
        }

        let siteName = workday.siteName
        let plan = KnockOffWarning.plan(knockOffTime: workday.knockOffTime, now: now)
        let center = UNUserNotificationCenter.current()
        center.setNotificationCategories([
            UNNotificationCategory(
                identifier: KnockOffWarning.category,
                actions: [],
                intentIdentifiers: [],
                options: []
            )
        ])
        center.getNotificationSettings { settings in
            let status = settings.authorizationStatus
            Task { @MainActor in
                guard token == generation else { return }
                await deliver(
                    status: status,
                    siteName: siteName,
                    openKnockOffCount: openKnockOffCount,
                    plan: plan,
                    token: token,
                    center: center
                )
            }
        }
    }

    private static func deliver(
        status: UNAuthorizationStatus,
        siteName: String,
        openKnockOffCount: Int,
        plan: KnockOffWarning.Plan,
        token: Int,
        center: UNUserNotificationCenter
    ) async {
        switch status {
        case .notDetermined:
            let granted = (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
            guard granted, token == generation else { return }
            try? await center.add(request(siteName: siteName, openKnockOffCount: openKnockOffCount, plan: plan))
        case .authorized, .provisional, .ephemeral:
            guard token == generation else { return }
            try? await center.add(request(siteName: siteName, openKnockOffCount: openKnockOffCount, plan: plan))
        case .denied:
            break
        @unknown default:
            break
        }
    }

    private static func request(siteName: String, openKnockOffCount: Int, plan: KnockOffWarning.Plan) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = siteName
        let defects = openKnockOffCount == 1
            ? "1 knock-off defect is still open"
            : "\(openKnockOffCount) knock-off defects are still open"
        content.body = plan.isNearTerm
            ? "Knock-off time has passed. \(defects)."
            : "Knock-off is in 30 minutes. \(defects)."
        content.categoryIdentifier = KnockOffWarning.category
        content.sound = .default
        let trigger: UNNotificationTrigger
        if plan.isNearTerm {
            trigger = UNTimeIntervalNotificationTrigger(timeInterval: KnockOffWarning.nearTermDelay, repeats: false)
        } else {
            let components = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: plan.firesAt
            )
            trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        }
        return UNNotificationRequest(
            identifier: KnockOffWarning.requestIdentifier,
            content: content,
            trigger: trigger
        )
    }
}
