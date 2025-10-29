//
//  NotificationManager.swift
//  Tadoodly
//
//  Created by modemlooper on 10/28/25.
//

import Foundation
import UserNotifications
import SwiftData

enum ReminderUnit: String, CaseIterable {
    case minutes = "Minutes"
    case hours = "Hours"
    case days = "Days"
    case weeks = "Weeks"
}

enum ReminderTimeUnit {
    case minutes(Int)
    case hours(Int)
    case days(Int)
    case weeks(Int)
    
    var calendarComponent: Calendar.Component {
        switch self {
        case .minutes: return .minute
        case .hours: return .hour
        case .days: return .day
        case .weeks: return .weekOfYear
        }
    }
    
    var value: Int {
        switch self {
        case .minutes(let val): return -val
        case .hours(let val): return -val
        case .days(let val): return -val
        case .weeks(let val): return -val
        }
    }
    
    var displayName: String {
        switch self {
        case .minutes(let val): return "\(val) minute\(val == 1 ? "" : "s")"
        case .hours(let val): return "\(val) hour\(val == 1 ? "" : "s")"
        case .days(let val): return "\(val) day\(val == 1 ? "" : "s")"
        case .weeks(let val): return "\(val) week\(val == 1 ? "" : "s")"
        }
    }
}

enum NotificationError: Error {
    case invalidDate
    case dateInPast
}

@Observable
class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()
    
    var shouldShowPermissionPrompt = false
    var modelContext: ModelContext?
    var onTaskNotificationTapped: ((UUID) -> Void)?
    
    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }
    
    func requestAuthorization() async throws {
        try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
    }
    
    func checkAuthorizationStatus() async -> UNAuthorizationStatus {
        await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }
    
    func checkIfShouldPromptForPermission() async {
        let status = await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
        
        // Only prompt if not yet determined
        if status == .notDetermined {
            await MainActor.run {
                shouldShowPermissionPrompt = true
            }
        }
    }
    
    private func hasPendingNotification(withId id: String) async -> Bool {
        await withCheckedContinuation { continuation in
            UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
                let exists = requests.contains { $0.identifier == id }
                continuation.resume(returning: exists)
            }
        }
    }
    
    func scheduleTestNotification(delaySeconds: Int = 5) async throws {
        let testDate = Date().addingTimeInterval(TimeInterval(delaySeconds))
        try await scheduleNotification(
            id: "test-notification-12345",
            title: "Test Notification",
            body: "This is a test notification from Tadoodly",
            date: testDate,
            replaceExisting: true
        )
    }
    
    func debugPendingNotifications() async {
        let requests = await getShceduledNotifications()
        print("📱 Pending Notifications: \(requests.count)")
        for request in requests {
            print("  - ID: \(request.identifier)")
            print("    Title: \(request.content.title)")
            print("    Body: \(request.content.body)")
            if let trigger = request.trigger as? UNCalendarNotificationTrigger,
               let nextTriggerDate = trigger.nextTriggerDate() {
                print("    Scheduled for: \(nextTriggerDate)")
            }
        }
    }
    
    // MARK: - UNUserNotificationCenterDelegate Handles notification taps
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let identifier = response.notification.request.identifier
        
        // Check if this is a task reminder notification (format: "task_<UUID>")
        if identifier.hasPrefix("task_") {
            let taskIdString = String(identifier.dropFirst(5)) // Remove "task_" prefix
            
            if let taskId = UUID(uuidString: taskIdString) {
                // Notify the app to navigate to the task using UUID
                // Reminder will be cleared when the task view opens if it's in the past
                onTaskNotificationTapped?(taskId)
            }
            
            // Cancel the notification
            cancelNotification(id: identifier)
        }
        
        completionHandler()
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        // .list shows in Notification Center, .banner shows as banner at top
        if #available(iOS 14.0, *) {
            completionHandler([.banner, .list, .sound, .badge])
        } else {
            completionHandler([.alert, .sound, .badge])
        }
    }
}


extension NotificationManager {
    func scheduleNotification(
        id: String,
        title: String,
        body: String,
        date: Date,
        replaceExisting: Bool = true
    ) async throws {
        // Check for existing pending request with same id
        if await hasPendingNotification(withId: id) {
            if replaceExisting {
                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
            } else {
                // Skip scheduling to avoid duplicate
                return
            }
        }
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        // Create date components for the trigger
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: id,
            content: content,
            trigger: trigger
        )
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
    
    func getNotificationSettings() async -> UNNotificationSettings {
        await withCheckedContinuation { continuation in
            UNUserNotificationCenter.current().getNotificationSettings { settings in
                continuation.resume(returning: settings)
            }
        }
    }
    
    func getShceduledNotifications() async -> [UNNotificationRequest] {
        await withCheckedContinuation { continuation in
            UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
                continuation.resume(returning: requests)
            }
        }
    }
    
    func cancelNotification(id: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
    }
    
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    func scheduleReminderBeforeDueDate(
        id: String,
        title: String,
        body: String,
        dueDate: Date,
        reminderUnitRaw: String,
        reminderAmount: Int,
        replaceExisting: Bool = true
    ) async throws {
        // Map raw unit string to Calendar.Component and negative offset
        let unit = reminderUnitRaw
        let amount = reminderAmount
        let component: Calendar.Component
        switch unit {
        case "Minutes": component = .minute
        case "Hours": component = .hour
        case "Days": component = .day
        case "Weeks": component = .weekOfYear
        default: component = .minute
        }
        let offset = -abs(amount)
        
        guard let notificationDate = Calendar.current.date(
            byAdding: component,
            value: offset,
            to: dueDate
        ) else {
            throw NotificationError.invalidDate
        }
        
        // Don't schedule if the notification date is in the past
        guard notificationDate > Date() else {
            throw NotificationError.dateInPast
        }
        
        try await scheduleNotification(
            id: id,
            title: title,
            body: body,
            date: notificationDate,
            replaceExisting: replaceExisting
        )
    }
    
    func scheduleRepeatingNotification(
        id: String,
        title: String,
        body: String,
        hour: Int,
        minute: Int,
        replaceExisting: Bool = true
    ) async throws {
        // Check for existing pending request with same id
        if await hasPendingNotification(withId: id) {
            if replaceExisting {
                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
            } else {
                return
            }
        }
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: true // This makes it repeat daily
        )
        
        let request = UNNotificationRequest(
            identifier: id,
            content: content,
            trigger: trigger
        )
        
        try await UNUserNotificationCenter.current().add(request)
    }
    
}
