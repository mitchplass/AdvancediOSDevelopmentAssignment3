import SwiftUI

struct CrewOnSiteScreen: View {
    @Environment(\.siteDiaryRepository) private var repository
    @State private var model: CrewOnSiteViewModel?

    var body: some View {
        Group {
            if let model {
                CrewOnSiteView(model: model)
            }
        }
        .task {
            if model == nil {
                model = CrewOnSiteViewModel(repository: repository)
            }
        }
    }
}

struct CrewOnSiteView: View {
    @Bindable var model: CrewOnSiteViewModel

    var body: some View {
        List {
            if let notice = model.notice {
                DiaryNoticeView(notice: notice)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            }

            if model.onSite.isEmpty && model.signedOff.isEmpty {
                ContentUnavailableView(
                    "Nobody is signed on",
                    systemImage: "person.2",
                    description: Text("Sign the crew on so you know who is on site.")
                )
                .listRowBackground(Color.clear)
            }

            if !model.onSite.isEmpty {
                Section("On site") {
                    ForEach(model.onSite) { person in
                        CrewRow(person: person, canSignOff: model.canSignOn) {
                            model.signOff(person)
                        }
                    }
                }
            }

            if !model.signedOff.isEmpty {
                Section("Signed off") {
                    ForEach(model.signedOff) { person in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(person.workerName)
                            Text(person.trade)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            if model.canSignOn {
                Section("Sign on") {
                    TextField("Name", text: $model.workerName)
                        .textInputAutocapitalization(.words)
                    TextField("Trade", text: $model.trade)
                        .textInputAutocapitalization(.words)
                    Button("Sign on") {
                        model.signOn()
                    }
                }
            }
        }
        .navigationTitle("Crew on site")
        .onAppear {
            model.load()
        }
    }
}

private struct CrewRow: View {
    let person: CrewPresence
    let canSignOff: Bool
    let signOff: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(person.workerName)
                Text(person.trade)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if canSignOff {
                Button("Sign off", action: signOff)
            }
        }
    }
}
