//
//  ProjectPlannerView.swift
//  Tadoodly
//
//  Created by modemlooper on 6/28/25.
//

import SwiftUI
import SwiftData
#if canImport(FoundationModels)
import FoundationModels

struct ProjectPlannerView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State var model: ProjectPlannerViewModel
    
    @State private var isCreateDisabled: Bool = true
    @State private var isInputDisabled: Bool = false
 
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        
        NavigationStack {
            
            VStack(spacing: 4) {
                
                if !model.partialPlans.isEmpty {
                    
                    Text(model.title)
                        .contentTransition(.opacity)
                        .padding()
                        .font(.title2)
                    
                    
                    Text(model.description)
                        .contentTransition(.opacity)
                        .padding()
                    
                } else {
                    
                    
                    ZStack {
                        
                        let meshColors: [Color] = [
                            .blue, .purple, .pink, .red, .orange, .yellow, .green, .blue
                        ]
                        
                        FeatheredMeshGradientCircle(
                            width: 3,
                            height: 3,
                            points: [
                                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                                [0.0, 0.5], [0.5, 0.5], [1.0, 0.5],
                                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
                            ],
                            colors: meshColors,
                            diameter: 320,
                            featherFraction: 1.3,
                            animate: model.isGenerating
                        )
                        
                        Text("Describe the project and a task list will be generated.")
                            .frame(maxWidth: 360)
                            .multilineTextAlignment(.center)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(colorScheme == .dark ? Color(red: 0.99, green: 0.99, blue: 0.95) : Color(red: 0.25, green: 0.25, blue: 0.25))
                    }
                }
                
                
                if !model.tasks.isEmpty {
                    TasksListView(model: model)
                }
            }
            .onAppear() {
                isInputFocused = true
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .toolbar {
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        model.title = ""
                        model.description = ""
                        model.inputText = ""
                        model.tasks = []
                        model.partialPlans = []
                        isCreateDisabled = true
                    }) {
                        Text("Clear")
                    }
                    .disabled(model.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && model.partialPlans.isEmpty)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
        
                    Button {
                        
                        let projectName = model.title.trimmingCharacters(in: .whitespacesAndNewlines)
                        let projectDescription = model.description.trimmingCharacters(in: .whitespacesAndNewlines)

                        // Validate there's something to save
                        guard !projectName.isEmpty || !projectDescription.isEmpty || !model.tasks.isEmpty else {
                            return
                        }

                        // Create and insert a new Project and associated Tasks using SwiftData
                        // NOTE: This assumes you have SwiftData models named `Project` and `TaskItem` (or adjust as needed).
                        // Example model signatures expected:
                        // @Model class Project { var title: String; var details: String; var tasks: [TaskItem] }
                        // @Model class TaskItem { var title: String; var isCompleted: Bool }

                        // Initialize the project
                        let project = Project()
                        project.name = projectName

                        // Map tasks from the model response into UserTask instances
                        let userTasks: [UserTask] = model.tasks
                            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                            .filter { !$0.isEmpty }
                            .map { taskTitle in
                                let task = UserTask()
                                task.title = taskTitle
                                task.isCompleted = false
                                return task
                            }

                        // Attach tasks to project (adjust depending on your model relationship)
                        // If `Project.tasks` is optional, assign directly using nil-coalescing to avoid mutating through an optional setter
                        project.tasks = (project.tasks ?? []) + userTasks

                        // Insert and save
                        modelContext.insert(project)

                        do {
                            try modelContext.save()
                            // Reset UI and dismiss
                            model.title = ""
                            model.description = ""
                            model.inputText = ""
                            model.tasks = []
                            model.partialPlans = []
                            isCreateDisabled = true
                            dismiss()
                        } catch {
                            model.errorMessage = "Failed to save project. Please try again."
                            model.showErrorAlert = true
                        }
                    } label: {
                        Text("Create Project")
                    }
                    .disabled(isCreateDisabled || model.isGenerating)

                }
                
                ToolbarItemGroup(placement: .bottomBar) {
                    TextField(model.isGenerating ? "Generating..." : "Describe Project" , text: $model.inputText)
                        .textFieldStyle(.plain)
                        .foregroundStyle(model.isInputDisabled ? .secondary : .primary)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal)
                        .focused($isInputFocused)
                        .disabled(model.isGenerating || isInputDisabled)

                    ZStack {
                        LoadSpinner(isActive: model.isGenerating)

                        Button(action: {
                            guard !model.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                                return
                            }
                            model.title = ""
                            model.description = ""
                            isInputFocused = false
                            isInputDisabled = true
                            model.tasks = []

                            Task {
                                await getPlan()
                            }
                        }) {
                            Image(systemName: "sparkles")
                                .foregroundStyle(model.isGenerating ? .white : .primary)
                        }
                        .disabled(model.isGenerating)
                    }
                }
            }
        }
        .background(Color(UIColor.systemBackground))
        .alert("Prompt Error", isPresented: $model.showErrorAlert, actions: {
            Button("OK", role: .cancel) { }
        }, message: {
            Text(model.errorMessage)
        })
    }
    
    
    func getPlan() async {
        model.isGenerating = true
        model.partialPlans = []
        do {
            let response = model.session.streamResponse(
                to: model.inputText,
                generating: Planner.self,
                includeSchemaInPrompt: true
            )
            model.inputText = ""
            for try await partial in response {
                await MainActor.run {
                    model.partialPlans.append(partial.content)
                    model.title = partial.content.title ?? ""
                    model.description = partial.content.description ?? ""
                    model.tasks = partial.content.tasks ?? []
                }
            }
        } catch {
            print("Stream error: \(error)")
            await MainActor.run {
                model.errorMessage = "Failed to generate response. Please try re-phrasing the prompt."
                model.showErrorAlert = true
            }
        }
        await MainActor.run {
            model.inputText = ""
            isInputDisabled = false
            model.isGenerating = false
            isCreateDisabled = false
        }
    }
        
}

struct TasksListView: View {
    @State var model: ProjectPlannerViewModel
    @State private var isGenerating: Bool = false
    
    var body: some View {
        List {
            // Conditionally show the rest of the items
       
                ForEach(model.tasks.indices, id: \.self) { index in
                    HStack(alignment: .top) {
                        Text("\(index + 1).")
                            .padding(.horizontal, 4)
                        Text("\(model.tasks[index])")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .onDelete(perform: deleteTask)
                if (!model.isGenerating) {
                    HStack(alignment: .center) {
                        Button {
                            isGenerating = true
                            Task {
                                await model.addTask()
                                isGenerating = false
                            }
                        } label: {
                            Text( isGenerating ? "Generating..."  : "Add Task")
                                .padding(.vertical, 8)
                                .padding(.horizontal, 10)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .disabled(isGenerating)
                    }
                }
        }
        .listStyle(InsetGroupedListStyle())
    }
    
    func deleteTask(at offsets: IndexSet) {
        model.tasks.remove(atOffsets: offsets)
    }
}
#endif // canImport(FoundationModels)


#if canImport(FoundationModels)
struct ProjectAssistSheet: View {
    var body: some View {
        ProjectPlannerView(model: ProjectPlannerViewModel())
    }
}
#endif

