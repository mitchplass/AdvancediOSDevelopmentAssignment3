import SwiftUI

struct RecordDefectScreen: View {
    @Environment(\.siteDiaryRepository) private var repository
    var day: Date

    var body: some View {
        RecordDefectHost(repository: repository, day: day)
    }
}

private struct RecordDefectHost: View {
    @State private var model: RecordDefectViewModel

    init(repository: any SiteDiaryRepository, day: Date) {
        _model = State(initialValue: RecordDefectViewModel(repository: repository, day: day))
    }

    var body: some View {
        RecordDefectView(model: model)
    }
}

struct RecordDefectView: View {
    @Bindable var model: RecordDefectViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            if let notice = model.notice {
                DiaryNoticeView(notice: notice)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            }

            TextField("What is wrong", text: $model.title)
            TextField("Location, such as level and grid", text: $model.location)
            TextField("Detail", text: $model.detail, axis: .vertical)
                .lineLimit(3...6)
            Toggle("Must be cleared before knock-off", isOn: $model.mustClearBeforeKnockOff)
            Button("Record defect") {
                if model.record() {
                    dismiss()
                }
            }
        }
        .navigationTitle("Record a defect")
        .navigationBarTitleDisplayMode(.inline)
    }
}
