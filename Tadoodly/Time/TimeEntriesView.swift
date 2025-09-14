//
//  TimeEntriesView.swift
//  Tadoodly
//
//  Created by modemlooper on 6/8/25.
//

import SwiftUI
import SwiftData


struct TimeEntriesView: View {
    
    @Binding var path: NavigationPath
    
    var task: UserTask = UserTask()
    
    var body: some View {
        
        ScrollView {
            if let entries = task.timeEntries {
                ForEach(entries) { entry in
                    NavigationLink(destination: AddTimeEntry(path: $path, timeEntry: entry)) {
                        EntryRow(entry: entry)
                    }
                    .buttonStyle(.plain)
                    .tint(.primary)
                    
                    Divider()
                }
            }
        }
        .toolbar() {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    // Create a new time entry and add it to the task
                    let newEntry = TimeEntry()
                    let now = Date()
                    newEntry.startTime = now
                    newEntry.endTime = now
                    newEntry.date = now
                    if task.timeEntries == nil {
                        task.timeEntries = []
                    }
                    task.timeEntries?.append(newEntry)
                    
                    // Navigate to the editor for the new entry
                    path.append(AddTimeRoute(timeEntry: newEntry))
                } label: {
                    Label("Add Task", systemImage: "plus")
                }
            }
        }
        
    }
}

struct EntryRow: View {
    
    var entry: TimeEntry = TimeEntry()
    
    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Start")
                        .font(.subheadline)
                    Spacer()
                    Text("\(entry.startTime.formatted(date: .abbreviated, time: .shortened))")
                        .font(.subheadline.bold())
                }
                HStack {
                    Text("End")
                        .font(.subheadline)
                    Spacer()
                    Text("\(entry.endTime.formatted(date: .abbreviated, time: .shortened))")
                        .font(.subheadline.bold())
                }
                HStack {
                    Text("Duration")
                        .font(.subheadline)
                    Spacer()
                    Text("\(formatDuration(start: entry.startTime, end: entry.endTime))")
                        .font(.subheadline.bold())
                }
            }
            .padding(.horizontal)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .padding(.top)
        .frame(maxWidth: .infinity, alignment: .leading)
        
    }
    
   
}

private func formatDuration(start: Date, end: Date) -> String {
    let duration = max(0, end.timeIntervalSince(start))
    let totalSeconds = Int(duration)
    let hours = totalSeconds / 3600
    let minutes = (totalSeconds % 3600) / 60
    let seconds = totalSeconds % 60
    return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
}

