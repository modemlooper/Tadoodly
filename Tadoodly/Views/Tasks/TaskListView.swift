//
//  TaskListView.swift
//  Tadoodly
//
//  Created by modemlooper on 6/2/25.
//

import Foundation
import SwiftUI
import SwiftData




enum SortOption: String, CaseIterable, Identifiable {
    case updateAt = "Recent"
    case createdAt = "Date"
    case priority = "Priority"
    case title = "Title"
    case projectName = "Project"
    var id: String { rawValue }
}

struct TaskListView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var showingAddTask = false
    @State private var showingOptionsPopover = false
    @State private var showingProjectAssist = false
    @State private var isSortDisclosureExpanded = false
    @State private var isExpanded = false
    @State private var scrollToTopTrigger: Bool = false
    
    @State private var selectedSortOption: TaskListSortOption = .updateAt
    @State private var showCompleted: Bool = false

    @EnvironmentObject private var router: NavigationRouter

    var body: some View {

        TaskListSection(selectedSortOption: $selectedSortOption)
        .navigationTitle("Tasks")
        .toolbar {
            #if canImport(FoundationModels)
            ToolbarItem(placement: .automatic) {
                
              
                if #available(iOS 26.0, *) {
                    if isFoundationModelAvailable() {
                        ProjectAssistButton(showingProjectAssist: $showingProjectAssist)
                    }
                } else {
                    // Fallback on earlier versions
                }
              
            }
            
            if #available(iOS 26.0, *) {
                ToolbarSpacer()
            }
            #endif
            
            ToolbarItem(placement: .primaryAction) {
                Button(action: { router.path.append(Route.addTask) }) {
                    Label("Add Task", systemImage: "plus")
                }
            }
            
           
            
            ToolbarItem {
                Button {
                    isSortDisclosureExpanded = false
                    showingOptionsPopover = true
                } label: {
                    Label("View Options", systemImage: "line.3.horizontal.decrease")
                }
                .popover(isPresented: $showingOptionsPopover) {
                    TaskListOptionsPopover(
                        selectedSortOption: $selectedSortOption,
                        isExpanded: $isExpanded,
                        isPopoverPresented: $showingOptionsPopover
                    )
                }
            }
        }
        .sheet(isPresented: $showingProjectAssist) {
            if #available(iOS 26.0, *) {
                ProjectAssistSheet()
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            } else {
                Text("Project Planner is only available on iOS 26.0 or newer.")
            }
        }
    }
}



@available(iOS 26.0, *)
private struct ProjectAssistButton: View {
    @Binding var showingProjectAssist: Bool
    
    var body: some View {
        Button {
            showingProjectAssist = true
        } label: {
            Image(systemName: "sparkles")
        }
    }
}

@available(iOS 26.0, *)
private struct ProjectAssistSheet: View {
    //@EnvironmentObject var projectPlannerViewModel: ProjectPlannerViewModel
    var body: some View {
        //ProjectPlannerView()
    }
}

#if canImport(FoundationModels)
#Preview {
    if #available(iOS 26.0, *) {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: UserTask.self, Project.self, TimeEntry.self, configurations: config)
        let modelContext = container.mainContext
        let project = Project(name: "Work", color: "blue")
        modelContext.insert(project)
        let task = UserTask(title: "Sample Task", project: project)
        task.priority = TaskPriority.low
        modelContext.insert(task)
        return AnyView(
            TaskListView()
                .modelContainer(container)
                .environmentObject(ProjectPlannerViewModel())
                .environmentObject(NavigationRouter())
        )
    } else {
        let router = NavigationRouter()
        return AnyView(
            TaskListView()
                .modelContainer(for: [Project.self, UserTask.self, TimeEntry.self], inMemory: true)
                .environmentObject(router)
        )
    }
}
#endif // canImport(FoundationModels)

