import Foundation
import UserNotifications

enum KnockOffWarning {
    static let category = "KNOCK_OFF_WARNING"
    static let requestIdentifier = "knock-off-warning"
    static let nearTermDelay: TimeInterval = 60
    static let knockOffTimeKey = "knockOffTime"

    struct Plan: Equatable {
        var firesAt: Date
        var isNearTerm: Bool
    }

    static func plan(knockOffTime: Date, now: Date) -> Plan {
        if knockOffTime > now {
            return Plan(firesAt: knockOffTime, isNearTerm: false)
        }
        return Plan(firesAt: now.addingTimeInterval(nearTermDelay), isNearTerm: true)
    }

    static func body(openKnockOffCount: Int, crewOnSiteCount: Int) -> String {
        switch (openKnockOffCount > 0, crewOnSiteCount > 0) {
        case (false, false):
            return "Knock-off has passed. Nothing is left open, and the crew has signed off."
        case (true, false):
            if openKnockOffCount == 1 {
                return "Knock-off has passed. 1 knock-off defect is still open."
            }
            return "Knock-off has passed. \(openKnockOffCount) knock-off defects are still open."
        case (false, true):
            if crewOnSiteCount == 1 {
                return "Knock-off has passed. 1 person is still signed on."
            }
            return "Knock-off has passed. \(crewOnSiteCount) people are still signed on."
        case (true, true):
            let defects = openKnockOffCount == 1
                ? "1 knock-off defect is still open"
                : "\(openKnockOffCount) knock-off defects are still open"
            let crew = crewOnSiteCount == 1
                ? "1 person is still signed on"
                : "\(crewOnSiteCount) people are still signed on"
            return "Knock-off has passed. \(defects), and \(crew)."
        }
    }
}

enum KnockOffWarningScheduler {
    private static var generation = 0

    static func schedule(
        for workday: Workday?,
        openKnockOffCount: Int,
        crewOnSiteCount: Int,
        now: Date = Date()
    ) {
        generation += 1
        let token = generation
        let center = UNUserNotificationCenter.current()
        guard let workday else {
            center.removePendingNotificationRequests(withIdentifiers: [KnockOffWarning.requestIdentifier])
            return
        }

        let siteName = workday.siteName
        let knockOffTime = workday.knockOffTime
        let plan = KnockOffWarning.plan(knockOffTime: knockOffTime, now: now)
        let body = KnockOffWarning.body(
            openKnockOffCount: openKnockOffCount,
            crewOnSiteCount: crewOnSiteCount
        )
        center.setNotificationCategories([
            UNNotificationCategory(
                identifier: KnockOffWarning.category,
                actions: [],
                intentIdentifiers: [],
                options: []
            )
        ])

        if plan.isNearTerm {
            center.getDeliveredNotifications { delivered in
                let alreadySent = delivered.contains { notification in
                    Self.matches(notification, knockOffTime: knockOffTime)
                }
                Task { @MainActor in
                    guard token == generation, !alreadySent else { return }
                    await deliver(
                        siteName: siteName,
                        body: body,
                        knockOffTime: knockOffTime,
                        plan: plan,
                        token: token,
                        center: center
                    )
                }
            }
        } else {
            Task { @MainActor in
                guard token == generation else { return }
                await deliver(
                    siteName: siteName,
                    body: body,
                    knockOffTime: knockOffTime,
                    plan: plan,
                    token: token,
                    center: center
                )
            }
        }
    }

    private static func matches(_ notification: UNNotification, knockOffTime: Date) -> Bool {
        guard notification.request.identifier == KnockOffWarning.requestIdentifier else { return false }
        let stored = notification.request.content.userInfo[KnockOffWarning.knockOffTimeKey]
        let timestamp = (stored as? NSNumber)?.doubleValue ?? stored as? Double
        guard let timestamp else { return false }
        return abs(timestamp - knockOffTime.timeIntervalSince1970) < 1
    }

    private static func deliver(
        siteName: String,
        body: String,
        knockOffTime: Date,
        plan: KnockOffWarning.Plan,
        token: Int,
        center: UNUserNotificationCenter
    ) async {
        let settings = await center.notificationSettings()
        guard token == generation else { return }
        switch settings.authorizationStatus {
        case .notDetermined:
            let granted = (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
            guard granted, token == generation else { return }
            try? await center.add(request(siteName: siteName, body: body, knockOffTime: knockOffTime, plan: plan))
        case .authorized, .provisional, .ephemeral:
            guard token == generation else { return }
            try? await center.add(request(siteName: siteName, body: body, knockOffTime: knockOffTime, plan: plan))
        case .denied:
            break
        @unknown default:
            break
        }
    }

    private static func request(
        siteName: String,
        body: String,
        knockOffTime: Date,
        plan: KnockOffWarning.Plan
    ) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = siteName
        content.body = body
        content.categoryIdentifier = KnockOffWarning.category
        content.sound = .default
        content.userInfo = [KnockOffWarning.knockOffTimeKey: knockOffTime.timeIntervalSince1970]
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
