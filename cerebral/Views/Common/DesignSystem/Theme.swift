//
//  Theme.swift
//  cerebral
//
//  Consolidated Theme System - Colors and Materials
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
        static let successGreen = success
        static let warningOrange = warning
        static let errorRed = error
        static let groupedBackground = Color(NSColor.unemphasizedSelectedContentBackgroundColor)
    }
    
    // MARK: - Enhanced Material System
    struct Materials {
        // MARK: - Primary Materials
        static let windowBackground = Material.regular
        static let sidebar = Material.bar
        static let contentBackground = Material.thin
        static let overlayBackground = Material.ultraThin
        
        // MARK: - Surface Materials
        static let cardSurface = Material.thin
        static let panelSurface = Material.regular
        static let modalSurface = Material.thick
        
        // MARK: - Interactive Materials
        static let hoverSurface = Material.ultraThin
        static let pressedSurface = Material.thin
        
        // MARK: - Legacy Color Support (for gradual migration)
        static let primarySurface = Material.thick
        static let secondarySurface = Material.regular
        static let tertiarySurface = Material.thin
        static let ultraThinSurface = Material.ultraThin
    }
    
    // MARK: - Shadow System (Subtle & Modern)
    struct Shadows {
        // MARK: - Shadow Colors
        static let subtle = Color.black.opacity(0.03)
        static let light = Color.black.opacity(0.06)
        static let medium = Color.black.opacity(0.10)
        static let strong = Color.black.opacity(0.15)
        
        // MARK: - Shadow Configurations
        static let micro = (radius: 1.0, x: 0.0, y: 0.5, opacity: 0.03)
        static let small = (radius: 2.0, x: 0.0, y: 1.0, opacity: 0.06)
        static let mediumShadow = (radius: 4.0, x: 0.0, y: 2.0, opacity: 0.10)
        static let large = (radius: 8.0, x: 0.0, y: 4.0, opacity: 0.15)
        static let floating = (radius: 12.0, x: 0.0, y: 6.0, opacity: 0.20)
        
        // MARK: - Legacy Support
        static let cardShadow = mediumShadow
        static let floatingShadow = large
        static let deepShadow = floating
    }
} 