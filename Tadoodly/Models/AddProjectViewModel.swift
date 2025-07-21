//  AddProjectViewModel.swift
//  Tadoodly
//
//  Created by AI Assistant on 7/13/25.
//

import Foundation
import SwiftData
import SwiftUI

class AddProjectViewModel: ObservableObject {
    @Published var selectedIcon: String?
    @Published var name: String
    @Published var projectDescription: String
    @Published var selectedColor: String
    @Published var tasks: [UserTask]
    @Published var status: ProjectStatus
    @Published var dueDate: Date?
    @Published var priority: ProjectPriority
    
    let project: Project?
    
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
        if let projectPriority = project?.priority, let status = ProjectPriority(rawValue: projectPriority) {
            self.priority = status
        } else {
            self.priority = .low
        }
        self.dueDate = project?.dueDate
    }
    
    // Optionally, add helpers to update fields or validate as needed
}

