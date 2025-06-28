//
//  DesignSystem.swift
//  cerebral
//
//  Modern Professional Design System for Cerebral macOS App
//  Inspired by Linear, Figma, Discord, and contemporary design tools
//

import SwiftUI

// MARK: - Design System

/// Modern Professional Design System for Cerebral
/// 
/// **Core Design Philosophy:**
/// - **Professional Vibrancy**: Bold, confident colors that convey intelligence
/// - **Spatial Intelligence**: Strategic use of whitespace and layout
/// - **Material Sophistication**: Leverage modern design patterns
/// - **Typographic Excellence**: Clear, readable typography hierarchy
/// - **Semantic Clarity**: Colors that communicate meaning intuitively
/// - **Responsive Elegance**: Smooth 60fps animations and transitions
///
/// **Quick Usage Examples:**
/// ```swift
/// // Text with proper hierarchy
/// Text("Primary Title")
///     .foregroundColor(DesignSystem.Colors.primaryText)
///     .font(DesignSystem.Typography.title)
///
/// // Modern button with vibrant accent
/// Button("Action") { }
///     .buttonStyle(PrimaryButtonStyle())
///
/// // Card with professional styling
/// VStack { }
///     .background(DesignSystem.Colors.surfaceBackground)
///     .cornerRadius(DesignSystem.CornerRadius.card)
///
/// // Gradient accent for visual interest
/// Rectangle()
///     .fill(DesignSystem.Gradients.brandPrimary)
/// ```
struct DesignSystem {
    // All design tokens are organized in their respective modules:
    // - Colors & Gradients: Theme.swift (completely redesigned)
    // - Typography & Spacing: Layout.swift
    // - Components & Interactions: Components.swift
    // - Animations & Transitions: Animations.swift
    // - Materials & Shadows: Theme.swift
} 