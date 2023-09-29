//
//  SwiftDataExplorationApp.swift
//  SwiftDataExploration
//
//  Created by Andrew Althage on 9/29/23.
//

import SwiftData
import SwiftUI

@main
struct SwiftDataExplorationApp: App {
    @StateObject var networkMonitor = NetworkMonitor()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Post.self,
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
                .environmentObject(networkMonitor)
        }
        .modelContainer(sharedModelContainer)
    }
}
