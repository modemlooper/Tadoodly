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
                    task.stopTimer()
                    now = Date()
                } else {
                    // Stop all other active tasks
                    let currentTaskID = task.id
                    let descriptor = FetchDescriptor<UserTask>(predicate: #Predicate { $0.isActive && $0.id != currentTaskID })
                    if let activeTasks = try? modelContext.fetch(descriptor) {
                        for otherTask in activeTasks {
                            otherTask.stopTimer()
                        }
                    }
                    task.startTimer()
                }
                try? modelContext.save()
            }
    }
}

struct TimeCounterView: View {
    @Bindable var task: UserTask
    var fontSize: CGFloat = 32
    
    @State private var currentTime = Date()
 
    private var elapsedTime: TimeInterval {
        let entries = task.timeEntries ?? []
        let completedDuration = entries.filter { $0.endTime != nil }.reduce(0) { $0 + $1.duration }
        if let activeEntry = entries.first(where: { $0.endTime == nil }) {
            return completedDuration + currentTime.timeIntervalSince(activeEntry.startTime)
        } else {
            return completedDuration
        }
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
            .padding(.bottom, 15)
            .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { now in
                currentTime = now
            }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: UserTask.self, Project.self, TimeEntry.self, configurations: config)
    let context = container.mainContext
    
    let project = Project(name: "Preview Project", color: "red")
    context.insert(project)
    let sampleTask = UserTask(title: "Preview Task", project: project, description: "A task for previews.")
    sampleTask.priority = .medium
    context.insert(sampleTask)
    
    return VStack(spacing: 24) {
        TimeCounterView(task: sampleTask, fontSize: 32)
        TimeButtonView(task: sampleTask, fontSize: 48)
    }
    .padding()
    .modelContainer(container)
}
