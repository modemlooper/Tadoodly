//
//  TaskItem.swift
//  Tadoodly
//
//  Created by modemlooper on 6/11/25.
//

import Foundation
import SwiftData

@Model
final class TaskItem {
    var id: UUID = UUID()
    var title: String = ""
    var itemDescription: String? = ""
    var createdAt: Date = Date()
    var completed: Bool = false
    
    // Optional to-one to UserTask; inverse is declared on UserTask.taskItems
    @Relationship
    var task: UserTask? = nil
    
    init() {}
}
