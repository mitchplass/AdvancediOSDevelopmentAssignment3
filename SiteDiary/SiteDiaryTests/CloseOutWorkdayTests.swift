import XCTest
@testable import SiteDiary

@MainActor
final class CloseOutWorkdayTests: XCTestCase {
    private let today = CloseOutWorkdayTests.makeDate(hour: 7, minute: 0)
    private let recordedAt = CloseOutWorkdayTests.makeDate(hour: 9, minute: 15)
    private let knockOff = CloseOutWorkdayTests.makeDate(hour: 15, minute: 30)

    func testClosingTheDaySucceedsWhenKnockOffDefectsAreCleared() throws {
        let repository = try openDiary()
        let defects = TrackDefect(repository: repository)
        let recorded = try defects.record(
            title: "Exposed starter bars",
            location: "Level 2, grid C4",
            mustClearBeforeKnockOff: true,
            on: today,
            recordedAt: recordedAt
        )
        _ = try defects.clear(defectID: recorded.id, at: recordedAt)
        _ = try defects.record(
            title: "Paint touch-up",
            location: "Level 1 lobby",
            mustClearBeforeKnockOff: false,
            on: today,
            recordedAt: recordedAt
        )

        let closed = try CloseOutWorkday(repository: repository).close(on: today)

        XCTAssertEqual(closed.status, .closed)
        XCTAssertEqual(try repository.workday(on: today)?.status, .closed)
    }

    func testClosingTheDayFailsWhileAKnockOffDefectIsStillOpen() throws {
        let repository = try openDiary()
        let defects = TrackDefect(repository: repository)
        _ = try defects.record(
            title: "Exposed starter bars",
            location: "Level 2, grid C4",
            mustClearBeforeKnockOff: true,
            on: today,
            recordedAt: recordedAt
        )
        _ = try defects.record(
            title: "Missing handrail",
            location: "Level 3 stair",
            mustClearBeforeKnockOff: true,
            on: today,
            recordedAt: recordedAt
        )

        XCTAssertThrowsError(try CloseOutWorkday(repository: repository).close(on: today)) { error in
            XCTAssertEqual(
                error as? CloseOutWorkdayError,
                .knockOffDefectsStillOpen(count: 2, locations: ["Level 2, grid C4", "Level 3 stair"])
            )
            XCTAssertEqual(
                CloseOutWorkdayError.knockOffDefectsStillOpen(count: 2, locations: []).whatWentWrong,
                "2 knock-off defects are still open."
            )
            XCTAssertEqual(
                CloseOutWorkdayError.knockOffDefectsStillOpen(
                    count: 2,
                    locations: ["Level 2, grid C4", "Level 3 stair"]
                ).whatToDoNext,
                "Clear them before you close the day. Still open: Level 2, grid C4; Level 3 stair."
            )
        }
        XCTAssertEqual(try repository.workday(on: today)?.status, .open)
    }

    func testClosingTheDayFailsWhileCrewAreStillSignedOn() throws {
        let repository = try openDiary()
        _ = try SignCrew(repository: repository).signOn(
            workerName: "Alex",
            trade: "Electrical",
            on: today,
            at: recordedAt
        )

        XCTAssertThrowsError(try CloseOutWorkday(repository: repository).close(on: today)) { error in
            XCTAssertEqual(error as? CloseOutWorkdayError, .crewStillOnSite(count: 1, names: ["Alex"]))
            XCTAssertEqual(
                CloseOutWorkdayError.crewStillOnSite(count: 1, names: ["Alex"]).whatToDoNext,
                "Sign them off before you close the day. Still on site: Alex."
            )
        }
        XCTAssertEqual(try repository.workday(on: today)?.status, .open)
    }

    func testClosingTheDaySucceedsOnceTheCrewHasSignedOff() throws {
        let repository = try openDiary()
        let crew = SignCrew(repository: repository)
        let signedOn = try crew.signOn(
            workerName: "Alex",
            trade: "Electrical",
            on: today,
            at: recordedAt
        )
        _ = try crew.signOff(presenceID: signedOn.id, at: knockOff)

        let closed = try CloseOutWorkday(repository: repository).close(on: today)

        XCTAssertEqual(closed.status, .closed)
    }

    private func openDiary() throws -> MockSiteDiaryRepository {
        let repository = MockSiteDiaryRepository()
        _ = try OpenTodaysDiary(repository: repository).open(
            siteName: "Riverside tower",
            knockOffTime: knockOff,
            on: today
        )
        return repository
    }

    private static func makeDate(hour: Int, minute: Int) -> Date {
        var components = DateComponents()
        components.year = 2026
        components.month = 9
        components.day = 27
        components.hour = hour
        components.minute = minute
        return SiteCalendar.calendar.date(from: components)!
    }
}
