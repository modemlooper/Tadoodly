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
import Playgrounds

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
        let currentWeekDate = calendar.date(byAdding: .weekOfYear, value: weekOffset, to: Date())!
        let weekInterval = calendar.dateInterval(of: .weekOfYear, for: currentWeekDate) ?? calendar.dateInterval(of: .weekOfMonth, for: currentWeekDate)!
        let startOfWeek = weekInterval.start
        let endOfWeek = calendar.date(byAdding: .day, value: 7, to: startOfWeek) ?? weekInterval.end
        
        // Create array of 7 days for the week
        let days: [Date] = (0..<7).map { calendar.date(byAdding: .day, value: $0, to: startOfWeek)! }
        
        // Filter time entries for the current week using startTime
        let weekTimeEntries = timeEntries.filter { entry in
            let entryStartDate = calendar.startOfDay(for: entry.startTime)
            return entryStartDate >= startOfWeek && entryStartDate < endOfWeek
        }
        
        // Group time entries by day using startTime
        let grouped = Dictionary(grouping: weekTimeEntries) { entry in
            calendar.startOfDay(for: entry.startTime)
        }
        
        // Calculate total duration for each day
        let actuals: [Date: Double] = grouped.mapValues { entries in
            entries.reduce(0.0) { total, entry in
                let entryDuration = entry.endTime.timeIntervalSince(entry.startTime) / 3600.0 // Convert to hours
                return total + entryDuration
            }
        }
        
        return days.map { date in
            (date: date, totalDuration: actuals[date] ?? 0.0)
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
}
