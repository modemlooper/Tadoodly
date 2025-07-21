//
//  ProjectsView.swift
//  Tadoodly
//
//  Created by modemlooper on 6/4/25.
//

import SwiftUI
import SwiftData

struct ProjectsView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var router: NavigationRouter
    
    @Query(sort: [SortDescriptor(\Project.name, order: .forward)]) private var projects: [Project]
    @State private var pendingDeleteOffsets: IndexSet? = nil
    @State private var showingDeleteConfirmation = false
    
    func deleteProjects(offsets: IndexSet) {
        for index in offsets {
            let project = projects[index]
            modelContext.delete(project)
        }
    }
    
    func askDeleteConfirmation(offsets: IndexSet) {
        pendingDeleteOffsets = offsets
        showingDeleteConfirmation = true
    }
    
    var body: some View {
        Group {
            if projects.isEmpty {
                VStack(spacing: 16) {
                    Text("No projects created.")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                    Button(action: { router.path.append(Route.addProject) }) {
                        Text("Add Project")
                           
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    ForEach(projects) { project in
                        ProjectCard(project: project)
                            .contentShape(Rectangle())
                            .onTapGesture(count: 1) {
                                router.navigate(Route.viewProject(project))
                            }
                            .onTapGesture(count: 2) {
                                router.navigate(Route.editProject(project))
                            }
                        Divider()
                    }
                    .onDelete(perform: askDeleteConfirmation)
                }
                .scrollIndicators(.hidden)
            }
        }
        .navigationTitle("Projects")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { router.path.append(Route.addProject) }) {
                    Label("Add Project", systemImage: "plus")
                }
            }
        }
        .alert("Are you sure you want to delete the selected project?", isPresented: $showingDeleteConfirmation, actions: {
            if let offsets = pendingDeleteOffsets {
                Button("Delete", role: .destructive) {
                    deleteProjects(offsets: offsets)
                }
            }
            Button("Cancel", role: .cancel) { }
        })
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: UserTask.self, Project.self, TimeEntry.self, configurations: config)
//    let modelContext = container.mainContext
//    let project = Project(name: "Work", color: "blue")
//    modelContext.insert(project)
//    let task = UserTask(title: "Sample Task", project: project)
//    task.priority = TaskPriority.low
//    modelContext.insert(task)
    return AnyView(
        NavigationStack {
            ProjectsView()
                .modelContainer(container)
                .environmentObject(NavigationRouter())
        }
    )
}
