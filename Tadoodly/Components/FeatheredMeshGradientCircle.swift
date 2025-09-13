//
//  BackgroundSwirlView.swift
//  Tadoodly
//
//  Created by modemlooper on 6/30/25.
//

import SwiftUI

struct FeatheredMeshGradientCircle: View {
    let width: Int
    let height: Int
    let points: [SIMD2<Float>]
    let initialColors: [Color]
    let diameter: CGFloat
    let featherFraction: CGFloat // 0.0 (no feather) to 1.0 (full feather)
    let animate: Bool

    @State private var animatedColors: [Color]
    @State private var timer: Timer? = nil
    @Environment(\.colorScheme) private var colorScheme

    init(width: Int, height: Int, points: [SIMD2<Float>], colors: [Color], diameter: CGFloat, featherFraction: CGFloat, animate: Bool = false) {
        self.width = width
        self.height = height
        self.points = points
        self.initialColors = colors
        self.diameter = diameter
        self.featherFraction = featherFraction
        self.animate = animate
        _animatedColors = State(initialValue: colors)
    }

    var body: some View {
        ZStack {
            MeshGradient(
                width: width,
                height: height,
                points: points,
                colors: animatedColors
            )
            .frame(width: diameter, height: diameter)
            .clipShape(Circle())
            .padding(30)
            .overlay(
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(stops: [
                                .init(color: (colorScheme == .dark ? Color.black.opacity(0) : Color.white.opacity(0)), location: 1 - featherFraction),
                                .init(color: (colorScheme == .dark ? Color.black : Color.white), location: 1)
                            ]),
                            center: .center,
                            startRadius: 0,
                            endRadius: diameter / 2
                        )
                    )
                    .blendMode(.destinationOut)
            )
            .compositingGroup()
        }
        .onAppear {
            if animate {
                timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
                    withAnimation(.linear(duration: 0.8)) {
                        animatedColors.append(animatedColors.removeFirst())
                    }
                }
            }
        }
        .onDisappear {
            timer?.invalidate()
            timer = nil
        }
        .onChange(of: animate) { _, newValue in
            if newValue {
                timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
                    withAnimation(.linear(duration: 0.8)) {
                        animatedColors.append(animatedColors.removeFirst())
                    }
                }
            } else {
                timer?.invalidate()
                timer = nil
            }
        }
    }
}

struct FeatheredMeshGradientCircle_Preview: View {
    @Environment(\.colorScheme) var colorScheme
    
    let meshColors: [Color] = [
        .blue, .purple, .pink, .red, .orange, .yellow, .green, .blue
    ]
    
    var body: some View {
        
        ZStack {
            FeatheredMeshGradientCircle(
                width: 3,
                height: 3,
                points: [
                    [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                    [0.0, 0.5], [0.5, 0.5], [1.0, 0.5],
                    [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
                ],
                colors: meshColors,
                diameter: 320,
                featherFraction: 1.3,
                animate: false
            )
        }
    }
}

#Preview(traits: .defaultLayout) {
    FeatheredMeshGradientCircle_Preview()
}
