//
//  addTimeEntryViewModel.swift
//  Tadoodly
//
//  Created by modemlooper on 7/18/25.
//

import Foundation
import SwiftData

class AddTimeEntryViewModel: ObservableObject {
    
    @Published var startTime: Date = Date()
    @Published var endTime: Date = Date()
    @Published var duration: TimeInterval = 0
    @Published var note: String = ""
    @Published var date: Date = Date()
    
    var timeEntry: TimeEntry?
    
    init(timeEntry: TimeEntry?) {
        self.timeEntry = timeEntry
        self.startTime = timeEntry!.startTime
        self.endTime = timeEntry!.endTime!
        self.note = timeEntry!.note

    }
        
    func update(modelContext: ModelContext) {
        guard let timeEntry = timeEntry else { return }
        timeEntry.startTime = startTime
        timeEntry.endTime = endTime
        timeEntry.note = note

        // Recalculate and update duration
        let newDuration = endTime.timeIntervalSince(startTime)
        self.duration = newDuration
        timeEntry.duration = newDuration

        if let task = timeEntry.task {
            task.updateAt = Date()
        }
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to save context: \(error)")
        }
    }
}
