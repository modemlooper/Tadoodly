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
struct AddTimeRoute: Hashable {
    let timeEntry: TimeEntry?
}
struct SettingstRoute: Hashable {}
struct TimeRoute: Hashable {
    let task: UserTask?
}


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
                    .navigationDestination(for: AddTimeRoute.self) { route in
                        if let entry = route.timeEntry {
                            AddTimeEntry(path: $pathTasks, timeEntry: entry)
                        } else {
                            AddTimeEntry(path: $pathTasks)
                        }
                    }
                    .navigationDestination(for: SettingstRoute.self) { _ in
                        SettingsView(path: $pathTasks)
                    }
                    .navigationDestination(for: TimeRoute.self) { route in
                        if let task = route.task {
                            TimeEntriesView(path: $pathTasks, task: task)
                        }
                    }
            }
            .tabItem {
                Label("Tasks", systemImage: "checklist")
            }
            
            NavigationStack(path: $pathProjects) {
                ProjectList(path: $pathProjects)
                    .navigationDestination(for: UserTask.self) { task in
                        TaskDetail(task: task)
                    }
                    .navigationDestination(for: Project.self) { project in
                        ProjectDetail(path: $pathProjects, project: project)
                    }
                    .navigationDestination(for: AddProjectRoute.self) { route in
                        AddProject(project: route.project, path: $pathProjects)
                    }
                    .navigationDestination(for: AddTaskRoute.self) { route in
                        AddTask(task: route.task, path: $pathTasks)
                    }
                    .navigationDestination(for: TimeRoute.self) { route in
                        if let task = route.task {
                            TimeEntriesView(path: $pathTasks, task: task)
                        }
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
                        AddTask(task: route.task, path: $pathSchedule)
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

#Preview("RootView with in-memory data") {
    // A helper view to encapsulate setup so the preview macro returns a single View
    struct RootPreviewContainer: View {
        let container: ModelContainer
        init() {
            let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
            container = try! ModelContainer(
                for: UserTask.self, Project.self, TaskItem.self, TimeEntry.self,
                configurations: configuration
            )
            let context = container.mainContext

            // Insert sample projects
            let sampleProjects = ["Home", "Work", "Health"]
            var projectsByName: [String: Project] = [:]
            for name in sampleProjects {
                let proj = Project()
                proj.name = name
                context.insert(proj)
                projectsByName[name] = proj
            }

            // Insert sample tasks
            let sampleTasks = ["Buy groceries", "Prepare presentation", "Book dentist appointment"]
            var createdTasks: [UserTask] = []
            for (index, title) in sampleTasks.enumerated() {
                let task = UserTask()
                task.title = title
                task.createdAt = Date()
                task.updatedAt = Date()
                task.priority = .low
                task.status = .inProgress
                if index == 0, let home = projectsByName["Home"] {
                    task.project = home
                } else if index == 1, let work = projectsByName["Work"] {
                    task.project = work
                }
                context.insert(task)
                createdTasks.append(task)
            }

            // Insert sample time entries
            if let firstTask = createdTasks.first {
                let entry1 = TimeEntry()
                entry1.task = firstTask
                entry1.startTime = Calendar.current.date(byAdding: .minute, value: -45, to: Date()) ?? Date().addingTimeInterval(-45 * 60)
                entry1.endTime = Date()
                entry1.duration = 45 * 60
                context.insert(entry1)
            }

            if createdTasks.count > 1 {
                let secondTask = createdTasks[1]
                let entry2 = TimeEntry()
                entry2.task = secondTask
                let now = Date()
                let cal = Calendar.current
                let startOfDay = cal.startOfDay(for: now)
                let nineAM = cal.date(byAdding: .hour, value: 9, to: startOfDay) ?? now
                let tenThirty = cal.date(byAdding: .minute, value: 90, to: nineAM) ?? now
                entry2.startTime = nineAM
                entry2.endTime = tenThirty
                entry2.duration = 90 * 60
                context.insert(entry2)
            }
        }

        var body: some View {
            RootView()
                .modelContainer(container)
        }
    }

    return RootPreviewContainer()
}

