import SwiftUI

struct CloseOutScreen: View {
    @Environment(\.siteDiaryRepository) private var repository

    var body: some View {
        CloseOutHost(repository: repository)
    }
}

private struct CloseOutHost: View {
    @State private var model: CloseOutViewModel

    init(repository: any SiteDiaryRepository) {
        _model = State(initialValue: CloseOutViewModel(repository: repository))
    }

    var body: some View {
        CloseOutView(model: model)
    }
}

struct CloseOutView: View {
    @Bindable var model: CloseOutViewModel

    var body: some View {
        List {
            if let notice = model.notice {
                DiaryNoticeView(notice: notice)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            }

            if model.isClosed {
                Text("The day is closed.")
            } else if !model.hasOpenDiary {
                Text("Open the day before you close it out.")
                    .foregroundStyle(.secondary)
            } else if model.remaining.isEmpty {
                Text("Nothing must be cleared before knock-off.")
                Button("Close out the day") {
                    model.closeOut()
                }
            } else {
                Section("Still open before knock-off") {
                    ForEach(model.remaining) { defect in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(defect.title)
                            Text(defect.location)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                Section {
                    Button("Close out the day") {
                        model.closeOut()
                    }
                    .disabled(!model.canClose)
                } footer: {
                    Text("Clear the knock-off defects before you close the day.")
                }
            }
        }
        .navigationTitle("Close out the day")
        .onAppear {
            model.load()
        }
    }
}
