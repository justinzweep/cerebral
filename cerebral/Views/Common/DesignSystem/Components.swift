//
//  Components.swift
//  cerebral
//
//  Modern Conversational UI Components
//  Inspired by ChatGPT's approachable intelligence and Airbnb's warm hospitality
//

import SwiftUI

// MARK: - Beautiful Gradient Button Styles (ChatGPT & Airbnb Inspired)

struct PrimaryGradientButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @State private var isHovered = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .appleTextStyle(.button)
            .foregroundColor(.white)
            .fontWeight(.semibold)
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .padding(.vertical, DesignSystem.Spacing.sm + 2)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button)
                    .fill(backgroundGradient(isPressed: configuration.isPressed))
            )
            .scaleEffect(scaleValue(isPressed: configuration.isPressed))
            .animation(DesignSystem.Animation.delightful, value: configuration.isPressed)
            .animation(DesignSystem.Animation.delightful, value: isHovered)
            .opacity(isEnabled ? 1.0 : 0.6)
            .onHover { isHovered = $0 }
    }
    
    private func backgroundGradient(isPressed: Bool) -> LinearGradient {
        if isPressed {
            return DesignSystem.Gradients.electricBlue
        } else if isHovered {
            return DesignSystem.Gradients.conversational
        } else {
            return DesignSystem.Gradients.oceanSunset
        }
    }
    
    private func scaleValue(isPressed: Bool) -> CGFloat {
        if isPressed {
            return DesignSystem.Scale.pressed
        } else if isHovered {
            return DesignSystem.Scale.hover
        } else {
            return 1.0
        }
    }
}

struct SecondaryGradientButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @State private var isHovered = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .appleTextStyle(.button)
            .foregroundColor(.white)
            .fontWeight(.medium)
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.vertical, DesignSystem.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button)
                    .fill(backgroundGradient(isPressed: configuration.isPressed))
            )
            .scaleEffect(scaleValue(isPressed: configuration.isPressed))
            .animation(DesignSystem.Animation.delightful, value: configuration.isPressed)
            .animation(DesignSystem.Animation.delightful, value: isHovered)
            .opacity(isEnabled ? 1.0 : 0.6)
            .onHover { isHovered = $0 }
    }
    
    private func backgroundGradient(isPressed: Bool) -> LinearGradient {
        if isPressed {
            return DesignSystem.Gradients.purpleDream
        } else if isHovered {
            return DesignSystem.Gradients.tealMagic
        } else {
            return DesignSystem.Gradients.purpleDream
        }
    }
    
    private func scaleValue(isPressed: Bool) -> CGFloat {
        if isPressed {
            return DesignSystem.Scale.pressed
        } else if isHovered {
            return DesignSystem.Scale.hover
        } else {
            return 1.0
        }
    }
}

struct WarmButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @State private var isHovered = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .appleTextStyle(.button)
            .foregroundColor(.white)
            .fontWeight(.medium)
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.vertical, DesignSystem.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button)
                    .fill(backgroundGradient(isPressed: configuration.isPressed))
            )
            .scaleEffect(scaleValue(isPressed: configuration.isPressed))
            .animation(DesignSystem.Animation.delightful, value: configuration.isPressed)
            .animation(DesignSystem.Animation.delightful, value: isHovered)
            .opacity(isEnabled ? 1.0 : 0.6)
            .onHover { isHovered = $0 }
    }
    
    private func backgroundGradient(isPressed: Bool) -> LinearGradient {
        if isPressed {
            return DesignSystem.Gradients.warmWelcome
        } else if isHovered {
            return DesignSystem.Gradients.warmWelcome
        } else {
            return DesignSystem.Gradients.warmWelcome
        }
    }
    
    private func scaleValue(isPressed: Bool) -> CGFloat {
        if isPressed {
            return DesignSystem.Scale.pressed
        } else if isHovered {
            return DesignSystem.Scale.hover
        } else {
            return 1.0
        }
    }
}

