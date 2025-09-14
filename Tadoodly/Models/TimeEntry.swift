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
    var endTime: Date = Date()
    var duration: TimeInterval = 0
    var date: Date = Date()
    var note: String = ""
    
    // Optional to-one to UserTask. Inverse is declared on UserTask.timeEntries.
    @Relationship
    var task: UserTask? = nil
    
    init() {}
}
