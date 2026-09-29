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
                HStack {
                    DiarySymbol(name: DiarySymbols.site)
                        .foregroundStyle(.secondary)
                    TextField("Site name", text: $model.siteName)
                        .textInputAutocapitalization(.words)
                }
                HStack {
                    DiarySymbol(name: DiarySymbols.calendar)
                        .foregroundStyle(.secondary)
                    DatePicker("Date", selection: $model.diaryDate, displayedComponents: .date)
                }
                HStack {
                    DiarySymbol(name: DiarySymbols.knockOff)
                        .foregroundStyle(.secondary)
                    DatePicker("Knock-off", selection: $model.knockOffTime, displayedComponents: .hourAndMinute)
                }
                Button {
                    if let day = model.openTheDay() {
                        path.append(day)
                    }
                } label: {
                    Label("Open the day", systemImage: DiarySymbols.openDay)
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
                DiarySymbol(name: DiarySymbols.site)
                    .foregroundStyle(.secondary)
                Text(workday.siteName)
                Spacer()
                Label(
                    workday.status == .open ? "Open" : "Closed",
                    systemImage: workday.status == .open ? DiarySymbols.openDay : DiarySymbols.closedDay
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
            Label(
                workday.calendarDate.formatted(date: .complete, time: .omitted),
                systemImage: DiarySymbols.calendar
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
    }
}
