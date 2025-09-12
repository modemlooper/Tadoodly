//
//  CircleChartView.swift
//  Tadoodly
//
//  Created by modemlooper on 7/12/25.
//

import SwiftUI
import SwiftData

struct CircleChartView: View {
    
    @Environment(\.colorScheme) private var colorScheme
    @Query private var tasks: [UserTask]
    @State private var animatedCompletion: Double = 0
    
    private var completionRatio: Double {
        guard totalTasks > 0 else { return 0 }
        return Double(completedTasks) / Double(totalTasks)
    }
    
    private var totalTasks: Int {
        tasks.count
    }
    
    private var completedTasks: Int {
        tasks.filter { $0.status == .done || $0.completed }.count
    }
    
    var body: some View {
        ZStack {
            
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(colorScheme == .dark ? Color(white: 0.12) : .white)
                .shadow(color: Color.black.opacity(0.05), radius: 3, x: 1, y: 1)
          
            ZStack {
                // Background Circle
                Circle()
                    .inset(by: 10)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 16)
                // Completed Arc
                Circle()
                    .inset(by: 10)
                    .trim(from: 0, to: min(animatedCompletion, 1.0))
                    .stroke(Color.green, style: StrokeStyle(lineWidth: 16, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                // Center Text
                VStack {
                    Text("Tasks")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(completedTasks)/\(totalTasks)")
                        .font(.title.bold())
                    Text("Completed")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(16)
            .drawingGroup()
            .onAppear {
                animatedCompletion = 0
                withAnimation(.easeOut(duration: 0.6)) {
                    animatedCompletion = completionRatio
                }
            }
        }
    
        
    }
}

#Preview {
    CircleChartView()
        .frame(width: 200)
}
