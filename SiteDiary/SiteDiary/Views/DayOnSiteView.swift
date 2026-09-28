import SwiftUI

struct DayOnSiteScreen: View {
    @Environment(\.siteDiaryRepository) private var repository
    var day: Date

    var body: some View {
        DayOnSiteHost(repository: repository, day: day)
    }
}

private struct DayOnSiteHost: View {
    @State private var model: DayOnSiteViewModel

    init(repository: any SiteDiaryRepository, day: Date) {
        _model = State(initialValue: DayOnSiteViewModel(repository: repository, day: day))
    }

    var body: some View {
        DayOnSiteView(model: model)
    }
}

struct DayOnSiteView: View {
    @Bindable var model: DayOnSiteViewModel

    var body: some View {
        Form {
            if let notice = model.notice {
                DiaryNoticeView(notice: notice)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            }

            if let workday = model.workday {
                Section {
                    LabeledContent("Site", value: workday.siteName)
                    LabeledContent("Date", value: workday.calendarDate.formatted(date: .complete, time: .omitted))
                    LabeledContent("Knock-off", value: workday.knockOffTime.formatted(date: .omitted, time: .shortened))
                    LabeledContent("Status", value: workday.status == .open ? "Open" : "Closed")
                }

                Section {
                    NavigationLink {
                        DefectListScreen(day: model.day)
                    } label: {
                        LabeledContent("Knock-off defects", value: "\(model.knockOffDefectCount)")
                    }
                    NavigationLink {
                        CrewOnSiteScreen(day: model.day)
                    } label: {
                        LabeledContent("Crew on site", value: "\(model.crewOnSiteCount)")
                    }
                    if workday.status == .open {
                        NavigationLink("Close out the day") {
                            CloseOutScreen(day: model.day)
                        }
                    }
                }
            } else {
                Text("This day is not in the diary.")
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle(model.day.formatted(date: .abbreviated, time: .omitted))
        .onAppear {
            model.load()
        }
    }
}
