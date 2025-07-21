//
//  TimeEntriesView.swift
//  Tadoodly
//
//  Created by modemlooper on 6/8/25.
//

import SwiftUI
import SwiftData

private func formatDuration(_ duration: TimeInterval) -> String {
    let totalSeconds = Int(duration)
    let hours = totalSeconds / 3600
    let minutes = (totalSeconds % 3600) / 60
    let seconds = totalSeconds % 60
    return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
}

struct TimeEntriesView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var router: NavigationRouter
    var task: UserTask
    
    init(task: UserTask) {
        self.task = task
    }
    
    @State private var isEditing = false
    @State private var selectedItems = Set<TimeEntry>()
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        if let entries = task.timeEntries, !entries.isEmpty {
            List {
                Section(header:
                    HStack {
                        if isEditing {
                            Button("Delete") {
                                showDeleteConfirmation = true
                            }
                            .foregroundColor(.red)
                            .opacity(selectedItems.isEmpty ? 0.5 : 1)
                            .disabled(selectedItems.isEmpty)
                            
                            Button(selectedItems.count == (task.timeEntries?.count ?? 0) ? "Deselect All" : "Select All") {
                                withAnimation {
                                    if let entries = task.timeEntries {
                                        if selectedItems.count == entries.count {
                                            selectedItems.removeAll()
                                        } else {
                                            selectedItems = Set(entries)
                                        }
                                    }
                                }
                            }
                        } else {
                            Text("")
                        }
                        
                        Spacer()
                        
                        Button(isEditing ? "Done" : "Edit") {
                            withAnimation {
                                isEditing.toggle()
                                if !isEditing { selectedItems.removeAll() }
                            }
                        }
                    }
                ) {
                    ForEach(entries) { entry in
                        if let end = entry.endTime {
                            HStack(alignment: .center, spacing: 0) {
                                
                                HStack(alignment: .center) {
                                    Button(action: {
                                        if selectedItems.contains(entry) {
                                            selectedItems.remove(entry)
                                        } else {
                                            selectedItems.insert(entry)
                                        }
                                    }) {
                                        Image(systemName: selectedItems.contains(entry) ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(.accentColor)
                                            .imageScale(.large)
                                            .font(.system(size: 18))
                                    }
                                }
                                .frame(width: isEditing ? 44 : 0)
                                .offset(x: isEditing ? 0 : -44)
                                .animation(.easeOut(duration: 0.3), value: isEditing)
                                
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
                                        Text("\(end.formatted(date: .abbreviated, time: .shortened))")
                                            .font(.subheadline.bold())
                                    }
                                    HStack {
                                        Text("Duration")
                                            .font(.subheadline)
                                        Spacer()
                                        Text("\(formatDuration(entry.duration))")
                                            .font(.subheadline.bold())
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    if !isEditing {
                                        router.navigate(.editTimeEntry(entry))
                                    }
                                }
                                .offset(x: isEditing ? 18 : 0)
                                .animation(.easeOut(duration: 0.3), value: isEditing)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .onDelete { indices in
                        withAnimation {
                            let toDelete = indices.map { entries[$0] }
                            task.timeEntries?.removeAll { toDelete.contains($0) }
                            selectedItems.subtract(toDelete)
                        }
                    }
                }
            }
            .alert("Are you sure you want to delete the selected entries?", isPresented: $showDeleteConfirmation) {
                Button("Delete", role: .destructive) {
                    withAnimation {
                        task.timeEntries?.removeAll { selectedItems.contains($0) }
                        selectedItems.removeAll()
                    }
                }
                Button("Cancel", role: .cancel) { }
            }
            .scrollIndicators(.hidden)
            .navigationTitle("Time Entries")
            .toolbar {
                ToolbarItem {
                    Button {
                        router.navigate(.addTimeEntry(task))
                    } label: {
                        Image(systemName: "plus")
                    }
                    
                }
            }
        } else {
            VStack {
                Spacer()
                Text("No entries yet.")
                    .foregroundStyle(.secondary)
                    .font(.title3)
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("Time Entries")
            .toolbar {
                ToolbarItem {
                    Button {
                        router.navigate(.addTimeEntry(task))
                    } label: {
                        Image(systemName: "plus")
                    }
                    
                }
            }
        }
        
    }
}



#Preview {
    let container = try! ModelContainer(for: Project.self, UserTask.self, TimeEntry.self)
    let context = container.mainContext
    let sampleTask = UserTask(title: "Sample Task")
    context.insert(sampleTask)
    let now = Date()
    let entry1 = TimeEntry(startTime: now.addingTimeInterval(-7200), task: sampleTask)
    entry1.endTime = now.addingTimeInterval(-7100)
    entry1.duration = entry1.endTime!.timeIntervalSince(entry1.startTime)
    let entry2 = TimeEntry(startTime: now.addingTimeInterval(-3600), task: sampleTask)
    entry2.endTime = now.addingTimeInterval(-3500)
    entry2.duration = entry2.endTime!.timeIntervalSince(entry2.startTime)
    let entry3 = TimeEntry(startTime: now.addingTimeInterval(-600), task: sampleTask)
    entry3.endTime = now
    entry3.duration = entry3.endTime!.timeIntervalSince(entry3.startTime)
    context.insert(entry1)
    context.insert(entry2)
    context.insert(entry3)
    let router = NavigationRouter()
    return NavigationStack {
        TimeEntriesView(task: sampleTask)
    }
    .modelContainer(container)
    .environmentObject(router)
}
