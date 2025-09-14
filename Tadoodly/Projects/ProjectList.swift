//
//  ProjectList.swift
//  Tadoodly
//
//  Created by modemlooper on 9/9/25.
//

import SwiftUI
import SwiftData

struct ProjectList: View {
    
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: [SortDescriptor(\Project.createdAt, order: .reverse)]) private var projects: [Project]
    @Binding var path: NavigationPath
    
    var body: some View {
        Group {
            if projects.isEmpty {
                GeometryReader { proxy in
                    ScrollView {
                        VStack {
                            Spacer(minLength: 0)
                            ContentUnavailableView(
                                "No Projects",
                                systemImage: "folder",
                                description: Text("Get started by adding a project.")
                            )
                            Spacer(minLength: 0)
                        }
                        .frame(maxWidth: .infinity, minHeight: (proxy.size.height - 60)) // context-aware height
                    }
                    .scrollIndicators(.hidden)
                }
            } else {
                ScrollView {
                    ForEach(projects) { project in
                        NavigationLink(value: project) {
                            ProjectRow(project: project)
                                .contentShape(Rectangle())
                            // Recognize double-tap with higher priority than the link's single tap
                                .highPriorityGesture(
                                    TapGesture(count: 2).onEnded {
                                        // Navigate to edit on double-tap
                                        //path.append(project)
                                        path.append(AddProjectRoute(project: project))
                                    }
                                )
                        }
                        .navigationLinkIndicatorVisibility(.hidden)
                        .tint(.primary)
                        .buttonStyle(.plain)
                        .listRowInsets(EdgeInsets())
                        
                       
                    }
                }
                .scrollIndicators(.hidden)
            }
        }
        .navigationTitle("Projects")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                NavigationLink(value: AddProjectRoute(project: nil)) {
                    Label("Add Project", systemImage: "plus")
                }
            }
        }
    }
}


struct ProjectRow: View {
    let project: Project
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var completedCount: Int { (project.tasks ?? []).filter { $0.completed }.count }
    private var totalCount: Int { project.tasks?.count ?? 0 }
    
    var body: some View {
     
            HStack(alignment: .top, spacing: 16) {
                
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(colorFromString(project.color).opacity(0.5))
                        .frame(width: 48, height: 48)
                    Image(systemName: project.icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(colorFromString(project.color))
                }
                
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 8) {
                        Text(project.name)
                            .font(.title3)
                            .fontWeight(.bold)
                    }
                    HStack(spacing: 18) {
                        
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle")
                            Text("\(completedCount)/\(totalCount)")
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                            Text("\(project.status)")
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
                        
                        
                    }
                    
                    Divider()
                }
              
                
            
            }
            .padding(.top)
            .padding(.horizontal)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
            
}
