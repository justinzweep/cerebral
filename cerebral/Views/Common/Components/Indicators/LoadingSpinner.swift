//
//  LoadingSpinner.swift
//  cerebral
//
//  Reusable Loading Spinner Component
//

import SwiftUI

struct LoadingSpinner: View {
    let size: SpinnerSize
    let color: Color
    
    enum SpinnerSize {
        case small, medium, large
        
        var diameter: CGFloat {
            switch self {
            case .small: return 16
            case .medium: return 24
            case .large: return 32
            }
        }
        
        var lineWidth: CGFloat {
            switch self {
            case .small: return 2
            case .medium: return 3
            case .large: return 4
            }
        }
    }
    
    init(size: SpinnerSize = .medium, color: Color = DesignSystem.Colors.accent) {
        self.size = size
        self.color = color
    }
    
    @State private var isAnimating = false
    
    var body: some View {
        Circle()
            .trim(from: 0, to: 0.7)
            .stroke(
                color,
                style: StrokeStyle(
                    lineWidth: size.lineWidth,
                    lineCap: .round
                )
            )
            .frame(width: size.diameter, height: size.diameter)
            .rotationEffect(.degrees(isAnimating ? 360 : 0))
            .animation(
                .linear(duration: 1)
                .repeatForever(autoreverses: false),
                value: isAnimating
            )
            .onAppear {
                isAnimating = true
            }
    }
}

#Preview {
    VStack(spacing: 20) {
        HStack(spacing: 20) {
            LoadingSpinner(size: .small)
            LoadingSpinner(size: .medium)
            LoadingSpinner(size: .large)
        }
        
        HStack(spacing: 20) {
            LoadingSpinner(size: .medium, color: .red)
            LoadingSpinner(size: .medium, color: .green)
            LoadingSpinner(size: .medium, color: .blue)
        }
    }
    .padding()
} 