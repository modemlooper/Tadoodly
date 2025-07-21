//
//  DailyAverageView.swift
//  Tadoodly
//
//  Created by modemlooper on 7/13/25.
//

import SwiftUI
import Charts
import SwiftData

enum ChartSeries: String {
    case daily = "Daily"
    case average = "Average"
}

struct CombinedPoint: Identifiable {
    var id: Date { date }
    let date: Date
    let value: Double
    let series: ChartSeries
}

struct DailyAverageView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    @Query(sort: [SortDescriptor<TimeEntry>(\TimeEntry.date)]) private var timeEntries: [TimeEntry]
    
    enum RangeType: String, CaseIterable, Identifiable {
        case month = "1M", threeMonths = "3M", sixMonths = "6M", year = "1yr"
        var id: String { rawValue }
    }

    struct DataPoint: Identifiable {
        var id: Date { date }
        let date: Date
        let value: Double
    }

    @State private var selectedRange: RangeType = .month
    @State private var aggregatedData: [DataPoint] = []
    @State private var dailyAverage: Double = 0

    private func calculateChartData() async {
        await MainActor.run {
            self.aggregatedData = []
            self.dailyAverage = 0
        }
        let calendar = Calendar.current
        let end = calendar.startOfDay(for: Date())
        let start: Date
        switch selectedRange {
        case .month:
            start = calendar.date(byAdding: .day, value: -29, to: end) ?? end
        case .threeMonths:
            start = calendar.date(byAdding: .day, value: -89, to: end) ?? end
        case .sixMonths:
            start = calendar.date(byAdding: .day, value: -179, to: end) ?? end
        case .year:
            start = calendar.date(byAdding: .year, value: -1, to: end) ?? end
        }
        let allDays: [Date] = stride(from: start, through: end, by: 60*60*24).map { calendar.startOfDay(for: $0) }
        let filteredEntries = timeEntries.filter { $0.date >= start && $0.date <= end }
        let grouped = Dictionary(grouping: filteredEntries) { calendar.startOfDay(for: $0.date) }
        let totals = grouped.mapValues { $0.reduce(0) { $0 + $1.duration / 3600 } }
        let newAggregatedData = allDays.map { day in DataPoint(date: day, value: totals[day] ?? 0) }.sorted { $0.date < $1.date }
        let sum = newAggregatedData.reduce(0) { $0 + $1.value }
        let newDailyAverage = newAggregatedData.isEmpty ? 0 : sum / Double(newAggregatedData.count)
        await MainActor.run {
            self.aggregatedData = newAggregatedData
            self.dailyAverage = newDailyAverage
        }
    }
    
    var body: some View {
        let combinedData = aggregatedData.flatMap { [
            CombinedPoint(date: $0.date, value: $0.value, series: .daily),
            CombinedPoint(date: $0.date, value: dailyAverage, series: .average)
        ] }
        
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(colorScheme == .dark ? Color(white: 0.12) : .white)
                .shadow(color: Color.black.opacity(0.05), radius: 3, x: 1, y: 1)
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .center, spacing: 10) {
                    Text("Performance")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Spacer()
                    RangePicker(selected: $selectedRange)
                }
                Text(String(format: "%.2f average hours", dailyAverage))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 6)
                
                Chart {
                    ForEach(combinedData) { point in
                        LineMark(
                            x: .value("Date", point.date),
                            y: .value("Value", point.value)
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(by: .value("Series", point.series.rawValue))
                        
                    }
                }
                .chartLegend(.hidden)
                .chartYAxis() {
                    AxisMarks(position: .leading)
                }
                .chartXAxis(.hidden)
                .frame(height: 180)
                HStack {
                    Label("Daily", systemImage: "minus").foregroundColor(.blue)
                    Spacer()
                    Label("Average", systemImage: "minus").foregroundColor(.green)
                }
                .font(.subheadline)
                .padding(.vertical, 8)
            }
            .padding()
        }
        .task {
            await calculateChartData()
        }
        .onChange(of: selectedRange) { _, _ in
            Task {
                await calculateChartData()
            }
        }
        .onChange(of: timeEntries) { _, _ in
            Task {
                await calculateChartData()
            }
        }
    }
}

struct RangePicker: View {
    @Binding var selected: DailyAverageView.RangeType
    var body: some View {
        HStack(spacing: 8) {
            ForEach(DailyAverageView.RangeType.allCases) { range in
                Button(action: { selected = range }) {
                    Text(range.rawValue)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 6)
                        .background(selected == range ? Color.accentColor.opacity(0.18) : Color.clear)
                        .clipShape(Capsule())
                        .foregroundStyle(selected == range ? Color.accentColor : .secondary)
                }
            }
        }
        .background(Color(.systemGray5).opacity(0.1))
        .clipShape(Capsule())
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: TimeEntry.self, configurations: config)
    let context = container.mainContext
    let calendar = Calendar.current
    let now = Date()
    // Add 30 days of entries with varying durations (0 to 4 hours)
    for i in 0..<60 {
        let entry = TimeEntry()
        let entryDate = calendar.date(byAdding: .day, value: -i, to: now) ?? now
        entry.date = calendar.startOfDay(for: entryDate)
        entry.duration = Double.random(in: 0...8*3600) // 0–4 hours
        context.insert(entry)
    }
    return DailyAverageView().modelContainer(container)
}
