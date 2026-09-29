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
                    LabeledContent {
                        Text(workday.siteName)
                    } label: {
                        Label("Site", systemImage: DiarySymbols.site)
                    }
                    LabeledContent {
                        Text(workday.calendarDate.formatted(date: .complete, time: .omitted))
                    } label: {
                        Label("Date", systemImage: DiarySymbols.calendar)
                    }
                    LabeledContent {
                        Text(workday.knockOffTime.formatted(date: .omitted, time: .shortened))
                    } label: {
                        Label("Knock-off", systemImage: DiarySymbols.knockOff)
                    }
                    LabeledContent {
                        Text(workday.status == .open ? "Open" : "Closed")
                    } label: {
                        Label(
                            "Status",
                            systemImage: workday.status == .open ? DiarySymbols.openDay : DiarySymbols.closedDay
                        )
                    }
                }

                Section {
                    NavigationLink {
                        DefectListScreen(day: model.day)
                    } label: {
                        LabeledContent {
                            Text("\(model.knockOffDefectCount)")
                        } label: {
                            Label("Knock-off defects", systemImage: DiarySymbols.defect)
                        }
                    }
                    NavigationLink {
                        CrewOnSiteScreen(day: model.day)
                    } label: {
                        LabeledContent {
                            Text("\(model.crewOnSiteCount)")
                        } label: {
                            Label("Crew on site", systemImage: DiarySymbols.crew)
                        }
                    }
                    if workday.status == .open {
                        NavigationLink {
                            CloseOutScreen(day: model.day)
                        } label: {
                            Label("Close out the day", systemImage: DiarySymbols.closeOut)
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
