import Foundation
import SwiftData

@Model
final class UserTask {
    var id: UUID = UUID()
    var title: String = ""
    var isActive: Bool = false
    var completed: Bool = false
    var isCompleted: Bool = false
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var taskDescription: String?
    var priority: TaskPriority?
    var completedAt: Date?
    var dueDate: Date?
    var status: TaskStatus?
    var updateAt: Date?
    var color: String?
    
    // Optional to-one to Project; inverse is Project.tasks (inverse declared here only)
    @Relationship(inverse: \Project.tasks)
    var project: Project?
    
    // Optional to-many collections to satisfy CloudKit; provide inverses for TaskItem.task and TimeEntry.task
    @Relationship(deleteRule: .cascade, inverse: \TaskItem.task)
    var taskItems: [TaskItem]?
    
    @Relationship(deleteRule: .cascade, inverse: \TimeEntry.task)
    var timeEntries: [TimeEntry]?
    
    init() {}
}

enum TaskStatus: String, Codable, CaseIterable, Identifiable {
    case todo = "Not Started"
    case inProgress = "In Progress"
    case done = "Completed"
    case onHold = "On Hold"
    case cancelled = "Cancelled"
    case ready = "Ready"

    public var id: String { rawValue }
}

enum TaskPriority: String, CaseIterable, Codable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case urgent = "urgent"
    
    var displayName: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        case .urgent: return "Urgent"
        }
    }
    
    var sortOrder: Int {
        switch self {
        case .low: return 0
        case .medium: return 1
        case .high: return 2
        case .urgent: return 3
        }
    }
}
