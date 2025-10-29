//
//  AddTaskView.swift
//  Tadoodly
//
//  Created by modemlooper on 9/8/25.
//

import SwiftUI
import SwiftData
import UserNotifications

struct AddTask: View {
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var notificationManager = NotificationManager.shared
    @State private var showPermissionAlert = false
    
    @Query(sort: \Project.name) private var projects: [Project]
    
    var task: UserTask?
    
    @Binding var path: NavigationPath
    
    @State private var showingCopyAlert = false
    @State private var showingDeleteAlert = false
    @State private var showNameEmptyAlert = false
    @State private var showTitleRequiredUnsavedAlert = false
    @State private var showingDeleteTaskItemAlert = false
    @State private var showPastDueDateAlert = false
    @State private var indexToDeleteTaskItem: Int? = nil
    @FocusState private var focusedItemIndex: Int?
    @FocusState private var titleFieldFocused: Bool
    
    // Working task instance
    @State private var workingTask = UserTask()
    
    @State private var selectedUnit: ReminderUnit = .minutes
    @State private var selectedValue: Int = 5
    
    private let minuteOptions = [1, 5, 10, 15, 30, 45]
    private let hourOptions = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24]
    private let dayOptions = [1, 2, 3, 4, 5, 6, 7]
    private let weekOptions = [1, 2, 3, 4]
    private let monthOptions = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]
    
    private var availableValues: [Int] {
        switch selectedUnit {
        case .minutes: return minuteOptions
        case .hours: return hourOptions
        case .days: return dayOptions
        case .weeks: return weekOptions
        }
    }
    
    private var isDueDateInFuture: Bool {
        guard let dueDate = workingTask.dueDate else { return false }
        let component: Calendar.Component
        switch selectedUnit {
        case .minutes: component = .minute
        case .hours: component = .hour
        case .days: component = .day
        case .weeks: component = .weekOfYear
        }
        // Calculate the minimum required future date (now + selectedValue)
        guard let minimumDate = Calendar.current.date(byAdding: component, value: workingTask.reminderAmount, to: Date()) else { return false }
        // Due date must be at least as far in the future as the reminder time
        return dueDate >= minimumDate
    }
    
    private var reminderNotificationDate: Date? {
        guard let dueDate = workingTask.dueDate else { return nil }
        let component: Calendar.Component
        switch selectedUnit {
        case .minutes: component = .minute
        case .hours: component = .hour
        case .days: component = .day
        case .weeks: component = .weekOfYear
        }
        return Calendar.current.date(byAdding: component, value: -selectedValue, to: dueDate)
    }
    
    var body: some View {
        
        Form {
            titleSection
            reminderSection
            statusSection
            prioritySection
            completedSection
            projectSection
            timeTrackingSection
            checklistSection
        }
        .onAppear() {
            if let task = task {
                // Copy values from existing task to our working task
                workingTask = task
            } else {
                // Set defaults for new task
                workingTask.priority = .low
                workingTask.status = .todo
            }
            
            // Initialize reminder controls from persisted task values
            workingTask.reminder = task?.reminder ?? false
            workingTask.reminderUnitRaw = task?.reminderUnitRaw ?? "Minutes"
            workingTask.reminderAmount = task?.reminderAmount ?? 5
            
            if let existing = task, existing.reminder, let dueDate = existing.dueDate {
                let component: Calendar.Component
                switch ReminderUnit(rawValue: existing.reminderUnitRaw) {
                case .minutes?: component = .minute
                case .hours?: component = .hour
                case .days?: component = .day
                case .weeks?: component = .weekOfYear
                default: return
                }
                
                if let notificationDate = Calendar.current.date(byAdding: component, value: -existing.reminderAmount, to: dueDate),
                   notificationDate < Date() {
                    // Reminder time is in the past, clear it
                    workingTask.reminder = false
                    workingTask.reminderUnitRaw = "Minutes"
                    workingTask.reminderAmount = 5
                    // Cancel the notification
                    notificationManager.cancelNotification(id: "task_\(existing.id)")
                    // Save the change
                    try? modelContext.save()
                }
            } else {
                // No reminder set, clear any existing notification
                workingTask.reminder = false
                workingTask.reminderUnitRaw = "Minutes"
                workingTask.reminderAmount = 5
                // Cancel the notification
                notificationManager.cancelNotification(id: "task_\(workingTask.id)")
                // Save the change
                try? modelContext.save()
            }
            
        }
        .alert("Are you sure you want to duplicate this task?", isPresented: $showingCopyAlert, actions: {
            Button("Duplicate", role: .destructive) {
                if let task = task {
                    // Manually duplicate the task since `copy(modelcontext:)` doesn't exist
                    let newTask = UserTask()
                    newTask.title = task.title + " (Copy)"
                    newTask.taskDescription = task.taskDescription
                    newTask.dueDate = task.dueDate
                    newTask.priority = task.priority
                    newTask.status = task.status
                    newTask.completed = false
                    newTask.project = task.project
                    // Deep-copy checklist items if present
                    if let items = task.taskItems {
                        var cloned: [TaskItem] = []
                        cloned.reserveCapacity(items.count)
                        for item in items {
                            let newItem = TaskItem()
                            newItem.title = item.title
                            cloned.append(newItem)
                        }
                        newTask.taskItems = cloned
                    }
                    modelContext.insert(newTask)
                    try? modelContext.save()
                }
                path = NavigationPath()
            }
            
            Button("Cancel", role: .cancel) { }
        })
        .alert("Are you sure you want to delete this task?", isPresented: $showingDeleteAlert, actions: {
            Button("Delete", role: .destructive) {
                if let task = task {
                    modelContext.delete(task)
                    try? modelContext.save() // ensure persistence before popping
                    
                    path = NavigationPath()
                }
            }
            Button("Cancel", role: .cancel) {}
        })
        .alert("Title required", isPresented: $showTitleRequiredUnsavedAlert) {
            Button("Enter Title", role: .cancel) {
                titleFieldFocused = true
            }
            Button("Delete", role: .destructive) {
                if let task = task {
                    // Existing task: delete it
                    modelContext.delete(task)
                    try? modelContext.save()
                }
                // New task: nothing persisted yet, just dismiss
                dismiss()
            }
        } message: {
            Text("Please enter a title for this task or delete it.")
        }
        .toolbar {
            
            if task != nil {
                ToolbarItem(placement: .automatic) {
                    Button {
                        handleCopyTap()
                    } label: {
                        Label("Duplicate", systemImage: "document.on.document")
                    }
                }
            }
            
            if task != nil {
                
                ToolbarItem(placement: .automatic) {
                    Button {
                        handleDeleteTap()
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
                
            }
            
            // Custom back button that replaces the system one
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    handleBackButtonTap()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 17, weight: .medium))
                        
                    }
                    .foregroundColor(.primary)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
    }
    
    private var titleSection: some View {
        Section() {
            TextField("Title (required)", text: $workingTask.title)
                .focused($titleFieldFocused)
            
            TextField("Description", text: Binding(
                get: { workingTask.taskDescription ?? "" },
                set: { workingTask.taskDescription = $0.isEmpty ? nil : $0 }
            ), axis: .vertical)
            .lineLimit(3...6)
            
            
            VStack {
                Toggle(isOn: Binding<Bool>(
                    get: { workingTask.dueDate != nil },
                    set: { newValue in
                        if newValue {
                            // If enabling, set to existing date or now
                            workingTask.dueDate = workingTask.dueDate ?? Date()
                        } else {
                            // If disabling, clear date and reset reminder settings
                            workingTask.dueDate = nil
                            workingTask.reminder = false
                            workingTask.reminderAmount = 15
                            workingTask.reminderUnit = .minutes
                        }
                    }
                )) {
                    Text("Due Date")
                }
                
                
                if let _ = workingTask.dueDate {
                    HStack {
                        
                        DatePicker(
                            "",
                            selection: Binding(
                                get: { workingTask.dueDate ?? Date() },
                                set: { newValue in
                                    workingTask.dueDate = newValue
                                }
                            ),
                            displayedComponents: [.date, .hourAndMinute]
                        )
                        .labelsHidden()
                        .datePickerStyle(.compact)
                        
                        Spacer()
                    }
                    .padding(.top, 10)
                }
            }
            
        }
    }
    
    @ViewBuilder private var reminderSection: some View {
        
        Section() {
            
            ZStack {
                Toggle(isOn: Binding<Bool>(
                    get: { workingTask.reminder },
                    set: { newValue in
                        workingTask.reminder = newValue
                    }
                )) {
                    Text("Add Reminder")
                }
                .disabled(!isDueDateInFuture)
                .onChange(of: workingTask.reminder) { _, newValue in
                    if newValue {
                        workingTask.reminderUnitRaw = selectedUnit.rawValue
                        workingTask.reminderAmount = selectedValue
                    } else {
                        // When reminder is turned off, cancel any scheduled notification for this task
                        notificationManager.cancelNotification(id: "task_\(workingTask.id)")
                    }
                }
                
                // Invisible overlay to capture taps when disabled
                if !isDueDateInFuture {
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture {
                            showPastDueDateAlert = true
                        }
                }
            }
            
            
            
            Picker("Time Unit", selection: $selectedUnit) {
                ForEach(ReminderUnit.allCases, id: \.self) { unit in
                    Text(unit.rawValue).tag(unit)
                }
            }
            .onChange(of: selectedUnit) { _, _ in
                selectedValue = availableValues.first ?? 1
                workingTask.reminderUnitRaw = selectedUnit.rawValue
                workingTask.reminderAmount = selectedValue
            }
            
            
            Picker("Time Amount", selection: $selectedValue) {
                ForEach(availableValues, id: \.self) { value in
                    Text("\(value)").tag(value)
                }
            }
            .onChange(of: selectedValue) { _, _ in
                workingTask.reminderAmount = selectedValue
            }
            
            Text("Notification will be sent \(selectedValue) \(selectedUnit.rawValue.lowercased()) before due date")
                .font(.caption)
                .foregroundStyle(.secondary)
            
        }
        .alert(isPresented: $showPastDueDateAlert) {
            Alert(
                title: Text("Reminder Unavailable"),
                message: Text("The due date must be at least \(workingTask.reminderAmount) \(workingTask.reminderUnit.rawValue.lowercased()) in the future."),
                dismissButton: .default(Text("OK"))
            )
        }
        
        
    }
    
    private var statusSection: some View {
        Picker("Status", selection: $workingTask.status) {
            ForEach(TaskStatus.allCases, id: \.self) { status in
                Text(status.rawValue).tag(status as TaskStatus?)
            }
        }
    }
    
    private var prioritySection: some View {
        Picker("Priority", selection: $workingTask.priority) {
            ForEach(TaskPriority.allCases, id: \.self) { priority in
                Text(priority.rawValue).tag(priority as TaskPriority?)
            }
        }
    }
    
    private var completedSection: some View {
        Toggle(isOn: Binding<Bool>(
            get: { workingTask.completed },
            set: { newValue in
                workingTask.completed = newValue
                // When toggled on, set status to .completed
                if newValue {
                    workingTask.status = .done
                }
            }
        )) {
            Text("Completed")
        }
    }
    
    private var projectSection: some View {
        Picker("Project", selection: $workingTask.project) {
            Text("No Project").tag(nil as Project?)
            ForEach(projects, id: \.self) { project in
                Text(project.name).tag(project as Project?)
            }
        }
        .disabled(projects.isEmpty)
    }
    
    private var timeTrackingSection: some View {
        Group {
            if let task = task {
                Button(action: {
                    // Push a route for Time Entries via path navigation
                    path.append(TimeRoute(task: task))
                }) {
                    HStack {
                        Text("Time Tracking")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.secondary)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    private var checklistSection: some View {
        Section(header: Text("Checklist")) {
            Button(action: {
                let newItem = TaskItem()
                newItem.title = "Task Item"
                if workingTask.taskItems == nil {
                    workingTask.taskItems = []
                }
                workingTask.taskItems?.append(newItem)
                // Optionally focus the newly added item for quick editing
                focusedItemIndex = (workingTask.taskItems?.count ?? 1) - 1
            }) {
                Text("Add Item")
                    .foregroundColor(.accentColor)
            }.buttonStyle(.plain)
            
            if let taskItems = workingTask.taskItems {
                ForEach(taskItems.indices, id: \.self) { idx in
                    HStack {
                        TextField("Item title", text: Binding(
                            get: { taskItems[idx].title },
                            set: { newValue in
                                workingTask.taskItems?[idx].title = newValue
                            }
                        ))
                        .focused($focusedItemIndex, equals: idx)
                        
                        Button(action: {
                            workingTask.taskItems?.remove(at: idx)
                        }) {
                            Image(systemName: "minus.circle.fill")
                                .foregroundColor(.red)
                                .font(.headline)
                        }
                    }
                }
            }
        }
        
    }
    
    private func handleCopyTap() {
        showingCopyAlert = true
    }
    
    private func handleDeleteTap() {
        showingDeleteAlert = true
    }
    
    // MARK: - Back Button Handling
    private func handleBackButtonTap() {
        if workingTask.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            showTitleRequiredUnsavedAlert = true
            titleFieldFocused = true
            return
        }
        
        if task == nil {
            // Create new task
            modelContext.insert(workingTask)
        }
        
        workingTask.reminderUnitRaw = selectedUnit.rawValue
        workingTask.reminderAmount = selectedValue
        
        do {
            try modelContext.save()
            
            // Capture task properties BEFORE entering Task closure to avoid SwiftData concurrency issues
            let taskId = workingTask.id
            let hasReminder = workingTask.reminder
            let taskDueDate = workingTask.dueDate
            let taskTitle = workingTask.title
            let taskReminderUnit = workingTask.reminderUnitRaw
            let taskReminderAmount = workingTask.reminderAmount
            
            // Schedule or cancel reminder based on current settings
            Task {
                if hasReminder, let date = taskDueDate {
                    // Verify authorization before scheduling
                    let status = await notificationManager.checkAuthorizationStatus()
                    if status == .authorized || status == .provisional {
                        print("Schedule: \(taskTitle)")
                        try await notificationManager.scheduleReminderBeforeDueDate(
                            id: "task_\(taskId)",
                            title: "Task Due in \(taskReminderAmount) \(taskReminderUnit)",
                            body: taskTitle,
                            dueDate: date,
                            reminderUnitRaw: taskReminderUnit,
                            reminderAmount: taskReminderAmount
                        )
                    } else {
                        print("⚠️ Cannot schedule notification: Not authorized")
                    }
                } else {
                    notificationManager.cancelNotification(id: "task_\(taskId)")
                }
            }
            dismiss()
        } catch {
            // Replace with your UI error handling if desired
            print("Failed to save model context: \(error)")
        }
    }
    
}
