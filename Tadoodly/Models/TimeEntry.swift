//
//  TimeEntry.swift
//  Tadoodly
//
//  Created by modemlooper on 6/4/25.
//
import SwiftData
import Foundation

@Model
final class TimeEntry {
    var startTime: Date = Date()
    var endTime: Date? = nil
    var duration: TimeInterval = 0
    var date: Date = Date()
    var note: String = ""
    
    // Optional to-one to UserTask. Inverse is declared on UserTask.timeEntries.
    @Relationship
    var task: UserTask? = nil
    
    init() {}
    
    public func stop() {
        endTime = Date()
        if let endTime = endTime {
            duration = endTime.timeIntervalSince(startTime)
        }
    }
    
    public var isActive: Bool {
        endTime == nil
    }
}

func deleteTimeEntryAndUpdateTask(timeEntryToDelete: TimeEntry, modelContext: ModelContext) {
    
    modelContext.delete(timeEntryToDelete)
    
    do {
        try modelContext.save()
        // Successfully saved. TaskRow should now reflect the deletion.
    } catch {
        // Log the error or handle it as appropriate for your app's error strategy.
        print("Error saving model context: \(error.localizedDescription)")
    }
}
