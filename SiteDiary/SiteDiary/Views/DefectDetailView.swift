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
                LabeledContent("What is wrong", value: defect.title)
                LabeledContent("Location", value: defect.location)
                if !defect.detail.isEmpty {
                    LabeledContent("Detail", value: defect.detail)
                }
                LabeledContent(
                    "Before knock-off",
                    value: defect.mustClearBeforeKnockOff ? "Must be cleared" : "Can wait"
                )
                LabeledContent("Status", value: defect.status == .open ? "Open" : "Cleared")
                if let clearedAt = defect.clearedAt {
                    LabeledContent("Cleared", value: clearedAt.formatted(date: .omitted, time: .shortened))
                }
                if defect.status == .open {
                    Button("Mark cleared") {
                        model.markCleared()
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
