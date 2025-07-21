//
//  ProjectStatsView.swift
//  Tadoodly
//
//  Created by modemlooper on 6/10/25.
//

import SwiftUI

struct ProjectStatsView: View {
    
    var project: Project
    
    let columns = [GridItem(.flexible()), GridItem(.flexible())]
    
    var body: some View {
        
        ScrollView {
            VStack(spacing: 8) { // Updated spacing to 12
                Text(project.name)
                    .font(.title)
                    .fontWeight(.bold)
                
                Text(formatTime(project.totalTime))
                    .font(.title2)
                    .fontWeight(.semibold)
                
                if !project.projectDescription.isEmpty {
                    Text(project.projectDescription)
                        .font(.caption)
                        .foregroundColor( colorFromString(project.color) == .white ? .black.opacity(0.8)  : .white.opacity(0.8))
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemGroupedBackground))
            .cornerRadius(20)
                        
            Spacer()
        }
        .padding()
    }
}

#Preview {
    ProjectStatsView(project: Project(name: "Test Project", description: "Test Description"))
}
