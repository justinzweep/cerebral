//
//  DesignSystem.swift
//  cerebral
//
//  Main Design System Container
//  Updated with Apple's macOS Typography Best Practices (2025)
//

import SwiftUI

/**
 # Cerebral Design System
 
 A comprehensive design system following Apple's macOS Typography Best Practices (2025).
 
 ## Typography Updates (Breaking Changes)
 
 The typography system has been completely updated to follow Apple's 2025 macOS guidelines:
 
 ### Key Changes:
 - **Font Sizes**: Updated to Apple's recommended sizes (body text now 13pt instead of 17pt)
 - **System Fonts**: Uses `Font.system()` instead of custom SF Pro fonts for better Dynamic Type support
 - **Line Heights**: Added proper line spacing based on Apple's guidelines
 - **Accessibility**: Enforces 11pt minimum size and proper contrast ratios
 
 ### Migration Guide:
 
 #### Old Usage (Deprecated):
 ```swift
 Text("Hello World")
     .font(DesignSystem.Typography.body)
 ```
 
 #### New Usage (Recommended):
 ```swift
 Text("Hello World")
     .appleTextStyle(.body)
 
 // Or use the convenience component:
 AppleText("Hello World", style: .body)
 ```
 
 ### Available Text Styles:
 - `.largeTitle` - 26pt, Bold (for page headers)
 - `.title` - 22pt, Semibold (for section headers)  
 - `.title2` - 17pt, Semibold (for subsection headers)
 - `.title3` - 15pt, Medium (for card headers)
 - `.headline` - 13pt, Semibold (for emphasized content)
 - `.body` - 13pt, Regular (primary body text - Apple macOS standard)
 - `.bodySecondary` - 11pt, Regular (secondary body text)
 - `.callout` - 13pt, Regular (same as body for macOS)
 - `.subheadline` - 11pt, Regular (table headers, tabs)
 - `.footnote` - 11pt, Regular (tooltips, help text)
 - `.caption` - 10pt, Medium (captions, metadata)
 - `.caption2` - 10pt, Regular (smallest text)
 - `.button` - 13pt, Medium (button labels)
 - `.menuItem` - 13pt, Regular (menu items)
 - `.tabBar` - 11pt, Medium (tab labels)
 
 ### Line Height Guidelines:
 The system automatically applies proper line spacing:
 - Body text: 1.5× font size
 - Headlines: 1.15× font size  
 - Interface elements: 1.25× font size
 - Compact spacing: 1.1× font size
 
 ### Accessibility Features:
 - Automatic Dynamic Type support
 - 11pt minimum font size enforcement
 - Proper color contrast ratios
 - 44pt minimum touch targets
 
 ## Usage Examples:
 
 ### Basic Text:
 ```swift
 AppleText("Primary content", style: .body)
 AppleText("Secondary info", style: .bodySecondary)
 AppleText("Caption text", style: .caption)
 ```
 
 ### Labels with Subtitles:
 ```swift
 AppleLabel("Document Title", subtitle: "Last modified today")
 ```
 
 ### Custom Line Spacing:
 ```swift
 Text("Custom spacing")
     .font(DesignSystem.Typography.body)
     .appleLineSpacing(for: .body)
 ```
 
 ### Button Text:
 ```swift
 Button("Action") { }
     .buttonStyle(PrimaryButtonStyle()) // Already uses .button style
 ```
 
 ## Components Included:
 - Typography (Layout.swift)
 - Colors & Materials (Theme.swift)  
 - Interactive Components (Components.swift)
 - Animations (Animations.swift)
 */

struct DesignSystem {
    // This struct serves as a namespace for the design system components
    // All actual implementations are in separate files:
    // - Typography & Layout: Layout.swift
    // - Colors & Materials: Theme.swift
    // - Components & Styles: Components.swift
    // - Animations: Animations.swift
} 