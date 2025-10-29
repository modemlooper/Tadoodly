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
struct ExportRoute: Hashable {}
struct ClientsRoute: Hashable {}

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    
    @State private var notificationManager = NotificationManager.shared
    
    @State private var pathTasks = NavigationPath()
    @State private var pathProjects = NavigationPath()
    @State private var pathStats = NavigationPath()
    @State private var pathSchedule = NavigationPath()
    
    @State private var selectedSortOption: TaskListSortOption = .updateAt
    @State private var selectedTab = 0
    
    var body: some View {
        // Build the TabView first so we can conditionally apply modifiers
        let tabHost = TabView(selection: $selectedTab) {
            
            NavigationStack(path: $pathTasks) {
                TaskList(path: $pathTasks, selectedSortOption: $selectedSortOption)
                    .navigationDestination(for: UserTask.self) { task in
                        TaskDetail(task: task)
                    }
                    .navigationDestination(for: AddTaskRoute.self) { route in
                        AddTask(task: route.task, path: $pathTasks)
                    }
                    .navigationDestination(for: AddTimeRoute.self) { route in
                        Group {
                            if let entry = route.timeEntry {
                                AddTimeEntry(path: $pathTasks, timeEntry: entry)
                            } else {
                                AddTimeEntry(path: $pathTasks)
                            }
                        }
                    }
                    .navigationDestination(for: SettingstRoute.self) { _ in
                        SettingsView(path: $pathTasks)
                    }
                    .navigationDestination(for: ExportRoute.self) { _ in
                        ExportView()
                    }
                    .navigationDestination(for: ClientsRoute.self) { _ in
                        ClientList()
                    }
                    .navigationDestination(for: TimeRoute.self) { route in
                        Group {
                            if let task = route.task {
                                TimeEntriesView(path: $pathTasks, task: task)
                            } else {
                                Text("No task available.")
                            }
                        }
                    }
            }
            .tabItem {
                Label("Tasks", systemImage: "checklist")
            }
            .tag(0)
            
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
                        AddTask(task: route.task, path: $pathProjects)
                    }
                    .navigationDestination(for: TimeRoute.self) { route in
                        Group {
                            if let task = route.task {
                                TimeEntriesView(path: $pathProjects, task: task)
                            } else {
                                Text("No task available.")
                            }
                        }
                    }
                    .navigationDestination(for: AddTimeRoute.self) { route in
                        Group {
                            if let entry = route.timeEntry {
                                AddTimeEntry(path: $pathProjects, timeEntry: entry)
                            } else {
                                AddTimeEntry(path: $pathProjects)
                            }
                        }
                    }
                
            }
            .tabItem {
                Label("Projects", systemImage: "folder")
            }
            .tag(1)
            
            NavigationStack() {
                StatsView()
                
            }
            .tabItem {
                Label("Stats", systemImage: "chart.bar.xaxis")
            }
            .tag(2)
            
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
            .tag(3)
            
        }
        .alert("Reminder Notifications?", isPresented: $notificationManager.shouldShowPermissionPrompt) {
             Button("Enable") {
                 Task {
                     do {
                         try await notificationManager.requestAuthorization()
                     } catch {
                         // Optionally log or present an error; for now, just print
                         print("Failed to request notification authorization: \(error)")
                     }
                 }
             }
             Button("Not Now", role: .cancel) { }
         } message: {
             Text("Get reminders for your scheduled tasks so you never miss a deadline.")
         }
        .task {
            // Set the model context for notification handling
            notificationManager.modelContext = modelContext
            
            // Set up navigation callback for notification taps
            notificationManager.onTaskNotificationTapped = { taskId in
                Task {
                    await MainActor.run {
                        // Fetch the task
                        let descriptor = FetchDescriptor<UserTask>(
                            predicate: #Predicate { task in
                                task.id == taskId
                            }
                        )
                        
                        if let tasks = try? modelContext.fetch(descriptor),
                           let task = tasks.first {
                            // Switch to Tasks tab
                            selectedTab = 0
                            
                            // Clear the navigation path and navigate to the task
                            pathTasks = NavigationPath()
                            
                            // Navigate to the task detail
                            pathTasks.append(AddTaskRoute(task: task))
                        }
                    }
                    
                    // Small delay to ensure navigation completes
                    try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                }
            }
            
            await notificationManager.checkIfShouldPromptForPermission()
        }
        
        if #available(iOS 26.0, *) {
            tabHost
                .tabViewBottomAccessory {
                    TimerBarView()
                }
        } else {
            tabHost
        }
    }
}

#Preview() {
    RootView()
        .modelContainer(PreviewModels.container)
}

