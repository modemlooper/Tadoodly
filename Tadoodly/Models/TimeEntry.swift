//
//  TimeEntry.swift
//  Tadoodly
//
//  Created by modemlooper on 6/4/25.
//
import SwiftData
import Foundation

@Model
public final class TimeEntry: Identifiable {
    public var startTime: Date = Date()
    public var endTime: Date? = nil
    public var duration: TimeInterval = 0
    public var date: Date = Date()
    public var note: String = ""
    public var task: UserTask? = nil
    
    public init(startTime: Date = Date(), task: UserTask? = nil) {
        self.startTime = startTime
        self.endTime = nil
        self.note = note
        self.duration = 0
        self.date = Calendar.current.startOfDay(for: startTime)
        self.task = task
    }
    
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
