import XCTest
@testable import SiteDiary

@MainActor
final class SignCrewTests: XCTestCase {
    private let today = SignCrewTests.makeDate(hour: 7, minute: 0)
    private let signedOnAt = SignCrewTests.makeDate(hour: 7, minute: 5)
    private let signedOffAt = SignCrewTests.makeDate(hour: 15, minute: 10)
    private let knockOff = SignCrewTests.makeDate(hour: 15, minute: 30)

    func testSigningAWorkerOnLeavesThemOnSite() throws {
        let repository = try openDiary()
        let useCase = SignCrew(repository: repository)

        let presence = try useCase.signOn(
            workerName: "  Alex  ",
            trade: " Electrical ",
            on: today,
            at: signedOnAt
        )

        XCTAssertEqual(presence.workerName, "Alex")
        XCTAssertEqual(presence.trade, "Electrical")
        XCTAssertEqual(presence.signedOnAt, signedOnAt)
        XCTAssertNil(presence.signedOffAt)
        XCTAssertTrue(presence.isOnSite)
        XCTAssertEqual(repository.crew.count, 1)
    }

    func testSigningAWorkerOffRecordsWhenTheyLeft() throws {
        let repository = try openDiary()
        let useCase = SignCrew(repository: repository)
        let signedOn = try useCase.signOn(workerName: "Alex", trade: "Electrical", on: today, at: signedOnAt)

        let signedOff = try useCase.signOff(presenceID: signedOn.id, at: signedOffAt)

        XCTAssertEqual(signedOff.signedOffAt, signedOffAt)
        XCTAssertFalse(signedOff.isOnSite)
    }

    func testSigningOnFailsWhenThatWorkerIsStillOnSite() throws {
        let repository = try openDiary()
        let useCase = SignCrew(repository: repository)
        _ = try useCase.signOn(workerName: "Alex", trade: "Electrical", on: today, at: signedOnAt)

        XCTAssertThrowsError(
            try useCase.signOn(workerName: "alex", trade: "electrical", on: today, at: signedOnAt)
        ) { error in
            XCTAssertEqual(
                error as? SignCrewError,
                .alreadyOnSite(name: "alex", trade: "electrical")
            )
            XCTAssertEqual(
                SignCrewError.alreadyOnSite(name: "Alex", trade: "Electrical").whatToDoNext,
                "Sign them off before signing them on again."
            )
        }
        XCTAssertEqual(repository.crew.count, 1)
    }

    func testSigningOnAgainBringsTheSamePersonBackWithoutASecondEntry() throws {
        let repository = try openDiary()
        let useCase = SignCrew(repository: repository)
        let first = try useCase.signOn(workerName: "Alex", trade: "Electrical", on: today, at: signedOnAt)
        _ = try useCase.signOff(presenceID: first.id, at: signedOffAt)

        let second = try useCase.signOn(workerName: "Alex", trade: "Electrical", on: today, at: signedOffAt)

        XCTAssertEqual(second.id, first.id)
        XCTAssertTrue(second.isOnSite)
        XCTAssertNil(second.signedOffAt)
        XCTAssertEqual(repository.crew.count, 1)
    }

    func testSigningBackOnClearsTheSignOffOnTheSameEntry() throws {
        let repository = try openDiary()
        let useCase = SignCrew(repository: repository)
        let signedOn = try useCase.signOn(workerName: "Alex", trade: "Electrical", on: today, at: signedOnAt)
        _ = try useCase.signOff(presenceID: signedOn.id, at: signedOffAt)

        let back = try useCase.signBackOn(presenceID: signedOn.id)

        XCTAssertEqual(back.id, signedOn.id)
        XCTAssertNil(back.signedOffAt)
        XCTAssertTrue(back.isOnSite)
        XCTAssertEqual(repository.crew.count, 1)
    }

    func testSigningOffFailsWhenTheWorkerIsNotOnSite() throws {
        let repository = try openDiary()
        let useCase = SignCrew(repository: repository)
        let signedOn = try useCase.signOn(workerName: "Alex", trade: "Electrical", on: today, at: signedOnAt)
        _ = try useCase.signOff(presenceID: signedOn.id, at: signedOffAt)

        XCTAssertThrowsError(try useCase.signOff(presenceID: signedOn.id, at: signedOffAt)) { error in
            XCTAssertEqual(error as? SignCrewError, .notOnSite(name: "Alex", trade: "Electrical"))
            XCTAssertEqual(
                SignCrewError.notOnSite(name: "Alex", trade: "Electrical").whatToDoNext,
                "Sign them on before you sign them off."
            )
        }
    }

    func testSigningOnFailsWhenTheDiaryIsAlreadyClosed() throws {
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
        let useCase = SignCrew(repository: repository)

        XCTAssertThrowsError(
            try useCase.signOn(workerName: "Alex", trade: "Electrical", on: today, at: signedOnAt)
        ) { error in
            XCTAssertEqual(error as? SignCrewError, .dayAlreadyClosed)
        }
        XCTAssertTrue(repository.crew.isEmpty)
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
