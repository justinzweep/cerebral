//
//  Components.swift
//  cerebral
//
//  UI Components and Styles for Cerebral macOS App
//  Modern interaction patterns and accessibility
//

import SwiftUI

// MARK: - Enhanced Button Styles (Modern Interaction Patterns)

struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @State private var isHovered = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DesignSystem.Typography.button)
            .foregroundColor(DesignSystem.Colors.textOnAccent)
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.vertical, DesignSystem.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button)
                    .fill(buttonBackgroundColor)
            )
            .scaleEffect(scaleValue(isPressed: configuration.isPressed))
            .animation(DesignSystem.Animation.micro, value: configuration.isPressed)
            .animation(DesignSystem.Animation.micro, value: isHovered)
            .opacity(isEnabled ? 1.0 : 0.6)
            .onHover { isHovered = $0 }
    }
    
    private var buttonBackgroundColor: Color {
        if !isEnabled {
            return DesignSystem.Colors.secondaryText
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
            .font(DesignSystem.Typography.button)
            .foregroundColor(DesignSystem.Colors.accent)
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.vertical, DesignSystem.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button)
                    .stroke(DesignSystem.Colors.accent.opacity(0.3), lineWidth: 1)
                    .background(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button)
                            .fill(backgroundFill(isPressed: configuration.isPressed))
                    )
            )
            .scaleEffect(scaleValue(isPressed: configuration.isPressed))
            .animation(DesignSystem.Animation.micro, value: configuration.isPressed)
            .animation(DesignSystem.Animation.micro, value: isHovered)
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

struct TertiaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @State private var isHovered = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DesignSystem.Typography.button)
            .foregroundColor(DesignSystem.Colors.secondaryText)
            .padding(.horizontal, DesignSystem.Spacing.sm)
            .padding(.vertical, DesignSystem.Spacing.xs)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button)
                    .fill(backgroundFill(isPressed: configuration.isPressed))
            )
            .scaleEffect(scaleValue(isPressed: configuration.isPressed))
            .animation(DesignSystem.Animation.micro, value: configuration.isPressed)
            .animation(DesignSystem.Animation.micro, value: isHovered)
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
            .font(DesignSystem.Typography.button)
            .foregroundColor(DesignSystem.Colors.error)
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.vertical, DesignSystem.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button)
                    .fill(backgroundFill(isPressed: configuration.isPressed))
            )
            .scaleEffect(scaleValue(isPressed: configuration.isPressed))
            .animation(DesignSystem.Animation.micro, value: configuration.isPressed)
            .animation(DesignSystem.Animation.micro, value: isHovered)
            .opacity(isEnabled ? 1.0 : 0.6)
            .onHover { isHovered = $0 }
    }
    
    private func backgroundFill(isPressed: Bool) -> Color {
        if isPressed {
            return DesignSystem.Colors.error.opacity(0.15)
        } else if isHovered {
            return DesignSystem.Colors.error.opacity(0.08)
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

// MARK: - Enhanced List Row Style (Modern Interaction)
struct EnhancedRowStyle: ViewModifier {
    @State private var isHovered = false
    let isSelected: Bool
    
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, DesignSystem.Spacing.sm)
            .padding(.vertical, DesignSystem.Spacing.xs)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                    .fill(backgroundFill)
            )
            .scaleEffect(isHovered ? DesignSystem.Scale.focus : 1.0)
            .animation(DesignSystem.Animation.micro, value: isHovered)
            .animation(DesignSystem.Animation.micro, value: isSelected)
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

// MARK: - Modern Text Field Style

struct CerebralTextFieldStyle: TextFieldStyle {
    @FocusState private var isFocused: Bool
    let isError: Bool
    
    init(isError: Bool = false) {
        self.isError = isError
    }
    
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(DesignSystem.Typography.body)
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.vertical, DesignSystem.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.input)
                    .fill(DesignSystem.Colors.background)
                    .stroke(
                        borderColor,
                        lineWidth: isFocused || isError ? 1.5 : 0.5
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

// MARK: - Modern Card Modifier

struct CardModifier: ViewModifier {
    let elevation: CardElevation
    let isInteractive: Bool
    @State private var isHovered = false
    
    enum CardElevation {
        case none, subtle, low, medium, high, floating
        
        var shadow: (radius: CGFloat, y: CGFloat, opacity: Double) {
            switch self {
            case .none: return (0, 0, 0)
            case .subtle: return (1, 0.5, 0.03)
            case .low: return (2, 1, 0.06)
            case .medium: return (4, 2, 0.10)
            case .high: return (8, 4, 0.15)
            case .floating: return (12, 6, 0.20)
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
    
    init(elevation: CardElevation = .medium, isInteractive: Bool = false) {
        self.elevation = elevation
        self.isInteractive = isInteractive
    }
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                    .fill(elevation.material)
                    .shadow(
                        color: Color.black.opacity(elevation.shadow.opacity),
                        radius: elevation.shadow.radius,
                        y: elevation.shadow.y
                    )
            )
            .scaleEffect(interactiveScale)
            .animation(DesignSystem.Animation.micro, value: isHovered)
            .onHover { hover in
                if isInteractive {
                    isHovered = hover
                }
            }
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
    func card(elevation: CardModifier.CardElevation = .medium, isInteractive: Bool = false) -> some View {
        modifier(CardModifier(elevation: elevation, isInteractive: isInteractive))
    }
}

// MARK: - Modern Status Indicators

struct StatusIndicator: View {
    enum Status {
        case connected, disconnected, loading, error, warning, info
        
        var color: Color {
            switch self {
            case .connected: return DesignSystem.Colors.success
            case .disconnected: return DesignSystem.Colors.secondaryText
            case .loading: return DesignSystem.Colors.warning
            case .error: return DesignSystem.Colors.error
            case .warning: return DesignSystem.Colors.warning
            case .info: return DesignSystem.Colors.info
            }
        }
        
        var text: String {
            switch self {
            case .connected: return "Connected"
            case .disconnected: return "Disconnected"
            case .loading: return "Connecting..."
            case .error: return "Connection Error"
            case .warning: return "Warning"
            case .info: return "Information"
            }
        }
        
        var icon: String {
            switch self {
            case .connected: return "checkmark.circle.fill"
            case .disconnected: return "xmark.circle.fill"
            case .loading: return "arrow.clockwise"
            case .error: return "exclamationmark.triangle.fill"
            case .warning: return "exclamationmark.triangle"
            case .info: return "info.circle.fill"
            }
        }
    }
    
    let status: Status
    let showText: Bool
    
    init(_ status: Status, showText: Bool = true) {
        self.status = status
        self.showText = showText
    }
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.xs) {
            Image(systemName: status.icon)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(status.color)
                .rotationEffect(.degrees(status == .loading ? 360 : 0))
                .animation(
                    status == .loading ? 
                    SwiftUI.Animation.linear(duration: 1.0).repeatForever(autoreverses: false) : 
                    .default, 
                    value: status
                )
            
            if showText {
                Text(status.text)
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(status.color)
            }
        }
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