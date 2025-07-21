//
//  Formatters.swift
//  Tadoodly
//
//  Created by modemlooper on 6/8/25.
//

import Foundation
import SwiftUI

func formatTime(_ timeInterval: TimeInterval) -> String {
    let hours = Int(timeInterval) / 3600
    let minutes = Int(timeInterval) % 3600 / 60
    let seconds = Int(timeInterval) % 60
    
    if hours > 0 {
        return "\(hours)h \(minutes)m \(seconds)s"
    } else {
        return "\(minutes)m \(seconds)s"
    }
}

func monthYearString(from date: Date) -> String {
    let calendar = Calendar.current
    let day = calendar.component(.day, from: date)
    let month = calendar.component(.month, from: date)
    let year = calendar.component(.year, from: date)

    let monthFormatter = DateFormatter()
    monthFormatter.dateFormat = "MMMM"
    let monthString = monthFormatter.monthSymbols[month - 1] // month is 1-indexed

    return "\(monthString) \(dayWithOrdinalSuffix(from: day)) \(year)"
}

func dayWithOrdinalSuffix(from day: Int) -> String {
    let suffix: String
    switch day {
    case 1, 21, 31:
        suffix = "st"
    case 2, 22:
        suffix = "nd"
    case 3, 23:
        suffix = "rd"
    default:
        suffix = "th"
    }
    // Handle 11th, 12th, 13th which are exceptions to the st/nd/rd rule
    if (11...13).contains(day % 100) {
        return "\(day)th"
    }
    return "\(day)\(suffix)"
}

func sortedTasks(_ tasks: [UserTask], sortOption: TaskListSortOption, showCompleted: Bool) -> [UserTask] {
    let filtered = showCompleted ? tasks : tasks.filter { !$0.completed }
    switch sortOption {
    case .updateAt:
        return filtered.sorted { lhs, rhs in
            switch (lhs.updateAt, rhs.updateAt) {
            case let (l?, r?):
                return l > r
            case (nil, _?):
                return false
            case (_?, nil):
                return true
            case (nil, nil):
                return lhs.createdAt < rhs.createdAt
            }
        }
    case .dueDate:
        return filtered.sorted { lhs, rhs in
            switch (lhs.dueDate, rhs.dueDate) {
            case let (l?, r?):
                return l > r
            case (nil, _?):
                return false
            case (_?, nil):
                return true
            case (nil, nil):
                return lhs.createdAt < rhs.createdAt
            }
        }
    case .createdAt:
        return filtered.sorted { lhs, rhs in
            let lhsCreated = lhs.createdAt
            let rhsCreated = rhs.createdAt
            return lhsCreated > rhsCreated
        }
    case .priority:
        return filtered.sorted { comparePriority(lhs: $0, rhs: $1) }
    case .title:
        return filtered.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
    case .status:
        return filtered.sorted { ($0.status?.rawValue ?? "").localizedCaseInsensitiveCompare($1.status?.rawValue ?? "") == .orderedAscending }
    case .projectName:
        return filtered.sorted { ($0.project?.name ?? "").localizedCaseInsensitiveCompare($1.project?.name ?? "") == .orderedAscending }
    }
}

private func comparePriority(lhs: UserTask, rhs: UserTask) -> Bool {
    let lhsPriority = lhs.priority?.rawValue ?? ""
    let rhsPriority = rhs.priority?.rawValue ?? ""
    return lhsPriority > rhsPriority
}

