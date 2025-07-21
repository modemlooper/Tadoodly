//
//  ProjectDetailsView.swift
//  Tadoodly
//
//  Created by modemlooper on 6/12/25.
//

import SwiftUI
import SwiftData

struct ProjectDetailsView: View {
    
    @EnvironmentObject private var router: NavigationRouter
    @Environment(\.modelContext) private var modelContext: ModelContext
    
    @Query private var allTasks: [UserTask]
    
    var project: Project
    
    @State private var showingDeleteConfirmation: Bool = false
    @State private var pendingDeleteOffsets: IndexSet = []
    
    var filteredTasks: [UserTask] {
        allTasks.filter { $0.project?.id == project.id }
    }
    
    private var completedCount: Int { project.tasks?.filter { $0.completed }.count ?? 0 }
    private var totalCount: Int { project.tasks?.count ?? 0 }
    
    var body: some View {
        
        List {
            Section {
                VStack(alignment:.leading, spacing: 25) {
                    // Title
                    Text(project.name)
                        .font(.title3)
                        .fontWeight(.semibold)

                    // Description
                    if ( !project.projectDescription.isEmpty ) {
                        Text(project.projectDescription)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack(spacing: 18) {
                        
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle")
                            Text("\(completedCount)/\(totalCount)")
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                            Text("Due \(project.dueDate, format: .dateTime.month(.abbreviated).day())")
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        
                        HStack(spacing: 4) {
                            Image(systemName: "flag")
                            Text("\(project.status)")
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        
                    }
                    
                    Divider()
              
                    HStack {
                        Text("Tasks")
                            .font(.headline)
                        Spacer()
                        if let items = project.tasks {
                            let completed = items.filter { $0.completed }.count
                            Text("\(completed)/\(items.count)")
                                .font(.subheadline)
                                .foregroundStyle(.gray)
                        }
                    }
                    
                    if filteredTasks.isEmpty == true {
                        
                        VStack(alignment: .center, spacing: 20) {
                            Text("There are no tasks.")
                                .font(.title3)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                            Button {
                                router.navigate(Route.editProject(project))
                            } label: {
                                Text("Add Task")
                                   
                            }
                            .foregroundColor(.accentColor)
                            .frame(maxWidth: .infinity, alignment: .center)
                        }
                        .padding(.vertical, 28)
                    }
                }
            }
            .listRowSeparator(.hidden)
            
            ForEach(filteredTasks, id: \.id) { task in
                ZStack {
                    TaskRowView(
                        task: task,
                        sortedTasks: filteredTasks,
                        askDeleteConfirmation: askDeleteConfirmation
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                    .onTapGesture(count: 2) {
                        router.navigate(Route.editTask(task))
                    }
                    .onTapGesture(count: 1) {
                        router.navigate(Route.viewTask(task))
                    }
                }
                .listRowInsets(.init())
            }
        }
        .animation(.default, value: filteredTasks)
        .scrollIndicators(.hidden)
        .listStyle(.plain)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit") {
                    router.navigate(Route.editProject(project))
                }
            }
        }
        .alert("Confirm Delete", isPresented: $showingDeleteConfirmation, actions: {
            Button("Delete", role: .destructive) {
                deleteTasks(offsets: pendingDeleteOffsets, filteredTasks: filteredTasks)
            }
            Button("Cancel", role: .cancel) {
                pendingDeleteOffsets = IndexSet()
            }
        }, message: {
            Text("Are you sure you want to delete the selected task(s)?")
        })
    }
    
    private func askDeleteConfirmation(offsets: IndexSet) {
        pendingDeleteOffsets = offsets
        showingDeleteConfirmation = true
    }
    
    private func deleteTasks(offsets: IndexSet, filteredTasks: [UserTask]) {
        withAnimation {
            for offset in offsets {
                guard offset < filteredTasks.count else { continue }
                let task = filteredTasks[offset]
                modelContext.delete(task)
            }
            pendingDeleteOffsets = IndexSet()
            showingDeleteConfirmation = false
        }
    }
}

#Preview {
    let container = try! ModelContainer(for: Project.self, UserTask.self, configurations: .init(isStoredInMemoryOnly: true))
    let sampleProject = Project(name: "Preview Project", description: "A test project for previewing.", color: "blue")
    let sampleTask1 = UserTask(title: "Sample Task 1", project: sampleProject, description: "This is the first sample task.")
    let sampleTask2 = UserTask(title: "Sample Task 2", project: sampleProject, description: "This is the second sample task.")
    container.mainContext.insert(sampleProject)
    container.mainContext.insert(sampleTask1)
    container.mainContext.insert(sampleTask2)
    
    return ProjectDetailsView(project: sampleProject)
        .environmentObject(NavigationRouter())
        .modelContainer(container)
}
