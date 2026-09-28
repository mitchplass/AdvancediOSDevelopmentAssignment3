import SwiftUI

struct CrewOnSiteScreen: View {
    @Environment(\.siteDiaryRepository) private var repository
    var day: Date

    var body: some View {
        CrewOnSiteHost(repository: repository, day: day)
    }
}

private struct CrewOnSiteHost: View {
    @State private var model: CrewOnSiteViewModel

    init(repository: any SiteDiaryRepository, day: Date) {
        _model = State(initialValue: CrewOnSiteViewModel(repository: repository, day: day))
    }

    var body: some View {
        CrewOnSiteView(model: model)
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
                        CrewRow(name: person.workerName, trade: person.trade) {
                            if model.canSignOn {
                                Button("Sign off") {
                                    model.signOff(person)
                                }
                                .buttonStyle(.borderless)
                            }
                        }
                    }
                }
            }

            if !model.signedOff.isEmpty {
                Section("Signed off") {
                    ForEach(model.signedOff) { person in
                        CrewRow(name: person.workerName, trade: person.trade) {
                            if model.canSignBackOn(person) {
                                Button("Sign back on") {
                                    model.signBackOn(person)
                                }
                                .buttonStyle(.borderless)
                            }
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

private struct CrewRow<Action: View>: View {
    let name: String
    let trade: String
    @ViewBuilder var action: () -> Action

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                Text(trade)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            action()
        }
    }
}
