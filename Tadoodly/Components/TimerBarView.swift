import SwiftUI
import SwiftData

@available(iOS 26.0, *)
struct TimerBarView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.tabViewBottomAccessoryPlacement) private var placement
    @Query(filter: #Predicate<UserTask> { $0.isActive == true }) private var activeTasks: [UserTask]
    
    private var activeTask: UserTask? {
        activeTasks.first
    }
    
    var body: some View {
        if let task = activeTask {
            switch placement {
            case .inline:
                CompactTimerView(task: task)
            case .expanded:
                ExpandedTimerView(task: task)
            case .none:
                CompactTimerView(task: task)
            case .some(_):
                EmptyView()
            }
        } else {
            EmptyView()
        }
    }
}

struct CompactTimerView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var task: UserTask
    
    var body: some View {
        HStack(spacing: 12) {
            
            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(.system(size: 14, weight: .medium))
                    .lineLimit(1)
                    .foregroundColor(.primary)
                
                TimeCounterView(task: task, fontSize: 12)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            TimeButtonView(task: task, fontSize: 20)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

struct ExpandedTimerView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var task: UserTask
    
    var body: some View {
        
        HStack(alignment: .center, spacing: 0) {
            
            VStack(alignment: .leading ,spacing: 0) {
                Text(task.title)
                    .font(.system(size: 14, weight: .medium))
                    .lineLimit(1)
                    .foregroundColor(.primary)
                
                TimeCounterView(task: task, fontSize: 14)
            }
            .frame(height: .infinity)
            
            Spacer()
            
            TimeButtonView(task: task, fontSize: 22)
            
        }
        .padding(.top, 16)
        .padding(.bottom, 16)
        .padding(.leading, 16)
        .padding(.trailing, 8)
        
    }
}
