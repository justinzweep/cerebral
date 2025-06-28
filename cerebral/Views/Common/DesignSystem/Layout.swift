//
//  Layout.swift
//  cerebral
//
//  Consolidated Layout System - Typography and Spacing
//  Based on Apple's macOS Typography Best Practices (2025)
//  Following San Francisco font guidelines and accessibility requirements
//

import SwiftUI

// MARK: - Typography System (Apple Best Practices 2025)

extension DesignSystem {
    struct Typography {
        
        // MARK: - Font Sizes (Apple Recommended)
        struct FontSize {
            // Headlines and Titles (SF Pro Display for ≥20pt)
            static let largeTitle: CGFloat = 26        // Large title (Apple spec)
            static let title1: CGFloat = 22            // Title 1 (Apple spec)  
            static let title2: CGFloat = 17            // Title 2 (Apple spec)
            static let title3: CGFloat = 15            // Title 3 (Apple spec)
            
            // Body Text (SF Pro Text for <20pt) - Apple macOS Standard
            static let headline: CGFloat = 13          // Headline (semibold weight)
            static let body: CGFloat = 13              // Primary body text (Apple macOS standard)
            static let bodySecondary: CGFloat = 11     // Secondary body text
            static let callout: CGFloat = 13           // Same as body for macOS
            
            // Supporting Text
            static let subheadline: CGFloat = 11       // Table headers, tabs
            static let footnote: CGFloat = 11          // Tooltips, help text  
            static let caption: CGFloat = 10           // Caption/helper text
            static let caption2: CGFloat = 10          // Status/metadata text (minimum 11pt for accessibility, but 10pt allowed for metadata)
            
            // Interface Elements
            static let button: CGFloat = 13            // Button labels (Apple spec)
            static let menuItem: CGFloat = 13          // Menu items (Apple spec)
            static let tabBar: CGFloat = 11            // Tab labels (Apple spec)
            
            // Minimum sizes for accessibility compliance
            static let minimum: CGFloat = 11           // Accessibility minimum (Apple requirement)
        }
        
        // MARK: - Line Height Multipliers (Apple Guidelines)
        struct LineHeight {
            static let bodyText: CGFloat = 1.5         // 1.4-1.6× for body text
            static let headlines: CGFloat = 1.15       // 1.1-1.2× for headlines
            static let interfaceElements: CGFloat = 1.25 // 1.2-1.3× for UI elements
            static let compact: CGFloat = 1.1          // Tight spacing for UI
        }
        
        // MARK: - System Text Styles (Apple Preferred Approach)
        // Use built-in system text styles for automatic Dynamic Type support
        
        // Headlines and Titles
        static let largeTitle = Font.system(.largeTitle, design: .default, weight: .bold)
        static let title = Font.system(.title, design: .default, weight: .semibold)  
        static let title2 = Font.system(.title2, design: .default, weight: .semibold)
        static let title3 = Font.system(.title3, design: .default, weight: .medium)
        
        // Body Text  
        static let headline = Font.system(.headline, design: .default, weight: .semibold)
        static let body = Font.system(.body, design: .default, weight: .regular)
        static let bodyMedium = Font.system(.body, design: .default, weight: .medium)
        static let callout = Font.system(.callout, design: .default, weight: .regular)
        
        // Supporting Text
        static let subheadline = Font.system(.subheadline, design: .default, weight: .regular)
        static let footnote = Font.system(.footnote, design: .default, weight: .regular)
        static let caption = Font.system(.caption, design: .default, weight: .medium)
        static let caption2 = Font.system(.caption2, design: .default, weight: .regular)
        
        // MARK: - Custom-Sized Fonts (When system styles don't match exactly)
        // These follow Apple's font size specifications while maintaining system behavior
        
        // Interface-specific fonts (13pt standard)
        static let button = Font.system(size: FontSize.button, weight: .medium, design: .default)
        static let menuItem = Font.system(size: FontSize.menuItem, weight: .regular, design: .default)
        static let tabBar = Font.system(size: FontSize.tabBar, weight: .medium, design: .default)
        
