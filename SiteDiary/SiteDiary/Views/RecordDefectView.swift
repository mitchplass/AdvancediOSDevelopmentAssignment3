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

            HStack {
                DiarySymbol(name: DiarySymbols.defect)
                    .foregroundStyle(.secondary)
                TextField("What is wrong", text: $model.title)
            }
            HStack {
                DiarySymbol(name: DiarySymbols.location)
                    .foregroundStyle(.secondary)
                TextField("Location, such as level and grid", text: $model.location)
            }
            TextField("Detail", text: $model.detail, axis: .vertical)
                .lineLimit(3...6)
            Toggle("Must be cleared before knock-off", isOn: $model.mustClearBeforeKnockOff)
            Button {
                if model.record() {
                    dismiss()
                }
            } label: {
                Label("Record defect", systemImage: DiarySymbols.record)
            }
        }
        .navigationTitle("Record a defect")
        .navigationBarTitleDisplayMode(.inline)
    }
}
