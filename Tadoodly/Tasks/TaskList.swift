import SwiftUI
import SwiftData

struct TaskList: View {
    @Environment(\.modelContext) private var modelContext
    
    @Query private var tasks: [UserTask]
    @Binding var path: NavigationPath
    
    var body: some View {
        ScrollViewReader { proxy in
            Group {
                if tasks.isEmpty {
                    GeometryReader { proxy in
                        ScrollView {
                            VStack {
                                Spacer(minLength: 0)
                                ContentUnavailableView(
                                    "No Tasks",
                                    systemImage: "checklist",
                                    description: Text("Get started by adding a task.")
                                )
                                Spacer(minLength: 0)
                            }
                            .frame(maxWidth: .infinity, minHeight: (proxy.size.height - 60)) // context-aware height
                        }
                        .scrollIndicators(.hidden)
                    }
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 3) {
                            ForEach(tasks, id: \.id) { task in
                                NavigationLink(value: task) {
                                    TaskRow(task: task)
                                        .contentShape(Rectangle())
                                    // Recognize double-tap with higher priority than the link's single tap
                                        .highPriorityGesture(
                                            TapGesture(count: 2).onEnded {
                                                // Navigate to edit on double-tap
                                                path.append(AddTaskRoute(task: task))
                                            }
                                        )
                                }
                                .navigationLinkIndicatorVisibility(.hidden)
                                .tint(.primary)
                                .buttonStyle(.plain)
                                .listRowInsets(EdgeInsets())
                            }
                        }
                    }
                }
            }
            .navigationTitle("Tasks")
            .toolbar {
#if canImport(FoundationModels)
                ToolbarItem(placement: .automatic) {
                    if #available(iOS 26.0, *) {
                        Button {
                            
                        } label: {
                            Label("AI Assist", systemImage: "sparkles")
                        }
                    } else {
                        // Fallback on earlier versions
                    }
                }
                if #available(iOS 26.0, *) {
                    ToolbarSpacer()
                }
#endif
                ToolbarItem {
                    Button {
                        
                    } label: {
                        Label("View Options", systemImage: "line.3.horizontal.decrease")
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    NavigationLink(value: AddTaskRoute(task: nil)) {
                        Label("Add Task", systemImage: "plus")
                    }
                }
            }
        }
    }
}

struct TaskRow: View {
    let task: UserTask
    
    private var completedCount: Int { task.taskItems?.filter { $0.completed }.count ?? 0 }
    private var totalCount: Int { task.taskItems?.count ?? 0 }
    
    var body: some View {
        HStack(alignment: .top) {
            if let project = task.project {
                Rectangle()
                    .fill((!project.color.isEmpty ? colorFromString(project.color) : Color(.darkGray)))
                    .frame(width: 8)
                    .padding(.vertical, 0)
                    .opacity(task.completed ? 0.5 : 1)
            } else {
                Rectangle()
                    .fill(.gray)
                    .frame(width: 8)
                    .padding(.trailing, 6)
            }
            
            VStack(alignment: .leading, spacing: 15) {
                StatusChip(task: task)
                
                Text(task.title)
                    .font(.title3)
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
                            Text(project.name)
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .onTapGesture {
                        }
                    }
                    
                    Spacer()
                }
                
                Divider()
            }
            .padding(.leading)
            .padding(.top)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
