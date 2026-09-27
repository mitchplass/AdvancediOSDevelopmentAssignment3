import SwiftUI

struct CloseOutScreen: View {
    @Environment(\.siteDiaryRepository) private var repository
    @State private var model: CloseOutViewModel?

    var body: some View {
        Group {
            if let model {
                CloseOutView(model: model)
            }
        }
        .task {
            if model == nil {
                model = CloseOutViewModel(repository: repository)
            }
        }
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

                if model.hasOpenDiary {
                    Button("Close out the day") {
                        model.closeOut()
                    }
                }
            }
        }
        .navigationTitle("Close out the day")
        .onAppear {
            model.load()
        }
    }
}
