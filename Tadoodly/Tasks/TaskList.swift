import SwiftUI
import SwiftData

struct TaskList: View {
    @Environment(\.modelContext) private var modelContext
    
    @Query private var tasks: [UserTask]

    @Binding var path: NavigationPath
    @Binding var selectedSortOption: TaskListSortOption
    
    @State private var showingAddTask = false
    @State private var showingOptionsPopover = false
    @State private var showingProjectAssist = false
    @State private var isSortDisclosureExpanded = false
    @State private var isExpanded = false
    @State private var scrollToTopTrigger: Bool = false
    
    @State private var showCompleted: Bool = false
    @AppStorage("showCompleted") private var showCompletedSetting: Bool = false
    
    // Computed property to sort tasks based on selected option
    private var sortedTasks: [UserTask] {
        // Filter based on persisted setting: hide completed unless showCompletedSetting is true
        let visibleTasks = showCompletedSetting ? tasks : tasks.filter { !$0.completed }
        switch selectedSortOption {
        case .updateAt:
            return visibleTasks.sorted { ($0.updatedAt) > ($1.updatedAt) }
        case .createdAt:
            return visibleTasks.sorted { $0.createdAt > $1.createdAt }
        case .dueDate:
            return visibleTasks.sorted { task1, task2 in
                switch (task1.dueDate, task2.dueDate) {
                case (nil, nil): return false
                case (nil, _): return false
                case (_, nil): return true
                case let (date1?, date2?): return date1 < date2
                }
            }
        case .priority:
            return visibleTasks.sorted { task1, task2 in
                let priority1 = task1.priority?.sortOrder ?? -1
                let priority2 = task2.priority?.sortOrder ?? -1
                return priority1 > priority2
            }
        case .title:
            return visibleTasks.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        case .status:
            return visibleTasks.sorted { task1, task2 in
                let status1 = task1.status?.rawValue ?? ""
                let status2 = task2.status?.rawValue ?? ""
                return status1.localizedCaseInsensitiveCompare(status2) == .orderedAscending
            }
        case .projectName:
            return visibleTasks.sorted { task1, task2 in
                let project1 = task1.project?.name ?? ""
                let project2 = task2.project?.name ?? ""
                return project1.localizedCaseInsensitiveCompare(project2) == .orderedAscending
            }
        }
    }
    
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
                            ForEach(sortedTasks, id: \.id) { task in
                                NavigationLink(value: task) {
                                    TaskRow(task: task)
                                        .contentShape(Rectangle())
                                    // Recognize double-tap with higher priority than the link's single tap
                                        .highPriorityGesture(
                                            TapGesture(count: 2).onEnded {
                                                // Navigate to edit on double-tap
                                                //path.append(task)
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
                    Button {
                        showingProjectAssist = true
                    } label: {
                        Label("AI Assist", systemImage: "sparkles")
                    }
                    .sheet(isPresented: $showingProjectAssist) {
                        ProjectAssistSheet()
                            .presentationDetents([.large])
                            .presentationDragIndicator(.visible)
                    }
                }
               
                ToolbarSpacer()
                
            #endif
                
                ToolbarItem {
                    Button {
                        isSortDisclosureExpanded = false
                        showingOptionsPopover = true
                    } label: {
                        Label("View Options", systemImage: "line.3.horizontal.decrease")
                    }
                    .popover(isPresented: $showingOptionsPopover) {
                        TaskListOptionsPopover(
                            selectedSortOption: $selectedSortOption,
                            isExpanded: $isExpanded,
                            isPopoverPresented: $showingOptionsPopover, path: $path
                        )
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
                
                HStack(alignment: .top) {
                    StatusChip(task: task)
                    Spacer()
                    if task.isActive {
                        Image(systemName: "play.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
                
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
            .padding(.horizontal)
            .padding(.top)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
