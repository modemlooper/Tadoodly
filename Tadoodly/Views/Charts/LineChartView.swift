//
//  LineChartView.swift
//  Tadoodly
//
//  Created by modemlooper on 6/10/25.
//

import SwiftUI
import SwiftData
import Charts
import Foundation

struct LineChartView: View {
    
    @Environment(\.colorScheme) private var colorScheme
    @Query private var timeEntries: [TimeEntry]
    @State private var weekOffset: Int = 0
    
    private static let weekdayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = "EEE"
        return formatter
    }()
    
    private var entriesByDay: [(date: Date, totalDuration: Double)] {
        let calendar = Calendar.current
        let today = calendar.date(byAdding: .weekOfYear, value: weekOffset, to: Date())!
        let startOfToday = calendar.startOfDay(for: today)
        let days: [Date] = (0..<7).map { calendar.date(byAdding: .day, value: -$0, to: startOfToday)! }.reversed()
        
        let grouped = Dictionary(grouping: timeEntries) { entry in
            calendar.startOfDay(for: entry.date)
        }
        let actuals: [Date: Double] = grouped.mapValues { entries in
            entries.reduce(0) { $0 + ($1.duration / 3600) }
        }
        return days.map { date in
            (date: date, totalDuration: actuals[date] ?? 0)
        }
    }
    
    private var weekRangeString: String {
        let calendar = Calendar.current
        let currentWeekDate = calendar.date(byAdding: .weekOfYear, value: weekOffset, to: Date())!
        // Get the current week interval (Sunday-Saturday)
        let weekInterval = calendar.dateInterval(of: .weekOfYear, for: currentWeekDate) ?? calendar.dateInterval(of: .weekOfMonth, for: currentWeekDate)!
        let start = weekInterval.start
        let end = calendar.date(byAdding: .day, value: 6, to: start) ?? start
        let startFormatter = DateFormatter()
        let endFormatter = DateFormatter()
        startFormatter.setLocalizedDateFormatFromTemplate("MMM d")
        // If the start and end are in different months, display end month
        if calendar.component(.month, from: start) != calendar.component(.month, from: end) {
            endFormatter.setLocalizedDateFormatFromTemplate("MMM d")
        } else {
            endFormatter.setLocalizedDateFormatFromTemplate("d")
        }
        return "\(startFormatter.string(from: start))–\(endFormatter.string(from: end))"
    }
    
    private func formattedTime(from hours: Double) -> String {
        let seconds = Int(hours * 3600)
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        return String(format: "%02d:%02d", h, m)
    }
    
    var body: some View {
        
        
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(colorScheme == .dark ? Color(white: 0.12) : .white)
                .shadow(color: Color.black.opacity(0.05), radius: 3, x: 1, y: 1)
            
            
            VStack {
                VStack{
                    HStack {
                        Button(action: { weekOffset -= 1 }) {
                            Image(systemName: "chevron.left")
                        }
                        Spacer()
                        VStack{
                            Text(weekRangeString)
                                .font(.headline)
                                .foregroundStyle(.secondary)
                            
                            Text("Daily Time")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .onTapGesture(count: 2) {
                            weekOffset = 0
                        }
                        Spacer()
                        Button(action: { weekOffset += 1 }) {
                            Image(systemName: "chevron.right")
                        }
                        .disabled(weekOffset == 0)
                        
                    }
                    .padding([.top, .leading, .trailing])
                    Divider()
                }
                
                Chart(entriesByDay, id: \.date) { day in
                    if day.totalDuration > (60.0 / 3600.0) {
                        BarMark(
                            x: .value("Day", day.date, unit: .day),
                            y: .value("Hours", day.totalDuration)
                        )
                        .annotation(position: .top) {
                            
                            Text(formattedTime(from: day.totalDuration))
                                .font(.caption2)
                                .foregroundStyle(Color.secondary)
                        }
                    } else {
                        BarMark(
                            x: .value("Day", day.date, unit: .day),
                            y: .value("Hours", 0)
                        )
                    }
                }
                .animation(.easeInOut, value: weekOffset)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { value in
                        AxisValueLabel(centered: true) {
                            if let date = value.as(Date.self) {
                                Text(Self.weekdayFormatter.string(from: date))
                                
                            }
                        }
                        
                    }
                }
                .padding()
                .chartYAxis(.hidden)
            }
            
        }
        // Handle swipe gestures to move through weeks
        .gesture(
            DragGesture(minimumDistance: 20, coordinateSpace: .local)
                .onEnded { value in
                    if value.translation.width < -30 {
                        // Swipe left (should not go to future week)
                        if weekOffset < 0 {
                            weekOffset += 1
                        }
                    } else if value.translation.width > 30 {
                        // Swipe right (go back to previous week)
                        weekOffset -= 1
                    }
                }
        )
        .frame(maxWidth: .infinity, minHeight: 240, maxHeight: 240)
    }
    
    static func mockModelContainer() -> ModelContainer {
        // Create in-memory ModelContainer for preview
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: Project.self, UserTask.self, TimeEntry.self, configurations: config)
        let context = container.mainContext
        
        // Create a sample Project
        let project = Project(name: "Sample Project")
        
        // Create a sample UserTask linked to the Project
        let userTask = UserTask(title: "Task")
        userTask.project = project
        
        // Add 7 sample TimeEntries, one for each day of the current week, with distinct durations
        let calendar = Calendar.current
        let now = Date()
        if let weekInterval = calendar.dateInterval(of: .dayOfYear, for: now) {
            let startOfWeek = weekInterval.start
            for i in 1..<7 {
                if let day = calendar.date(byAdding: .hour, value: i, to: startOfWeek) {
                    let timeEntry = TimeEntry()
                    timeEntry.date = day
                    timeEntry.duration = Double.random(in: 600...29800) // between 10 minutes and 8 hours
                    timeEntry.task = userTask
                    context.insert(timeEntry)
                }
            }
        }
        context.insert(userTask)
        context.insert(project)
        return container
    }
}

#Preview {
    LineChartView()
        .modelContainer(LineChartView.mockModelContainer())
}

