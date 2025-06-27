//
//  DesignSystem.swift
//  cerebral
//
//  Design System for Cerebral macOS App
//  Following Apple Human Interface Guidelines
//

import SwiftUI

// MARK: - Design System

struct DesignSystem {
    
    // MARK: - Enhanced Colors (Following UI Improvements Document)
    struct Colors {
        // Semantic colors with proper contrast ratios
        static let primaryText = Color(.labelColor)
        static let secondaryText = Color(.secondaryLabelColor)
        static let tertiaryText = Color(.tertiaryLabelColor)
        static let placeholderText = Color(.placeholderTextColor)
        
        // Surface colors using proper materials
        static let primarySurface = Material.thick
        static let secondarySurface = Material.regular
        static let tertiarySurface = Material.thin
        static let ultraThinSurface = Material.ultraThin
        
        // Accent colors with accessibility compliance
        static let accent = Color(.controlAccentColor)
        static let accentSecondary = Color(.controlAccentColor).opacity(0.8)
        static let accentTertiary = Color(.controlAccentColor).opacity(0.6)
        
        // Legacy colors for backward compatibility
        static let primary = Color.primary
        static let secondary = Color.secondary
        
        // Custom App Colors with refined palette
        static let pdfRed = Color(.systemRed)
        static let folderBlue = Color(.systemBlue)
        static let highlightYellow = Color(.systemYellow)
        static let successGreen = Color(.systemGreen)
        static let warningOrange = Color(.systemOrange)
        static let errorRed = Color(.systemRed)
        
        // Background Colors with material support
        static let background = Color(NSColor.controlBackgroundColor)
        static let secondaryBackground = Color(NSColor.windowBackgroundColor)
        static let groupedBackground = Color(NSColor.unemphasizedSelectedContentBackgroundColor)
        static let selectedBackground = Color(NSColor.selectedContentBackgroundColor)
        static let hoverBackground = Color(NSColor.controlAccentColor).opacity(0.1)
        
        // Surface Colors with Materials (Enhanced)
        static let surfacePrimary = Material.regular
        static let surfaceSecondary = Material.thin
        static let surfaceUltraThin = Material.ultraThin
        
        // Text Colors (Enhanced)
        static let textPrimary = primaryText
        static let textSecondary = secondaryText
        static let textTertiary = tertiaryText
        static let textPlaceholder = placeholderText
        static let textOnAccent = Color.white
        
        // Border Colors with refined contrast
        static let border = Color(NSColor.separatorColor)
        static let borderSecondary = Color(NSColor.gridColor)
        static let borderFocus = accent
        static let borderError = errorRed
    }
    
    // MARK: - Enhanced Typography System
    struct Typography {
        // Better hierarchy with consistent line heights
        static let title1 = Font.largeTitle.weight(.bold).leading(.tight)
        static let title2 = Font.title.weight(.semibold).leading(.tight)
        static let title3 = Font.title2.weight(.semibold).leading(.tight)
        
        // Refined body text with better readability
        static let headline = Font.headline.weight(.medium).leading(.tight)
        static let body = Font.body.leading(.loose)
        static let bodyMedium = Font.body.weight(.medium).leading(.loose)
        static let callout = Font.callout.leading(.loose)
        static let subheadline = Font.subheadline.leading(.tight)
        
        // Small Text Styles with improved hierarchy
        static let footnote = Font.footnote.leading(.tight)
        static let caption = Font.caption.weight(.medium).leading(.tight)
        static let caption2 = Font.caption2.leading(.tight)
        
        // Special Styles
        static let monospace = Font.system(.body, design: .monospaced)
        static let code = Font.system(.caption, design: .monospaced)
    }
    
    // MARK: - Spacing (Enhanced 8pt Grid System)
    struct Spacing {
        static let xxxs: CGFloat = 2   // 2pt
        static let xxs: CGFloat = 4    // 4pt
        static let xs: CGFloat = 8     // 8pt
        static let sm: CGFloat = 12    // 12pt
        static let md: CGFloat = 16    // 16pt
        static let lg: CGFloat = 20    // 20pt
        static let xl: CGFloat = 24    // 24pt
        static let xxl: CGFloat = 32   // 32pt
        static let xxxl: CGFloat = 40  // 40pt
        static let huge: CGFloat = 48  // 48pt
        static let massive: CGFloat = 64 // 64pt
    }
    
    // MARK: - Corner Radius
    struct CornerRadius {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 6
        static let md: CGFloat = 8
        static let lg: CGFloat = 12
        static let xl: CGFloat = 16
        static let round: CGFloat = 999 // For pills/circular elements
    }
    
