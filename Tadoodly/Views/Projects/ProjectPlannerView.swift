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

@available(iOS 26.0, *)
struct ProjectPlannerView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State var model: ProjectPlannerViewModel
    
    @State private var isCreateDisabled: Bool = true
    @State private var isInputDisabled: Bool = false
 
    @FocusState private var isInputFocused: Bool
    
    let session = LanguageModelSession()
    
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
                    Button("Clear") {
                        model.title = ""
                        model.description = ""
                        model.inputText = ""
                        model.tasks = []
                        model.partialPlans = []
                        isCreateDisabled = true
                    }
                    .disabled(model.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && model.partialPlans.isEmpty)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create Project") {
                        let projectName = model.title.trimmingCharacters(in: .whitespacesAndNewlines)
                        let projectDescription = model.description.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !projectName.isEmpty else { return }
                        
                        // Optionally pick a color or use default
                        let project = Project(name: projectName, description: projectDescription, color: colors.randomElement()!)
                        
                        // Create UserTask objects for each string
                        let userTasks = model.tasks.map { title -> UserTask in
                            let task = UserTask(title: title, project: project)
                            return task
                        }
                        project.tasks = userTasks
                        
                        for task in userTasks {
                            task.project = project
                            modelContext.insert(task)
                        }
                        
                        modelContext.insert(project)
                        try? modelContext.save()
                        
                        dismiss()
                        
                        // Optionally reset state or notify user
                        model.title = ""
                        model.description = ""
                        model.inputText = ""
                        model.tasks = []
                        model.partialPlans = []
                        isCreateDisabled = true
                    }
                    .disabled(isCreateDisabled || model.isGenerating)
                }
            }
            .toolbar {
                
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
        .task {
            prewarm()
        }
    }
    
    
    func getPlan() async {
        model.isGenerating = true
        model.partialPlans = []
        do {
            let response = session.streamResponse(
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
        
    func prewarm() {
        session.prewarm()
    }
    
}

@available(iOS 26.0, *)
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
