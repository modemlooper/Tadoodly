//
//  ScheduleView.swift
//  Tadoodly
//
//  Created by modemlooper on 6/20/25.
//

import SwiftUI
import SwiftData

struct ScheduleView: View {
    @EnvironmentObject private var router: NavigationRouter
    @State private var selectedDate: Date? = .now
    @State private var currentMonth: Date = .now
    @Query private var tasks: [UserTask]
    
    @State private var showingCalendar = true
    @State private var pendingDeleteOffsets: IndexSet = []
    
    private var filteredTasks: [UserTask] {
        let calendar = Calendar.current
        guard let selectedDate else { return [] }
        return tasks.filter { task in
            if let due = task.dueDate {
                return calendar.isDate(due, inSameDayAs: selectedDate)
            }
            return false
        }
    }
    
    private var formattedSelectedDate: String {
        guard let selectedDate else { return "" }
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: selectedDate)
    }
        
    var body: some View {
        
        ScrollView {
            VStack() {
                
                if showingCalendar == true {
                    CustomCalendarView(selectedDate: $selectedDate, currentMonth: $currentMonth, tasks: tasks)
                    Divider()
                }
                
                if filteredTasks.isEmpty {
                    Text("No tasks for this date.")
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    if selectedDate != nil {
                        Text("Tasks for \(formattedSelectedDate)")
                            .font(.title3)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                    }
                    else {
                        Text("No date selected")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding()
                    }
                }
                
                ForEach(filteredTasks, id: \.id) { task in
                    
                    TaskRow(task: task)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            router.navigate(.viewTask(task))
                        }
                    Divider()
                }
                
           
            }
            .frame(maxWidth: .infinity)
            .navigationTitle("Schedule")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingCalendar.toggle()
                    } label: {
                        Image(systemName: "calendar")
                            .foregroundColor(showingCalendar ? .primary : .secondary)
                    }
                }
            }
            
            
        }
    }
}

struct CustomCalendarView: View {
    @Binding var selectedDate: Date?
    @Binding var currentMonth: Date
    let tasks: [UserTask]
    
    private static let weekdaySymbols = ["S", "M", "T", "W", "T", "F", "S"]
    
    private var calendar: Calendar { .current }
    private var monthInterval: DateInterval {
        return calendar.dateInterval(of: .month, for: currentMonth) ?? DateInterval()
    }
    private var days: [Date?] {
        let startDay = calendar.component(.weekday, from: monthInterval.start)
        // Adjusting leading empty count to be non-negative and to align with calendar.firstWeekday
        let firstWeekday = calendar.firstWeekday // Usually 1 (Sunday)
        let leadingCount = (startDay >= firstWeekday) ? startDay - firstWeekday : 7 - (firstWeekday - startDay)
        let leadingEmpty = Array(repeating: Optional<Date>(nil), count: leadingCount)
        let monthDays = stride(from: monthInterval.start, to: monthInterval.end, by: 60*60*24).map { Optional($0) }
        return leadingEmpty + monthDays
    }
    private var daysWithTasks: Set<Date> {
        Set(tasks.compactMap { $0.dueDate }.map { calendar.startOfDay(for: $0) })
    }
    
    private var weekdayHeaders: some View {
        ForEach(0..<Self.weekdaySymbols.count, id: \.self) { index in
            Text(Self.weekdaySymbols[index]).font(.caption).bold()
        }
    }
    
    private var dayButtons: some View {
        ForEach(days.indices, id: \.self) { index in
            if let date = days[index] {
                let isSelected = selectedDate.flatMap { calendar.isDate(date, inSameDayAs: $0) } ?? false
                let isToday = calendar.isDateInToday(date)
                let hasTask = daysWithTasks.contains(calendar.startOfDay(for: date))
                Button(action: { selectedDate = date }) {
                    ZStack {
                        if isSelected {
                            Circle().fill(Color.accentColor.opacity(0.3))
                                .frame(width: 36, height: 36)
                        }
                        if isToday {
                            Circle()
                                .stroke(Color.accentColor, lineWidth: 2)
                                .frame(width: 36, height: 36)
                        }
                        
                        if hasTask && !isToday {
                            Text("\(calendar.component(.day, from: date))")
                                .foregroundColor(.accentColor)
                                .fontWeight(.regular)
                        } else {
                            Text("\(calendar.component(.day, from: date))")
                                .foregroundColor(isSelected ? .accentColor : .primary)
                                .fontWeight(isSelected ? .bold : .regular)
                        }
                    }
                    .frame(width: 36, height: 36)
                }
                .buttonStyle(.plain)
            } else {
                Color.clear.frame(width: 36, height: 36)
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Button(action: { changeMonth(by: -1) }) {
                    Image(systemName: "chevron.left")
                }
                Spacer()
                Text(monthYearString(for: currentMonth))
                    .font(.headline)
                    .onTapGesture(count: 2) {
                        currentMonth = .now
                    }
                Spacer()
                Button(action: { changeMonth(by: 1) }) {
                    Image(systemName: "chevron.right")
                }
            }
            .padding(.horizontal)
            let columns = Array(repeating: GridItem(.flexible()), count: 7)
            LazyVGrid(columns: columns, spacing: 8) {
                weekdayHeaders
                dayButtons
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
    }
    
    private func changeMonth(by value: Int) {
        if let newMonth = calendar.date(byAdding: .month, value: value, to: currentMonth) {
            currentMonth = newMonth
        }
    }
    private func monthYearString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "LLLL yyyy"
        return formatter.string(from: date)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: UserTask.self, configurations: config)
    let context = container.mainContext

    let sampleTask = UserTask(title: "Sample Task with Due Date", description: "Demo for preview")
    sampleTask.dueDate = Calendar.current.date(byAdding: .day, value: 2, to: Date())
    context.insert(sampleTask)

    return
    NavigationStack {
        ScheduleView()
            .modelContainer(container)
            .environmentObject(NavigationRouter())
    }
}

