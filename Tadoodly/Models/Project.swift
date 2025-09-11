import Foundation
import SwiftData

@Model
final class Project {
    var id: UUID = UUID()
    var name: String = ""
    var projectDescription: String?
    var color: String = "blue"
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var isCompleted: Bool = false
    var completedAt: Date?

    var status: String = ProjectStatus.notStarted.rawValue
    var priority: String = ProjectPriority.low.rawValue
    var dueDate: Date?
    var icon: String = "folder"
    
    // To-many must be optional for CloudKit. Declare relationship; inverse is declared on UserTask.project.
    @Relationship(deleteRule: .cascade)
    var tasks: [UserTask]?

    init() {}
}

// Define the ProjectStatus enum with public access
enum ProjectStatus: String, CaseIterable, Identifiable, Codable {
    case notStarted = "Not Started"
    case inProgress = "In Progress"
    case completed = "Completed"
    case archived = "Archived"
    
    public var id: String { self.rawValue }
}

enum ProjectPriority: String, CaseIterable, Identifiable, Codable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
 
    public var id: String { self.rawValue }
}
