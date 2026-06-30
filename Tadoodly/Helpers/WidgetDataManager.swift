//
//  WidgetDataManager.swift
//  Tadoodly
//

import Foundation
import SwiftData
import WidgetKit

struct WidgetDataManager {
    private static let appGroupSuite = "group.com.tadoodly.app"
    private static let tasksKey = "widgetTodaysTasks"

    // Matches WidgetTask in TaskWidget.swift — field names must stay in sync
    private struct TaskData: Codable {
        let id: UUID
        let title: String
        let isCompleted: Bool
        let priorityRaw: String?
    }

    static func applyPendingToggles(context: ModelContext) {
        let pendingKey = "pendingTaskCompletions"

        guard let defaults = UserDefaults(suiteName: appGroupSuite),
              let pending = defaults.dictionary(forKey: pendingKey) as? [String: Bool],
              !pending.isEmpty
        else { return }

        for (idString, isCompleted) in pending {
            guard let uuid = UUID(uuidString: idString) else { continue }
            var descriptor = FetchDescriptor<UserTask>(predicate: #Predicate { $0.id == uuid })
            descriptor.fetchLimit = 1
            if let task = try? context.fetch(descriptor).first {
                task.isCompleted = isCompleted
                task.completed = isCompleted
                if isCompleted && task.completedAt == nil {
                    task.completedAt = .now
                } else if !isCompleted {
                    task.completedAt = nil
                }
                task.statusRaw = isCompleted ? TaskStatus.done.rawValue : TaskStatus.todo.rawValue
            }
        }

        try? context.save()
        defaults.removeObject(forKey: pendingKey)
    }

    static func updateWidgetData(with tasks: [UserTask]) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!

        let todaysTasks = tasks
            .filter { task in
                guard task.statusRaw != TaskStatus.cancelled.rawValue else { return false }
                if let due = task.dueDate {
                    return due >= today && due < tomorrow
                }
                // No due date: include if not completed
                return !(task.isCompleted || task.completed)
            }
            .sorted { lhs, rhs in
                let lDone = lhs.isCompleted || lhs.completed
                let rDone = rhs.isCompleted || rhs.completed
                if lDone != rDone { return !lDone }
                let lp = TaskPriority(rawValue: lhs.priorityRaw ?? "")?.sortOrder ?? -1
                let rp = TaskPriority(rawValue: rhs.priorityRaw ?? "")?.sortOrder ?? -1
                return lp > rp
            }

        let encoded = todaysTasks.map { task in
            TaskData(
                id: task.id,
                title: task.title,
                isCompleted: task.isCompleted || task.completed,
                priorityRaw: task.priorityRaw
            )
        }

        guard let defaults = UserDefaults(suiteName: appGroupSuite),
              let data = try? JSONEncoder().encode(encoded)
        else { return }

        defaults.set(data, forKey: tasksKey)
        WidgetCenter.shared.reloadTimelines(ofKind: "TaskWidget")
    }
}
