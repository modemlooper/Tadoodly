//
//  TadoodlyApp.swift
//  Tadoodly
//
//  Created by modemlooper on 5/25/25.
//

import SwiftUI
import SwiftData

@main
struct TadoodlyApp: App {
    let container: ModelContainer
    
    @StateObject private var router = NavigationRouter()

     init() {
         let schema = Schema([
             Project.self,
             UserTask.self,
             TimeEntry.self,
         ])
         let config = ModelConfiguration("iCloud.com.tadoodly.app")
         do {
             container = try ModelContainer(for: schema, configurations: [config])
         } catch {
             fatalError("Could not create ModelContainer: \(error)")
         }
     }

    var body: some Scene {
     
        WindowGroup {
            if #available(iOS 26.0, *) {
                //ContentView()
                    //.environmentObject(ProjectPlannerViewModel())
                
            } else {
                ContentView()
            }
        }
        .modelContainer(container)
        .environmentObject(router)
    }
}
