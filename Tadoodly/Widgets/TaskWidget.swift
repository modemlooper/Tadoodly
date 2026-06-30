//
//  TaskWidget.swift
//  Tadoodly Widget Extension
//
//  NOTE: This file belongs in the Widget Extension target, NOT the main app target.
//  Add a new Widget Extension target in Xcode (File > New > Target > Widget Extension),
//  then move this file to that target's compilation sources.
//

import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Shared Data Model
// Must match the encoding in WidgetDataManager.swift (main app)

private let appGroupSuite = "group.com.tadoodly.app"
private let widgetTasksKey = "widgetTodaysTasks"

struct WidgetTask: Codable, Identifiable {
    let id: UUID
    let title: String
    let isCompleted: Bool
    let priorityRaw: String?
}

// MARK: - App Intent

struct ToggleTaskIntent: AppIntent {
    static var title: LocalizedStringResource = "Toggle Task Completion"
    static var isDiscoverable: Bool = false

    @Parameter(title: "Task ID")
    var taskID: String

    init() {}
    init(taskID: String) { self.taskID = taskID }

    func perform() async throws -> some IntentResult {
        guard let uuid = UUID(uuidString: taskID),
              let defaults = UserDefaults(suiteName: appGroupSuite),
              let data = defaults.data(forKey: widgetTasksKey),
              var tasks = try? JSONDecoder().decode([WidgetTask].self, from: data)
        else { return .result() }

        var newCompleted = false
        if let index = tasks.firstIndex(where: { $0.id == uuid }) {
            newCompleted = !tasks[index].isCompleted
            let t = tasks[index]
            tasks[index] = WidgetTask(id: t.id, title: t.title, isCompleted: newCompleted, priorityRaw: t.priorityRaw)
        }

        if let encoded = try? JSONEncoder().encode(tasks) {
            defaults.set(encoded, forKey: widgetTasksKey)
        }

        var pending = (defaults.dictionary(forKey: "pendingTaskCompletions") as? [String: Bool]) ?? [:]
        pending[taskID] = newCompleted
        defaults.set(pending, forKey: "pendingTaskCompletions")

        WidgetCenter.shared.reloadTimelines(ofKind: "TaskWidget")
        return .result()
    }
}

// MARK: - Timeline Entry

struct TaskWidgetEntry: TimelineEntry {
    let date: Date
    let tasks: [WidgetTask]
}

// MARK: - Timeline Provider

struct TaskWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> TaskWidgetEntry {
        TaskWidgetEntry(date: .now, tasks: [
            WidgetTask(id: UUID(), title: "Review project proposal", isCompleted: false, priorityRaw: "high"),
            WidgetTask(id: UUID(), title: "Send email to client", isCompleted: false, priorityRaw: "medium"),
            WidgetTask(id: UUID(), title: "Team standup", isCompleted: true, priorityRaw: nil),
        ])
    }

    func getSnapshot(in context: Context, completion: @escaping (TaskWidgetEntry) -> Void) {
        completion(TaskWidgetEntry(date: .now, tasks: loadTasks()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TaskWidgetEntry>) -> Void) {
        let entry = TaskWidgetEntry(date: .now, tasks: loadTasks())
        // Refresh at midnight so "today's tasks" updates automatically
        let midnight = Calendar.current.startOfDay(for: .now).addingTimeInterval(86400)
        completion(Timeline(entries: [entry], policy: .after(midnight)))
    }

    private func loadTasks() -> [WidgetTask] {
        guard let defaults = UserDefaults(suiteName: appGroupSuite),
              let data = defaults.data(forKey: widgetTasksKey),
              let tasks = try? JSONDecoder().decode([WidgetTask].self, from: data)
        else { return [] }
        return tasks
    }
}

// MARK: - Reusable Components

private struct PriorityDot: View {
    let priorityRaw: String?

    var color: Color {
        switch priorityRaw {
        case "urgent": return .red
        case "high":   return .orange
        case "medium": return .yellow
        default:       return .clear
        }
    }

    var body: some View {
        Circle().fill(color).frame(width: 7, height: 7)
    }
}

private struct WidgetTaskRow: View {
    let task: WidgetTask

    var body: some View {
        HStack(spacing: 8) {
            Button(intent: ToggleTaskIntent(taskID: task.id.uuidString)) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(task.isCompleted ? .green : .secondary)
                    .font(.system(size: 18))
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)

            Link(destination: URL(string: "tadoodly://task?id=\(task.id.uuidString)")!) {
                HStack {
                    Text(task.title)
                        .font(.caption)
                        .foregroundStyle(task.isCompleted ? .secondary : .primary)
                        .strikethrough(task.isCompleted)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    if !task.isCompleted {
                        PriorityDot(priorityRaw: task.priorityRaw)
                    }
                }
            }
            .foregroundStyle(task.isCompleted ? .secondary : .primary)
        }
    }
}

// MARK: - Small Widget (task count only)

private struct SmallWidgetView: View {
    let entry: TaskWidgetEntry

    var remaining: Int { entry.tasks.filter { !$0.isCompleted }.count }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: "checklist")
                    .foregroundStyle(.blue)
                    .font(.caption2)
                Text("Today")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text("\(remaining)")
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .minimumScaleFactor(0.5)

            Text(remaining == 1 ? "task left" : "tasks left")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding()
        .widgetURL(URL(string: "tadoodly://tasks"))
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

// MARK: - Medium Widget (4 tasks)

private struct MediumWidgetView: View {
    let entry: TaskWidgetEntry

    var displayTasks: [WidgetTask] { Array(entry.tasks.prefix(4)) }
    var remaining: Int { entry.tasks.filter { !$0.isCompleted }.count }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Image(systemName: "checklist")
                    .foregroundStyle(.blue)
                    .font(.caption2)
                Text("Tasks")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(remaining) remaining")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, 8)

            if entry.tasks.isEmpty {
                Spacer()
                HStack {
                    Spacer()
                    VStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("All done!")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                Spacer()
            } else {
                VStack(spacing: 6) {
                    ForEach(displayTasks) { task in
                        WidgetTaskRow(task: task)
                    }
                }
                Spacer(minLength: 0)
            }
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

// MARK: - Large Widget (8 tasks)

private struct LargeWidgetView: View {
    let entry: TaskWidgetEntry

    var displayTasks: [WidgetTask] { Array(entry.tasks.prefix(8)) }
    var remaining: Int { entry.tasks.filter { !$0.isCompleted }.count }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Image(systemName: "checklist")
                    .foregroundStyle(.blue)
                Text("Today's Tasks")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(remaining)/\(entry.tasks.count) remaining")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, 10)

            if entry.tasks.isEmpty {
                Spacer()
                VStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.green)
                    Text("All caught up for today!")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                Spacer()
            } else {
                ForEach(Array(displayTasks.enumerated()), id: \.element.id) { index, task in
                    WidgetTaskRow(task: task)
                        .padding(.vertical, 4)
                    if index < displayTasks.count - 1 {
                        Divider()
                    }
                }
                Spacer(minLength: 0)
            }
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

// MARK: - Entry View

struct TaskWidgetEntryView: View {
    let entry: TaskWidgetEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(entry: entry)
        default:
            MediumWidgetView(entry: entry)
        }
    }
}

// MARK: - Widget Configuration

struct TaskWidget: Widget {
    let kind: String = "TaskWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TaskWidgetProvider()) { entry in
            TaskWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Today's Tasks")
        .description("See your tasks for today at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Widget Bundle Entry Point

@main
struct TaskWidgetBundle: WidgetBundle {
    var body: some Widget {
        TaskWidget()
    }
}
