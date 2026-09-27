import SwiftUI

struct DefectListScreen: View {
    @Environment(\.siteDiaryRepository) private var repository
    @State private var model: DefectListViewModel?

    var body: some View {
        Group {
            if let model {
                DefectListView(model: model)
            }
        }
        .task {
            if model == nil {
                model = DefectListViewModel(repository: repository)
            }
        }
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
                    NavigationLink("Record a defect") {
                        RecordDefectScreen()
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
            VStack(alignment: .leading, spacing: 4) {
                Text(defect.title)
                Text(defect.location)
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
