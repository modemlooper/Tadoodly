//
//  Clients.swift
//  Tadoodly
//
//  Created by modemlooper on 10/27/25.
//

import Foundation
import SwiftData

@Model
final class Client {
    var id: UUID = UUID()
    var name: String = ""
    var email: String = ""
    
    @Relationship(deleteRule: .cascade)
    var projects: [Project]?
    
    init() {}
}
