//
//  MultiCounterApp.swift
//  MultiCounter
//
//  Created by  유 주연 on 8/25/24.
//

import SwiftUI
import SwiftData

@main
struct MultiCounterApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            CountState.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
