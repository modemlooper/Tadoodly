//
//  Planner.swift
//  Tadoodly
//
//  Created by modemlooper on 6/28/25.
//

#if canImport(FoundationModels)
import FoundationModels


@available(iOS 26.0, *)
@Generable
struct Planner {
    @Guide(description: "Short project name")
    var title: String
    @Guide(description: "Description of the project")
    var description: String
    @Guide(description: "List of tasks for the project. Tasks should help a user complete the project. Do not include a list number for each task. do not repeat a task.", .maximumCount(12))
    var tasks: [String]
}

@available(iOS 26.0, *)
@Generable
struct Information {
    @Guide(description: "Follow up information about the project")
    var information: String
}

// Conform PartiallyGenerated to Equatable and Hashable for SwiftUI compatibility
@available(iOS 26.0, *)
extension Information.PartiallyGenerated: Equatable, Hashable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.information == rhs.information
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(information)
    }
}
#endif
