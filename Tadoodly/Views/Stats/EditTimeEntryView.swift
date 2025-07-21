//
//  editTimeEntryView.swift
//  Tadoodly
//
//  Created by modemlooper on 7/18/25.
//

import SwiftUI

struct EditTimeEntryView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var router: NavigationRouter
    @StateObject private var viewModel: AddTimeEntryViewModel
    
    @State private var showDeleteConfirmation = false
      
    var timeEntry: TimeEntry

    init(timeEntry: TimeEntry?) {
        self.timeEntry = timeEntry!
        _viewModel = StateObject(wrappedValue: AddTimeEntryViewModel(timeEntry: timeEntry))
    }

    var body: some View {

        Form {
            
            DatePicker("Start", selection: $viewModel.startTime, displayedComponents: [.date, .hourAndMinute])
                .datePickerStyle(.compact)
                .onChange(of: viewModel.startTime) { newValue, _ in
                    timeEntry.startTime = newValue
                    viewModel.update(modelContext: modelContext)
                }
            
            DatePicker("End", selection: Binding(
                get: { viewModel.endTime },
                set: { newValue in viewModel.endTime = newValue }
            ), displayedComponents: [.date, .hourAndMinute])
                .datePickerStyle(.compact)
                .onChange(of: viewModel.endTime) { _, _ in
                    viewModel.update(modelContext: modelContext)
                }
            
            Section("Note") {
                TextEditor(text: $viewModel.note)
                    .frame(minHeight: 80)
                    .onChange(of: viewModel.note) { _, _ in
                        viewModel.update(modelContext: modelContext)
                    }
            }
            
            Section {
                HStack {
                    Spacer()
                    Button("Delete Entry") {
                        showDeleteConfirmation = true
                    }
                    .foregroundColor(.red)
                    .confirmationDialog("Are you sure you want to delete this entry?", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
                        Button("Delete", role: .destructive) {
                            modelContext.delete(timeEntry)
                            try? modelContext.save()
                            router.pop()
                        }
                        Button("Cancel") {}
                    }
                    Spacer()
                }
            }
            
        }
        .navigationTitle("Edit Time Entry")
    }
}

#Preview {
    let sampleEntry = TimeEntry()
    EditTimeEntryView(timeEntry: sampleEntry)
}
