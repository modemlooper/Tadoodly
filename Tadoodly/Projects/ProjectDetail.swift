//
//  ProjectDetail.swift
//  Tadoodly
//
//  Created by modemlooper on 9/9/25.
//

import SwiftUI
import SwiftData

struct ProjectDetail: View {
    
    @Environment(\.modelContext) private var modelContext
    
    var project: Project
    
    @State private var showingDeleteConfirmation: Bool = false
    @State private var pendingDeleteOffsets: IndexSet = []
    @State private var isAddItemShowing: Bool = false
    
    private var completedCount: Int { (project.tasks ?? []).filter { $0.completed }.count }
    private var totalCount: Int { (project.tasks ?? []).count }
        
    var body: some View {
        
        ScrollView {
            VStack(alignment:.leading, spacing: 20) {
                
                HStack(alignment: .top) {
                    
                    VStack(alignment:.leading, spacing: 0) {
                        
                        // Title
                        Text(project.name)
                            .font(.title3)
                            .fontWeight(.semibold)
                        
                        // Description
                        if let desc = project.projectDescription, !desc.isEmpty {
                            Text(desc)
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        
                    }
                    
                    Spacer()
                }
              
                
                HStack(spacing: 18) {
                    
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle")
                        Text("\(completedCount)/\(totalCount)")
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    
                    if let due = project.dueDate {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                            Text("Due \(due, format: .dateTime.month(.abbreviated).day())")
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: "flag")
                        Text("\(project.status)")
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    
                }
            }
            .padding()
            
            Divider()
            
            ForEach(project.tasks ?? []) { task in
                TaskRow(task: task)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets())
            }
        }
        .scrollIndicators(.hidden)
        .listRowInsets(EdgeInsets())
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                NavigationLink(value: AddProjectRoute(project: project)) {
                    Text("Edit")
                }
            }
        }
    }
}

