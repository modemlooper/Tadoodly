//
//  ContentView.swift
//  Tadoodly
//
//  Created by modemlooper on 5/25/25.
//

import SwiftUI
import SwiftData
import Foundation

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @StateObject var tasksRouter = NavigationRouter()
    @StateObject var projectsRouter = NavigationRouter()
    @StateObject var statsRouter = NavigationRouter()
    @StateObject var scheduleRouter = NavigationRouter()
    
    var body: some View {
        TabView {
            // Tasks
            NavigationStack(path: $tasksRouter.path) {
                TaskListView()
                    .navigationDestination(for: Route.self) { route in
                        route.destinationView
                    }
            }
            .environmentObject(tasksRouter)
            .tabItem {
                Label("Tasks", systemImage: "checklist")
            }
            
            // Projects
            NavigationStack(path: $projectsRouter.path) {
                ProjectsView()
                    .navigationDestination(for: Route.self) { route in
                        route.destinationView
                    }
            }
            .environmentObject(projectsRouter)
            .tabItem {
                Label("Projects", systemImage: "folder")
            }
            
            // Stats
            NavigationStack(path: $statsRouter.path) {
                StatsView()
                    .navigationDestination(for: Route.self) { route in
                        route.destinationView
                    }
            }
            .environmentObject(statsRouter)
            .tabItem {
                Label("Stats", systemImage: "chart.bar.xaxis")
            }
            
            // Schedule
            NavigationStack(path: $scheduleRouter.path) {
                ScheduleView()
                    .navigationDestination(for: Route.self) { route in
                        route.destinationView
                    }
            }
            .environmentObject(scheduleRouter)
            .tabItem {
                Label("Schedule", systemImage: "calendar")
            }
        }
    }
}


#Preview {
    if #available(iOS 26.0, *) {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: UserTask.self, Project.self, TimeEntry.self, configurations: config)
        let modelContext = container.mainContext
        let project = Project(name: "Work", color: "blue")
        modelContext.insert(project)
        let task = UserTask(title: "Sample Task", project: project)
        task.priority = TaskPriority.low
        modelContext.insert(task)
        
        let task2 = UserTask(title: "1 Sample Task", project: project)
        task2.priority = TaskPriority.low
        modelContext.insert(task2)
        
        return ContentView()
            .modelContainer(container)
//            .environmentObject(ProjectPlannerViewModel())
            .environmentObject(NavigationRouter())
    } else {
        return ContentView()
            .modelContainer(for: [Project.self, UserTask.self, TimeEntry.self], inMemory: true)
    }
}

