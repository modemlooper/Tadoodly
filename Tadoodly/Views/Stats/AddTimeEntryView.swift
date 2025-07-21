//
//  AddTimeEntryView.swift
//  Tadoodly
//
//  Created by modemlooper on 7/18/25.
//

import SwiftUI

struct AddTimeEntryView: View {
    
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var router: NavigationRouter
    
    var task: UserTask!
    
    @State private var startTime: Date = Date()
    @State private var endTime: Date = Date()
    @State private var note: String = ""
    
    var body: some View {
        Form {
            
            DatePicker("Start", selection: $startTime, displayedComponents: [.date, .hourAndMinute])
                .datePickerStyle(.compact)
            DatePicker("End", selection: $endTime, displayedComponents: [.date, .hourAndMinute])
                .datePickerStyle(.compact)
            
            Section("Note") {
                TextEditor(text: $note )
                    .frame(minHeight: 80)
            }
        }
        .navigationTitle("Add Time Entry")
        .toolbar {
            ToolbarItem {
                Button("Save") {
                    let newEntry = TimeEntry(startTime: startTime, task: task)
                    newEntry.endTime = endTime
                    newEntry.duration = endTime.timeIntervalSince(startTime)
                    newEntry.date = Calendar.current.startOfDay(for: startTime)
                    newEntry.note = note
                    if task.timeEntries == nil {
                        task.timeEntries = []
                    }
                    task.timeEntries?.append(newEntry)
                    modelContext.insert(newEntry)
                    do {
                        try modelContext.save()
                        router.pop()
                    } catch {
                        print("Failed to save time entry: \(error)")
                    }
                }
            }
        }
    }
}

#Preview {
    AddTimeEntryView()
}
