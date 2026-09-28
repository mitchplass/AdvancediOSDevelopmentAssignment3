import SwiftUI

struct DiaryHomeScreen: View {
    @Environment(\.siteDiaryRepository) private var repository

    var body: some View {
        DiaryHomeHost(repository: repository)
    }
}

private struct DiaryHomeHost: View {
    @State private var model: DiaryHomeViewModel

    init(repository: any SiteDiaryRepository) {
        _model = State(initialValue: DiaryHomeViewModel(repository: repository))
    }

    var body: some View {
        DiaryHomeView(model: model)
    }
}

struct DiaryHomeView: View {
    @Bindable var model: DiaryHomeViewModel
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            diaryForm
        }
    }

    private var diaryForm: some View {
        Form {
            if let notice = model.notice {
                DiaryNoticeView(notice: notice)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            }

            Section {
                TextField("Site name", text: $model.siteName)
                    .textInputAutocapitalization(.words)
                DatePicker("Date", selection: $model.diaryDate, displayedComponents: .date)
                DatePicker("Knock-off", selection: $model.knockOffTime, displayedComponents: .hourAndMinute)
                Button("Open the day") {
                    if let day = model.openTheDay() {
                        path.append(day)
                    }
                }
            } header: {
                Text("Open a day")
            }

            Section("Days") {
                if model.days.isEmpty {
                    Text("No days recorded yet.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(model.days) { workday in
                        NavigationLink(value: workday.calendarDate) {
                            DiaryDayRow(workday: workday)
                        }
                    }
                }
            }
        }
        .navigationTitle("Site diary")
        .navigationDestination(for: Date.self) { day in
            DayOnSiteScreen(day: day)
        }
        .onAppear {
            model.load()
        }
    }
}

private struct DiaryDayRow: View {
    let workday: Workday

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(workday.siteName)
                Spacer()
                Text(workday.status == .open ? "Open" : "Closed")
                    .foregroundStyle(.secondary)
            }
            Text(workday.calendarDate.formatted(date: .complete, time: .omitted))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}
