//
//  TaskItem.swift
//  Tadoodly
//
//  Created by modemlooper on 6/11/25.
//

import Foundation
import SwiftData

@Model
public final class TaskItem: Identifiable {
    public var id: UUID = UUID()
    public var title: String = ""
    public var itemDescription: String? = ""
    public var createdAt: Date = Date()
    public var completed: Bool = false
    public var task: UserTask? = nil
    
    public init(title: String, task: UserTask? = nil, description: String = "") {
        self.title = title
        self.createdAt = Date()
        self.itemDescription = description
        self.task = task
    }
    
}
