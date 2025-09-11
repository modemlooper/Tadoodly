//
//  AddProjectView.swift
//  Tadoodly
//
//  Created by modemlooper on 6/6/25.
//

import SwiftUI
import SwiftData

let colors = ["red", "blue", "green", "orange", "purple", "teal", "pink", "indigo", "gray", "darkGray"]

struct AddProjectView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var router: NavigationRouter
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme

    @State private var viewModel: AddProjectViewModel

    @State private var showingDeleteAlert = false
    @State private var showingTaskDeleteAlert = false
    @State private var showingCopyAlert = false
    @State private var taskToDelete: UserTask? = nil

    @FocusState private var focusedTaskIndex: Int?

    @State private var hasUnsavedChanges = false
    @State private var showUnsavedChangesAlert = false
    @State private var showNameRequiredUnsavedAlert = false
    @State private var showSaveProjectFirstAlert = false
    
    @State private var isAddItemShowing: Bool = false
    @State private var showSymbolPicker: Bool = false

    let project: Project?

    init(project: Project? = nil) {
        self.project = project
        _viewModel = State(wrappedValue: AddProjectView.createViewModel(project: project))
    }
    
    private static func createViewModel(project: Project?) -> AddProjectViewModel {
        return AddProjectViewModel(project: project)
    }
    
    private var sectionHeader: some View {
        HStack(spacing: 16) {
            Spacer()
            if project != nil {
                Image(systemName: "document.on.document")
                    .font(.title2)
                    .foregroundColor(.secondary)
                    .onTapGesture(perform: handleCopyTap)
                Image(systemName: "trash")
                    .font(.title2)
                    .foregroundColor(.red)
                    .onTapGesture(perform: handleDeleteTap)
            }
        }
        .frame(maxWidth: .infinity)
    }

    var body: some View {
        Form {
            projectDetailsSection
            StatusSection
            ColorSection
            AddTaskSection
        }
        .navigationTitle(project != nil ? "Edit Project" : "Add Project")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    handleBackButton()
                } label: {
                    Image(systemName: "chevron.left")
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    saveProject()
                }
                .disabled(viewModel.name.isEmpty)
            }
        }
        .navigationDestination(isPresented: $isAddItemShowing) {
            // Use the view model's current project, which we set on save
            AddTaskView(task: nil, preselectedProject: viewModel.project)
        }
        .alert("Are you sure you want to duplicate this project?", isPresented: $showingCopyAlert, actions: {
            Button("Duplicate", role: .destructive) {
                if let project = project {
                    project.copy(modelContext: modelContext)
                    router.root()
                }
            }
            Button("Cancel", role: .cancel) { }
        })
        .alert("Are you sure you want to delete this project?", isPresented: $showingDeleteAlert, actions: {
            Button("Delete", role: .destructive) {
                if let project = project {
                    project.delete(modelContext: modelContext)
                    try? modelContext.save()
                    router.root()
                } 
            }
            Button("Cancel", role: .cancel) {}
        })
        .alert("Are you sure you want to delete this task?", isPresented: $showingTaskDeleteAlert, actions: {
            Button("Delete", role: .destructive) {
                if let task = taskToDelete {
                    // Remove from the in-memory list
                    if let idx = viewModel.tasks.firstIndex(where: { $0.id == task.id }) {
                        let removed = viewModel.tasks.remove(at: idx)
                        // If editing an existing project, delete from SwiftData as well
                        if project != nil {
                            removed.delete(modelcontext: modelContext)
                            try? modelContext.save()
                        }
                        hasUnsavedChanges = true
                    }
                }
                taskToDelete = nil
            }
            Button("Cancel", role: .cancel) {
                taskToDelete = nil
            }
        })
        .alert("You have unsaved changes. What would you like to do?", isPresented: $showUnsavedChangesAlert, actions: {
            Button("Save") {
                saveProject()
                dismiss()
            }
            Button("Discard", role: .destructive) {
                dismiss()
            }
            Button("Cancel", role: .cancel) {
                // do nothing
            }
        })
        .alert("Project name is required.", isPresented: $showNameRequiredUnsavedAlert) {
            Button("Edit", role: .cancel) { }
            Button("Discard", role: .destructive) {
                dismiss()
            }
        } message: {
            Text("Please enter a name for your project or discard your changes.")
        }
        .alert("Save Project First", isPresented: $showSaveProjectFirstAlert) {
//            Button("Save & Add Task") {
//                if !viewModel.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
//                    saveProject()
//                    isAddItemShowing = true
//                }
//            }
            Button("Ok", role: .cancel) { }
        } message: {
            Text("Please add a name and save before adding tasks.")
        }
        .sheet(isPresented: $showSymbolPicker) {
            SFSymbolPicker(
                selectedSymbol: Binding(
                    get: { viewModel.selectedIcon ?? "folder" },
                    set: { newValue in
                        viewModel.selectedIcon = newValue
                        hasUnsavedChanges = true
                    }
                )
            )
        }
        .onAppear(perform: handleOnAppear)
        .onChange(of: isAddItemShowing) { oldValue, newValue in
            // When AddTaskView is dismissed (newValue == false), refresh tasks from the live project
            if oldValue == true, newValue == false {
                // Check if we have a project in the view model (saved project)
                if let vmProject = viewModel.project {
                    if let latest = fetchProject(by: vmProject.id) {
                        viewModel.update(from: latest)
                    } else {
                        viewModel.update(from: nil)
                    }
                }
                // Also check the original project parameter for existing projects
                else if let project = project {
                    if let latest = fetchProject(by: project.id) {
                        viewModel.update(from: latest)
                    } else {
                        viewModel.update(from: nil)
                    }
                }
            }
        }
    }

    private var projectDetailsSection: some View {
        Section(header: sectionHeader) {
            TextField("Project Name", text: $viewModel.name)
                .onChange(of: viewModel.name) { _, _ in
                    hasUnsavedChanges = true
                }
            TextField("Description (Optional)", text: $viewModel.projectDescription, axis: .vertical)
                .lineLimit(3...6)
                .onChange(of: viewModel.projectDescription) { _, _ in
                    hasUnsavedChanges = true
                }
            
            HStack {
                if let dueDate = viewModel.dueDate {
                    DatePicker("Due Date",
                               selection: Binding(
                                   get: { dueDate },
                                   set: { newValue in
                                       viewModel.dueDate = newValue
                                       hasUnsavedChanges = true
                                   }
                               ),
                               displayedComponents: .date
                    )
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

    private var AddTaskSection: some View {
        Section(header:
                    Text("Tasks")
        ) {

            Button(action: handleAddTaskTap) {
                Text("Add Task")
                    .foregroundColor(.accentColor)
            }.buttonStyle(.plain)

            ForEach(viewModel.tasks, id: \.id) { task in
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
                    router.navigate(.editTask(task))
                }
            }
        }
    
    }
    
    private var StatusSection: some View {
        Section {
            Picker("Status", selection: $viewModel.status) {
                ForEach(ProjectStatus.allCases) { statusOption in
                    Text(statusOption.rawValue).tag(statusOption)
                }
            }
            .onChange(of: viewModel.status) { _, _ in
                hasUnsavedChanges = true
            }
            
            Picker("Priority", selection: $viewModel.priority) {
                ForEach(ProjectPriority.allCases) { priorityOption in
                    Text(priorityOption.rawValue).tag(priorityOption)
                }
            }
            .onChange(of: viewModel.priority) { _, _ in
                hasUnsavedChanges = true
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
                                viewModel.selectedColor = color
                                hasUnsavedChanges = true
                            }
                        if (viewModel.selectedColor == color) {
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
                        Image(systemName: viewModel.selectedIcon ?? "folder")
                            .foregroundColor(.accentColor)
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }
    
    private func saveProject() {
        if let project = project {
            // Update existing project
            project.name = viewModel.name
            project.projectDescription = viewModel.projectDescription
            project.color = viewModel.selectedColor
            project.status = viewModel.status.rawValue
            project.icon = viewModel.selectedIcon ?? project.icon
            project.priority = viewModel.priority.rawValue
            project.dueDate = viewModel.dueDate ?? project.dueDate

            // Update tasks and relationships
            project.tasks = viewModel.tasks
            for task in viewModel.tasks {
                task.project = project
                modelContext.insert(task)
            }
            // Keep VM's project in sync so navigation can use it
            viewModel.update(from: project)
        } else {
            // Create new project
            let newProject = Project(name: viewModel.name, description: viewModel.projectDescription, color: viewModel.selectedColor, status: viewModel.status)
            newProject.icon = viewModel.selectedIcon ?? "folder"
            newProject.priority = viewModel.priority.rawValue
            newProject.dueDate = viewModel.dueDate ?? nil
            newProject.tasks = viewModel.tasks
            for task in viewModel.tasks {
                task.project = newProject
                modelContext.insert(task)
            }
            modelContext.insert(newProject)
            // Update VM so we now have a non-nil project reference
            viewModel.update(from: newProject)
        }
        try? modelContext.save()
        hasUnsavedChanges = false
        //dismiss()
    }
    
    // MARK: - Helpers
    private func fetchProject(by id: UUID) -> Project? {
        let descriptor = FetchDescriptor<Project>(predicate: #Predicate { $0.id == id }, sortBy: [])
        return try? modelContext.fetch(descriptor).first
    }
    
    private func handleCopyTap() {
        showingCopyAlert = true
    }
    
    private func handleDeleteTap() {
        showingDeleteAlert = true
    }
    
    private func handleBackButton() {
        if hasUnsavedChanges {
            if viewModel.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                showNameRequiredUnsavedAlert = true
            } else {
                showUnsavedChangesAlert = true
            }
        } else {
            dismiss()
        }
    }
    
    private func handleAddTaskTap() {
        // If we have a saved project in the VM, allow navigation.
        if let _ = viewModel.project {
            isAddItemShowing = true
            return
        }
        // Otherwise, block and ask user to save first
        if viewModel.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            showSaveProjectFirstAlert = true
        } else if hasUnsavedChanges {
            showSaveProjectFirstAlert = true
        } else {
            // Fallback: still blocked because no concrete project exists
            showSaveProjectFirstAlert = true
        }
    }
    
    private func handleOnAppear() {
        // Stronger: refetch the latest Project by id to avoid stale references.
        guard let project else { return }
        if let latest = fetchProject(by: project.id) {
            viewModel.update(from: latest)
        } else {
            // If the project was deleted elsewhere, clear the VM to defaults.
            viewModel.update(from: nil)
        }
    }
}

struct NoChevronButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
    }
}
