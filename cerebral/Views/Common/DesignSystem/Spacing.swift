//
//  Spacing.swift
//  cerebral
//
//  Spacing and Layout System for Cerebral macOS App
//  Based on 8pt Grid System and Accessibility Guidelines
//

import SwiftUI

// MARK: - Spacing and Layout System

extension DesignSystem {
    struct Spacing {
        // MARK: - Core Spacing Scale
        static let xs: CGFloat = 4      // 4pt - Tight spacing
        static let sm: CGFloat = 8      // 8pt - Small spacing
        static let md: CGFloat = 16     // 16pt - Medium spacing (base unit)
        static let lg: CGFloat = 24     // 24pt - Large spacing
        static let xl: CGFloat = 32     // 32pt - Extra large spacing
        static let xxl: CGFloat = 48    // 48pt - Extra extra large spacing
        
        // MARK: - Micro Spacing
        static let xxxs: CGFloat = 2    // 2pt - Minimal spacing
        static let xxs: CGFloat = 4     // 4pt - Tiny spacing (same as xs for consistency)
        
        // MARK: - Macro Spacing
        static let xxxl: CGFloat = 64   // 64pt - Section spacing
        static let huge: CGFloat = 80   // 80pt - Large section spacing
        static let massive: CGFloat = 96 // 96pt - Page-level spacing
        
        // MARK: - Content Spacing
        static let contentPadding = md  // 16pt - Standard content padding
        static let cardPadding = lg     // 24pt - Card internal padding
        static let sectionSpacing = xl  // 32pt - Between sections
        
        // MARK: - Layout Spacing
        static let sidebarWidth: CGFloat = 280      // Optimal sidebar width
        static let contentMaxWidth: CGFloat = 800   // Optimal reading width
        static let minimumTouchTarget: CGFloat = 44 // Accessibility minimum
    }
    
    // MARK: - Corner Radius System
    struct CornerRadius {
        static let xs: CGFloat = 4      // Subtle rounding
        static let sm: CGFloat = 6      // Small elements
        static let md: CGFloat = 8      // Standard elements (buttons, cards)
        static let lg: CGFloat = 12     // Large elements (panels, modals)
        static let xl: CGFloat = 16     // Extra large elements
        static let xxl: CGFloat = 20    // Very large elements
        static let round: CGFloat = 999 // Fully rounded (pills, avatars)
        
        // MARK: - Semantic Radii
        static let button = md          // 8pt - Button radius
        static let card = lg            // 12pt - Card radius
        static let modal = xl           // 16pt - Modal radius
        static let input = sm           // 6pt - Input field radius
    }
    
    // MARK: - Interaction Scale System
    struct Scale {
        static let pressed: CGFloat = 0.96      // Button press scale
        static let hover: CGFloat = 1.02        // Gentle hover scale
        static let active: CGFloat = 0.98       // Active state scale
        static let focus: CGFloat = 1.01        // Focus state scale
    }
    
    // MARK: - Layout Constants
    struct Layout {
        // MARK: - Content Widths
        static let readingWidth: CGFloat = 680      // Optimal reading line length
        static let contentMaxWidth: CGFloat = 800   // Maximum content width
        static let sidebarMinWidth: CGFloat = 240   // Minimum sidebar width
        static let sidebarMaxWidth: CGFloat = 320   // Maximum sidebar width
        
        // MARK: - Heights
        static let toolbarHeight: CGFloat = 52      // Standard toolbar height
        static let tabBarHeight: CGFloat = 48       // Tab bar height
        static let listRowHeight: CGFloat = 44      // Standard list row height
        static let buttonHeight: CGFloat = 36       // Standard button height
        
        // MARK: - Touch Targets
        static let minimumTouchTarget: CGFloat = 44 // Accessibility minimum
        static let preferredTouchTarget: CGFloat = 48 // Preferred touch target
    }
} 