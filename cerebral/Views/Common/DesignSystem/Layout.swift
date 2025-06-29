//
//  Layout.swift
//  cerebral
//
//  Modern Conversational Layout System
//  Warm, generous spacing inspired by Airbnb's welcoming design
//  Apple-compliant typography with ChatGPT's approachable intelligence
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
    
    // MARK: - Spacing and Layout System (8pt Grid, Warm & Generous)
    
    struct Spacing {
        // MARK: - Core Spacing Scale (8pt Grid System - Airbnb Inspired)
        static let xs: CGFloat = 6      // 6pt - Comfortable tight spacing (increased)
        static let sm: CGFloat = 12     // 12pt - Small spacing (increased for warmth)
        static let md: CGFloat = 20     // 20pt - Medium spacing (increased generosity)
        static let lg: CGFloat = 28     // 28pt - Large spacing (increased)
        static let xl: CGFloat = 36     // 36pt - Extra large spacing (increased)
        static let xxl: CGFloat = 52    // 52pt - Extra extra large spacing (increased)
        
        // MARK: - Micro Spacing
        static let xxxs: CGFloat = 3    // 3pt - Minimal spacing (slightly increased)
        static let xxs: CGFloat = 6     // 6pt - Tiny spacing (same as xs for consistency)
        
        // MARK: - Macro Spacing
        static let xxxl: CGFloat = 68   // 68pt - Section spacing (increased)
        static let huge: CGFloat = 84   // 84pt - Large section spacing (increased)
        static let massive: CGFloat = 100 // 100pt - Page-level spacing (increased)
        
        // MARK: - Content Spacing (More Generous for Comfort)
        static let contentPadding = md  // 20pt - Standard content padding (increased)
        static let cardPadding = lg     // 28pt - Card internal padding (increased)
        static let sectionSpacing = xl  // 36pt - Between sections (increased)
        
        // MARK: - Layout Spacing
        static let sidebarWidth: CGFloat = 300      // Optimal sidebar width (increased)
        static let contentMaxWidth: CGFloat = 800   // Optimal reading width
        static let minimumTouchTarget: CGFloat = 44 // Accessibility minimum (Apple requirement)
    }
    
    // MARK: - Corner Radius System (Warm & Inviting)
    struct CornerRadius {
        static let xs: CGFloat = 6      // Subtle rounding (increased for warmth)
        static let sm: CGFloat = 8      // Small elements (increased)
        static let md: CGFloat = 12     // Standard elements (increased for friendliness)
        static let lg: CGFloat = 16     // Large elements (increased)
        static let xl: CGFloat = 20     // Extra large elements (increased)
        static let xxl: CGFloat = 24    // Very large elements (increased)
        static let round: CGFloat = 999 // Fully rounded (pills, avatars)
        
        // MARK: - Semantic Radii (ChatGPT & Airbnb Inspired)
        static let button = md          // 12pt - More friendly button radius
        static let card = lg            // 16pt - Warmer card radius
        static let modal = xl           // 20pt - Welcoming modal radius
        static let input = sm           // 8pt - Comfortable input field radius
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
    
    // MARK: - Component Dimensions
    struct ComponentSizes {
        // MARK: - Icon Sizes
        static let iconXXS: CGFloat = 6             // Extra extra small icons
        static let iconXS: CGFloat = 8              // Extra small icons
        static let iconSM: CGFloat = 10             // Small icons
        static let iconM: CGFloat = 11              // Medium-small icons
        static let iconMD: CGFloat = 12             // Medium icons (default)
        static let iconLG: CGFloat = 14             // Large icons
        static let iconXL: CGFloat = 16             // Extra large icons
        
        // MARK: - Button Sizes
        static let buttonIconSM: CGFloat = 24       // Small icon button frame
        static let buttonIconMD: CGFloat = 32       // Medium icon button frame
        static let buttonIconLG: CGFloat = 40       // Large icon button frame
        
        // MARK: - Indicator Sizes
        static let spinnerSM: CGFloat = 16          // Small spinner diameter
        static let spinnerMD: CGFloat = 24          // Medium spinner diameter
        static let spinnerLG: CGFloat = 32          // Large spinner diameter
        static let spinnerLineWidthSM: CGFloat = 2  // Small spinner line width
        static let spinnerLineWidthMD: CGFloat = 3  // Medium spinner line width
        static let spinnerLineWidthLG: CGFloat = 4  // Large spinner line width
        
        // MARK: - Context Dots and Pills
        static let contextDot: CGFloat = 6          // Context indicator dot
        static let statusIndicator: CGFloat = 3     // Status indicator width
        
        // MARK: - Thumbnail Sizes
        static let thumbnailSM = CGSize(width: 36, height: 44)    // Small PDF thumbnail
        static let thumbnailMD = CGSize(width: 48, height: 64)    // Medium PDF thumbnail
        static let thumbnailLG = CGSize(width: 120, height: 160)  // Large PDF thumbnail
        
        // MARK: - Window and Panel Sizes
        static let settingsWindowWidth: CGFloat = 700       // Settings window width
        static let settingsWindowHeight: CGFloat = 500      // Settings window height
        static let settingsSidebarWidth: CGFloat = 200      // Settings sidebar width
        static let dividerWidth: CGFloat = 1                // Standard divider width
        
        // MARK: - Chat Component Sizes
        static let chatInputMinHeight: CGFloat = 66         // Chat input minimum height (2 lines)
        static let chatInputMaxHeight: CGFloat = 120        // Chat input maximum height
        static let chatInputBottomPadding: CGFloat = 120    // Bottom padding for messages
        
        // MARK: - Component Frames
        static let standardIconFrame = CGSize(width: 20, height: 20)        // Standard icon frame
        static let smallIconFrame = CGSize(width: 16, height: 16)           // Small icon frame
        static let mediumIconFrame = CGSize(width: 24, height: 24)          // Medium icon frame
        static let largeIconFrame = CGSize(width: 32, height: 32)           // Large icon frame
        
        // MARK: - Content Constraints
        static let alertMaxWidth: CGFloat = 400             // Maximum alert width
        static let panelMaxWidth: CGFloat = 280             // Maximum panel width
        static let dropdownMaxItems: Int = 5                // Maximum dropdown items before scroll
        static let dropdownItemHeight: CGFloat = 44         // Dropdown item height
        
        // MARK: - Preview and Demo Sizes
        static let previewPanelWidth: CGFloat = 480         // Standard preview panel width
        static let previewPanelHeight: CGFloat = 400        // Standard preview panel height
        static let demoWindowWidth: CGFloat = 600           // Demo window width
        static let demoWindowHeight: CGFloat = 600          // Demo window height
        static let compactPanelHeight: CGFloat = 32         // Compact panel height
        static let standardPanelHeight: CGFloat = 48        // Standard panel height
        
        // MARK: - Chat and Message Sizes
        static let chatPanelWidth: CGFloat = 480            // Chat panel width
        static let messagePanelWidth: CGFloat = 500         // Message panel width
        static let contextPanelWidth: CGFloat = 600         // Context panel width
    }
} 