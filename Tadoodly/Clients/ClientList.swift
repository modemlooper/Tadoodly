//
//  ClientsView.swift
//  Tadoodly
//
//  Created by modemlooper on 10/27/25.
//

import SwiftUI
import SwiftData

struct ClientList: View {
    
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: [SortDescriptor(\Client.name, order: .forward)]) private var clients: [Client]
    
    var body: some View {
        
        List(clients) { client in
            VStack(alignment: .leading) {
                Text(client.name)
                    .font(.headline)
                Text(client.email)
                    .font(.subheadline)
            }
            
        }
    }
}

