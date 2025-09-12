//
//  AddTaskView.swift
//  Tadoodly
//
//  Created by modemlooper on 9/8/25.
//

import SwiftUI
import SwiftData

struct AddTask: View {
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Query(sort: \Project.name) private var projects: [Project]
    
    var task: UserTask?
    
    @Binding var path: NavigationPath
    
    @State private var showingCopyAlert = false
    @State private var showingDeleteAlert = false
    @State private var showNameEmptyAlert = false
    @State private var showTitleRequiredUnsavedAlert = false
    @State private var showingDeleteTaskItemAlert = false
    @State private var indexToDeleteTaskItem: Int? = nil
    @FocusState private var focusedItemIndex: Int?
    
    // Working task instance
    @State private var workingTask = UserTask()
    
    var body: some View {
        
        Form {
            titleSection
            statusSection
            prioritySection
            completedSection
            projectSection
            checklistSection
        }
        .onAppear() {
            if let task = task {
                // Copy values from existing task to our working task
                workingTask = task
            } else {
                // Set defaults for new task
                workingTask.priority = .low
                workingTask.status = .todo
            }
            
        }
        .alert("Are you sure you want to duplicate this task?", isPresented: $showingCopyAlert, actions: {
            Button("Duplicate", role: .destructive) {
                if let task = task {
                    // Manually duplicate the task since `copy(modelcontext:)` doesn't exist
                    let newTask = UserTask()
                    newTask.title = task.title + " Copy"
                    newTask.taskDescription = task.taskDescription
                    newTask.dueDate = task.dueDate
                    newTask.priority = task.priority
                    newTask.status = task.status
                    newTask.completed = false
                    newTask.project = task.project
                    // Deep-copy checklist items if present
                    if let items = task.taskItems {
                        var cloned: [TaskItem] = []
                        cloned.reserveCapacity(items.count)
                        for item in items {
                            let newItem = TaskItem()
                            newItem.title = item.title
                            cloned.append(newItem)
                        }
                        newTask.taskItems = cloned
                    }
                    modelContext.insert(newTask)
                    try? modelContext.save()
                }
                path = NavigationPath()
            }
            
            Button("Cancel", role: .cancel) { }
        })
        .alert("Are you sure you want to delete this task?", isPresented: $showingDeleteAlert, actions: {
            Button("Delete", role: .destructive) {
                if let task = task {
                    modelContext.delete(task)
                    try? modelContext.save() // ensure persistence before popping
                    
                    path = NavigationPath()
                }
            }
            Button("Cancel", role: .cancel) {}
        })
        .toolbar {
            
            ToolbarItem(placement: .automatic) {
                Button {
                    handleCopyTap()
                } label: {
                    Label("Duplicate", systemImage: "document.on.document")
                }
            }
            
            ToolbarItem(placement: .automatic) {
                Button {
                    handleDeleteTap()
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
            
            if #available(iOS 26.0, *) {
                ToolbarSpacer()
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
    
    private var titleSection: some View {
        Section() {
            TextField("Title (required)", text: $workingTask.title)
            
            TextField("Description", text: Binding(
                get: { workingTask.taskDescription ?? "" },
                set: { workingTask.taskDescription = $0.isEmpty ? nil : $0 }
            ), axis: .vertical)
            .lineLimit(3...6)
            
            HStack {
                if let dueDate = workingTask.dueDate {
                    DatePicker(
                        "Due Date",
                        selection: Binding(
                            get: { dueDate },
                            set: { newValue in
                                workingTask.dueDate = newValue
                            }
                        ),
                        displayedComponents: .date
                    )
                    .datePickerStyle(.compact)
                    
                    Button("Clear") {
                        workingTask.dueDate = nil
                    }
                    .foregroundColor(.red)
                } else {
                    Button("Add Due Date") {
                        workingTask.dueDate = Date()
                    }
                    .foregroundColor(.accentColor)
                }
            }
        }
    }
    
    private var statusSection: some View {
        Picker("Status", selection: $workingTask.status) {
            ForEach(TaskStatus.allCases, id: \.self) { status in
                Text(status.rawValue).tag(status as TaskStatus?)
            }
        }
    }
    
    private var prioritySection: some View {
        Picker("Priority", selection: $workingTask.priority) {
            ForEach(TaskPriority.allCases, id: \.self) { priority in
                Text(priority.rawValue).tag(priority as TaskPriority?)
            }
        }
    }
    
    private var completedSection: some View {
        Toggle(isOn: $workingTask.completed) {
            Text("Completed")
        }
    }
    
    private var projectSection: some View {
        Picker("Project", selection: $workingTask.project) {
            Text("No Project").tag(nil as Project?)
            ForEach(projects, id: \.self) { project in
                Text(project.name).tag(project as Project?)
            }
        }
        .disabled(projects.isEmpty)
    }
    
    private var sectionHeader: some View {
        HStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "document.on.document")
                .font(.title2)
                .foregroundColor(.secondary)
                .onTapGesture {
                    showingCopyAlert = true
                }
            
            Image(systemName: "trash")
                .font(.title2)
                .foregroundColor(.red)
                .onTapGesture {
                    showingDeleteAlert = true
                }
        }
        .frame(maxWidth: .infinity)
    }
    
    private var checklistSection: some View {
        Section(header: Text("Checklist")) {
            Button(action: {
                let newItem = TaskItem()
                newItem.title = "Task Item"
                if workingTask.taskItems == nil {
                    workingTask.taskItems = []
                }
                workingTask.taskItems?.append(newItem)
                // Optionally focus the newly added item for quick editing
                focusedItemIndex = (workingTask.taskItems?.count ?? 1) - 1
            }) {
                Text("Add Item")
                    .foregroundColor(.accentColor)
            }.buttonStyle(.plain)
            
            if let taskItems = workingTask.taskItems {
                ForEach(taskItems.indices, id: \.self) { idx in
                    HStack {
                        TextField("Item title", text: Binding(
                            get: { taskItems[idx].title },
                            set: { newValue in
                                workingTask.taskItems?[idx].title = newValue
                            }
                        ))
                        .focused($focusedItemIndex, equals: idx)
                        
                        Button(action: {
                            workingTask.taskItems?.remove(at: idx)
                        }) {
                            Image(systemName: "minus.circle.fill")
                                .foregroundColor(.red)
                                .font(.headline)
                        }
                    }
                }
            }
        }
    
    }
    
    private func handleCopyTap() {
        showingCopyAlert = true
    }
    
    private func handleDeleteTap() {
        showingDeleteAlert = true
    }
    
    // MARK: - Back Button Handling
    private func handleBackButtonTap() {
        guard !workingTask.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            showNameEmptyAlert = true
            return
        }
        
        if task == nil {
            // Create new task
            modelContext.insert(workingTask)
        }
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            // Replace with your UI error handling if desired
            print("Failed to save model context: \(error)")
        }
    }
}

