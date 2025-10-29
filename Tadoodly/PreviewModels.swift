import SwiftUI
import SwiftData

struct RootPreviewContainer: View {
    let container: ModelContainer
    init() {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try! ModelContainer(
            for: UserTask.self, Project.self, TaskItem.self, TimeEntry.self, Client.self,
            configurations: configuration
        )
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
        
        let client = Client()
        client.name = "Example Client"
        client.email = "client@example.com"
        context.insert(client)
        
        let client2 = Client()
        client2.name = "Example Client 2"
        client2.email = "client2@example.com"
        context.insert(client2)
    }

    var body: some View {
        RootView()
            .modelContainer(container)
    }
}
