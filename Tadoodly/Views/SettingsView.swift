//
//  SettingsView.swift
//  Tadoodly
//
//  Created by modemlooper on 6/8/25.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var path: NavigationPath
    @State private var showDeleteAlert = false
    @AppStorage("isDarkMode") private var isDarkMode: Bool = false
    @AppStorage("isAssistEnabled") private var isAssistEnabled: Bool = true
    
    var body: some View {
        List {
            Toggle(isOn: $isDarkMode) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "circle.righthalf.filled.inverse")
                        .font(Font.system(size: 16))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Dark Mode")
                    }
                }
            }
            
            Toggle(isOn: $isAssistEnabled) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "sparkles")
                        .font(Font.system(size: 18))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("AI Project Assistant")
                        Text(isAssistEnabled ? "Disable AI project creation assistance"
                                             : "Enable AI project creation assistance")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Section {
                Button("Delete App Data", role: .destructive) {
                    showDeleteAlert = true
                }
            }
        }
        .navigationBarTitle("Settings")
        .alert("Delete All App Data?", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                deleteAllAppData()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently erase all projects, tasks, and time entries. This cannot be undone.")
        }
    }
    
    private func deleteAllAppData() {
        // Delete all Projects
        let projects = try? modelContext.fetch(FetchDescriptor<Project>())
        projects?.forEach { modelContext.delete($0) }
        // Delete all UserTasks
        let tasks = try? modelContext.fetch(FetchDescriptor<UserTask>())
        tasks?.forEach { modelContext.delete($0) }
        // Delete all TimeEntries
        let entries = try? modelContext.fetch(FetchDescriptor<TimeEntry>())
        entries?.forEach { modelContext.delete($0) }
        try? modelContext.save()
    }
}

