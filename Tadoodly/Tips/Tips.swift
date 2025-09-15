//
//  Tips.swift
//  Tadoodly
//
//  Created by modemlooper on 9/15/25.
//

import Foundation
import TipKit

struct AddTaskTip: Tip {
    var title: Text {
        Text("Add Task")
    }
    var message: Text? {
        Text("Tap here to add a new task.")
    }
    var image: Image {
        Image(systemName: "checklist")
    }
}


struct PopoverTip: View {
    
    let tip = AddTaskTip()
    
    var body: some View {
        NavigationStack {
            Group {
                Text("fff")
            }
            .toolbar {
                ToolbarItem {
                    Button {
                        
                    } label: {
                        Text("dddd")
                    }
                    .popoverTip(tip)

                }
            }
               
        }

    }
}

#Preview {
    PopoverTip()
        .task {
            try? Tips.resetDatastore()
            try? Tips.configure([
                .displayFrequency(.immediate),
                .datastoreLocation(.applicationDefault)
            ])
        }
}
