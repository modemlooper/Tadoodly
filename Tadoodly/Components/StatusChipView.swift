//
//  StatusChipView.swift
//  Tadoodly
//
//  Created by modemlooper on 7/7/25.
//

import SwiftUI


struct StatusChipView: View {
    
    var task: UserTask
    
    private var chipColor: Color {
        switch task.status {
        case .inProgress:
            return .green
        case .cancelled:
            return .red
        default:
            return .blue
        }
    }

    var body: some View {
        Text(task.status?.rawValue ?? "Unknown")
            .font(.caption2)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule().fill(chipColor.opacity(0.2))
            )
            .foregroundColor(chipColor)
            .overlay(
                Capsule().stroke(chipColor, lineWidth: 0.5)
            )
    }
}