// MARK: - Classic Button Styles (Updated with New Colors)

struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @State private var isHovered = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .appleTextStyle(.button)
            .foregroundColor(DesignSystem.Colors.textOnAccent)
            .fontWeight(.semibold)
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .padding(.vertical, DesignSystem.Spacing.sm + 2)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button)
                    .fill(backgroundFill(isPressed: configuration.isPressed))
            )
            .scaleEffect(scaleValue(isPressed: configuration.isPressed))
            .animation(DesignSystem.Animation.delightful, value: configuration.isPressed)
            .animation(DesignSystem.Animation.delightful, value: isHovered)
            .opacity(isEnabled ? 1.0 : 0.6)
            .onHover { isHovered = $0 }
    }
    
    private func backgroundFill(isPressed: Bool) -> Color {
        if isPressed {
            return DesignSystem.Colors.accentPressed
        } else if isHovered {
            return DesignSystem.Colors.accentHover
        } else {
            return DesignSystem.Colors.accent
        }
    }
    
    private func scaleValue(isPressed: Bool) -> CGFloat {
        if isPressed {
            return DesignSystem.Scale.pressed
        } else if isHovered {
            return DesignSystem.Scale.hover
        } else {
            return 1.0
        }
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @State private var isHovered = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .appleTextStyle(.button)
            .foregroundColor(foregroundColor(isPressed: configuration.isPressed))
            .fontWeight(.medium)
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.vertical, DesignSystem.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button)
                    .stroke(borderColor(isPressed: configuration.isPressed), lineWidth: 1.5)
                    .background(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button)
                            .fill(backgroundFill(isPressed: configuration.isPressed))
                    )
            )
            .scaleEffect(scaleValue(isPressed: configuration.isPressed))
            .animation(DesignSystem.Animation.delightful, value: configuration.isPressed)
            .animation(DesignSystem.Animation.delightful, value: isHovered)
            .opacity(isEnabled ? 1.0 : 0.6)
            .onHover { isHovered = $0 }
    }
    
    private func foregroundColor(isPressed: Bool) -> Color {
        if isPressed {
            return DesignSystem.Colors.accentPressed
        } else if isHovered {
            return DesignSystem.Colors.accentHover
        } else {
            return DesignSystem.Colors.accent
        }
    }
    
    private func borderColor(isPressed: Bool) -> Color {
        if isPressed {
            return DesignSystem.Colors.accentPressed
        } else if isHovered {
            return DesignSystem.Colors.accentHover
        } else {
            return DesignSystem.Colors.accent.opacity(0.4)
        }
    }
    
    private func backgroundFill(isPressed: Bool) -> Color {
        if isPressed {
            return DesignSystem.Colors.pressedBackground
        } else if isHovered {
            return DesignSystem.Colors.hoverBackground
        } else {
            return Color.clear
        }
    }
    
    private func scaleValue(isPressed: Bool) -> CGFloat {
        if isPressed {
            return DesignSystem.Scale.pressed
        } else if isHovered {
            return DesignSystem.Scale.hover
        } else {
            return 1.0
        }
    }
}

struct TertiaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @State private var isHovered = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .appleTextStyle(.button)
            .foregroundColor(DesignSystem.Colors.secondaryText)
            .fontWeight(.medium)
            .padding(.horizontal, DesignSystem.Spacing.sm)
            .padding(.vertical, DesignSystem.Spacing.xs)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button)
                    .fill(backgroundFill(isPressed: configuration.isPressed))
            )
            .scaleEffect(scaleValue(isPressed: configuration.isPressed))
            .animation(DesignSystem.Animation.delightful, value: configuration.isPressed)
            .animation(DesignSystem.Animation.delightful, value: isHovered)
            .opacity(isEnabled ? 1.0 : 0.6)
            .onHover { isHovered = $0 }
    }
    
    private func backgroundFill(isPressed: Bool) -> Color {
        if isPressed {
            return DesignSystem.Colors.pressedBackground
        } else if isHovered {
            return DesignSystem.Colors.hoverBackground
        } else {
            return Color.clear
        }
    }
    
    private func scaleValue(isPressed: Bool) -> CGFloat {
        if isPressed {
            return DesignSystem.Scale.pressed
        } else if isHovered {
            return DesignSystem.Scale.hover
        } else {
            return 1.0
        }
    }
}

