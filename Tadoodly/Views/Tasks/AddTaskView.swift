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
    let preselectedProject: Project? // NEW: optional preselection
    
    @State private var isAddItemShowing: Bool = false
    
    @State private var hasUnsavedChanges = false
    @State private var showUnsavedChangesAlert = false
    @State private var showNameEmptyAlert = false
    @State private var showingCopyAlert = false
    @State private var showingDeleteAlert = false
    @State private var showTitleRequiredUnsavedAlert = false
    @State private var showingDeleteTaskItemAlert = false
    @State private var indexToDeleteTaskItem: Int? = nil
    @FocusState private var focusedItemIndex: Int?
    
    init(task: UserTask?, preselectedProject: Project? = nil) {
        self.task = task
        self.preselectedProject = preselectedProject
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
                    try? modelContext.save() // ensure persistence before popping
                    
                    if preselectedProject != nil {
                        router.root()
                    } else {
                        router.pop(2)
                    }
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
        .onAppear {
            // Preselect the project only when creating a new task and if a project is provided
            if task == nil, let preselectedProject {
                viewModel.selectedProject = preselectedProject
            }
            // Refresh from model if editing an existing task (child views may have persisted changes)
            if let task {
                viewModel.update(from: task)
            }
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
                    .font(.subheadline)
                    .foregroundColor(.secondary).opacity(0.8)
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
                isAddItemShowing = true
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
        .onAppear() {
            // When returning from AddTaskItemView that persisted to SwiftData,
            // refresh local copy to reflect any changes.
            if let task {
                viewModel.update(from: task)
            }
        }
        .navigationDestination(isPresented: $isAddItemShowing) {
            // Persist immediately when editing an existing task.
            // Pass the task through so AddTaskItemView saves to SwiftData.
            AddTaskItemView(task: task) { newItem in
                // If we were in "new task" mode (task == nil), still support draft append.
                viewModel.taskItems.append(newItem)
                hasUnsavedChanges = true
            }
        }
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

