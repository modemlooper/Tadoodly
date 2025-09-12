//
//  AddProject.swift
//  Tadoodly
//
//  Created by modemlooper on 9/9/25.
//

import SwiftUI
import SwiftData

struct AddProject: View {
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var project: Project?
    
    @Binding var path: NavigationPath
    
    @State private var showingDeleteAlert = false
    @State private var showingTaskDeleteAlert = false
    @State private var showingCopyAlert = false
    @State private var taskToDelete: UserTask? = nil

    @FocusState private var focusedTaskIndex: Int?

    @State private var showNameRequiredUnsavedAlert = false
    @State private var showSaveProjectFirstAlert = false
    
    @State private var isAddItemShowing: Bool = false
    @State private var showSymbolPicker: Bool = false
    
    @State private var workingProject = Project()
        
    var body: some View {
        Form {
            projectDetailsSection
            StatusSection
            ColorSection
            AddTaskSection
        }
        .onAppear() {
            if let project = project {
                // Copy values from existing project to our working project
                workingProject = project
            } else {
          
            }
            
        }
        .alert("Are you sure you want to duplicate this project?", isPresented: $showingCopyAlert, actions: {
            Button("Duplicate", role: .destructive) {
                if let project = project {
                    // Manually duplicate the project since `copy(modelcontext:)` doesn't exist
                    let duplicate = Project()
                    // Copy scalar properties
                    duplicate.name = project.name + " Copy"
                    duplicate.projectDescription = project.projectDescription
                    duplicate.dueDate = project.dueDate
                    duplicate.status = project.status
                    duplicate.priority = project.priority
                    duplicate.color = project.color
                    duplicate.icon = project.icon

                    // Deep copy tasks if any
                    if let tasks = project.tasks, !tasks.isEmpty {
                        var newTasks: [UserTask] = []
                        newTasks.reserveCapacity(tasks.count)
                        for task in tasks {
                            let newTask = UserTask()
                            newTask.title = task.title
                            newTask.isCompleted = task.isCompleted
                            newTask.dueDate = task.dueDate
                            newTask.priority = task.priority
                            newTasks.append(newTask)
                        }
                        duplicate.tasks = newTasks
                    }

                    // Insert and save
                    modelContext.insert(duplicate)
                    try? modelContext.save()
                }
                path = NavigationPath()
            }
            
            Button("Cancel", role: .cancel) { }
        })
        .alert("Are you sure you want to delete this project?", isPresented: $showingDeleteAlert, actions: {
            Button("Delete", role: .destructive) {
                if let project = project {
                    modelContext.delete(project)
                    try? modelContext.save()
                    
                }
                path = NavigationPath()
            }
            Button("Cancel", role: .cancel) {}
        })
        .toolbar {
            
            if project != nil {
                ToolbarItem(placement: .automatic) {
                    Button {
                        handleCopyTap()
                    } label: {
                        Label("Duplicate", systemImage: "document.on.document")
                    }
                }
            }
            
            if project != nil {
                ToolbarItem(placement: .automatic) {
                    Button {
                        handleDeleteTap()
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
                        
            // Custom back button that replaces the system one
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    handleBackButtonTap()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 17, weight: .medium))
                        
                    }
                    .foregroundColor(.primary)
                }
            }
        }
        .navigationBarBackButtonHidden(true)

    }
    
    private var projectDetailsSection: some View {
        Section() {
            TextField(
                "Project Name",
                text: Binding<String>(
                    get: { workingProject.name },
                    set: { newValue in
                        workingProject.name = newValue
                    }
                )
            )
         
            TextField(
                "Description (Optional)",
                text: Binding<String>(
                    get: { workingProject.projectDescription ?? "" },
                    set: { newValue in
                        workingProject.projectDescription = newValue
                    }
                ),
                axis: .vertical
            )
            .lineLimit(3...6)
            
            HStack {
                if let dueDate = workingProject.dueDate {
                    DatePicker("Due Date",
                               selection: Binding(
                                   get: { dueDate },
                                   set: { newValue in
                                       workingProject.dueDate = newValue
                                   }
                               ),
                               displayedComponents: .date
                    )
                    .datePickerStyle(.compact)
                    Button("Clear") {
                        workingProject.dueDate = nil
                    }
                    .foregroundColor(.red)
                } else {
                    Button("Add Due Date") {
                        workingProject.dueDate = Date()
                    }
                    .foregroundColor(.accentColor)
                }
            }

        }
    }
    
    private var StatusSection: some View {
        Section {
            Picker("Status", selection: $workingProject.status) {
                ForEach(ProjectStatus.allCases) { statusOption in
                    Text(statusOption.rawValue).tag(statusOption)
                }
            }

            Picker("Priority", selection: $workingProject.priority) {
                ForEach(ProjectPriority.allCases) { priorityOption in
                    Text(priorityOption.rawValue).tag(priorityOption)
                }
            }

        }
    }

    private var ColorSection: some View {
        Section("Icon Color") {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 12) {
                ForEach(colors, id: \.self) { color in
                    ZStack {
                        Circle()
                            .fill(colorFromString(color))
                            .frame(width: 40, height: 40)
                            .onTapGesture {
                                workingProject.color = color
                            }
                        if (workingProject.color == color) {
                            Image(systemName: "checkmark")
                                .foregroundColor(.white)
                        }
                    }
                }
            }
            
            // Custom row with your own chevron; no default accessory
            Button {
                showSymbolPicker = true
            } label: {
                HStack {
                    Text("Icon")
                    Spacer()
                    HStack(spacing: 8) {
                        Image(systemName: (workingProject.icon.isEmpty == false ? workingProject.icon : "folder"))
                            .foregroundColor(.accentColor)
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .sheet(isPresented: $showSymbolPicker) {
            SFSymbolPicker(
                selectedSymbol: Binding(
                    get: { workingProject.icon },
                    set: { newValue in
                        workingProject.icon = newValue
                    }
                )
            )
        }
    }
    
    private var AddTaskSection: some View {
        Section(header:
                    Text("Tasks")
        ) {

            Button(action: handleAddTaskTap) {
                Text("Add Task")
                    .foregroundColor(.accentColor)
            }.buttonStyle(.plain)

            ForEach(workingProject.tasks ?? [], id: \.id) { task in
                HStack() {
                    Text(task.title)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.subheadline)
                        .foregroundColor(.secondary).opacity(0.8)
                }
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
                .onTapGesture {
                   
                }
            }
        }
    
    }
    
    private func handleAddTaskTap() {

    }
    
    private func handleCopyTap() {
        showingCopyAlert = true
    }
    
    private func handleDeleteTap() {
        showingDeleteAlert = true
    }
    
    // MARK: - Back Button Handling
    private func handleBackButtonTap() {
        let nameIsEmpty = workingProject.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        
        // If creating a new project and the name is empty, just go back without saving
        if project == nil && nameIsEmpty {
            dismiss()
            return
        }
        
        // Otherwise, save the working project
        if project == nil {
            // New project with a non-empty name: insert then save
            modelContext.insert(workingProject)
        } else {
            // Editing existing project: ensure changes are persisted
            // (workingProject already points to the existing model)
        }
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            // Handle save error: keep the view open and optionally present an alert/log
            print("Failed to save project: \(error)")
        }
    }
 
}
