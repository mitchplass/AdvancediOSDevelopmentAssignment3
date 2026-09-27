import XCTest
@testable import SiteDiary

@MainActor
final class TrackDefectTests: XCTestCase {
    private let today = TrackDefectTests.makeDate(hour: 7, minute: 0)
    private let recordedAt = TrackDefectTests.makeDate(hour: 9, minute: 15)
    private let clearedAt = TrackDefectTests.makeDate(hour: 15, minute: 0)
    private let knockOff = TrackDefectTests.makeDate(hour: 15, minute: 30)

    func testRecordingAKnockOffDefectKeepsItOpen() throws {
        let repository = try openDiary()
        let useCase = TrackDefect(repository: repository)

        let defect = try useCase.record(
            title: "  Exposed starter bars  ",
            location: " Level 2, grid C4 ",
            detail: "Caps missing on the east edge",
            mustClearBeforeKnockOff: true,
            on: today,
            recordedAt: recordedAt
        )

        XCTAssertEqual(defect.title, "Exposed starter bars")
        XCTAssertEqual(defect.location, "Level 2, grid C4")
        XCTAssertEqual(defect.status, .open)
        XCTAssertTrue(defect.mustClearBeforeKnockOff)
        XCTAssertNil(defect.clearedAt)
        XCTAssertEqual(defect.recordedAt, recordedAt)
        XCTAssertEqual(repository.defects.count, 1)
    }

    func testClearingAnOpenDefectMarksItCleared() throws {
        let repository = try openDiary()
        let useCase = TrackDefect(repository: repository)
        let recorded = try useCase.record(
            title: "Exposed starter bars",
            location: "Level 2, grid C4",
            mustClearBeforeKnockOff: true,
            on: today,
            recordedAt: recordedAt
        )

        let cleared = try useCase.clear(defectID: recorded.id, at: clearedAt)

        XCTAssertEqual(cleared.status, .cleared)
        XCTAssertEqual(cleared.clearedAt, clearedAt)
        XCTAssertEqual(try repository.defect(id: recorded.id)?.status, .cleared)
    }

    func testRecordingFailsWhenTheLocationIsBlank() throws {
        let repository = try openDiary()
        let useCase = TrackDefect(repository: repository)

        XCTAssertThrowsError(
            try useCase.record(
                title: "Exposed starter bars",
                location: "   ",
                mustClearBeforeKnockOff: true,
                on: today,
                recordedAt: recordedAt
            )
        ) { error in
            XCTAssertEqual(error as? TrackDefectError, .locationMissing)
            XCTAssertEqual(
                TrackDefectError.locationMissing.whatToDoNext,
                "Add the location, such as level and grid, so the crew can find it."
            )
        }
        XCTAssertTrue(repository.defects.isEmpty)
    }

    func testRecordingFailsWhenTheDiaryIsAlreadyClosed() throws {
        let repository = MockSiteDiaryRepository()
        try repository.save(
            Workday(
                id: UUID(),
                siteName: "Riverside tower",
                calendarDate: SiteCalendar.startOfDay(for: today),
                knockOffTime: knockOff,
                status: .closed
            )
        )
        let useCase = TrackDefect(repository: repository)

        XCTAssertThrowsError(
            try useCase.record(
                title: "Exposed starter bars",
                location: "Level 2, grid C4",
                mustClearBeforeKnockOff: true,
                on: today,
                recordedAt: recordedAt
            )
        ) { error in
            XCTAssertEqual(error as? TrackDefectError, .dayAlreadyClosed)
        }
        XCTAssertTrue(repository.defects.isEmpty)
    }

    func testClearingFailsWhenTheDefectIsAlreadyCleared() throws {
        let repository = try openDiary()
        let useCase = TrackDefect(repository: repository)
        let recorded = try useCase.record(
            title: "Exposed starter bars",
            location: "Level 2, grid C4",
            mustClearBeforeKnockOff: true,
            on: today,
            recordedAt: recordedAt
        )
        _ = try useCase.clear(defectID: recorded.id, at: clearedAt)

        XCTAssertThrowsError(try useCase.clear(defectID: recorded.id, at: clearedAt)) { error in
            XCTAssertEqual(error as? TrackDefectError, .defectAlreadyCleared)
            XCTAssertEqual(
                TrackDefectError.defectAlreadyCleared.whatToDoNext,
                "Leave it cleared. Record a new defect if the problem has come back."
            )
        }
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
