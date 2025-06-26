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
    
    // MARK: - Colors
    struct Colors {
        // Semantic Colors
        static let primary = Color.primary
        static let secondary = Color.secondary
        static let accent = Color.accentColor
        
        // Custom App Colors
        static let pdfRed = Color(.systemRed)
        static let folderBlue = Color(.systemBlue)
        static let highlightYellow = Color(.systemYellow)
        static let successGreen = Color(.systemGreen)
        static let warningOrange = Color(.systemOrange)
        static let errorRed = Color(.systemRed)
        
        // Background Colors
        static let background = Color(NSColor.controlBackgroundColor)
        static let secondaryBackground = Color(NSColor.windowBackgroundColor)
        static let groupedBackground = Color(NSColor.unemphasizedSelectedContentBackgroundColor)
        
        // Surface Colors with Materials
        static let surfacePrimary = Material.regular
        static let surfaceSecondary = Material.thin
        static let surfaceUltraThin = Material.ultraThin
        
        // Text Colors
        static let textPrimary = Color.primary
        static let textSecondary = Color.secondary
        static let textTertiary = Color(NSColor.tertiaryLabelColor)
        static let textPlaceholder = Color(NSColor.placeholderTextColor)
        
        // Border Colors
        static let border = Color(NSColor.separatorColor)
        static let borderSecondary = Color(NSColor.gridColor)
    }
    
    // MARK: - Typography
    struct Typography {
        // Title Styles
        static let largeTitle = Font.largeTitle.weight(.bold)
        static let title = Font.title.weight(.semibold)
        static let title2 = Font.title2.weight(.semibold)
        static let title3 = Font.title3.weight(.medium)
        
        // Body Styles
        static let headline = Font.headline.weight(.medium)
        static let body = Font.body
        static let bodyMedium = Font.body.weight(.medium)
        static let callout = Font.callout
        static let subheadline = Font.subheadline
        
        // Small Text Styles
        static let footnote = Font.footnote
        static let caption = Font.caption
        static let caption2 = Font.caption2
        
        // Special Styles
        static let monospace = Font.system(.body, design: .monospaced)
        static let code = Font.system(.caption, design: .monospaced)
    }
    
    // MARK: - Spacing (8pt Grid System)
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
    
    // MARK: - Shadows
    struct Shadows {
        static let subtle = Color.black.opacity(0.05)
        static let light = Color.black.opacity(0.1)
        static let medium = Color.black.opacity(0.15)
        static let strong = Color.black.opacity(0.25)
    }
    
    // MARK: - Animation
    struct Animation {
        static let quick = SwiftUI.Animation.easeInOut(duration: 0.15)
        static let smooth = SwiftUI.Animation.easeInOut(duration: 0.25)
        static let gentle = SwiftUI.Animation.easeInOut(duration: 0.35)
        static let spring = SwiftUI.Animation.spring(response: 0.5, dampingFraction: 0.8)
    }
}

// MARK: - Custom Button Styles

struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DesignSystem.Typography.bodyMedium)
            .foregroundColor(.white)
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.vertical, DesignSystem.Spacing.xs)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                    .fill(isEnabled ? DesignSystem.Colors.accent : DesignSystem.Colors.secondary)
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(DesignSystem.Animation.quick, value: configuration.isPressed)
            .opacity(isEnabled ? 1.0 : 0.6)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    
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
                            .fill(configuration.isPressed ? DesignSystem.Colors.accent.opacity(0.1) : Color.clear)
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(DesignSystem.Animation.quick, value: configuration.isPressed)
            .opacity(isEnabled ? 1.0 : 0.6)
    }
}

struct TertiaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DesignSystem.Typography.body)
            .foregroundColor(DesignSystem.Colors.textSecondary)
            .padding(.horizontal, DesignSystem.Spacing.sm)
            .padding(.vertical, DesignSystem.Spacing.xs)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                    .fill(configuration.isPressed ? DesignSystem.Colors.background : Color.clear)
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(DesignSystem.Animation.quick, value: configuration.isPressed)
            .opacity(isEnabled ? 1.0 : 0.6)
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