struct DestructiveButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @State private var isHovered = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .appleTextStyle(.button)
            .foregroundColor(DesignSystem.Colors.error)
            .fontWeight(.medium)
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.vertical, DesignSystem.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button)
                    .fill(backgroundFill(isPressed: configuration.isPressed))
            )
            .scaleEffect(scaleValue(isPressed: configuration.isPressed))
            .animation(DesignSystem.Animation.delightful, value: configuration.isPressed)
            .animation(DesignSystem.Animation.delightful, value: isHovered)
            .opacity(isEnabled ? 1.0 : 0.6)
            .onHover { isHovered = $0 }
    }
    
    private func backgroundFill(isPressed: Bool) -> Color {
        if isPressed {
            return DesignSystem.Colors.error.opacity(0.2)
        } else if isHovered {
            return DesignSystem.Colors.error.opacity(0.12)
        } else {
            return Color.clear
        }
    }
    
    private func scaleValue(isPressed: Bool) -> CGFloat {
        if isPressed {
            return DesignSystem.Scale.pressed
        } else if isHovered {
            return DesignSystem.Scale.hover
        } else {
            return 1.0
        }
    }
}

// MARK: - Enhanced Row Style (Warm & Responsive)
struct EnhancedRowStyle: ViewModifier {
    @State private var isHovered = false
    let isSelected: Bool
    
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, DesignSystem.Spacing.sm)
            .padding(.vertical, DesignSystem.Spacing.xs + 2)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                    .fill(backgroundFill)
            )
            .scaleEffect(isHovered ? DesignSystem.Scale.focus : 1.0)
            .animation(DesignSystem.Animation.delightful, value: isHovered)
            .animation(DesignSystem.Animation.delightful, value: isSelected)
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

// MARK: - Modern Conversational Text Field Style

struct ConversationalTextFieldStyle: TextFieldStyle {
    @FocusState private var isFocused: Bool
    let isError: Bool
    
    init(isError: Bool = false) {
        self.isError = isError
    }
    
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .appleTextStyle(.body)
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.vertical, DesignSystem.Spacing.sm + 2)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.input)
                    .fill(DesignSystem.Colors.surfaceBackground)
                    .stroke(
                        borderColor,
                        lineWidth: isFocused || isError ? 2.0 : 1.0
                    )
                    .animation(DesignSystem.Animation.quick, value: isFocused)
            )
            .focused($isFocused)
    }
    
    private var borderColor: Color {
        if isError {
            return DesignSystem.Colors.borderError
        } else if isFocused {
            return DesignSystem.Colors.borderFocus
        } else {
            return DesignSystem.Colors.border
        }
    }
}

// MARK: - Beautiful Card Modifier (ChatGPT & Airbnb Inspired)

struct BeautifulCardModifier: ViewModifier {
    let elevation: CardElevation
    let isInteractive: Bool
    let useGradient: Bool
    @State private var isHovered = false
    
    enum CardElevation {
        case none, subtle, low, medium, high, floating
        
        var shadow: (radius: CGFloat, y: CGFloat, opacity: Double) {
            switch self {
            case .none: return (0, 0, 0)
            case .subtle: return (2, 1, 0.04)
            case .low: return (4, 2, 0.08)
            case .medium: return (8, 4, 0.12)
            case .high: return (12, 6, 0.16)
            case .floating: return (20, 10, 0.24)
            }
        }
        
        var material: Material {
            switch self {
            case .none, .subtle, .low: return Material.thin
            case .medium: return Material.regular
            case .high, .floating: return Material.thick
            }
        }
    }
    
