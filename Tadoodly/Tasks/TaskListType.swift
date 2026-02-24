//
//  TaskListType.swift
//  Tadoodly
//
//  Created by modemlooper on 2/24/26.
//

import SwiftUI
import SwiftData

struct TaskListType: View {
    enum Kind: String {
        case today
        case scheduled
        case all
        case completed
    }
    
    let type: Kind
    
    @Query private var tasks: [UserTask]
    
    private var filteredTasks: [UserTask] {
        let calendar = Calendar.autoupdatingCurrent
        switch type {
        case .today:
            return tasks.filter { task in
                guard let dueDate = task.dueDate else { return false }
                return calendar.isDateInToday(dueDate) && !isTaskCompleted(task)
            }
        case .scheduled:
            return tasks.filter { $0.dueDate != nil && !isTaskCompleted($0) }
        case .all:
            return tasks.filter { !isTaskCompleted($0) }
        case .completed:
            return tasks.filter { isTaskCompleted($0) }
        }
    }

    private func isTaskCompleted(_ task: UserTask) -> Bool {
        task.completed || task.status == .done
    }
    
    private var title: String {
        switch type {
        case .today:
            return "Today"
        case .scheduled:
            return "Scheduled"
        case .all:
            return "All"
        case .completed:
            return "Completed"
            
        }
      

    }
    
    var body: some View {
        
        if filteredTasks.isEmpty {
            ContentUnavailableView(
                "No Tasks",
                systemImage: "checklist",
                description: Text("No tasks \(title).")
            )
            .padding(.top, 40)
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: 3) {
                    ForEach(filteredTasks, id: \.id) { task in
                        NavigationLink(value: task) {
                            TaskRow(task: task)
                                .contentShape(Rectangle())
                        }
                        .navigationLinkIndicatorVisibility(.hidden)
                        .tint(.primary)
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
            }
            .navigationTitle(title)
        }
        
    }
}
