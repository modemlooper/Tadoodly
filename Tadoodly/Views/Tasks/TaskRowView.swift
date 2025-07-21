import SwiftUI
import SwiftData

struct TaskRowView: View {
    let task: UserTask
    let sortedTasks: [UserTask]
    let askDeleteConfirmation: ((IndexSet) -> Void)?
    @Environment(\.modelContext) private var modelContext: ModelContext
    
    var body: some View {
        TaskRow(task: task)
            .id(String(describing: task.id))
//            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 10))
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                Button(role: .destructive) {
                    if let index = sortedTasks.firstIndex(where: { $0.id == task.id }) {
                        askDeleteConfirmation?(IndexSet(integer: index))
                    }
                } label: {
                    Image(systemName: "trash")
                }
            }
            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                Button {
                    toggleCompleted()
                } label: {
                    if task.completed {
                        Label("", systemImage: "arrow.uturn.left.circle")
                    } else {
                        Label("", systemImage: "checkmark.circle")
                    }
                }
                .tint(task.completed ? .yellow : .green)
            }
    }
    
    private func toggleCompleted() {
        task.completed.toggle()
        do {
            try modelContext.save()
        } catch {
            // Handle error
        }
    }
}