    init(elevation: CardElevation = .medium, isInteractive: Bool = false, useGradient: Bool = false) {
        self.elevation = elevation
        self.isInteractive = isInteractive
        self.useGradient = useGradient
    }
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                    .fill(cardBackground)
                    .shadow(
                        color: shadowColor,
                        radius: elevation.shadow.radius,
                        y: elevation.shadow.y
                    )
            )
            .scaleEffect(interactiveScale)
            .animation(DesignSystem.Animation.delightful, value: isHovered)
            .onHover { hover in
                if isInteractive {
                    isHovered = hover
                }
            }
    }
    
    private var cardBackground: AnyShapeStyle {
        if useGradient {
            return AnyShapeStyle(DesignSystem.Gradients.cardSurface)
        } else {
            return AnyShapeStyle(DesignSystem.Colors.cardBackground)
        }
    }
    
    private var shadowColor: Color {
        Color.black.opacity(elevation.shadow.opacity)
    }
    
    private var interactiveScale: CGFloat {
        if isInteractive && isHovered {
            return DesignSystem.Scale.hover
        } else {
            return 1.0
        }
    }
}

extension View {
    func beautifulCard(elevation: BeautifulCardModifier.CardElevation = .medium, 
                      isInteractive: Bool = false, 
                      useGradient: Bool = false) -> some View {
        modifier(BeautifulCardModifier(elevation: elevation, isInteractive: isInteractive, useGradient: useGradient))
    }
    
    // Legacy support
    func card(elevation: BeautifulCardModifier.CardElevation = .medium, isInteractive: Bool = false) -> some View {
        modifier(BeautifulCardModifier(elevation: elevation, isInteractive: isInteractive))
    }
}

// MARK: - Modern Status Indicators (Friendly & Clear)

struct StatusIndicator: View {
    enum Status {
        case connected, disconnected, loading, error, warning, info, thinking, ready
        
        var color: Color {
            switch self {
            case .connected: return DesignSystem.Colors.success
            case .disconnected: return DesignSystem.Colors.tertiaryText
            case .loading, .thinking: return DesignSystem.Colors.secondaryAccent
            case .error: return DesignSystem.Colors.error
            case .warning: return DesignSystem.Colors.warning
            case .info, .ready: return DesignSystem.Colors.accent
            }
        }
        
        var gradient: LinearGradient? {
            switch self {
            case .connected: return DesignSystem.Gradients.success
            case .thinking: return DesignSystem.Gradients.conversational
            case .ready: return DesignSystem.Gradients.aiAssistant
            default: return nil
            }
        }
        
        var text: String {
            switch self {
            case .connected: return "Connected"
            case .disconnected: return "Disconnected"
            case .loading: return "Loading..."
            case .thinking: return "Thinking..."
            case .error: return "Error"
            case .warning: return "Warning"
            case .info: return "Info"
            case .ready: return "Ready"
            }
        }
        
        var icon: String {
            switch self {
            case .connected: return "checkmark.circle.fill"
            case .disconnected: return "xmark.circle.fill"
            case .loading: return "arrow.clockwise"
            case .thinking: return "brain.head.profile"
            case .error: return "exclamationmark.triangle.fill"
            case .warning: return "exclamationmark.triangle"
            case .info: return "info.circle.fill"
            case .ready: return "sparkles"
            }
        }
    }
    
    let status: Status
    let showText: Bool
    let useGradient: Bool
    
