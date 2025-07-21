//
//  AddTaskViewModel.swift
//  Tadoodly
//
//  Created by modemlooper on 7/6/25.
//

import Foundation
import SwiftData

class AddTaskViewModel: ObservableObject {
    @Published var name: String = ""
    @Published var description: String = ""
    @Published var priority: TaskPriority = .low
    @Published var status: TaskStatus = .todo
    @Published var selectedProject: Project? = nil
    @Published var taskItems: [TaskItem] = []
    @Published var dueDate: Date? = nil
    
    var task: UserTask?
    var hasAppeared = false
    
    init(task: UserTask?) {
        self.task = task
        if let task = task {
            dueDate = task.dueDate
        } else {
            dueDate = nil
        }
        update(from: task)
    }
    
    func update(from task: UserTask?) {
        self.task = task
        if let task = task {
            name = task.title
            description = task.taskDescription ?? ""
            priority = task.priority ?? .low
            status = task.status ?? .todo
            selectedProject = task.project
            taskItems = task.taskItems ?? []
            dueDate = task.dueDate
        } else {
            name = ""
            description = ""
            priority = .low
            status = .todo
            selectedProject = nil
            taskItems = []
            dueDate = nil
        }
        hasAppeared = true
    }
    
    func makeTask(with modelContext: ModelContext, shouldDismiss: Bool = false, dismiss: (() -> Void)? = nil) {
        if let task = task {
            // Update existing task
            task.title = name
            task.priority = priority
            task.status = status
            task.taskDescription = description
            task.updateAt = Date()
            task.project = selectedProject
            task.dueDate = dueDate
            
            let oldItems = task.taskItems ?? []
            let toRemove = oldItems.filter { oldItem in
                !taskItems.contains(where: { $0.id == oldItem.id })
            }
            for item in toRemove {
                modelContext.delete(item)
            }
            
            for item in taskItems {
                item.task = task
                modelContext.insert(item)
            }
        } else {
            // Create new task
            let newTask = UserTask(title: name, project: selectedProject, description: description)
            newTask.status = status
            newTask.priority = priority
            newTask.dueDate = dueDate
            modelContext.insert(newTask)
            
            for item in taskItems {
                item.task = newTask
                modelContext.insert(item)
            }
            self.task = newTask
        }
        try? modelContext.save()
        if shouldDismiss {
            dismiss?()
        }
    }
}
