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
    let onColorChanged: (HighlightColor?) -> Void
    
    var body: some View {
        // Color selection controls highlighting directly
        HStack(spacing: DesignSystem.Spacing.md) {
            ForEach(HighlightColor.allCases) { color in
                Button(action: {
                    // Toggle color selection - if same color is tapped, deselect it
                    if highlightingState.selectedColor == color {
                        // Deselect color and disable highlighting
                        onColorChanged(nil)
                        onModeChanged(.disabled)
                    } else {
                        // Select new color and enable highlighting
                        onColorChanged(color)
                        onModeChanged(.highlight)
                    }
                }) {
                    ZStack {
                        // Selection ring background
                        if highlightingState.selectedColor == color {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 32, height: 32)
                                .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                        }
                        
                        // Color circle
                        let isSelected = highlightingState.selectedColor == color
                        let circleSize: CGFloat = isSelected ? 26 : 24
                        
                        Circle()
                            .fill(color.color)
                            .frame(width: circleSize, height: circleSize)
                        
                        // Selection ring
                        if highlightingState.selectedColor == color {
                            Circle()
                                .stroke(DesignSystem.Colors.accent, lineWidth: 2)
                                .frame(width: 30, height: 30)
                        }
                        
                        // Checkmark for selected color
                        if highlightingState.selectedColor == color {
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(color.hasGoodWhiteTextContrast ? .white : .black)
                                .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 0.5)
                        }
                    }
                    .animation(.easeInOut(duration: 0.2), value: highlightingState.selectedColor)
                }
                .buttonStyle(.plain)
                .scaleEffect(highlightingState.selectedColor == color ? 1.0 : 0.95)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: highlightingState.selectedColor)
                .accessibilityLabel("\(color.displayName) highlight")
                .accessibilityHint(highlightingState.selectedColor == color ? "Tap to disable highlighting" : "Tap to highlight with \(color.displayName.lowercased())")
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.lg)
        .padding(.vertical, DesignSystem.Spacing.md)
        // .background(
        //     RoundedRectangle(cornerRadius: 12)
        //         .fill(DesignSystem.Colors.surfaceBackground)
        //         .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        // )
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
    var selectedColor: HighlightColor? = nil
    
    var isHighlightingEnabled: Bool {
        mode != .disabled && selectedColor != nil
    }
    
    func toggleMode() {
        mode = mode == .disabled ? .highlight : .disabled
        // If disabling, also clear selected color
        if mode == .disabled {
            selectedColor = nil
        }
    }
    
    func setColor(_ color: HighlightColor?) {
        selectedColor = color
        // Auto-enable highlighting when a color is selected, disable when nil
        mode = color != nil ? .highlight : .disabled
    }
    
    func deselectColor() {
        selectedColor = nil
        mode = .disabled
    }
}

// MARK: - Preview

#Preview {
    @State var highlightingState = HighlightingState()
    
    return VStack(spacing: 20) {
        Text("PDF Highlight Toolbar")
            .font(.headline)
        
        PDFHighlightToolbar(
            highlightingState: $highlightingState,
            onModeChanged: { mode in
                highlightingState.mode = mode
                print("Mode changed to: \(mode)")
            },
            onColorChanged: { color in
                highlightingState.setColor(color)
                if let color = color {
                    print("Color changed to: \(color.displayName)")
                } else {
                    print("Color deselected")
                }
            }
        )
        
        // Debug info
        Text("Mode: \(highlightingState.mode == .disabled ? "Disabled" : "Enabled")")
            .font(.caption)
        Text("Color: \(highlightingState.selectedColor?.displayName ?? "None")")
            .font(.caption)
        Text("Highlighting Enabled: \(highlightingState.isHighlightingEnabled ? "Yes" : "No")")
            .font(.caption)
            .foregroundColor(highlightingState.isHighlightingEnabled ? .green : .red)
    }
    .padding()
    .frame(width: 400, height: 200)
} 