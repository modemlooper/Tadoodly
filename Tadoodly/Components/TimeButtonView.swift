import SwiftUI
import SwiftData

struct TimeButtonView: View {
    @Environment(\.modelContext) private var modelContext
    let task: UserTask
    var fontSize: CGFloat = 32

    @State private var now = Date()
    @State private var isExpanded = false

    init(task: UserTask, fontSize: CGFloat = 32) {
        self.task = task
        self.fontSize = fontSize
    }

    var body: some View {
        Image(systemName: task.isActive ? "pause.circle.fill" : "play.circle.fill")
            .font(.system(size: fontSize))
            .foregroundColor(task.isActive ? .red : .green)
            .scaleEffect(isExpanded ? 1.2 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.5), value: isExpanded)
            .onTapGesture {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.5)) {
                    isExpanded = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.5)) {
                        isExpanded = false
                    }
                }
                if task.isActive {
                    // Stop current task: mark inactive and end the active time entry
                    task.isActive = false
                    let endDate = Date()

                    // End the currently active (open) entry for this task
                    if let entries = task.timeEntries {
                        if let openIndex = entries.firstIndex(where: { $0.endTime == .distantFuture }) {
                            entries[openIndex].endTime = endDate
                        }
                    }
                } else {
                    task.isActive = true
                    // Stop all other active tasks and close their open entries
                    let currentTaskID = task.id
                    let descriptor = FetchDescriptor<UserTask>(predicate: #Predicate { $0.isActive && $0.id != currentTaskID })
                    if let activeTasks = try? modelContext.fetch(descriptor) {
                        for otherTask in activeTasks {
                            otherTask.isActive = false
                            if let otherEntries = otherTask.timeEntries,
                               let openIndex = otherEntries.firstIndex(where: { $0.endTime == .distantFuture }) {
                                otherEntries[openIndex].endTime = Date()
                            }
                        }
                    }

                    // Start this task: mark active and create a new open time entry
                    // Create a new open time entry with current start time
                    let newEntry = TimeEntry()
                    newEntry.startTime = Date()
                    newEntry.endTime = .distantFuture

                    if task.timeEntries == nil {
                        task.timeEntries = [TimeEntry]()
                    }
                    task.timeEntries?.insert(newEntry, at: 0)
                }
                try? modelContext.save()
            }
    }
}

struct TimeCounterView: View {
    @Bindable var task: UserTask
    var fontSize: CGFloat = 32
    
    @State private var currentTime = Date()
    @State private var tickerTask: Task<Void, Never>? = nil
 
    private var elapsedTime: TimeInterval {
        let entries = task.timeEntries ?? []
        var total: TimeInterval = 0
        for entry in entries {
            let endDate = (entry.endTime == .distantFuture) ? currentTime : entry.endTime
            total += max(0, endDate.timeIntervalSince(entry.startTime))
        }
        return total
    }

    private var formattedTime: String {
        let seconds = Int(ceil(elapsedTime))
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, secs)
    }

    var body: some View {
        Text(formattedTime)
            .font(.system(size: fontSize, design: .monospaced))
            .onAppear {
                tickerTask = Task {
                    while !Task.isCancelled {
                        await MainActor.run {
                            currentTime = Date()
                        }
                        try? await Task.sleep(for: .seconds(1))
                    }
                }
            }
            .onDisappear {
                tickerTask?.cancel()
                tickerTask = nil
            }
    }
}

