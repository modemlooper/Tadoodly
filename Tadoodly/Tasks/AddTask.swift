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
    
    @State private var hasUnsavedChanges = false
    @State private var showUnsavedChangesAlert = false
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
            
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    saveTask()
                }
                .disabled(workingTask.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
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
        .alert("Unsaved Changes", isPresented: $showUnsavedChangesAlert) {
            Button("Discard Changes", role: .destructive) {
                dismiss()
            }
            Button("Keep Editing", role: .cancel) { }
        } message: {
            Text("You have unsaved changes. Discard changes or save.")
        }
        .onDisappear {
            print("AddTask view disappeared")
        }
    }
    
    private var titleSection: some View {
        Section() {
            TextField("Title (required)", text: $workingTask.title)
                .onChange(of: workingTask.title) { hasUnsavedChanges = true }
            
            TextField("Description", text: Binding(
                get: { workingTask.taskDescription ?? "" },
                set: { workingTask.taskDescription = $0.isEmpty ? nil : $0 }
            ), axis: .vertical)
            .lineLimit(3...6)
            .onChange(of: workingTask.taskDescription) { hasUnsavedChanges = true }
            
            HStack {
                if let dueDate = workingTask.dueDate {
                    DatePicker(
                        "Due Date",
                        selection: Binding(
                            get: { dueDate },
                            set: { newValue in
                                workingTask.dueDate = newValue
                                hasUnsavedChanges = true
                            }
                        ),
                        displayedComponents: .date
                    )
                    .datePickerStyle(.compact)
                    
                    Button("Clear") {
                        workingTask.dueDate = nil
                        hasUnsavedChanges = true
                    }
                    .foregroundColor(.red)
                } else {
                    Button("Add Due Date") {
                        workingTask.dueDate = Date()
                        hasUnsavedChanges = true
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
        .onChange(of: workingTask.status) { hasUnsavedChanges = true }
    }
    
    private var prioritySection: some View {
        Picker("Priority", selection: $workingTask.priority) {
            ForEach(TaskPriority.allCases, id: \.self) { priority in
                Text(priority.rawValue).tag(priority as TaskPriority?)
            }
        }
        .onChange(of: workingTask.priority) { hasUnsavedChanges = true }
    }
    
    private var completedSection: some View {
        Toggle(isOn: $workingTask.completed) {
            Text("Completed")
        }
        .onChange(of: workingTask.completed) {
            workingTask.status = .done
            hasUnsavedChanges = true
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
        .onChange(of: workingTask.project) { hasUnsavedChanges = true }
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
                hasUnsavedChanges = true
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
                                hasUnsavedChanges = true
                            }
                        ))
                        .focused($focusedItemIndex, equals: idx)
                        
                        Button(action: {
                            workingTask.taskItems?.remove(at: idx)
                            hasUnsavedChanges = true
                        }) {
                            Image(systemName: "minus.circle.fill")
                                .foregroundColor(.red)
                                .font(.headline)
                        }
                    }
                }
            }
        }
        .onAppear() {
            hasUnsavedChanges = false
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
        if hasUnsavedChanges {
            showUnsavedChangesAlert = true
        } else {
            dismiss()
        }
    }
    
    // MARK: - Save Task
    private func saveTask() {
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
            hasUnsavedChanges = false
        } catch {
            // Replace with your UI error handling if desired
            print("Failed to save model context: \(error)")
        }
    }
}
