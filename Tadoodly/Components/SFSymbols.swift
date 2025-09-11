//
//  SFSymbols.swift
//  Tadoodly
//
//  Created by modemlooper on 7/19/25.
//

import SwiftUI

/// A basic picker to select an SF Symbol and return its name.
struct SFSymbolPicker: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedSymbol: String   // non-optional
    
    // For demo, a basic curated set of symbols. Expand as needed.
    let symbols: [String] = [
        "star", "heart", "folder", "moon", "bolt", "flame", "leaf", "cloud", "sun.max", "cloud.rain", "person", "house", "bell", "doc", "camera", "photo", "figure.walk", "map", "car", "tram", "bicycle", "binoculars", "person.3", "figure", "figure.run", "dumbbell", "cart", "creditcard", "microphone", "bubble", "airplane", "gamecontroller", "lightbulb", "globe.americas.fill", "lock", "exclamationmark.triangle"
    ]
    
    @State private var searchText: String = ""
    
    var filteredSymbols: [String] {
        if searchText.isEmpty {
            return symbols
        } else {
            return symbols.filter { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        VStack {
            TextField("Search icons", text: $searchText)
                .padding(.horizontal)
                .textFieldStyle(.roundedBorder)
            
            ScrollView {
                LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 4), spacing: 24) {
                    ForEach(filteredSymbols, id: \.self) { symbol in
                        Button {
                            selectedSymbol = symbol
                            dismiss()
                        } label: {
                            VStack {
                                Image(systemName: symbol)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 32, height: 32)
                                    .foregroundColor(selectedSymbol == symbol ? Color.accentColor : .secondary)
                            }
                            .padding(4)
                        }
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Pick an icon")
    }
}

// Usage example elsewhere:
// @State private var chosenSymbol: String = "star"
// SFSymbolPicker(selectedSymbol: $chosenSymbol)


struct SFSymbolPickerPreviewContainer: View {
    @State private var chosenSymbol: String = "star"
    var body: some View {
        SFSymbolPicker(selectedSymbol: $chosenSymbol)
    }
}

#Preview {
    SFSymbolPickerPreviewContainer()
}

