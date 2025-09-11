//
//  TadoodlyApp.swift
//  Tadoodly
//
//  Created by modemlooper on 5/25/25.
//

import SwiftUI
import SwiftData
import CloudKit

@main
struct TadoodlyApp: App {
    let container: ModelContainer
    
    @StateObject private var router = NavigationRouter()
    @AppStorage("isDarkMode") private var isDarkMode: Bool = false
    @AppStorage("didInitializeColorScheme") private var didInitializeColorScheme: Bool = false

    init() {
        let schema = Schema([
            Project.self,
            UserTask.self,
            TimeEntry.self,
        ])
        
        // Check CloudKit availability and create appropriate configuration
        let config: ModelConfiguration
        
        if Self.isCloudKitAvailable() {
            // Use CloudKit configuration when iCloud account is available
            config = ModelConfiguration("iCloud.com.tadoodly.app")
            print("✅ CloudKit available - using iCloud sync")
        } else {
            // Fallback to local storage when CloudKit is unavailable
            // Create a proper local storage configuration with explicit store name
            config = ModelConfiguration("TadoodlyLocal", cloudKitDatabase: .none)
            print("⚠️ CloudKit unavailable - using local storage only")
        }
        
        do {
            container = try ModelContainer(for: schema, configurations: [config])
        } catch {
            // If CloudKit configuration fails, fallback to local storage
            print("❌ CloudKit configuration failed: \(error)")
            print("🔄 Falling back to local storage...")
            
            let fallbackConfig = ModelConfiguration("TadoodlyLocal", cloudKitDatabase: .none)
            do {
                container = try ModelContainer(for: schema, configurations: [fallbackConfig])
                print("✅ Local storage configuration successful")
            } catch {
                fatalError("Could not create ModelContainer with local storage: \(error)")
            }
        }
    }
    
    /// Check if CloudKit is available by verifying iCloud account status
    private static func isCloudKitAvailable() -> Bool {
        let container = CKContainer(identifier: "iCloud.com.tadoodly.app")
        var isAvailable = false
        let semaphore = DispatchSemaphore(value: 0)
        
        container.accountStatus { status, error in
            switch status {
            case .available:
                isAvailable = true
            case .noAccount:
                print("ℹ️ No iCloud account signed in")
                isAvailable = false
            case .restricted:
                print("ℹ️ iCloud account restricted")
                isAvailable = false
            case .couldNotDetermine:
                print("ℹ️ Could not determine iCloud account status")
                isAvailable = false
            case .temporarilyUnavailable:
                print("ℹ️ iCloud temporarily unavailable")
                isAvailable = false
            @unknown default:
                print("ℹ️ Unknown iCloud account status")
                isAvailable = false
            }
            semaphore.signal()
        }
        
        semaphore.wait()
        return isAvailable
    }
    
    var body: some Scene {
        WindowGroup {
            // Your existing root selection logic
            Group {
                if #available(iOS 26.0, *) {
                    #if canImport(FoundationModels)
                    iOSRootView()
                        .environment(ProjectPlannerViewModel())
                    #else
                    iOSRootView()
                    #endif
                } else {
                    iOSRootView()
                }
            }
            .onAppear {
                // Optional: mirror system on first launch
                if !didInitializeColorScheme {
                    isDarkMode = (UITraitCollection.current.userInterfaceStyle == .dark)
                    didInitializeColorScheme = true
                }
            }
            .preferredColorScheme(isDarkMode ? .dark : .light)
        }
        .modelContainer(container)
        .environmentObject(router)
    }
}
