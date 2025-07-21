//
//  TaskView.swift
//  Tadoodly
//
//  Created by modemlooper on 7/5/25.
//

import SwiftUI
import SwiftData

struct TaskView: View {
    
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var router: NavigationRouter
    
    let task: UserTask?
    
    private var chipColor: Color {
        switch task!.status {
        case .inProgress:
            return .green
        case .onHold:
            return .yellow
        case .cancelled:
            return .red
        default:
            return .blue
        }
    }
    
    var body: some View {
      
            ScrollView {
                VStack(alignment:.leading, spacing: 10) {
                    
                    HStack(alignment: .top) {
                        
                        VStack(alignment:.leading, spacing: 25) {
                            
                            // Status badge
                            StatusChipView(task: task!)
                            
                            // Title
                            Text(task?.title ?? "")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .fixedSize(horizontal: false, vertical: true)
                            
                            // Description
                            Text(task?.taskDescription ?? "")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                            
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            TimeCounterView(
                                task: task!,
                                fontSize: 18
                            )
                            
                            TimeButtonView(
                                task: task!,
                                fontSize: 48
                            )
                        }
                    }
                    
                    // Metadata
                    
                    HStack(spacing: 18) {
                        
                        HStack(spacing: 4) {
                            Image(systemName: "flag")
                            Text(task?.priority?.rawValue ?? "")
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        
                        
                        if let dueDate = task?.dueDate {
                            HStack(spacing: 4) {
                                Image(systemName: "calendar")
                                Text("Due \(dueDate, format: .dateTime.month(.abbreviated).day())")
                            }
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        }
                        
               
                        if let project = task?.project {
                            HStack(spacing: 4) {
                                Image(systemName: "folder")
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
                    }
                    .padding(.top, 12)
                    .padding(.bottom, 6)
                    
                    
                    Divider()
                    
                    // Checklist header
                    HStack {
                        Text("Checklist")
                            .font(.headline)
                        Spacer()
                        if let items = task?.taskItems {
                            let completed = items.filter { $0.completed }.count
                            Text("\(completed)/\(items.count)")
                                .font(.subheadline)
                                .foregroundStyle(.gray)
                        }
                    }
                    .padding(.top)
                    // Checklist items
                    VStack(spacing: 0) {
                        if let items = task?.taskItems {
                            ForEach(Array(items.enumerated()), id: \.offset) { idx, item in
                                HStack(alignment: .center, spacing: 12) {
                                    ZStack {
                                        Circle()
                                            .fill(item.completed ? Color.green : Color.clear)
                                            .frame(width: 28, height: 28)
                                            .overlay(Circle().stroke(Color.gray, lineWidth: item.completed ? 0 : 1))
                                        if item.completed {
                                            Image(systemName: "checkmark")
                                                .foregroundColor(.white)
                                        }
                                    }
                                    
                                    Text(item.title)
                                        .font(.body)
                                        .fixedSize(horizontal: false, vertical: true)
                                    Spacer()
                                }
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    withAnimation {
                                        item.completed.toggle()
                                        // If extra persistence handling is needed, add here
                                    }
                                }
                                .padding(.vertical, 8)
                                if idx != items.count - 1 {
                                    Divider()
                                        .background(Color.gray.opacity(0.4))
                                        .padding(.leading, 40)
                                }
                            }
                        }
                    }
                    
                    if task?.taskItems?.isEmpty == true {
                        
                        VStack(alignment: .center, spacing: 20) {
                            Text("There are no items.")
                                .font(.title3)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                            Button {
                                router.navigate(Route.editTask(task!))
                            } label: {
                                Text("Add Item")
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                        }
                        .padding(.vertical, 28)
                    }
                    
                    Spacer()
                }
                .padding(24)
            
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        router.navigate(Route.editTask(task!))
                    } label: {
                        Text("Edit")
                    }

                }
            }
    }
}


#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: UserTask.self, Project.self, TaskItem.self, configurations: config)
    
    // Create a sample project
    let project = Project(name: "Preview Project", color: "blue")
    container.mainContext.insert(project)
    
    // Create a sample task
    let task = UserTask(title: "Sample Preview Task", project: project, description: "A preview task for TaskView.")
    task.status = TaskStatus.inProgress
    task.priority = TaskPriority.high
    task.taskDescription = "taskDescription this is a task description its the best task on the planet."
    
    // Create a couple of checklist items
    let item1 = TaskItem(title: "First checklist item")
    item1.completed = true
    let item2 = TaskItem(title: "Second checklist item")
    task.taskItems = [item1, item2]
    
    return TaskView(task: task)
        .modelContainer(container)
}

