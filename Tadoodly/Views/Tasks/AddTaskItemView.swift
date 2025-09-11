//
//  AddTaskItemView.swift
//  Tadoodly
//
//  Created by modemlooper on 9/5/25.
//

import SwiftUI
import SwiftData

struct AddTaskItemView: View {
    
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var router: NavigationRouter
    @Environment(\.dismiss) private var dismiss
    
    var task: UserTask?
    var onDraftSave: ((TaskItem) -> Void)? = nil
    
    @State private var title: String = ""
    @State private var itemDescription: String = ""
    @State private var completed: Bool = false
    
    @State private var showTitleRequiredAlert = false
    @State private var hasUnsavedChanges = false
    @State private var showUnsavedChangesAlert = false
    
    private var canSave: Bool {
        // Allow save if there’s a non-empty title AND either a real task or a draft handler
        let hasTitle = !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        return hasTitle && (task != nil || onDraftSave != nil)
    }
    
    init(task: UserTask?, onDraftSave: ((TaskItem) -> Void)? = nil) {
        self.task = task
        self.onDraftSave = onDraftSave
    }
    
    var body: some View {
        Form {
            Section {
                TextField("Title (required)", text: $title)
                    .onChange(of: title) { _, _ in hasUnsavedChanges = true }
                
                TextField("Description (optional)", text: $itemDescription, axis: .vertical)
                    .lineLimit(3...6)
                    .onChange(of: itemDescription) { _, _ in hasUnsavedChanges = true }
                
                Toggle("Completed", isOn: $completed)
                    .onChange(of: completed) { _, _ in hasUnsavedChanges = true }
            } header: {
                HStack {
                    Text("New Item")
                    Spacer()
                    if let task {
                        Text(task.title)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                }
            }
        }
        .navigationTitle("Add Item")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    if hasUnsavedChanges {
                        showUnsavedChangesAlert = true
                    } else {
                        dismiss()
                    }
                } label: {
                    Image(systemName: "chevron.left")
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    saveItem()
                }
                .disabled(!canSave)
            }
        }
        .alert("Title is required.", isPresented: $showTitleRequiredAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Please enter a title for the checklist item.")
        }
        .alert("You have unsaved changes.", isPresented: $showUnsavedChangesAlert) {
            Button("Save") { saveItem() }
            Button("Discard", role: .destructive) { dismiss() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Would you like to save before leaving?")
        }
        .onAppear {
            // Ensure we have a task or a draft handler; otherwise disallow saving.
            let titleString = task?.title ?? "nil"
            print("AddTaskItemView appeared with task title: \(titleString)")
        }
    }
    
    private func saveItem() {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            showTitleRequiredAlert = true
            return
        }
        
        if let task {
            // Persisted mode: attach to a real task and save to SwiftData
            let newItem = TaskItem(title: trimmed, task: task, description: itemDescription)
            newItem.completed = completed
            
            if task.taskItems == nil {
                task.taskItems = []
            }
            task.taskItems?.append(newItem)
            modelContext.insert(newItem)
            try? modelContext.save()
            hasUnsavedChanges = false
            dismiss()
        } else if let onDraftSave {
            // Draft mode: create item and hand it back, do not touch modelContext
            let draftItem = TaskItem(title: trimmed, task: nil, description: itemDescription)
            draftItem.completed = completed
            hasUnsavedChanges = false
            onDraftSave(draftItem)
            dismiss()
        } else {
            // Should not happen due to canSave, but be defensive
            showTitleRequiredAlert = true
        }
    }
}
