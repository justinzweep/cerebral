//
//  Materials.swift
//  cerebral
//
//  Material and Shadow System for Cerebral macOS App
//  Modern depth and layering system
//

import SwiftUI

// MARK: - Materials and Shadows

extension DesignSystem {
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