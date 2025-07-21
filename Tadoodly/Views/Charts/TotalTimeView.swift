//
//  TotalTimeView.swift
//  Tadoodly
//
//  Created by modemlooper on 7/12/25.
//

import SwiftUI
import SwiftData

struct TotalTimeView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Query private var timeEntries: [TimeEntry]
    
    private var currentDayTotalSeconds: TimeInterval {
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? now
        return timeEntries.filter {
            $0.date >= startOfDay && $0.date < endOfDay
        }.reduce(0) { $0 + $1.duration }
    }
    
    private var currentWeekTotalSeconds: TimeInterval {
        let calendar = Calendar.current
        let now = Date()
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: now) else { return 0 }
        return timeEntries.filter {
            $0.date >= weekInterval.start && $0.date < weekInterval.end
        }.reduce(0) { $0 + $1.duration }
    }
    
    private var currentMonthTotalSeconds: TimeInterval {
        let calendar = Calendar.current
        let now = Date()
        guard let monthInterval = calendar.dateInterval(of: .month, for: now) else { return 0 }
        return timeEntries.filter {
            $0.date >= monthInterval.start && $0.date < monthInterval.end
        }.reduce(0) { $0 + $1.duration }
    }
    
    private var currentYearTotalSeconds: TimeInterval {
        let calendar = Calendar.current
        let now = Date()
        guard let monthInterval = calendar.dateInterval(of: .year, for: now) else { return 0 }
        return timeEntries.filter {
            $0.date >= monthInterval.start && $0.date < monthInterval.end
        }.reduce(0) { $0 + $1.duration }
    }
    
    private func formattedTime(_ seconds: TimeInterval) -> String {
        if seconds < 60 {
            return String(format: "%.0f Sec", seconds)
        } else if seconds < 3600 {
            return String(format: "%.0f Min", seconds / 60)
        } else {
            return String(format: "%.0f Hrs", seconds / 3600)
        }
    }
    
    var body: some View {
        ZStack {
            
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(colorScheme == .dark ? Color(white: 0.12) : .white)
                .shadow(color: Color.black.opacity(0.05), radius: 3, x: 1, y: 1)
            
           
            VStack(alignment: .leading, spacing: 6) {
                Text("Total Time")
                    .font(.headline.bold())
                
                Spacer()
                
                HStack {
                    Text("Today")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(formattedTime(currentDayTotalSeconds))")
                        .font(.subheadline.bold())
                        .foregroundColor(.secondary)
                }
                
                Divider()
                
                HStack {
                    Text("Week")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(formattedTime(currentWeekTotalSeconds))")
                        .font(.subheadline.bold())
                        .foregroundColor(.secondary)
                }

                Divider()
                HStack {
                    Text("Month")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(formattedTime(currentMonthTotalSeconds))")
                        .font(.subheadline.bold())
                        .foregroundColor(.secondary)
                }
                
                Divider()
                HStack {
                    Text("Year")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(formattedTime(currentYearTotalSeconds))")
                        .font(.subheadline.bold())
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            
        }
       
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: TimeEntry.self, configurations: config)
    let context = container.mainContext
    let calendar = Calendar.current
    let now = Date()
    // Today (add 2 hours)
    let entryToday = TimeEntry(startTime: now)
    entryToday.duration = 2 * 3600 // 2 hours
    entryToday.date = calendar.startOfDay(for: now)
    context.insert(entryToday)
    // This week, not today (add 3 hours, e.g., two days ago)
    let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: now)!
    let entryWeek = TimeEntry(startTime: twoDaysAgo)
    entryWeek.duration = 3 * 3600 // 3 hours
    entryWeek.date = calendar.startOfDay(for: twoDaysAgo)
    context.insert(entryWeek)
    // This month, not this week (add 4 hours, e.g., 10 days ago)
    let tenDaysAgo = calendar.date(byAdding: .day, value: -10, to: now)!
    let entryMonth = TimeEntry(startTime: tenDaysAgo)
    entryMonth.duration = 4 * 3600 // 4 hours
    entryMonth.date = calendar.startOfDay(for: tenDaysAgo)
    context.insert(entryMonth)
    return TotalTimeView().modelContainer(container)
        .frame(width: 200)
}
