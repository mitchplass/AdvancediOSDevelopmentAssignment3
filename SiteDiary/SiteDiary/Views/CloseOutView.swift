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
    @Environment(\.dismiss) private var dismiss

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
            } else if model.canClose {
                Text("Nothing must be cleared before knock-off, and the crew is signed off.")
                Button("Close out the day") {
                    model.closeOut()
                }
            } else {
                if !model.remaining.isEmpty {
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
                }
                if !model.crewStillOnSite.isEmpty {
                    Section("Still signed on") {
                        ForEach(model.crewStillOnSite) { person in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(person.workerName)
                                Text(person.trade)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                Section {
                    Button("Close out the day") {
                        model.closeOut()
                    }
                    .disabled(true)
                } footer: {
                    Text(closeOutBlocker)
                }
            }
        }
        .navigationTitle("Close out the day")
        .onAppear {
            model.load()
        }
        .onChange(of: model.didClose) { _, didClose in
            if didClose {
                dismiss()
            }
        }
    }

    private var closeOutBlocker: String {
        switch (model.remaining.isEmpty, model.crewStillOnSite.isEmpty) {
        case (false, false):
            return "Clear the knock-off defects and sign the crew off before you close the day."
        case (false, true):
            return "Clear the knock-off defects before you close the day."
        case (true, false):
            return "Sign the crew off before you close the day."
        case (true, true):
            return "Open the day before you close it out."
        }
    }
}
