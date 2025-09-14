//
//  AddTimeEntry.swift
//  Tadoodly
//
//  Created by modemlooper on 9/14/25.
//

import SwiftUI
import SwiftData

struct AddTimeEntry: View {
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Binding var path: NavigationPath
    
    @State private var showDeleteConfirmation = false
    
    var timeEntry: TimeEntry = TimeEntry()
 
    var body: some View {
        
        Form {
            
            DatePicker(
                "Start",
                selection: Binding(
                    get: { timeEntry.startTime },
                    set: { newValue in timeEntry.startTime = newValue }
                ),
                displayedComponents: [.date, .hourAndMinute]
            )
            .datePickerStyle(.compact)
            .onChange(of: timeEntry.startTime) { newValue, _ in
                timeEntry.startTime = newValue
                do { try modelContext.save() } catch { /* handle save error if needed */ }
            }
            
            DatePicker("End", selection: Binding(
                get: { timeEntry.endTime },
                set: { newValue in timeEntry.endTime = newValue }
            ), displayedComponents: [.date, .hourAndMinute])
                .datePickerStyle(.compact)
                .onChange(of: timeEntry.endTime) { _, _ in
                    do { try modelContext.save() } catch { /* handle save error if needed */ }
                }
            
            Section("Note") {
                TextEditor(text: Binding(
                    get: { timeEntry.note },
                    set: { newValue in timeEntry.note = newValue }
                ))
                .frame(minHeight: 80)
                .onChange(of: timeEntry.note) { _, _ in
                    do { try modelContext.save() } catch { /* handle save error if needed */ }
                }
            }
            
            Section {
                HStack {
                    Spacer()
                    Button("Delete Time") {
                        showDeleteConfirmation = true
                    }
                    .foregroundColor(.red)
                    .confirmationDialog("Are you sure you want to delete this time?", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
                        Button("Delete", role: .destructive) {
                            modelContext.delete(timeEntry)
                            try? modelContext.save()
                            dismiss()
                        }
                        Button("Cancel") {}
                    }
                    Spacer()
                }
            }
            
        }
        .navigationTitle("Edit Time")
    }
}

