//
//  TimeEntriesView.swift
//  Tadoodly
//
//  Created by modemlooper on 6/8/25.
//

import SwiftUI
import SwiftData


struct TimeEntriesView: View {
   
    var task: UserTask?
    
    var body: some View {
        
        if let entries = task?.timeEntries {
            ForEach(Array(entries.enumerated()), id: \.offset) { idx, entry in
                Text(entry.date.formatted())
            }
        }
    }
}
