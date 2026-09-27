import SwiftUI

struct TodayOnSiteScreen: View {
    @Environment(\.siteDiaryRepository) private var repository

    var body: some View {
        TodayOnSiteHost(repository: repository)
    }
}

private struct TodayOnSiteHost: View {
    @State private var model: TodayOnSiteViewModel

    init(repository: any SiteDiaryRepository) {
        _model = State(initialValue: TodayOnSiteViewModel(repository: repository))
    }

    var body: some View {
        TodayOnSiteView(model: model)
    }
}

struct TodayOnSiteView: View {
    @Bindable var model: TodayOnSiteViewModel

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
                    LabeledContent("Knock-off defects", value: "\(model.knockOffDefectCount)")
                    LabeledContent("Crew on site", value: "\(model.crewOnSiteCount)")
                    NavigationLink("Defects") {
                        DefectListScreen()
                    }
                    NavigationLink("Crew on site") {
                        CrewOnSiteScreen()
                    }
                    if workday.status == .open {
                        NavigationLink("Close out the day") {
                            CloseOutScreen()
                        }
                    }
                }
            } else {
                Section {
                    Text("Open the day before you walk the site.")
                        .foregroundStyle(.secondary)
                    TextField("Site name", text: $model.siteName)
                        .textInputAutocapitalization(.words)
                    DatePicker("Knock-off", selection: $model.knockOffTime, displayedComponents: .hourAndMinute)
                    Button("Open the day") {
                        model.openTheDay()
                    }
                } header: {
                    Text("No diary for today yet")
                }
            }
        }
        .navigationTitle("Today on site")
        .onAppear {
            model.load()
        }
    }
}
