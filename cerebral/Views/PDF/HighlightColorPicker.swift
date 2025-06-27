//
//  HighlightColorPicker.swift
//  cerebral
//
//  Created by Justin Zweep on 26/06/2025.
//

import SwiftUI
import PDFKit

struct HighlightColorPicker: View {
    let position: CGPoint
    let onColorSelected: (NSColor) -> Void
    let onDismiss: () -> Void
    
    @State private var isVisible = false
    
    // Highlight colors with proper transparency
    private let highlightColors: [(name: String, color: NSColor)] = [
        ("Yellow", NSColor.systemYellow.withAlphaComponent(0.4)),
        ("Green", NSColor.systemGreen.withAlphaComponent(0.4)),
        ("Blue", NSColor.systemBlue.withAlphaComponent(0.4))
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Triangle pointer
            TrianglePointer()
                .fill(DesignSystem.Colors.background)
                .frame(width: 16, height: 8)
                .shadow(
                    color: Color.black.opacity(0.1),
                    radius: 2,
                    y: 1
                )
            
            // Color picker container
            HStack(spacing: DesignSystem.Spacing.xs) {
                ForEach(Array(highlightColors.enumerated()), id: \.offset) { index, colorData in
                    ColorButton(
                        color: Color(colorData.color),
                        name: colorData.name
                    ) {
                        onColorSelected(colorData.color)
                        onDismiss()
                    }
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.sm)
            .padding(.vertical, DesignSystem.Spacing.xs)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                    .fill(DesignSystem.Colors.background)
                    .shadow(
                        color: Color.black.opacity(0.2),
                        radius: 8,
                        y: 4
                    )
            )
        }
        .position(x: position.x, y: position.y)
        .scaleEffect(isVisible ? 1.0 : 0.8)
        .opacity(isVisible ? 1.0 : 0.0)
        .animation(DesignSystem.Animation.spring, value: isVisible)
        .onAppear {
            withAnimation {
                isVisible = true
            }
        }
        .onTapGesture {
            // Prevent dismissing when tapping inside the picker
        }
    }
}

// MARK: - Color Button

private struct ColorButton: View {
    let color: Color
    let name: String
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                .fill(color)
                .frame(width: 32, height: 32)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                        .stroke(
                            isHovered ? DesignSystem.Colors.accent : DesignSystem.Colors.border,
                            lineWidth: isHovered ? 2 : 1
                        )
                )
                .scaleEffect(isHovered ? 1.1 : 1.0)
                .animation(DesignSystem.Animation.microInteraction, value: isHovered)
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            isHovered = hovering
        }
        .help(name) // Tooltip
    }
}

// MARK: - Triangle Pointer

private struct TrianglePointer: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let width = rect.size.width
        let height = rect.size.height
        
        path.move(to: CGPoint(x: width * 0.5, y: 0))
        path.addLine(to: CGPoint(x: width, y: height))
        path.addLine(to: CGPoint(x: 0, y: height))
        path.closeSubpath()
        
        return path
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.gray.opacity(0.3)
            .ignoresSafeArea()
        
        HighlightColorPicker(
            position: CGPoint(x: 200, y: 100),
            onColorSelected: { color in
                print("Selected color: \(color)")
            },
            onDismiss: {
                print("Dismissed")
            }
        )
    }
} 