        // Secondary body text (11pt)
        static let bodySecondary = Font.system(size: FontSize.bodySecondary, weight: .regular, design: .default)
        
        // MARK: - Monospaced Fonts (SF Mono)
        static let code = Font.system(.body, design: .monospaced, weight: .regular)
        static let codeSmall = Font.system(.caption, design: .monospaced, weight: .medium)
        static let terminal = Font.system(.callout, design: .monospaced, weight: .regular)
        
        // MARK: - Serif Font (New York) for Reading-Heavy Content
        static let serif = Font.system(.body, design: .serif, weight: .regular)
        static let serifTitle = Font.system(.title2, design: .serif, weight: .semibold)
        
        // MARK: - Accessibility Helpers
        // These ensure minimum font sizes while supporting Dynamic Type
        static func accessibleFont(baseSize: CGFloat, weight: Font.Weight = .regular) -> Font {
            let adjustedSize = max(baseSize, FontSize.minimum)
            return Font.system(size: adjustedSize, weight: weight, design: .default)
        }
        
        // MARK: - Line Height Helpers
        // Apply proper line spacing based on Apple guidelines
        static func lineSpacing(for fontSize: CGFloat, type: LineHeightType = .body) -> CGFloat {
            let multiplier: CGFloat
            switch type {
            case .body:
                multiplier = LineHeight.bodyText
            case .headline:
                multiplier = LineHeight.headlines
            case .interface:
                multiplier = LineHeight.interfaceElements
            case .compact:
                multiplier = LineHeight.compact
            }
            return (fontSize * multiplier) - fontSize
        }
        
        enum LineHeightType {
            case body, headline, interface, compact
        }
        
        // MARK: - Legacy Support (Deprecated - use system styles above)
        @available(*, deprecated, message: "Use system text styles for better Dynamic Type support")
        static let systemLargeTitle = Font.largeTitle.weight(.bold)
        @available(*, deprecated, message: "Use system text styles for better Dynamic Type support") 
        static let systemTitle = Font.title.weight(.semibold)
        @available(*, deprecated, message: "Use system text styles for better Dynamic Type support")
        static let systemTitle2 = Font.title2.weight(.semibold)
        @available(*, deprecated, message: "Use system text styles for better Dynamic Type support")
        static let systemTitle3 = Font.title3.weight(.medium)
        @available(*, deprecated, message: "Use system text styles for better Dynamic Type support")
        static let systemHeadline = Font.headline.weight(.semibold)
        @available(*, deprecated, message: "Use system text styles for better Dynamic Type support")
        static let systemBody = Font.body
        @available(*, deprecated, message: "Use system text styles for better Dynamic Type support")
        static let systemCallout = Font.callout
        @available(*, deprecated, message: "Use system text styles for better Dynamic Type support")
        static let systemSubheadline = Font.subheadline
        @available(*, deprecated, message: "Use system text styles for better Dynamic Type support")
        static let systemFootnote = Font.footnote
        @available(*, deprecated, message: "Use system text styles for better Dynamic Type support")
        static let systemCaption = Font.caption.weight(.medium)
    }
    
    // MARK: - Spacing and Layout System (8pt Grid)
    
    struct Spacing {
        // MARK: - Core Spacing Scale (8pt Grid System)
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
        static let minimumTouchTarget: CGFloat = 44 // Accessibility minimum (Apple requirement)
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
        
        // MARK: - Heights (Apple Standards)
        static let toolbarHeight: CGFloat = 52      // Standard toolbar height
        static let tabBarHeight: CGFloat = 48       // Tab bar height
        static let listRowHeight: CGFloat = 44      // Standard list row height
        static let buttonHeight: CGFloat = 36       // Standard button height
        
        // MARK: - Touch Targets (Accessibility)
        static let minimumTouchTarget: CGFloat = 44 // Apple accessibility minimum
        static let preferredTouchTarget: CGFloat = 48 // Preferred touch target
    }
} 