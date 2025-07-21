//
//  LoadingCircle.swift
//  Tadoodly
//
//  Created by modemlooper on 7/1/25.
//

import Foundation
import SwiftUI

struct LoadSpinner: View {
    
    var isActive = false
    
    @State private var buttonBorderAnimationPhase: Double = 0
    @State private var buttonBorderAnimationTimer: Timer? = nil
    
    var body: some View {
        
        let meshColors: [Color] = [
            .blue, .purple, .pink, .red, .orange, .yellow, .green, .blue
        ]
        
        FeatheredMeshGradientCircle(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [0.5, 0.5], [1.0, 0.5],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
            ],
            colors: meshColors,
            diameter: 34,
            featherFraction: 0,
            animate: true
        )
        .frame(width: 34, height: 34)
        .scaleEffect(isActive ? 1.1 : 0.0)
        .opacity(isActive ? 1.0 : 0.0)
        .animation(.spring(response: 0.35, dampingFraction: 0.55), value: isActive)
        .onAppear {
            buttonBorderAnimationTimer?.invalidate()
            buttonBorderAnimationTimer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { _ in
                buttonBorderAnimationPhase = (buttonBorderAnimationPhase + 1).truncatingRemainder(dividingBy: 360)
            }
        }
        .onDisappear {
            buttonBorderAnimationTimer?.invalidate()
            buttonBorderAnimationTimer = nil
        }
    }
}
