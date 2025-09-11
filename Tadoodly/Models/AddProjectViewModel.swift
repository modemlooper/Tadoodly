//  AddProjectViewModel.swift
//  Tadoodly
//
//  Created by AI Assistant on 7/13/25.
//

import Foundation
import SwiftData
import SwiftUI

@Observable
class AddProjectViewModel {
   var selectedIcon: String?
    var name: String
    var projectDescription: String
    var selectedColor: String
    var tasks: [UserTask]
    var status: ProjectStatus
    var dueDate: Date?
    var priority: ProjectPriority
    
    private(set) var project: Project?
    
    init(project: Project? = nil) {
        self.project = project
        self.selectedIcon = project?.icon ?? nil
        self.name = project?.name ?? ""
        self.projectDescription = project?.projectDescription ?? ""
        self.selectedColor = project?.color ?? "blue"
        self.tasks = project?.tasks ?? []
        if let projectStatus = project?.status, let status = ProjectStatus(rawValue: projectStatus) {
            self.status = status
        } else {
            self.status = .notStarted
        }
        if let projectPriority = project?.priority, let prio = ProjectPriority(rawValue: projectPriority) {
            self.priority = prio
        } else {
            self.priority = .low
        }
        self.dueDate = project?.dueDate
    }
    
    func update(from project: Project?) {
        self.project = project
        guard let project else {
            // Reset to defaults for "new project" mode
            self.selectedIcon = "folder"
            self.name = ""
            self.projectDescription = ""
            self.selectedColor = "blue"
            self.tasks = []
            self.status = .notStarted
            self.priority = .low
            self.dueDate = nil
            return
        }
        
        self.selectedIcon = project.icon.isEmpty ? "folder" : project.icon
        self.name = project.name
        self.projectDescription = project.projectDescription
        self.selectedColor = project.color
        self.tasks = Array(project.tasks) // force fresh value copy
        if let status = ProjectStatus(rawValue: project.status) {
            self.status = status
        } else {
            self.status = .notStarted
        }
        if let prio = ProjectPriority(rawValue: project.priority) {
            self.priority = prio
        } else {
            self.priority = .low
        }
        self.dueDate = project.dueDate
    }
}

