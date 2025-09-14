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
        
        let todayEntries = timeEntries.filter {
            $0.startTime >= startOfDay && $0.startTime < endOfDay
        }
        
        print("DEBUG: Today entries count: \(todayEntries.count)")
        print("DEBUG: All entries count: \(timeEntries.count)")
        print("DEBUG: Start of day: \(startOfDay)")
        print("DEBUG: End of day: \(endOfDay)")
        
        for entry in timeEntries.prefix(3) {
            print("DEBUG: Entry startTime: \(entry.startTime), duration: \(entry.endTime.timeIntervalSince(entry.startTime))")
        }
        
        return todayEntries.reduce(0) { $0 + $1.endTime.timeIntervalSince($1.startTime) }
    }
    
    private var currentWeekTotalSeconds: TimeInterval {
        let calendar = Calendar.current
        let now = Date()
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: now) else { return 0 }
        return timeEntries.filter {
            $0.startTime >= weekInterval.start && $0.startTime < weekInterval.end
        }.reduce(0) { $0 + $1.endTime.timeIntervalSince($1.startTime) }
    }
    
    private var currentMonthTotalSeconds: TimeInterval {
        let calendar = Calendar.current
        let now = Date()
        guard let monthInterval = calendar.dateInterval(of: .month, for: now) else { return 0 }
        return timeEntries.filter {
            $0.startTime >= monthInterval.start && $0.startTime < monthInterval.end
        }.reduce(0) { $0 + $1.endTime.timeIntervalSince($1.startTime) }
    }
    
    private var currentYearTotalSeconds: TimeInterval {
        let calendar = Calendar.current
        let now = Date()
        guard let yearInterval = calendar.dateInterval(of: .year, for: now) else { return 0 }
        return timeEntries.filter {
            $0.startTime >= yearInterval.start && $0.startTime < yearInterval.end
        }.reduce(0) { $0 + $1.endTime.timeIntervalSince($1.startTime)}
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

