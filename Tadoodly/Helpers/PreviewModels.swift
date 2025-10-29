import Foundation
import SwiftData

#if DEBUG
enum PreviewModels {
    static let container: ModelContainer = {
        // Include all SwiftData models used by the app in this schema.
        // At minimum, we know about `Client` from ClientList.swift.
        let schema = Schema([UserTask.self, Project.self, TaskItem.self, TimeEntry.self, Client.self])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: [configuration])
        
        let context = container.mainContext

        // Insert sample projects
        let sampleProjects = ["Home", "Work", "Health"]
        var projectsByName: [String: Project] = [:]
        for name in sampleProjects {
            let proj = Project()
            proj.name = name
            context.insert(proj)
            projectsByName[name] = proj
        }
        
        // Insert sample tasks
        let sampleTasks = ["Buy groceries", "Prepare presentation", "Book dentist appointment"]
        var createdTasks: [UserTask] = []
        for (index, title) in sampleTasks.enumerated() {
            let task = UserTask()
            task.title = title
            task.createdAt = Date()
            task.updatedAt = Date()
            task.priority = .low
            task.status = .inProgress
            if index == 0, let home = projectsByName["Home"] {
                task.project = home
            } else if index == 1, let work = projectsByName["Work"] {
                task.project = work
            }
            context.insert(task)
            createdTasks.append(task)
        }

        // Insert sample time entries
        if let firstTask = createdTasks.first {
            let entry1 = TimeEntry()
            entry1.task = firstTask
            let entry1StartTime = Calendar.current.date(byAdding: .minute, value: -45, to: Date()) ?? Date().addingTimeInterval(-45 * 60)
            entry1.startTime = entry1StartTime
            entry1.endTime = Date()
            entry1.date = entry1StartTime
            entry1.duration = 45 * 60
            context.insert(entry1)
        }

        if createdTasks.count > 1 {
            let secondTask = createdTasks[1]
            
            // Entry from yesterday
            let entry2 = TimeEntry()
            entry2.task = secondTask
            let cal = Calendar.current
            let yesterday = cal.date(byAdding: .day, value: -1, to: Date()) ?? Date()
            let yesterdayStart = cal.date(byAdding: .hour, value: 10, to: cal.startOfDay(for: yesterday)) ?? yesterday
            let yesterdayEnd = cal.date(byAdding: .hour, value: 2, to: yesterdayStart) ?? yesterdayStart
            entry2.startTime = yesterdayStart
            entry2.endTime = yesterdayEnd
            entry2.date = yesterdayStart
            entry2.duration = 2 * 3600 // 2 hours
            context.insert(entry2)
            
            // Entry from last month
            let entry3 = TimeEntry()
            entry3.task = secondTask
            let lastMonth = cal.date(byAdding: .month, value: -1, to: Date()) ?? Date()
            let lastMonthStart = cal.date(byAdding: .hour, value: 14, to: cal.startOfDay(for: lastMonth)) ?? lastMonth
            let lastMonthEnd = cal.date(byAdding: .minute, value: 90, to: lastMonthStart) ?? lastMonthStart
            entry3.startTime = lastMonthStart
            entry3.endTime = lastMonthEnd
            entry3.date = lastMonthStart
            entry3.duration = 90 * 60 // 1.5 hours
            context.insert(entry3)
        }

        // Seed sample data once if empty
        do {
            var descriptor = FetchDescriptor<Client>()
            descriptor.fetchLimit = 1
            let existing = try container.mainContext.fetch(descriptor)
            if existing.isEmpty {
                let c1 = Client()
                c1.name = "Example Client"
                c1.email = "client@example.com"

                let c2 = Client()
                c2.name = "Example Client 2"
                c2.email = "client2@example.com"

                container.mainContext.insert(c1)
                container.mainContext.insert(c2)
            }
        } catch {
            // In previews, it's acceptable to fail silently; we still return the container.
        }

        return container
    }()
}
#endif
