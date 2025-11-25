//
//  TaksDetail.swift
//  Tadoodly
//
//  Created by modemlooper on 9/8/25.
//

import SwiftUI


struct TaskDetail: View {
    
    @Environment(\.modelContext) private var modelContext
    
    let task: UserTask?
    
    private var chipColor: Color {
        switch task!.status {
        case .inProgress:
            return .green
        case .onHold:
            return .yellow
        case .cancelled:
            return .red
        default:
            return .blue
        }
    }
    
    var body: some View {
        
        ScrollView {
            VStack(alignment:.leading, spacing: 20) {
                
                HStack(alignment: .top) {
                    
                    VStack(alignment:.leading, spacing: 0) {
                        
                        if let status = task?.status {
                            Text(status.rawValue)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .padding(.bottom, 14)
                            
                        }
                        
                        //Status badge
//                        StatusChip(task: task!)
//                            .padding(.bottom, 16)
                        
                        // Title
                        if let title = task?.title, !title.isEmpty {
                            Text(title)
                                .font(.title3)
                                .fontWeight(.semibold)
                        }
                        
                        // Description
                        if let desc = task?.taskDescription, !desc.isEmpty {
                            Text(desc)
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        if let task = task {
                            TimeCounterView(
                                task: task,
                                fontSize: 18
                            )
                            .padding(.bottom, 10)
                            
                            TimeButtonView(
                                task: task,
                                fontSize: 48
                            )
                        }
                    }
                }
                
                
                HStack(spacing: 18) {
                    
                    
                    HStack(spacing: 4) {
                        Image(systemName: "flag")
                        Text(task?.priority?.rawValue ?? "")
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    
                    if let dueDate = task?.dueDate {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                            Text("Due \(dueDate, format: .dateTime.month(.abbreviated).day())")
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    }
                    
                    if let project = task?.project {
                        HStack(spacing: 4) {
                            Image(systemName: "folder")
                            Text(project.name)
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    }
                    
                }
            }
            .padding(12)
            
            Divider()
            
            // Checklist header
            HStack {
                Text("Checklist")
                    .font(.headline)
                Spacer()
                if let items = task?.taskItems {
                    let completed = items.filter { $0.completed }.count
                    Text("\(completed)/\(items.count)")
                        .font(.subheadline)
                        .foregroundStyle(.gray)
                } else {
                    Text("0/0")
                        .font(.subheadline)
                        .foregroundStyle(.gray)
                }
            }
            .padding()
            
            // Checklist items
            if let items = task?.taskItems {
                ForEach(Array(items.enumerated()), id: \.offset) { idx, item in
                    HStack(alignment: .center, spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(item.completed ? Color.green : Color.clear)
                                .frame(width: 28, height: 28)
                                .overlay(Circle().stroke(Color.gray, lineWidth: item.completed ? 0 : 1))
                            if item.completed {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.white)
                            }
                        }

                        Text(item.title)
                            .font(.body)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer()
                    }
                    .contentShape(Rectangle())
                    .padding(.horizontal)
                    .onTapGesture {
                        withAnimation {
                            item.completed.toggle()
                            // If extra persistence handling is needed, add here
                        }
                    }
                    .padding(.vertical, 8)
                    if idx != items.count - 1 {
                        Divider()
                            .background(Color.gray.opacity(0.4))
                            .padding(.leading, 40)
                    }
                }
            }
        }
        .scrollIndicators(.hidden)
        .listRowInsets(EdgeInsets())
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                NavigationLink(value: AddTaskRoute(task: task)) {
                    Text("Edit")
                }
            }
        }
    }
}

