//
//  TaskSort.swift
//  Tadoodly
//
//  Created by modemlooper on 9/13/25.
//

import SwiftUI

enum TaskListSortOption: String, CaseIterable, Identifiable {
    case updateAt = "Recent"
    case createdAt = "Date Created"
    case dueDate = "Due Date"
    case priority = "Priority"
    case title = "Title"
    case status = "Status"
    case projectName = "Project"
    
    var id: String { self.rawValue }
}


struct TaskListOptionsPopover: View {
   
    @Binding var selectedSortOption: TaskListSortOption
    @AppStorage("showCompleted") private var showCompleted: Bool = false
    @Binding var isExpanded: Bool
    @Binding var isPopoverPresented: Bool
    @Binding var path: NavigationPath
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            DisclosureGroup(
                content: {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(TaskListSortOption.allCases) { option in
                            Divider()
                            Button(action: {
                                withAnimation {
                                    selectedSortOption = option
                                }
                            }) {
                                HStack {
                                    if selectedSortOption == option {
                                        Image(systemName: "checkmark")
                                            .font(.subheadline)
                                            .foregroundColor(.accentColor)
                                    } else {
                                        Image(systemName: "checkmark")
                                            .opacity(0)
                                    }
                                    Text(option.rawValue)
                                        .font(.subheadline)
                                        .foregroundColor(.primary)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                },
                label: {
                    HStack {
                        Image(systemName: "arrow.up.arrow.down")
                            .foregroundColor(Color.gray)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Sort By")
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            Text(selectedSortOption.rawValue)
                                .font(.subheadline)
                                .foregroundColor(Color.gray)
                        }
                        Spacer()
                    }
                }
            )
            .frame(minWidth: 160)
            Divider()
            Button(action: {
                showCompleted.toggle()
            }) {
                HStack {
                    Image(systemName: "checkmark")
                        .font(.subheadline)
                        .opacity(showCompleted ? 1 : 0)
                    Text("Show Completed")
                }
            }
            Divider()
            Button(action: {
                isPopoverPresented = false
                path.append(SettingstRoute())
                
            }) {
                HStack {
                    Image(systemName: "checkmark")
                        .opacity(0)
                    Text("Settings")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.accentColor)
                        
                }
            }
        }
        .padding()
        .presentationCompactAdaptation(.none)
    }
}
