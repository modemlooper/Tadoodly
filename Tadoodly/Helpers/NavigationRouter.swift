import Foundation
import SwiftUI

final class NavigationRouter: ObservableObject {
    @Published var path = NavigationPath()
    @Published var refreshID = UUID() // ADD: a simple change signal
    
    init() {}
    
    func navigate(_ route: Route) {
        path.append(route)
    }
    
    func pop() {
        path.removeLast()
    }
    
    // NEW: Pop multiple elements safely
    func pop(_ count: Int) {
        guard count > 0 else { return }
        let toRemove = min(count, path.count)
        if toRemove > 0 {
            path.removeLast(toRemove)
        }
    }
    
    func root() {
        path = NavigationPath()
    }
 
}

enum Route: Hashable {
    case viewTask(UserTask)
    case editTask(UserTask)
    case addTask
    case viewProject(Project)
    case editProject(Project)
    case addProject
    case settings
    case timeEntries(UserTask)
    case editTimeEntry(TimeEntry)
    case addTimeEntry(UserTask)
}

extension Route {
    @ViewBuilder
    var destinationView: some View {
        switch self {
            case .viewTask(let task):
                TaskView(task: task)
            case .editTask(let task):
                AddTaskView(task: task)
            case .addTask:
                AddTaskView(task: nil)
            case .viewProject(let project):
                ProjectDetailsView(project: project)
            case .editProject(let project):
                AddProjectView(project: project)
            case .addProject:
                AddProjectView(project: nil)
            case .settings:
                SettingsView()
            case .timeEntries(let task):
                TimeEntriesView(task: task)
            case .editTimeEntry(let timeEntry):
                EditTimeEntryView(timeEntry: timeEntry)
            case .addTimeEntry(let task):
                AddTimeEntryView(task: task)
        }
    }
}
