//
//  Colors.swift
//  cerebral
//
//  Color System for Cerebral macOS App
//  Semantic Color System inspired by Linear, Notion, ChatGPT, Claude
//

import SwiftUI

// MARK: - Color System

extension DesignSystem {
    struct Colors {
        // MARK: - Neutrals (inspired by Linear/Notion)
        static let background = Color(NSColor.controlBackgroundColor)
        static let secondaryBackground = Color(NSColor.windowBackgroundColor)
        static let tertiaryBackground = Color(NSColor.underPageBackgroundColor)
        static let surfaceBackground = Color(NSColor.textBackgroundColor)
        
        // MARK: - Text Hierarchy (Progressive contrast)
        static let primaryText = Color(NSColor.labelColor)
        static let secondaryText = Color(NSColor.secondaryLabelColor)
        static let tertiaryText = Color(NSColor.tertiaryLabelColor)
        static let placeholderText = Color(NSColor.placeholderTextColor)
        
        // MARK: - Accent Colors (inspired by Claude/ChatGPT)
        static let accent = Color(NSColor.controlAccentColor)
        static let accentSecondary = Color(NSColor.controlAccentColor).opacity(0.1)
        static let accentHover = Color(NSColor.controlAccentColor).opacity(0.8)
        static let accentPressed = Color(NSColor.controlAccentColor).opacity(0.9)
        
        // MARK: - Status Colors (Semantic)
        static let success = Color(NSColor.systemGreen)
        static let warning = Color(NSColor.systemOrange)
        static let error = Color(NSColor.systemRed)
        static let info = Color(NSColor.systemBlue)
        
        // MARK: - Interactive States
        static let hoverBackground = Color(NSColor.controlAccentColor).opacity(0.08)
        static let selectedBackground = Color(NSColor.selectedContentBackgroundColor)
        static let pressedBackground = Color(NSColor.controlAccentColor).opacity(0.12)
        
        // MARK: - Borders & Separators
        static let border = Color(NSColor.separatorColor)
        static let borderSecondary = Color(NSColor.gridColor)
        static let borderFocus = accent
        static let borderError = error
        
        // MARK: - Special Purpose Colors
        static let textOnAccent = Color.white
        static let overlayBackground = Color.black.opacity(0.3)
        
        // MARK: - Legacy Support (for gradual migration)
        static let primary = primaryText
        static let secondary = secondaryText
        static let pdfRed = error
        static let folderBlue = info
        static let highlightYellow = Color(NSColor.systemYellow)
        static let successGreen = success
        static let warningOrange = warning
        static let errorRed = error
        static let groupedBackground = Color(NSColor.unemphasizedSelectedContentBackgroundColor)
    }
} 