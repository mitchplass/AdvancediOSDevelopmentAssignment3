import Foundation
import Observation

@Observable
final class CrewOnSiteViewModel {
    var workerName = ""
    var trade = ""
    var onSite: [CrewPresence] = []
    var signedOff: [CrewPresence] = []
    var canSignOn = false
    var notice: DiaryNotice?

    private let day: Date
    private let repository: any SiteDiaryRepository

    init(repository: any SiteDiaryRepository, day: Date) {
        self.repository = repository
        self.day = day
    }

    func load() {
        do {
            guard let workday = try repository.workday(on: day) else {
                onSite = []
                signedOff = []
                canSignOn = false
                return
            }
            canSignOn = workday.status == .open
            let crew = try repository.crew(for: workday.id)
            onSite = crew.filter(\.isOnSite)
            signedOff = crew.filter { !$0.isOnSite }
        } catch {
            notice = DiaryFeedback.couldNotReadDiary
        }
    }

    func signOn() {
        notice = nil
        do {
            _ = try SignCrew(repository: repository).signOn(workerName: workerName, trade: trade, on: day)
            workerName = ""
            trade = ""
            load()
        } catch let error as SignCrewError {
            notice = DiaryNotice(whatWentWrong: error.whatWentWrong, whatToDoNext: error.whatToDoNext)
        } catch {
            notice = DiaryFeedback.couldNotSaveDiary
        }
    }

    func signOff(_ presence: CrewPresence) {
        notice = nil
        do {
            _ = try SignCrew(repository: repository).signOff(presenceID: presence.id)
            load()
        } catch let error as SignCrewError {
            notice = DiaryNotice(whatWentWrong: error.whatWentWrong, whatToDoNext: error.whatToDoNext)
        } catch {
            notice = DiaryFeedback.couldNotSaveDiary
        }
    }
}
