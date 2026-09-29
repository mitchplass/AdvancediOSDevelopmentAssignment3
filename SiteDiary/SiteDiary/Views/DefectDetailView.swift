import SwiftUI

struct DefectDetailScreen: View {
    @Environment(\.siteDiaryRepository) private var repository
    let defectID: UUID

    var body: some View {
        DefectDetailHost(repository: repository, defectID: defectID)
    }
}

private struct DefectDetailHost: View {
    @State private var model: DefectDetailViewModel

    init(repository: any SiteDiaryRepository, defectID: UUID) {
        _model = State(initialValue: DefectDetailViewModel(repository: repository, defectID: defectID))
    }

    var body: some View {
        DefectDetailView(model: model)
    }
}

struct DefectDetailView: View {
    @Bindable var model: DefectDetailViewModel

    var body: some View {
        Form {
            if let notice = model.notice {
                DiaryNoticeView(notice: notice)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            }

            if let defect = model.defect {
                LabeledContent {
                    Text(defect.title)
                } label: {
                    Label("What is wrong", systemImage: DiarySymbols.defect)
                }
                LabeledContent {
                    Text(defect.location)
                } label: {
                    Label("Location", systemImage: DiarySymbols.location)
                }
                if !defect.detail.isEmpty {
                    LabeledContent("Detail", value: defect.detail)
                }
                LabeledContent {
                    Text(defect.mustClearBeforeKnockOff ? "Must be cleared" : "Can wait")
                } label: {
                    Label("Before knock-off", systemImage: DiarySymbols.knockOff)
                }
                LabeledContent {
                    Text(defect.status == .open ? "Open" : "Cleared")
                } label: {
                    Label(
                        "Status",
                        systemImage: defect.status == .cleared ? DiarySymbols.cleared : DiarySymbols.openDay
                    )
                }
                if let clearedAt = defect.clearedAt {
                    LabeledContent("Cleared", value: clearedAt.formatted(date: .omitted, time: .shortened))
                }
                if defect.status == .open {
                    Button {
                        model.markCleared()
                    } label: {
                        Label("Mark cleared", systemImage: DiarySymbols.cleared)
                    }
                }
            }
        }
        .navigationTitle("Defect")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            model.load()
        }
    }
}
