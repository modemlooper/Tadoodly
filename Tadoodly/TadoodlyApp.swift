//
//  TadoodlyApp.swift
//  Tadoodly
//
//  Created by modemlooper on 9/7/25.
//

import SwiftUI
import SwiftData
import WidgetKit

@main
struct TadoodlyApp: App {

    @AppStorage("isDarkMode") private var isDarkMode: Bool = false
    @AppStorage("didInitializeColorScheme") private var didInitializeColorScheme: Bool = false
    @Environment(\.scenePhase) private var scenePhase

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Project.self,
            UserTask.self,
            TaskItem.self,
            TimeEntry.self,
            Client.self
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
            RootView()
                .preferredColorScheme(isDarkMode ? .dark : .light)
        }
        .modelContainer(sharedModelContainer)
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                refreshWidgetData()
            }
        }
    }

    private func refreshWidgetData() {
        let context = sharedModelContainer.mainContext
        WidgetDataManager.applyPendingToggles(context: context)
        let descriptor = FetchDescriptor<UserTask>()
        if let tasks = try? context.fetch(descriptor) {
            WidgetDataManager.updateWidgetData(with: tasks)
        }
    }
}
