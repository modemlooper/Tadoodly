//
//  AddTaskView.swift
//  Tadoodly
//
//  Created by modemlooper on 6/4/25.
//

import SwiftUI
import SwiftData

struct AddTaskView: View {
    
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var router: NavigationRouter
    @Environment(\.dismiss) private var dismiss
    
    @Query(sort: \Project.name) private var projects: [Project]
    
    @StateObject private var viewModel: AddTaskViewModel
    
    let task: UserTask?
    
    @State private var hasUnsavedChanges = false
    @State private var showUnsavedChangesAlert = false
    @State private var showNameEmptyAlert = false
    @State private var showingCopyAlert = false
    @State private var showingDeleteAlert = false
    @State private var showTitleRequiredUnsavedAlert = false
    @State private var showingDeleteTaskItemAlert = false
    @State private var indexToDeleteTaskItem: Int? = nil
    @FocusState private var focusedItemIndex: Int?
    
    init(task: UserTask?) {
        self.task = task
        _viewModel = StateObject(wrappedValue: AddTaskViewModel(task: task))
    }
    
    private var sectionHeader: some View {
        HStack(spacing: 16) {
            Spacer()
            if task != nil {
                let copyIcon = AnyView(
                    Image(systemName: "document.on.document")
                        .font(.title2)
                        .foregroundColor(.secondary)
                        .onTapGesture {
                            showingCopyAlert = true
                        }
                )
                let deleteIcon = AnyView(
                    Image(systemName: "trash")
                        .font(.title2)
                        .foregroundColor(.red)
                        .onTapGesture {
                            showingDeleteAlert = true
                        }
                )
                copyIcon
                deleteIcon
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    @ViewBuilder
    private var mainBody: some View {
        Form {
            titleSection
            
            statusSection
            
            prioritySection
            
            projectSection
            
            timeTrackingSection
            
            checklistSection
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    if hasUnsavedChanges {
                        if viewModel.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            showTitleRequiredUnsavedAlert = true
                        } else {
                            showUnsavedChangesAlert = true
                        }
                    } else {
                        dismiss()
                    }
                }) {
                    Image(systemName: "chevron.left")
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    saveTask()
                }
                .disabled(viewModel.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .alert("Are you sure you want to duplicate this task?", isPresented: $showingCopyAlert, actions: {
            Button("Duplicate", role: .destructive) {
                if let task = task {
                    task.copy(modelcontext: modelContext)
                    router.root()
                }
            }
        
            Button("Cancel", role: .cancel) { }
        })
        .alert("Are you sure you want to delete this task?", isPresented: $showingDeleteAlert, actions: {
            Button("Delete", role: .destructive) {
                if let task = task {
                    task.delete(modelcontext: modelContext)
                    router.root()
                }
            }
            Button("Cancel", role: .cancel) {}
        })
        .alert("You have unsaved changes.", isPresented: $showUnsavedChangesAlert) {
            Button("Save") {
                saveTask()
                dismiss()
            }
            Button("Discard", role: .destructive) {
                dismiss()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Would you like to save before leaving?")
        }
        .alert("The title field is required.", isPresented: $showTitleRequiredUnsavedAlert) {
            Button("Edit", role: .cancel) { }
            Button("Discard", role: .destructive) {
                dismiss()
            }
        } message: {
            Text("Please enter a title for your task or discard your changes.")
        }
    }
    
    var body: some View {
        mainBody
            .navigationTitle(task == nil ? "Add Task" : "Edit Task")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true) // Add this line
            .alert("The title field must be filled.", isPresented: $showNameEmptyAlert) {
                Button("OK", role: .cancel) { }
            }
    }
    
    // Extract title Section
    private var titleSection: some View {
        Section(header: sectionHeader) {
            TextField("Title (required)", text: $viewModel.name)
                .onChange(of: viewModel.name) { hasUnsavedChanges = true }
            TextField("Description", text: $viewModel.description, axis: .vertical)
                .lineLimit(3...6)
                .onChange(of: viewModel.description) { hasUnsavedChanges = true }
            
            HStack {
                if let dueDate = viewModel.dueDate {
                    DatePicker("Due Date", selection: Binding(
                          get: { dueDate },
                          set: { newValue in
                              viewModel.dueDate = newValue
                              hasUnsavedChanges = true
                          }
                        ), displayedComponents: .date)
                        .datePickerStyle(.compact)
                    Button("Clear") {
                        viewModel.dueDate = nil
                        hasUnsavedChanges = true
                    }
                    .foregroundColor(.red)
                } else {
                    Button("Add Due Date") {
                        viewModel.dueDate = Date()
                        hasUnsavedChanges = true
                    }
                    .foregroundColor(.accentColor)
                }
            }
        }
    }
    
    private var statusSection: some View {
        Picker("Status", selection: $viewModel.status) {
            ForEach(TaskStatus.allCases, id: \.self) { status in
                Text(status.rawValue).tag(status)
            }
        }
        .onChange(of: viewModel.status) { hasUnsavedChanges = true }
    }
    
    private var prioritySection: some View {
        Picker("Priority", selection: $viewModel.priority) {
            ForEach(TaskPriority.allCases, id: \.self) { priority in
                Text(priority.rawValue).tag(priority)
            }
        }
        .onChange(of: viewModel.priority) { hasUnsavedChanges = true }
    }
    
    private var projectSection: some View {
        Picker("Project", selection: $viewModel.selectedProject) {
            Text("No Project").tag(nil as Project?)
            ForEach(projects, id: \.self) { project in
                Text(project.name).tag(project as Project?)
            }
        }
        .disabled(projects.isEmpty)
        .onChange(of: viewModel.selectedProject) { hasUnsavedChanges = true }
    }
    
    @ViewBuilder
    private var timeTrackingSection: some View {
        if task != nil {
            HStack {
                Text("Time Tracking")
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                router.navigate(.timeEntries(task!))
            }
        }
    }
    

    
    private var checklistSection: some View {
        Section(header:
            Text("Checklist")
        ) {
            Button(action: {
                viewModel.taskItems.insert(TaskItem(title: "Item"), at: 0)
                hasUnsavedChanges = true
                focusedItemIndex = 0
            }) {
                Text("Add Item")
                    .foregroundColor(.accentColor)
            }.buttonStyle(.plain)
            ForEach(viewModel.taskItems.indices, id: \.self) { idx in
                HStack {
                    TextEditor(text: $viewModel.taskItems[idx].title)
                        .frame(minHeight: 36, maxHeight: 80)
                        .focused($focusedItemIndex, equals: idx)
                        .onChange(of: viewModel.taskItems[idx].title) { hasUnsavedChanges = true }
                    Button(action: {
                        indexToDeleteTaskItem = idx
                        showingDeleteTaskItemAlert = true
                    }) {
                        Image(systemName: "minus.circle.fill")
                            .foregroundColor(.red)
                            .font(.headline)
                    }
                }
            }
        }
        .alert("Are you sure you want to delete this item?", isPresented: $showingDeleteTaskItemAlert, actions: {
            Button("Delete", role: .destructive) {
                if let idx = indexToDeleteTaskItem {
                    viewModel.taskItems.remove(at: idx)
                    hasUnsavedChanges = true
                }
                indexToDeleteTaskItem = nil
                showingDeleteTaskItemAlert = false
            }
            Button("Cancel", role: .cancel) {
                indexToDeleteTaskItem = nil
                showingDeleteTaskItemAlert = false
            }
        })
    }
    
    private func saveTask() {
        guard !viewModel.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            showNameEmptyAlert = true
            return
        }
        viewModel.taskItems.removeAll { $0.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        viewModel.makeTask(with: modelContext)
        hasUnsavedChanges = false
    }
    
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: UserTask.self, Project.self, TaskItem.self, configurations: config)

    let sampleProject = Project(name: "Preview Project", color: "blue")
    let sampleTask = UserTask(title: "Sample Preview Task", project: sampleProject, description: "A sample task for AddTaskView preview.")

    let item1 = TaskItem(title: "Preview subtask 1")
    let item2 = TaskItem(title: "Preview subtask 2")
    sampleTask.taskItems = [item1, item2]

    return AddTaskView(task: sampleTask)
        .modelContainer(container)
}