    // MARK: - Enhanced Shadows
    struct Shadows {
        static let subtle = Color.black.opacity(0.05)
        static let light = Color.black.opacity(0.1)
        static let medium = Color.black.opacity(0.15)
        static let strong = Color.black.opacity(0.25)
        
        // Specific shadow configurations
        static let cardShadow = (radius: 4.0, x: 0.0, y: 2.0, opacity: 0.1)
        static let floatingShadow = (radius: 8.0, x: 0.0, y: 4.0, opacity: 0.15)
        static let deepShadow = (radius: 16.0, x: 0.0, y: 8.0, opacity: 0.25)
    }
    
    // MARK: - Sophisticated Animation System
    struct Animation {
        // Micro-interactions
        static let microInteraction = SwiftUI.Animation.easeOut(duration: 0.15)
        static let interface = SwiftUI.Animation.easeInOut(duration: 0.2)
        static let smooth = SwiftUI.Animation.easeInOut(duration: 0.25)
        static let gentle = SwiftUI.Animation.easeInOut(duration: 0.35)
        
        // Modal and page transitions
        static let modal = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.8)
        static let pageTransition = SwiftUI.Animation.easeInOut(duration: 0.3)
        
        // Legacy support
        static let quick = microInteraction
        static let spring = modal
    }
}

// MARK: - Enhanced Button Styles

struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @State private var isHovered = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DesignSystem.Typography.bodyMedium)
            .foregroundColor(DesignSystem.Colors.textOnAccent)
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.vertical, DesignSystem.Spacing.xs)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                    .fill(buttonBackgroundColor)
                    .shadow(
                        color: DesignSystem.Shadows.light,
                        radius: configuration.isPressed ? 1 : 2,
                        y: configuration.isPressed ? 0 : 1
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(DesignSystem.Animation.microInteraction, value: configuration.isPressed)
            .animation(DesignSystem.Animation.microInteraction, value: isHovered)
            .opacity(isEnabled ? 1.0 : 0.6)
            .onHover { isHovered = $0 }
    }
    
    private var buttonBackgroundColor: Color {
        if !isEnabled {
            return DesignSystem.Colors.secondaryText
        } else if isHovered {
            return DesignSystem.Colors.accentSecondary
        } else {
            return DesignSystem.Colors.accent
        }
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @State private var isHovered = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DesignSystem.Typography.body)
            .foregroundColor(DesignSystem.Colors.accent)
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.vertical, DesignSystem.Spacing.xs)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                    .stroke(DesignSystem.Colors.accent, lineWidth: 1)
                    .background(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                            .fill(backgroundFill(isPressed: configuration.isPressed))
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(DesignSystem.Animation.microInteraction, value: configuration.isPressed)
            .animation(DesignSystem.Animation.microInteraction, value: isHovered)
            .opacity(isEnabled ? 1.0 : 0.6)
            .onHover { isHovered = $0 }
    }
    
    private func backgroundFill(isPressed: Bool) -> Color {
        if isPressed || isHovered {
            return DesignSystem.Colors.hoverBackground
        } else {
            return Color.clear
        }
    }
}

struct TertiaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @State private var isHovered = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DesignSystem.Typography.body)
            .foregroundColor(DesignSystem.Colors.textSecondary)
            .padding(.horizontal, DesignSystem.Spacing.sm)
            .padding(.vertical, DesignSystem.Spacing.xs)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                    .fill(backgroundFill(isPressed: configuration.isPressed))
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(DesignSystem.Animation.microInteraction, value: configuration.isPressed)
            .animation(DesignSystem.Animation.microInteraction, value: isHovered)
            .opacity(isEnabled ? 1.0 : 0.6)
            .onHover { isHovered = $0 }
    }
    
    private func backgroundFill(isPressed: Bool) -> Color {
        if isPressed || isHovered {
            return DesignSystem.Colors.hoverBackground
        } else {
            return Color.clear
        }
    }
}

struct DestructiveButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @State private var isHovered = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DesignSystem.Typography.body)
            .foregroundColor(DesignSystem.Colors.errorRed)
            .padding(.horizontal, DesignSystem.Spacing.sm)
            .padding(.vertical, DesignSystem.Spacing.xs)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                    .fill(backgroundFill(isPressed: configuration.isPressed))
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(DesignSystem.Animation.microInteraction, value: configuration.isPressed)
            .animation(DesignSystem.Animation.microInteraction, value: isHovered)
            .opacity(isEnabled ? 1.0 : 0.6)
            .onHover { isHovered = $0 }
    }
    
    private func backgroundFill(isPressed: Bool) -> Color {
        if isPressed || isHovered {
            return DesignSystem.Colors.errorRed.opacity(0.1)
        } else {
            return Color.clear
        }
    }
}

