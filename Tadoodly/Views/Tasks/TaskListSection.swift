//
//  TaskListSection.swift
//  Tadoodly
//
//  Created by modemlooper on 7/8/25.
//

import Foundation
import SwiftUI
import SwiftData

// Extracted from TaskListView.swift

struct TaskListSection: View {
    @EnvironmentObject private var router: NavigationRouter
    @Environment(\.modelContext) private var modelContext
    
    @Query private var tasks: [UserTask]
    
    @Binding var selectedSortOption: TaskListSortOption
    @AppStorage("showCompleted") private var showCompleted: Bool = false
    @State private var showingDeleteConfirmation: Bool = false
    @State private var pendingDeleteOffsets: IndexSet = []
    
    private var displayedTasks: [UserTask] {
        sortedTasks(tasks, sortOption: selectedSortOption, showCompleted: showCompleted)
    }
    
    var body: some View {
        if displayedTasks.isEmpty {
            VStack(spacing: 16) {
                Text("No tasks created.")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                Button(action: {
                    router.navigate(Route.addTask)
                }) {
                    Text("Add Task")
                        .font(.headline)
                        .foregroundColor(.accent)
                }
                .buttonStyle(.plain)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollViewReader { proxy in
                List {
                    ForEach(displayedTasks, id: \.id) { task in
                        ZStack {
                            TaskRowView(
                                task: task,
                                sortedTasks: displayedTasks,
                                askDeleteConfirmation: askDeleteConfirmation
                            )
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                            .onTapGesture(count: 2) {
                                router.navigate(Route.editTask(task))
                            }
                            .onTapGesture(count: 1) {
                                router.navigate(Route.viewTask(task))
                            }
                        }
                        .listRowInsets(.init(top: 1, leading: 0, bottom: 1, trailing: 0))
                    }
                }
                .animation(.default, value: displayedTasks)
                .scrollIndicators(.hidden)
                .onChange(of: selectedSortOption) { _, _ in
                    if let firstId = displayedTasks.first?.id {
                        proxy.scrollTo(firstId, anchor: .top)
                    }
                }
                .onChange(of: showCompleted) { _, _ in
                    if let firstId = displayedTasks.first?.id {
                        proxy.scrollTo(firstId, anchor: .top)
                    }
                }
                .listStyle(.plain)
                .alert("Confirm Delete", isPresented: $showingDeleteConfirmation, actions: {
                    Button("Delete", role: .destructive) {
                        deleteTasks(offsets: pendingDeleteOffsets)
                    }
                    Button("Cancel", role: .cancel) {
                        pendingDeleteOffsets = []
                    }
                }, message: {
                    Text("Are you sure you want to delete the selected task(s)?")
                })
            }
        }
    }
    
    private func askDeleteConfirmation(offsets: IndexSet) {
        pendingDeleteOffsets = offsets
        showingDeleteConfirmation = true
    }
    
    private func deleteTasks(offsets: IndexSet) {
        withAnimation {
            for offset in offsets {
                guard offset < displayedTasks.count else { continue }
                let task = displayedTasks[offset]
                modelContext.delete(task)
            }
            pendingDeleteOffsets = []
            showingDeleteConfirmation = false
        }
    }
}

enum TaskListSortOption: String, CaseIterable, Identifiable {
    case updateAt = "Recent"
    case createdAt = "Date Created"
    case dueDate = "Due Date"
    case priority = "Priority"
    case title = "Title"
    case status = "Status"
    case projectName = "Project"
    
    var id: String { self.rawValue }
}


struct TaskListOptionsPopover: View {
    @EnvironmentObject private var router: NavigationRouter
    @Binding var selectedSortOption: TaskListSortOption
    @AppStorage("showCompleted") private var showCompleted: Bool = false
    @Binding var isExpanded: Bool
    @Binding var isPopoverPresented: Bool
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            DisclosureGroup(
                content: {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(TaskListSortOption.allCases) { option in
                            Divider()
                            Button(action: {
                                withAnimation {
                                    selectedSortOption = option
                                }
                            }) {
                                HStack {
                                    if selectedSortOption == option {
                                        Image(systemName: "checkmark")
                                            .font(.subheadline)
                                            .foregroundColor(.accentColor)
                                    } else {
                                        Image(systemName: "checkmark")
                                            .opacity(0)
                                    }
                                    Text(option.rawValue)
                                        .font(.subheadline)
                                        .foregroundColor(.primary)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                },
                label: {
                    HStack {
                        Image(systemName: "arrow.up.arrow.down")
                            .foregroundColor(Color.gray)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Sort By")
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            Text(selectedSortOption.rawValue)
                                .font(.subheadline)
                                .foregroundColor(Color.gray)
                        }
                        Spacer()
                    }
                }
            )
            .frame(minWidth: 160)
            Divider()
            Button(action: {
                showCompleted.toggle()
            }) {
                HStack {
                    Image(systemName: "checkmark")
                        .font(.subheadline)
                        .opacity(showCompleted ? 1 : 0)
                    Text("Show Completed")
                }
            }
            Divider()
            Button(action: {
                isPopoverPresented = false
                router.navigate(.settings)
                
            }) {
                HStack {
                    Image(systemName: "checkmark")
                        .opacity(0)
                    Text("Settings")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.accentColor)
                        
                }
            }
        }
        .padding()
        .presentationCompactAdaptation(.none)
    }
}


struct PreviewWrapper: View {
    @State private var selectedSortOption: TaskListSortOption = .updateAt
    @State private var isExpanded: Bool = true
    var body: some View {
        TaskListOptionsPopover(
            selectedSortOption: $selectedSortOption,
            isExpanded: $isExpanded,
            isPopoverPresented: .constant(false)
        )
    }
}

#Preview {
    PreviewWrapper()
}

