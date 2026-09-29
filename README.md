# Site Diary

Site Diary is an iPhone app for a construction site supervisor. It keeps the daily site diary: which day is open, who is still signed on, and which defects must be cleared before knock-off. The record stays on the phone. A home screen widget and a knock-off warning show the unfinished part of the day without making the supervisor unlock the diary.

## Domain

The stakeholder is the site supervisor on a building job. During the day they open the diary for that date, sign the crew on and off, and record defects while they walk the site. A defect that must be cleared before knock-off stays open until it is marked cleared. The day cannot be closed while one of those defects is still open, or while someone is still signed on.

The diary is one supervisor, one phone, and often no signal. It is not a shared office system.

## Architecture

The app is SwiftUI, organised as views, view models, use cases, and a repository.

Views and view models never touch Core Data. Each use case talks only to the `SiteDiaryRepository` protocol and enforces one business rule. Failures are typed errors written for the supervisor (`whatWentWrong`, `whatToDoNext`), not for a log.

| Use case | Rule |
| --- | --- |
| `OpenTodaysDiary` | One diary for a calendar date. A closed day cannot be opened again. |
| `TrackDefect` | A defect needs a title and a location, and the day must still be open. Only an open defect can be cleared. |
| `SignCrew` | The same worker and trade cannot be signed on twice while they are still on site. Signing back on reuses that crew entry. |
| `CloseOutWorkday` | Close-out waits until every knock-off defect is cleared and the crew has signed off. |

`CoreDataSiteDiaryRepository` is the only type that uses the Core Data stack. After a save it writes `SiteDiaryGlance.json` into the App Group and asks WidgetKit to reload. It also schedules the knock-off warning from that same moment. The widget and the notification content extension read the glance file. They do not open the database.

## Extensions

**WidgetKit** (`SiteDiaryWidget`). The supervisor looks at the home screen between walks and needs the open working day: the site, the date, whether the day is still open, the knock-off defects still open, and who is still signed on. Small, medium, and large sizes read the same glance. The app calls `WidgetCenter` after every diary change.

**Notification content extension** (`KnockOffNotificationContent`), category `KNOCK_OFF_WARNING`. When knock-off time passes, a local notification says which of these is true: nothing is left open and the crew has signed off, a knock-off defect is still open, someone is still signed on, or both. Holding the notification replaces the default body with the site and those lists, read from the glance so they match the diary.

## Database

Core Data, on device. The store is `SiteDiary.sqlite` in the App Group container. Three related entities: `Workday`, `Defect`, and `CrewPresence`. A defect and a crew presence each belong to one workday. The repository fetches open defects that must be cleared before knock-off on an open workday, and that result feeds close-out, the glance, and the warning.

CloudKit is the wrong default here. The diary has to save immediately when the phone has no reception. Sharing it with an office would be a different product.

## App Group

`group.com.iosdev.SiteDiary`

The app, the widget, and the notification content extension all use this group. The database and `SiteDiaryGlance.json` live in the group container. Bundle id: `com.iosdev.SiteDiary`.

## Setup

1. Open `SiteDiary/SiteDiary.xcodeproj`.
2. Select the **SiteDiary** scheme and an iPhone simulator or device on iOS 26.2.
3. The signing team is `4V28M9347U`. The App Group entitlement is already on the app and both extensions.
4. Run the app. Allow notifications when the system asks.
5. On the home screen, add the **Site diary** widget. It supports small, medium, and large.
6. To see the knock-off warning, open a day, then set the clock to that day's knock-off time or just after it and open the app again. Hold the banner to see the custom view.

Unit tests are the **SiteDiary** scheme, test target `SiteDiaryTests`. They use `MockSiteDiaryRepository`, not the Core Data store.

## Attribution

No third-party packages. The system frameworks are SwiftUI, Core Data, WidgetKit, UserNotifications, and UserNotificationsUI, used as described in Apple's documentation.

The written assessment is `docs/RequiredDocument.pdf`.
