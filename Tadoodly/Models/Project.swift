//
//  Project.swift
//  Tadoodly
//
//  Created by modemlooper on 6/4/25.
//

import SwiftUI
import SwiftData

// Define the ProjectStatus enum with public access
public enum ProjectStatus: String, CaseIterable, Identifiable, Codable {
    case notStarted = "Not Started"
    case inProgress = "In Progress"
    case completed = "Completed"
    case archived = "Archived"
    
    public var id: String { self.rawValue }
}

public enum ProjectPriority: String, CaseIterable, Identifiable, Codable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
 
    public var id: String { self.rawValue }
}

public func colorFromString(_ color: String) -> Color {
    switch color {
    case "red": return .red
    case "blue": return .blue
    case "green": return .green
    case "orange": return .orange
    case "purple": return .purple
    case "teal": return .teal
    case "pink": return .pink
    case "indigo": return .indigo
    case "gray": return .gray
    case "darkGray": return Color(.darkGray)
    case "white": return .white
    default: return .white
    }
}

@Model
public final class Project: Identifiable {
    public var id: UUID = UUID()
    public var name: String = ""
    public var projectDescription: String = ""
    public var color: String = "white"
    public var status: String = ProjectStatus.notStarted.rawValue
    public var priority: String = ProjectPriority.low.rawValue
    public var createdAt: Date = Date()
    public var dueDate: Date? = Date()
    public var icon: String = "folder"
    
    @Relationship(deleteRule: .cascade, inverse: \UserTask.project)
    public var tasks: [UserTask] = []
    
    public init(name: String, description: String = "", color: String = "darkGray", status: ProjectStatus = .notStarted, createdAt: Date = Date()) {
        self.name = name
        self.projectDescription = description
        self.color = color
        self.status = status.rawValue
        self.createdAt = createdAt
    }
    
    public var totalTime: TimeInterval {
        tasks.reduce(0) { $0 + $1.totalTime }
    }
    
    public func copy(modelContext: ModelContext) {
        // Step 1: Copy the project (except id, createdAt, dueDate)
        let newProject = Project(name: self.name + " (Copy)", description: self.projectDescription, color: self.color, status: ProjectStatus(rawValue: self.status) ?? .notStarted, createdAt: Date())
        newProject.priority = self.priority
        newProject.icon = self.icon
        newProject.dueDate = self.dueDate
        newProject.createdAt = Date()

        var newTasks: [UserTask] = []

        for oldTask in self.tasks {
            let newTask = UserTask(title: oldTask.title, project: newProject, description: oldTask.taskDescription ?? "")
            newTask.status = oldTask.status
            newTask.priority = oldTask.priority
            newTask.isActive = false
            newTask.completed = oldTask.completed
            newTask.dueDate = oldTask.dueDate
            newTask.color = oldTask.color

            // Copy time entries
            if let oldTimeEntries = oldTask.timeEntries {
                var newTimeEntries: [TimeEntry] = []
                for oldEntry in oldTimeEntries {
                    let newEntry = TimeEntry()
                    newEntry.startTime = oldEntry.startTime
                    newEntry.endTime = oldEntry.endTime
                    newEntry.duration = oldEntry.duration
                    newEntry.date = oldEntry.date
                    newEntry.note = oldEntry.note
                    newEntry.task = newTask
                    modelContext.insert(newEntry)
                    newTimeEntries.append(newEntry)
                }
                newTask.timeEntries = newTimeEntries
            }

            // Copy task items
            if let oldTaskItems = oldTask.taskItems {
                var newTaskItems: [TaskItem] = []
                for oldItem in oldTaskItems {
                    let newItem = TaskItem(title: oldItem.title, task: newTask, description: oldItem.itemDescription ?? "")
                    newItem.completed = oldItem.completed
                    modelContext.insert(newItem)
                    newTaskItems.append(newItem)
                }
                newTask.taskItems = newTaskItems
            }

            modelContext.insert(newTask)
            newTasks.append(newTask)
        }

        newProject.tasks = newTasks
        modelContext.insert(newProject)
        try? modelContext.save()
    }
    
    public func delete(modelContext: ModelContext) {
        modelContext.delete(self)
    }
}