// MARK: - Enhanced Row Style for Lists
struct EnhancedRowStyle: ViewModifier {
    @State private var isHovered = false
    let isSelected: Bool
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                    .fill(backgroundFill)
            )
            .animation(DesignSystem.Animation.microInteraction, value: isHovered)
            .animation(DesignSystem.Animation.microInteraction, value: isSelected)
            .onHover { isHovered = $0 }
    }
    
    private var backgroundFill: Color {
        if isSelected {
            return DesignSystem.Colors.selectedBackground
        } else if isHovered {
            return DesignSystem.Colors.hoverBackground
        } else {
            return Color.clear
        }
    }
}

extension View {
    func enhancedRowStyle(isSelected: Bool = false) -> some View {
        modifier(EnhancedRowStyle(isSelected: isSelected))
    }
}

// MARK: - Custom Text Field Style

struct CerebralTextFieldStyle: TextFieldStyle {
    @FocusState private var isFocused: Bool
    let isError: Bool
    
    init(isError: Bool = false) {
        self.isError = isError
    }
    
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(DesignSystem.Typography.body)
            .padding(.horizontal, DesignSystem.Spacing.sm)
            .padding(.vertical, DesignSystem.Spacing.xs)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                    .fill(DesignSystem.Colors.background)
                    .stroke(
                        isError ? DesignSystem.Colors.errorRed :
                        isFocused ? DesignSystem.Colors.accent : DesignSystem.Colors.border,
                        lineWidth: isFocused || isError ? 2 : 1
                    )
            )
            .focused($isFocused)
    }
}

// MARK: - Accessibility Helpers

extension View {
    /// Adds proper accessibility labeling for buttons
    func accessibleButton(label: String, hint: String? = nil) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityAddTraits(.isButton)
            .accessibilityHint(hint ?? "")
    }
    
    /// Adds proper accessibility labeling for headings
    func accessibleHeading(level: AccessibilityHeadingLevel = .h1) -> some View {
        self
            .accessibilityAddTraits(.isHeader)
            .accessibilityHeading(level)
    }
    
    /// Adds minimum touch target size for accessibility
    func minimumTouchTarget() -> some View {
        self
            .frame(minWidth: 44, minHeight: 44)
    }
}

// MARK: - Custom View Modifiers

struct CardModifier: ViewModifier {
    let elevation: CardElevation
    
    enum CardElevation {
        case low, medium, high
        
        var shadow: (radius: CGFloat, y: CGFloat, opacity: Double) {
            switch self {
            case .low: return (2, 1, 0.1)
            case .medium: return (4, 2, 0.15)
            case .high: return (8, 4, 0.25)
            }
        }
    }
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                    .fill(DesignSystem.Colors.background)
                    .shadow(
                        color: Color.black.opacity(elevation.shadow.opacity),
                        radius: elevation.shadow.radius,
                        y: elevation.shadow.y
                    )
            )
    }
}

extension View {
    func card(elevation: CardModifier.CardElevation = .medium) -> some View {
        modifier(CardModifier(elevation: elevation))
    }
}

// MARK: - Status Indicators

struct StatusIndicator: View {
    enum Status {
        case connected, disconnected, loading, error
        
        var color: Color {
            switch self {
            case .connected: return DesignSystem.Colors.successGreen
            case .disconnected: return DesignSystem.Colors.secondary
            case .loading: return DesignSystem.Colors.warningOrange
            case .error: return DesignSystem.Colors.errorRed
            }
        }
        
        var text: String {
            switch self {
            case .connected: return "Connected"
            case .disconnected: return "Disconnected"
            case .loading: return "Connecting..."
            case .error: return "Connection Error"
            }
        }
    }
    
    let status: Status
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.xxs) {
            Circle()
                .fill(status.color)
                .frame(width: 8, height: 8)
            
            Text(status.text)
                .font(DesignSystem.Typography.caption)
                .foregroundColor(status.color)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Connection status: \(status.text)")
    }
}

// MARK: - Environment Extensions

extension EnvironmentValues {
    var openSettings: () -> Void {
        get { self[OpenSettingsKey.self] }
        set { self[OpenSettingsKey.self] = newValue }
    }
}

private struct OpenSettingsKey: EnvironmentKey {
    static let defaultValue: () -> Void = {
        NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
    }
} 