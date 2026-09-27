//
//  SiteDiaryApp.swift
//  SiteDiary
//
//  Created by Mitchell Plass on 27/9/2026.
//

import SwiftUI
import CoreData

@main
struct SiteDiaryApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