    init(_ status: Status, showText: Bool = true, useGradient: Bool = false) {
        self.status = status
        self.showText = showText
        self.useGradient = useGradient
    }
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.xs) {
            Group {
                if useGradient && status.gradient != nil {
                    Image(systemName: status.icon)
                        .font(.system(size: DesignSystem.ComponentSizes.iconMD, weight: .medium))
                        .foregroundStyle(status.gradient!)
                } else {
                    Image(systemName: status.icon)
                        .font(.system(size: DesignSystem.ComponentSizes.iconMD, weight: .medium))
                        .foregroundColor(status.color)
                }
            }
            .rotationEffect(.degrees(shouldRotate ? 360 : 0))
            .animation(
                shouldRotate ? 
                SwiftUI.Animation.linear(duration: 1.5).repeatForever(autoreverses: false) : 
                .default, 
                value: status
            )
            
            if showText {
                Text(status.text)
                    .appleTextStyle(.caption)
                    .foregroundColor(status.color)
                    .fontWeight(.medium)
            }
        }
    }
    
    private var shouldRotate: Bool {
        status == .loading || status == .thinking
    }
}

// MARK: - Conversational Badge Component

struct ConversationalBadge: View {
    let text: String
    let style: BadgeStyle
    
    enum BadgeStyle {
        case primary, secondary, success, warning, error, info, gradient
        
        var colors: (background: Color, text: Color) {
            switch self {
            case .primary:
                return (DesignSystem.Colors.accent.opacity(0.1), DesignSystem.Colors.accent)
            case .secondary:
                return (DesignSystem.Colors.secondaryAccent.opacity(0.1), DesignSystem.Colors.secondaryAccent)
            case .success:
                return (DesignSystem.Colors.successBackground, DesignSystem.Colors.success)
            case .warning:
                return (DesignSystem.Colors.warningBackground, DesignSystem.Colors.warning)
            case .error:
                return (DesignSystem.Colors.errorBackground, DesignSystem.Colors.error)
            case .info:
                return (DesignSystem.Colors.tertiaryAccentBackground, DesignSystem.Colors.tertiaryAccent)
            case .gradient:
                return (Color.clear, Color.white)
            }
        }
        
        var gradient: LinearGradient? {
            switch self {
            case .gradient: return DesignSystem.Gradients.conversational
            default: return nil
            }
        }
    }
    
    init(_ text: String, style: BadgeStyle = .primary) {
        self.text = text
        self.style = style
    }
    
    var body: some View {
        Text(text)
            .appleTextStyle(.caption2)
            .fontWeight(.semibold)
            .foregroundColor(style.colors.text)
            .padding(.horizontal, DesignSystem.Spacing.xs + 2)
            .padding(.vertical, DesignSystem.Spacing.xxxs + 1)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xs)
                    .fill(badgeBackground)
            )
    }
    
    private var badgeBackground: AnyShapeStyle {
        if let gradient = style.gradient {
            return AnyShapeStyle(gradient)
        } else {
            return AnyShapeStyle(style.colors.background)
        }
    }
}

// MARK: - Typography Convenience Components

struct ConversationalText: View {
    let text: String
    let style: TextStyle
    
    enum TextStyle {
        case hero, title, subtitle, body, caption, accent
        
        var font: Font {
            switch self {
            case .hero: return DesignSystem.Typography.largeTitle
            case .title: return DesignSystem.Typography.title
            case .subtitle: return DesignSystem.Typography.title2
            case .body: return DesignSystem.Typography.body
            case .caption: return DesignSystem.Typography.caption
            case .accent: return DesignSystem.Typography.headline
            }
        }
        
        var color: Color {
            switch self {
            case .hero, .title: return DesignSystem.Colors.primaryText
            case .subtitle: return DesignSystem.Colors.secondaryText
            case .body: return DesignSystem.Colors.primaryText
            case .caption: return DesignSystem.Colors.tertiaryText
            case .accent: return DesignSystem.Colors.accent
            }
        }
        
        var weight: Font.Weight {
            switch self {
            case .hero: return .bold
            case .title: return .semibold
            case .subtitle: return .medium
            case .body: return .regular
            case .caption: return .medium
            case .accent: return .semibold
            }
        }
    }
    
    init(_ text: String, style: TextStyle = .body) {
        self.text = text
        self.style = style
    }
    
    var body: some View {
        Text(text)
            .font(style.font.weight(style.weight))
            .foregroundColor(style.color)
    }
}



