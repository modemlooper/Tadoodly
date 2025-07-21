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

    @StateObject private var viewModel: AddProjectViewModel

    @State private var showingDeleteAlert = false
    @State private var showingCopyAlert = false
    @State private var indexToDelete: Int? = nil

    @FocusState private var focusedTaskIndex: Int?

    @State private var hasUnsavedChanges = false
    @State private var showUnsavedChangesAlert = false
    @State private var showNameRequiredUnsavedAlert = false

    let project: Project?

    init(project: Project? = nil) {
        self.project = project
        _viewModel = StateObject(wrappedValue: AddProjectView.createViewModel(project: project))
    }
    
    private static func createViewModel(project: Project?) -> AddProjectViewModel {
        return AddProjectViewModel(project: project)
    }
    
    private var sectionHeader: some View {
        HStack(spacing: 16) {
            Spacer()
            if project != nil {
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

    var body: some View {
        Form {
            projectDetailsSection
            
            StatusSection

            ColorSection
            
            AddTaskSection

        }
        .navigationTitle( project != nil ? "Edit Project" : "Add Project")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    if hasUnsavedChanges {
                        if viewModel.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            showNameRequiredUnsavedAlert = true
                        } else {
                            showUnsavedChangesAlert = true
                        }
                    } else {
                        dismiss()
                    }
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
                    router.root()
                } 
            }
            Button("Cancel", role: .cancel) {}
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

    private var AddTaskSection: some View {
        Section(header:
                    Text("Tasks")
        ) {

            Button(action: {
                viewModel.tasks.insert(UserTask(title: "Task"), at: 0)
                focusedTaskIndex = 0
                hasUnsavedChanges = true
            }) {
                Text("Add Task")
                    .foregroundColor(.accentColor)
            }.buttonStyle(.plain)

            ForEach(viewModel.tasks.indices, id: \.self) { idx in
                let titleBinding = Binding(
                    get: { viewModel.tasks[idx].title },
                    set: { viewModel.tasks[idx].title = $0 }
                )
                HStack {
                    TextField("Task", text: titleBinding)
                        .focused($focusedTaskIndex, equals: idx)
                        .onChange(of: titleBinding.wrappedValue) { _, _ in
                            hasUnsavedChanges = true
                        }
                    Button(action: {
                        indexToDelete = idx
                        showingDeleteAlert = true
                    }) {
                        Image(systemName: "minus.circle.fill").foregroundColor(.red)
                    }
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
            .onChange(of: viewModel.status) { _, _ in
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

            NavigationLink(destination: SFSymbolPicker(selectedSymbol: Binding<String?>(
                get: { viewModel.selectedIcon },
                set: {
                    viewModel.selectedIcon = $0
                    hasUnsavedChanges = true
                }
            ))) {
                HStack {
                    Text("Icon")
                    Spacer()
                    HStack {
                        Image(systemName: viewModel.selectedIcon ?? project?.icon ?? "folder")
                            .foregroundColor(.accent)
                    }
                }
            }
        }
    }
    
    private func saveProject() {
        if let project = project {
            // Update existing project
            project.name = viewModel.name
            project.projectDescription = viewModel.projectDescription
            project.color = viewModel.selectedColor
            project.status = viewModel.status.rawValue
            project.icon = viewModel.selectedIcon ?? "folder"

            // Remove old tasks if needed, update tasks array
            // Assign project to each task and insert new tasks if needed
            project.tasks = viewModel.tasks
            for task in viewModel.tasks {
                task.project = project
                modelContext.insert(task)
            }
        } else {
            // Create new project
            let newProject = Project(name: viewModel.name, description: viewModel.projectDescription, color: viewModel.selectedColor, status: viewModel.status)
            newProject.icon = viewModel.selectedIcon ?? "folder"
            newProject.tasks = viewModel.tasks
            for task in viewModel.tasks {
                task.project = newProject
                modelContext.insert(task)
            }
            modelContext.insert(newProject)
        }
        try? modelContext.save()
        hasUnsavedChanges = false
        //dismiss()
    }
    
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: UserTask.self, Project.self, TaskItem.self, configurations: config)
    AddProjectView()
        .modelContainer(container)
        .environmentObject(NavigationRouter())
}

