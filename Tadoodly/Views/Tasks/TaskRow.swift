import SwiftUI
import SwiftData

struct TaskRow: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var router: NavigationRouter
    @Bindable var task: UserTask
    
    private var completedCount: Int { task.taskItems?.filter { $0.completed }.count ?? 0 }
    private var totalCount: Int { task.taskItems?.count ?? 0 }
    
    init(task: UserTask) {
        self.task = task
        
    }
    
    var body: some View {
        
        HStack(alignment: .top) {
            
            if let project = task.project {
                Rectangle()
                    .fill((!project.color.isEmpty ? colorFromString(project.color) : Color(.darkGray)))
                    .frame(width: 10)
                    .padding(.vertical, 0)
                    .opacity(task.completed ? 0.5 : 1)
            } else {
                Rectangle()
                    .fill(.gray)
                    .frame(width: 10)
                    .padding(.trailing, 6)
            }
            
            
            VStack(alignment: .leading, spacing: 10) {
                
                StatusChipView(task: task)
                
                Text(task.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                    .truncationMode(.tail)
                
                HStack(spacing: 14) {

                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle")
                        Text("\(completedCount)/\(totalCount)")
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "flag")
                        Text(task.priority?.rawValue ?? "")
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    
                    if let dueDate = task.dueDate {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                            Text("Due \(dueDate, format: .dateTime.month(.abbreviated).day())")
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    }
                    
                    if let project = task.project {
                        HStack(spacing: 4) {
                            Image(systemName: project.icon)
                            Text(project.name.count > 10 ? String(project.name.prefix(10)) + "…" : project.name)
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .onTapGesture {
                            router.navigate(Route.viewProject(project))
                        }
                    }
                    
                    Spacer()
                }
                
            }
            .padding(.vertical)
            .padding(.leading)
           
            Spacer()
            
            VStack(alignment: .trailing) {
                if task.isActive {
                    Image(systemName: "play.circle")
                        .foregroundColor(.secondary)
                        .padding()
                }
            }
            .padding(.leading)
        }
    }
}


#Preview(traits: .sizeThatFitsLayout) {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: UserTask.self, Project.self, TimeEntry.self, configurations: config)
    let modelContext = container.mainContext
    
    let project = Project(name: "Work", color: "blue")
    modelContext.insert(project)
    
    let task = UserTask(title: "Sample Task", project: project)
    task.priority = TaskPriority.low
    task.isActive = true
    modelContext.insert(task)
    
    return TaskRow(task: task)
        .modelContainer(container)
}

