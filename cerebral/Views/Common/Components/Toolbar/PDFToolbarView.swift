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
                                .fill(DesignSystem.Colors.surfaceBackground)
                                .frame(width: DesignSystem.ComponentSizes.largeIconFrame.width, height: DesignSystem.ComponentSizes.largeIconFrame.height)
                                .shadow(color: DesignSystem.Shadows.light, radius: DesignSystem.Shadows.small.radius, x: DesignSystem.Shadows.small.x, y: DesignSystem.Shadows.small.y)
                        }
                        
                        // Color circle
                        let isSelected = highlightingState.selectedColor == color
                        let circleSize: CGFloat = isSelected ? DesignSystem.ComponentSizes.buttonIconMD - DesignSystem.Spacing.xs : DesignSystem.ComponentSizes.buttonIconSM
                        
                        Circle()
                            .fill(color.color)
                            .frame(width: circleSize, height: circleSize)
                        
                        // Selection ring
                        if highlightingState.selectedColor == color {
                            Circle()
                                .stroke(DesignSystem.Colors.accent, lineWidth: 2)
                                .frame(width: DesignSystem.ComponentSizes.buttonIconMD - 2, height: DesignSystem.ComponentSizes.buttonIconMD - 2)
                        }
                        
                        // Checkmark for selected color
                        if highlightingState.selectedColor == color {
                            Image(systemName: "checkmark")
                                .font(.system(size: DesignSystem.ComponentSizes.iconSM, weight: .bold))
                                .foregroundColor(color.hasGoodWhiteTextContrast ? DesignSystem.Colors.textOnAccent : DesignSystem.Colors.primaryText)
                                .shadow(color: DesignSystem.Shadows.medium, radius: DesignSystem.Shadows.micro.radius, x: DesignSystem.Shadows.micro.x, y: DesignSystem.Shadows.micro.y)
                        }
                    }
                    .animation(DesignSystem.Animation.quick, value: highlightingState.selectedColor)
                }
                .buttonStyle(.plain)
                .scaleEffect(highlightingState.selectedColor == color ? 1.0 : DesignSystem.Scale.active)
                .animation(DesignSystem.Animation.gentleSpring, value: highlightingState.selectedColor)
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
            .foregroundColor(highlightingState.isHighlightingEnabled ? DesignSystem.Colors.success : DesignSystem.Colors.error)
    }
    .padding()
    .frame(width: DesignSystem.ComponentSizes.alertMaxWidth, height: DesignSystem.ComponentSizes.previewPanelHeight / 2)
} 