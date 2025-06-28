//
//  PDFHighlightToolbar.swift
//  cerebral
//
//  Created by Assistant on 26/06/2025.
//

import SwiftUI
import PDFKit

// MARK: - Simple Bottom Highlighting Toolbar

struct PDFHighlightToolbar: View {
    @Binding var highlightingState: HighlightingState
    let onModeChanged: (HighlightingMode) -> Void
    let onColorChanged: (HighlightColor) -> Void
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            // Simple marker toggle
            Button(action: {
                let newMode: HighlightingMode = highlightingState.mode == .disabled ? .highlight : .disabled
                onModeChanged(newMode)
            }) {
                Image(systemName: "highlighter")
                    .font(DesignSystem.Typography.bodyMedium)
                    .foregroundColor(highlightingState.mode == .disabled ? 
                                    DesignSystem.Colors.secondaryText : 
                                    DesignSystem.Colors.accent)
            }
            .buttonStyle(.plain)
            .frame(width: 36, height: 36)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(highlightingState.mode == .disabled ? 
                          DesignSystem.Colors.surfaceBackground : 
                          DesignSystem.Colors.accent.opacity(0.15))
            )
            
            // 4 Color circles behind the toggle
            HStack(spacing: DesignSystem.Spacing.xs) {
                ForEach(HighlightColor.allCases) { color in
                    Button(action: {
                        onColorChanged(color)
                        // Auto-enable highlighting when color is selected
                        if highlightingState.mode == .disabled {
                            onModeChanged(.highlight)
                        }
                    }) {
                        Circle()
                            .fill(color.color)
                            .frame(width: 24, height: 24)
                            .overlay(
                                Circle()
                                    .stroke(DesignSystem.Colors.background, lineWidth: highlightingState.selectedColor == color ? 2 : 0)
                                    .scaleEffect(highlightingState.selectedColor == color ? 1.1 : 1.0)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.md)
        .padding(.vertical, DesignSystem.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(DesignSystem.Colors.surfaceBackground)
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
    }
}

// MARK: - Highlighting State Models

enum HighlightingMode {
    case disabled
    case highlight
}

@Observable
class HighlightingState {
    var mode: HighlightingMode = .disabled
    var selectedColor: HighlightColor = .yellow
    
    var isHighlightingEnabled: Bool {
        mode != .disabled
    }
    
    func toggleMode() {
        mode = mode == .disabled ? .highlight : .disabled
    }
    
    func setColor(_ color: HighlightColor) {
        selectedColor = color
        // Auto-enable highlighting when a color is selected
        if mode == .disabled {
            mode = .highlight
        }
    }
}

#Preview {
    @State var highlightingState = HighlightingState()
    
    return PDFHighlightToolbar(
        highlightingState: $highlightingState,
        onModeChanged: { mode in
            highlightingState.mode = mode
        },
        onColorChanged: { color in
            highlightingState.setColor(color)
        }
    )
    .padding()
    .frame(width: 300, height: 100)
} 