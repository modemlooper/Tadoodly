//
//  ExportView.swift
//  Tadoodly
//
//  Created by modemlooper on 10/27/25.
//

import SwiftUI
import SwiftData

struct ExportView: View {
    
    @Environment(\.modelContext) private var modelContext
    
    @Query private var tasks: [UserTask]
    
    // MARK: - Date Range
    @State private var startDate: Date = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
    @State private var endDate: Date = Date()
        
    // MARK: - Filtering
    private var filteredTasks: [UserTask] {
        let normalizedStart = startDate.startOfDay
        let normalizedEnd = endDate.endOfDay
        return tasks.filter { task in
            (normalizedStart ... normalizedEnd).contains(task.createdAt)
        }.sorted { $0.createdAt < $1.createdAt }
    }
    
    var body: some View {
        
        Form {
            Section("Date Range") {
                DatePicker("Start", selection: $startDate, displayedComponents: [.date])
                    .onChange(of: startDate) { _, newValue in
                        // Keep start <= end by clamping end forward if needed
                        if newValue > endDate {
                            endDate = newValue
                        }
                    }
                
                DatePicker("End", selection: $endDate, in: startDate...Date.distantFuture, displayedComponents: [.date])
                    .onChange(of: endDate) { _, newValue in
                        // Ensure end >= start
                        if newValue < startDate {
                            startDate = newValue
                        }
                    }
            }
                        
            Section("Tasks in Range") {
                
                if !filteredTasks.isEmpty {
                    Text("\(filteredTasks.count) tasks found.")
                } else {
                    Text("There are no tasks in the selected date range.")
                }
            }
        }
        .toolbar {
            ToolbarItem {
                Button {
                  
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
    }
}

private extension Date {
    var startOfDay: Date { Calendar.current.startOfDay(for: self) }
    var endOfDay: Date {
        let start = Calendar.current.startOfDay(for: self)
        return Calendar.current.date(byAdding: DateComponents(day: 1, second: -1), to: start) ?? self
    }
}

//#Preview {
//    ExportView()
//}
