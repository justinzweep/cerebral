//
//  PDFToolbarView.swift
//  cerebral
//
//  Created by Assistant on 26/06/2025.
//

import SwiftUI
import PDFKit

struct PDFToolbarView: View {
    @Binding var toolbarState: ToolbarState
    let onColorSelected: (HighlightColor) -> Void
    let onDismiss: () -> Void
    let onRemoveHighlight: (() -> Void)?
    
    @State private var hoveredColor: HighlightColor?
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.xs) {
            // Color swatches
            ForEach(HighlightColor.allCases) { color in
                ColorSwatch(
                    color: color,
                    isSelected: toolbarState.selectedColor == color,
                    isHovered: hoveredColor == color,
                    onTap: {
                        onColorSelected(color)
                    }
                )
                .onHover { hovering in
                    hoveredColor = hovering ? color : nil
                }
            }
            
            // Remove highlight button (if editing existing highlight)
            if toolbarState.existingHighlight != nil {
                Divider()
                    .frame(height: 20)
                
                Button(action: {
                    onRemoveHighlight?()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
                .buttonStyle(PlainButtonStyle())
                .frame(width: 20, height: 20)
                .background(
                    Circle()
                        .fill(DesignSystem.Colors.tertiaryBackground)
                        .opacity(hoveredColor == nil ? 0.5 : 1.0)
                )
                .onHover { hovering in
                    if hovering {
                        hoveredColor = nil
                    }
                }
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.sm)
        .padding(.vertical, DesignSystem.Spacing.xs)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(DesignSystem.Colors.surfaceBackground)
                .shadow(
                    color: Color.black.opacity(0.15),
                    radius: 6,
                    x: 0,
                    y: 2
                )
        )
        .frame(width: toolbarState.existingHighlight != nil ? 180 : 140, height: 36)
        .position(toolbarState.position)
        .opacity(toolbarState.isVisible ? 1 : 0)
        .scaleEffect(toolbarState.isVisible ? 1 : 0.8)
        .animation(.easeOut(duration: toolbarState.isVisible ? 0.15 : 0.1), value: toolbarState.isVisible)
        .onTapGesture {
            // Prevent dismissal when tapping inside toolbar
        }
    }
}

// MARK: - Color Swatch Component

struct ColorSwatch: View {
    let color: HighlightColor
    let isSelected: Bool
    let isHovered: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Circle()
                .fill(color.color)
                .frame(width: 24, height: 24)
                .overlay(
                    // Selection indicator
                    Circle()
                        .stroke(Color.white, lineWidth: isSelected ? 2 : 0)
                        .frame(width: 24, height: 24)
                )
                .overlay(
                    // Hover effect
                    Circle()
                        .stroke(DesignSystem.Colors.borderFocus, lineWidth: isHovered ? 1 : 0)
                        .frame(width: 26, height: 26)
                )
                .scaleEffect(isHovered ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 0.15), value: isHovered)
        }
        .buttonStyle(PlainButtonStyle())
        .help(color.semanticMeaning)
    }
}

// MARK: - Toolbar Container

struct PDFToolbarContainer: View {
    @State private var appState = ServiceContainer.shared.appState
    let pdfDocument: PDFDocument?
    let documentURL: URL?
    
    private let toolbarService = ServiceContainer.shared.toolbarService
    
    var body: some View {
        PDFToolbarView(
            toolbarState: $appState.toolbarState,
            onColorSelected: { color in
                Task {
                    await handleColorSelection(color)
                }
            },
            onDismiss: {
                appState.hideToolbar()
            },
            onRemoveHighlight: {
                Task {
                    await handleRemoveHighlight()
                }
            }
        )
    }
    
    @MainActor
    private func handleColorSelection(_ color: HighlightColor) async {
        guard let selection = appState.toolbarState.currentSelection,
              let document = pdfDocument,
              let url = documentURL else {
            appState.hideToolbar()
            return
        }
        
        do {
            if let existingHighlight = appState.toolbarState.existingHighlight {
                // Update existing highlight
                let updatedHighlight = try await toolbarService.updateHighlight(
                    existingHighlight,
                    newColor: color,
                    in: document
                )
                appState.updateHighlight(existingHighlight, with: updatedHighlight)
            } else {
                // Create new highlight
                let newHighlight = try await toolbarService.applyHighlight(
                    color: color,
                    to: selection,
                    in: document,
                    documentURL: url
                )
                appState.addHighlight(newHighlight)
            }
            
            // Keep selection visible briefly, then hide toolbar
            try await Task.sleep(nanoseconds: 500_000_000) // 500ms
            appState.hideToolbar()
            
        } catch {
            print("❌ Failed to apply highlight: \(error)")
            ServiceContainer.shared.errorManager.handle(error, context: "highlight_apply")
            appState.hideToolbar()
        }
    }
    
    @MainActor
    private func handleRemoveHighlight() async {
        guard let existingHighlight = appState.toolbarState.existingHighlight,
              let document = pdfDocument else {
            appState.hideToolbar()
            return
        }
        
        do {
            try await toolbarService.removeHighlight(existingHighlight, from: document)
            appState.removeHighlight(existingHighlight)
            appState.hideToolbar()
        } catch {
            print("❌ Failed to remove highlight: \(error)")
            ServiceContainer.shared.errorManager.handle(error, context: "highlight_remove")
            appState.hideToolbar()
        }
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.2)
        
        PDFToolbarView(
            toolbarState: .constant(ToolbarState()),
            onColorSelected: { _ in },
            onDismiss: { },
            onRemoveHighlight: { }
        )
    }
    .frame(width: 400, height: 300)
} 