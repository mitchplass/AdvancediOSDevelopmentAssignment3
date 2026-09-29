import SwiftUI

struct DefectListScreen: View {
    @Environment(\.siteDiaryRepository) private var repository
    var day: Date

    var body: some View {
        DefectListHost(repository: repository, day: day)
    }
}

private struct DefectListHost: View {
    @State private var model: DefectListViewModel

    init(repository: any SiteDiaryRepository, day: Date) {
        _model = State(initialValue: DefectListViewModel(repository: repository, day: day))
    }

    var body: some View {
        DefectListView(model: model)
    }
}

struct DefectListView: View {
    @Bindable var model: DefectListViewModel

    var body: some View {
        List {
            if let notice = model.notice {
                DiaryNoticeView(notice: notice)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            }

            if model.knockOffDefects.isEmpty && model.otherDefects.isEmpty {
                ContentUnavailableView(
                    "No defects yet",
                    systemImage: "exclamationmark.triangle",
                    description: Text("Record one when you find something that cannot wait until tomorrow.")
                )
                .listRowBackground(Color.clear)
            }

            if !model.knockOffDefects.isEmpty {
                Section("Before knock-off") {
                    ForEach(model.knockOffDefects) { defect in
                        DefectRow(defect: defect)
                    }
                }
            }

            if !model.otherDefects.isEmpty {
                Section("Can wait") {
                    ForEach(model.otherDefects) { defect in
                        DefectRow(defect: defect)
                    }
                }
            }
        }
        .navigationTitle("Defects")
        .toolbar {
            if model.canRecord {
                ToolbarItem(placement: .primaryAction) {
                    NavigationLink {
                        RecordDefectScreen(day: model.day)
                    } label: {
                        Label("Record a defect", systemImage: DiarySymbols.record)
                    }
                }
            }
        }
        .onAppear {
            model.load()
        }
    }
}

private struct DefectRow: View {
    let defect: Defect

    var body: some View {
        NavigationLink {
            DefectDetailScreen(defectID: defect.id)
        } label: {
            HStack(alignment: .top, spacing: 10) {
                DiarySymbol(name: defect.status == .cleared ? DiarySymbols.cleared : DiarySymbols.defect)
                    .foregroundStyle(defect.mustClearBeforeKnockOff && defect.status == .open ? .orange : .secondary)
                VStack(alignment: .leading, spacing: 4) {
                    Text(defect.title)
                    Label(defect.location, systemImage: DiarySymbols.location)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    if defect.mustClearBeforeKnockOff && defect.status == .open {
                        Text("Must be cleared before knock-off")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    } else if defect.status == .cleared {
                        Text("Cleared")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}
