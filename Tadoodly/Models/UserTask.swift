//
//  Task.swift
//  Tadoodly
//
//  Created by modemlooper on 5/25/25.
//

import Foundation
import SwiftData

public enum TaskStatus: String, Codable, CaseIterable, Identifiable {
    case todo = "Not Started"
    case inProgress = "In Progress"
    case done = "Completed"
    case onHold = "On Hold"
    case cancelled = "Cancelled"
    case ready = "Ready"

    public var id: String { rawValue }
}

public enum TaskPriority: String, Codable, CaseIterable, Identifiable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    

    public var id: String { rawValue }
}

@Model
public final class UserTask {
    public var id: UUID = UUID()
    public var title: String = ""
    public var taskDescription: String? = ""
    public var priority: TaskPriority? = TaskPriority.low
    public var status: TaskStatus? = TaskStatus.todo
    public var isActive: Bool = false
    public var completed: Bool = false
    public var createdAt: Date = Date()
    public var updateAt: Date? = Date()
    public var dueDate: Date? = nil
    public var color: String? = nil
    public var project: Project? = nil
    
    @Relationship(deleteRule: .cascade, inverse: \TimeEntry.task)
    @Relationship(inverse: \Project.tasks)
    
    public var timeEntries: [TimeEntry]? = []
    
    @Relationship(deleteRule: .cascade, inverse: \TaskItem.task)
    public var taskItems: [TaskItem]? = []

    
    public init(title: String, project: Project? = nil, description: String = "") {
        self.title = title
        self.createdAt = Date()
        self.updateAt = Date()
        self.taskDescription = description
        self.project = project
    }
        
    public var totalTime: TimeInterval {
        timeEntries!.reduce(0) { $0 + $1.duration }
    }
    
    public var activeTimeEntry: TimeEntry? {
        timeEntries!.first { $0.isActive }
    }
    
    public func startTimer() {
        guard !isActive else { return }
        isActive = true
        updateAt = Date()
        let entry = TimeEntry(startTime: Date(), task: self as UserTask)
        timeEntries!.append(entry)
    }
    
    public func stopTimer() {
        guard isActive else { return }
        isActive = false
        activeTimeEntry?.stop()
    }
    
    public func copy(modelcontext: ModelContext) {
        let newTask = UserTask(title: self.title + " (Copy)", project: self.project, description: self.taskDescription ?? "")
        newTask.priority = self.priority
        newTask.status = self.status
        newTask.completed = self.completed
        newTask.dueDate = self.dueDate
        newTask.color = self.color
        newTask.isActive = false

        // Duplicate task items (if any)
        if let items = self.taskItems {
            newTask.taskItems = items.map { item in
                let newItem = TaskItem(title: item.title)
                newItem.task = newTask
                return newItem
            }
        } else {
            newTask.taskItems = []
        }
        // No time entries copied
        newTask.timeEntries = []
        modelcontext.insert(newTask)
    }
    
    public func delete(modelcontext: ModelContext) {
        modelcontext.delete(self)
    }
}

