//
//  StatsView.swift
//  Tadoodly
//
//  Created by modemlooper on 6/4/25.
//

import Foundation
import SwiftUI
import SwiftData

struct StatsView: View {

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            (colorScheme == .light ? Color(.systemGray6) : Color.clear)
                .ignoresSafeArea()

            ScrollView {
                
                LineChartView()
                    .padding(.horizontal)
           
                Grid {
        
                    GridRow {
                        CircleChartView()
                            .frame(maxHeight: .infinity)
                        TotalTimeView()
                            .frame(maxHeight: .infinity)
                    }
                    
                    DailyAverageView()
                }
                .padding(.horizontal)
               
            }
         
            .scrollIndicators(.hidden)
            .navigationTitle("Statistics")
            .toolbar {
            }
        }
    }
    
}

#Preview {
    let container = try! ModelContainer(for: Project.self, UserTask.self, TimeEntry.self, configurations: .init(isStoredInMemoryOnly: true))
    let context = container.mainContext
    
    // Sample Project
    let sampleProject = Project(name: "Preview Project", color: "blue")
    let sampleProject2 = Project(name: "Preview Project 2", color: "blue")
    context.insert(sampleProject)
    context.insert(sampleProject2)
    
    // Optionally, add a sample TimeEntry for the project if the initializer allows
    // let sampleEntry = TimeEntry(date: .now, duration: 3600, project: sampleProject)
    // context.insert(sampleEntry)
    
    return NavigationStack {
        StatsView()
            .modelContainer(container)
    }
}
