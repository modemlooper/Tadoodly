//
//  ProjectDetail.swift
//  Tadoodly
//
//  Created by modemlooper on 9/9/25.
//

import SwiftUI
import SwiftData

struct ProjectDetail: View {
    
    @Environment(\.modelContext) private var modelContext
    @Binding var path: NavigationPath
    
    var project: Project
    
    @State private var showingDeleteConfirmation: Bool = false
    @State private var pendingDeleteOffsets: IndexSet = []
    @State private var isAddItemShowing: Bool = false
    
    private var completedCount: Int { (project.tasks ?? []).filter { $0.completed }.count }
    private var totalCount: Int { (project.tasks ?? []).count }
        
    var body: some View {
        
        ScrollView {
            VStack(alignment:.leading, spacing: 20) {
                
                HStack(alignment: .top) {
                    
                    VStack(alignment:.leading, spacing: 0) {
                        
                        // Title
                        Text(project.name)
                            .font(.title3)
                            .fontWeight(.semibold)
                        
                        // Description
                        if let desc = project.projectDescription, !desc.isEmpty {
                            Text(desc)
                                .font(.body)
                                .foregroundColor(.secondary)
                                .padding(.top, 10)
                        }
                        
                    }
                    
                    Spacer()
                }
              
                
                HStack(spacing: 18) {
                    
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle")
                        Text("\(completedCount)/\(totalCount)")
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    
                    if let due = project.dueDate {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                            Text("Due \(due, format: .dateTime.month(.abbreviated).day())")
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: "flag")
                        Text("\(project.status)")
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    
                }
            }
            .padding(12)
            
            Divider()
            
            if let tasks = project.tasks, !tasks.isEmpty {
                VStack(alignment: .leading, spacing: 3) {
                    ForEach(tasks) { task in
                        TaskRow(task: task)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets())
                            .contentShape(Rectangle())
                            .onTapGesture(count: 2) {
                                // Double-tap: go to edit
                                path.append(AddTaskRoute(task: task))
                            }
                            .onTapGesture {
                                // Single-tap: go to detail
                                path.append(task)
                            }
                    }
                }
            } else {
                ContentUnavailableView(
                    "No Tasks",
                    systemImage: "checklist",
                    description: Text("Get started by adding a task.")
                )
                .padding(.top, 40)
                
                Button {
                    // Create a new task and add it to the project
                    let newTask = UserTask()
                    
                    // Associate the task with this project
                    // If Project has a tasks relationship, append the new task
                    if project.tasks == nil {
                        project.tasks = []
                    }
                    project.tasks?.append(newTask)
                    
                    // If your model requires insertion into the context explicitly, uncomment:
                    // modelContext.insert(newTask)
                    
                    // Navigate to add/edit task route
                    path.append(AddTaskRoute(task: newTask))
                } label: {
                    Text("Add Task")
                }

            }
        }
        .scrollIndicators(.hidden)
        .listRowInsets(EdgeInsets())
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                NavigationLink(value: AddProjectRoute(project: project)) {
                    Text("Edit")
                }
            }
        }
    }
}

