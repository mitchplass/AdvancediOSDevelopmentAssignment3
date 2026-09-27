import XCTest
@testable import SiteDiary

@MainActor
final class OpenTodaysDiaryTests: XCTestCase {
    private let today = Date(timeIntervalSince1970: 1_758_960_000)
    private let knockOff = Date(timeIntervalSince1970: 1_759_009_200)

    func testOpeningTodayCreatesAnOpenDiary() throws {
        let repository = MockSiteDiaryRepository()
        let useCase = OpenTodaysDiary(repository: repository)

        let workday = try useCase.open(siteName: "  Riverside tower  ", knockOffTime: knockOff, on: today)

        XCTAssertEqual(workday.siteName, "Riverside tower")
        XCTAssertEqual(workday.status, .open)
        XCTAssertEqual(workday.calendarDate, SiteCalendar.startOfDay(for: today))
        XCTAssertEqual(workday.knockOffTime, knockOff)
        XCTAssertEqual(repository.workdays.count, 1)
    }

    func testOpeningTodayAgainReturnsTheDiaryAlreadyStarted() throws {
        let repository = MockSiteDiaryRepository()
        let useCase = OpenTodaysDiary(repository: repository)
        let first = try useCase.open(siteName: "Riverside tower", knockOffTime: knockOff, on: today)

        let second = try useCase.open(siteName: "Riverside tower", knockOffTime: knockOff, on: today)

        XCTAssertEqual(second.id, first.id)
        XCTAssertEqual(repository.workdays.count, 1)
    }

    func testOpeningTodayFailsWhenTheDiaryIsAlreadyClosed() throws {
        let repository = MockSiteDiaryRepository()
        let closed = Workday(
            id: UUID(),
            siteName: "Riverside tower",
            calendarDate: SiteCalendar.startOfDay(for: today),
            knockOffTime: knockOff,
            status: .closed
        )
        try repository.save(closed)
        let useCase = OpenTodaysDiary(repository: repository)

        XCTAssertThrowsError(try useCase.open(siteName: "Riverside tower", knockOffTime: knockOff, on: today)) { error in
            XCTAssertEqual(error as? OpenTodaysDiaryError, .dayAlreadyClosed)
            XCTAssertEqual(
                OpenTodaysDiaryError.dayAlreadyClosed.whatToDoNext,
                "Today is finished. Open a diary for another date instead of starting a second one."
            )
        }
        XCTAssertEqual(repository.workdays.count, 1)
    }

    func testOpeningTodayFailsWhenTheSiteNameIsBlank() throws {
        let repository = MockSiteDiaryRepository()
        let useCase = OpenTodaysDiary(repository: repository)

        XCTAssertThrowsError(try useCase.open(siteName: "   ", knockOffTime: knockOff, on: today)) { error in
            XCTAssertEqual(error as? OpenTodaysDiaryError, .siteNameMissing)
        }
        XCTAssertTrue(repository.workdays.isEmpty)
    }
}
