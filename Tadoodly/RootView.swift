//
//  ContentView.swift
//  Tadoodly
//
//  Created by modemlooper on 9/7/25.
//

import SwiftUI
import SwiftData

// Navigation Routes
struct AddTaskRoute: Hashable {
    let task: UserTask?
}
struct AddProjectRoute: Hashable {
    let project: Project?
}
struct SettingstRoute: Hashable {}
struct TimeRoute: Hashable {}


struct RootView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var pathTasks = NavigationPath()
    @State private var pathProjects = NavigationPath()
    @State private var pathStats = NavigationPath()
    @State private var pathSchedule = NavigationPath()
    
    @State private var selectedSortOption: TaskListSortOption = .updateAt

    var body: some View {
        TabView {

            NavigationStack(path: $pathTasks) {
                TaskList(path: $pathTasks, selectedSortOption: $selectedSortOption)
                    .navigationDestination(for: UserTask.self) { task in
                        TaskDetail(task: task)
                    }
                    .navigationDestination(for: AddTaskRoute.self) { route in
                        AddTask(task: route.task, path: $pathTasks)
                    }
                    .navigationDestination(for: SettingstRoute.self) { _ in
                        SettingsView(path: $pathTasks)
                    }
            }
            .tabItem {
                Label("Tasks", systemImage: "checklist")
            }
            
            NavigationStack(path: $pathProjects) {
                ProjectList(path: $pathProjects)
                    .navigationDestination(for: Project.self) { project in
                        ProjectDetail(project: project)
                    }
                    .navigationDestination(for: AddProjectRoute.self) { route in
                        AddProject(project: route.project, path: $pathProjects)
                    }
                
            }
            .tabItem {
                Label("Projects", systemImage: "folder")
            }
            
            NavigationStack() {
                StatsView()
                
            }
            .tabItem {
                Label("Stats", systemImage: "chart.bar.xaxis")
            }
            
            NavigationStack(path: $pathSchedule) {
                ScheduleView(path: $pathSchedule)
                    .navigationDestination(for: UserTask.self) { task in
                        TaskDetail(task: task)
                    }
                    .navigationDestination(for: AddTaskRoute.self) { route in
                        AddTask(task: route.task, path: $pathTasks)
                    }
                
            }
            .tabItem {
                Label("Schedule", systemImage: "calendar")
            }
            
        }
        .tabViewBottomAccessory() {
            TimerBarView()
        }
        
    }
}

#Preview {
    // Create an in-memory SwiftData container for previews and seed 3 tasks
    let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: UserTask.self, Project.self, TaskItem.self, TimeEntry.self,
        configurations: configuration
    )

    // Insert three sample projects
    let context = container.mainContext
    
    let sampleProjects = ["Home", "Work", "Health"]
    var projectsByName: [String: Project] = [:]
    for name in sampleProjects {
        let proj = Project()
        proj.name = name
        context.insert(proj)
        projectsByName[name] = proj
    }
    
    let sampleTasks = ["Buy groceries", "Prepare presentation", "Book dentist appointment"]
    for (index, title) in sampleTasks.enumerated() {
        let task = UserTask()
        task.title = title
        task.createdAt = Date()
        task.updatedAt = Date()
        task.priority = .low
        task.status = .inProgress
        // Assign first task to Home, second to Work, leave third without a project (if your data model supports optional project)
        if index == 0, let home = projectsByName["Home"] {
            task.project = home
        } else if index == 1, let work = projectsByName["Work"] {
            task.project = work
        }
        context.insert(task)
    }
    
    return RootView()
        .modelContainer(container)
}
