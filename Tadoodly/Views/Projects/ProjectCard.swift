//
//  ProjectCard.swift
//  Tadoodly
//
//  Created by modemlooper on 6/6/25.
//

import SwiftUI
import SwiftData

struct ProjectCard: View {
    let project: Project
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var completedCount: Int { project.tasks?.filter { $0.completed }.count ?? 0 }
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
                
                VStack(alignment: .leading, spacing: 10) {
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
                        
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                            Text("Due \(project.dueDate, format: .dateTime.month(.abbreviated).day())")
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        
                        
                    }
                }
                
            
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
    }
            
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: UserTask.self, Project.self, TimeEntry.self, configurations: config)
    let modelContext = container.mainContext
    
    let project = Project(name: "Work", color: "blue")
    modelContext.insert(project)

    
    return ProjectCard(project: project)
        .modelContainer(container)
}
