//
//  Colors.swift
//  Tadoodly
//
//  Created by modemlooper on 9/8/25.
//

import SwiftUI

let colors = ["red", "blue", "green", "orange", "purple", "teal", "pink", "indigo", "gray", "darkGray"]

public func colorFromString(_ color: String) -> Color {
    switch color {
    case "red": return .red
    case "blue": return .blue
    case "green": return .green
    case "orange": return .orange
    case "purple": return .purple
    case "teal": return .teal
    case "pink": return .pink
    case "indigo": return .indigo
    case "gray": return .gray
    case "darkGray": return Color(.darkGray)
    case "white": return .white
    default: return .white
    }
}

