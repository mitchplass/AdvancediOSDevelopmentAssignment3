import SwiftUI

struct TodayOnSiteScreen: View {
    @Environment(\.siteDiaryRepository) private var repository
    @State private var model: TodayOnSiteViewModel?

    var body: some View {
        Group {
            if let model {
                TodayOnSiteView(model: model)
            }
        }
        .task {
            if model == nil {
                model = TodayOnSiteViewModel(repository: repository)
            }
        }
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
