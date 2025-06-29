//
//  Buttons.swift
//  cerebral
//
//  Consolidated Button Components
//

import SwiftUI

// MARK: - Primary Button

struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    let isDisabled: Bool
    let isLoading: Bool
    
    init(
        _ title: String,
        isDisabled: Bool = false,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.isDisabled = isDisabled
        self.isLoading = isLoading
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignSystem.Spacing.xs) {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .progressViewStyle(CircularProgressViewStyle(tint: DesignSystem.Colors.textOnAccent))
                }
                
                Text(title)
                    .font(DesignSystem.Typography.button)
                    .foregroundColor(DesignSystem.Colors.textOnAccent)
            }
        }
        .buttonStyle(PrimaryButtonStyle())
        .disabled(isDisabled || isLoading)
    }
}

// MARK: - Secondary Button

struct SecondaryButton: View {
    let title: String
    let action: () -> Void
    let isDisabled: Bool
    let isLoading: Bool
    
    init(
        _ title: String,
        isDisabled: Bool = false,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.isDisabled = isDisabled
        self.isLoading = isLoading
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignSystem.Spacing.xs) {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .progressViewStyle(CircularProgressViewStyle(tint: DesignSystem.Colors.accent))
                }
                
                Text(title)
                    .font(DesignSystem.Typography.button)
                    .foregroundColor(DesignSystem.Colors.accent)
            }
        }
        .buttonStyle(SecondaryButtonStyle())
        .disabled(isDisabled || isLoading)
    }
}

// MARK: - Icon Button

struct IconButton: View {
    let icon: String
    let action: () -> Void
    let isDisabled: Bool
    let style: IconButtonStyle
    let size: IconSize
    
    enum IconButtonStyle {
        case primary, secondary, tertiary, destructive
        
        var buttonStyle: any ButtonStyle {
            switch self {
            case .primary: return PrimaryButtonStyle()
            case .secondary: return SecondaryButtonStyle()
            case .tertiary: return TertiaryButtonStyle()
            case .destructive: return DestructiveButtonStyle()
            }
        }
        
        var iconColor: Color {
            switch self {
            case .primary: return DesignSystem.Colors.textOnAccent
            case .secondary: return DesignSystem.Colors.accent
            case .tertiary: return DesignSystem.Colors.secondaryText
            case .destructive: return DesignSystem.Colors.error
            }
        }
    }
    
    enum IconSize {
        case small, medium, large
        
        var font: Font {
            switch self {
            case .small: return .system(size: DesignSystem.ComponentSizes.iconMD, weight: .medium)
            case .medium: return .system(size: DesignSystem.ComponentSizes.iconLG, weight: .medium)
            case .large: return .system(size: DesignSystem.ComponentSizes.iconXL, weight: .medium)
            }
        }
        
        var frameSize: CGFloat {
            switch self {
            case .small: return DesignSystem.ComponentSizes.buttonIconSM
            case .medium: return DesignSystem.ComponentSizes.buttonIconMD
            case .large: return DesignSystem.ComponentSizes.buttonIconLG
            }
        }
    }
    
    init(
        icon: String,
        style: IconButtonStyle = .tertiary,
        size: IconSize = .medium,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.style = style
        self.size = size
        self.isDisabled = isDisabled
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(size.font)
                .foregroundColor(style.iconColor)
                .frame(width: size.frameSize, height: size.frameSize)
        }
        .buttonStyle(AnyButtonStyle(style.buttonStyle))
        .disabled(isDisabled)
    }
}

// MARK: - Helper for Type Erasure

private struct AnyButtonStyle: ButtonStyle {
    private let _makeBody: (Configuration) -> AnyView
    
    init<S: ButtonStyle>(_ style: S) {
        _makeBody = { configuration in
            AnyView(style.makeBody(configuration: configuration))
        }
    }
    
    func makeBody(configuration: Configuration) -> some View {
        _makeBody(configuration)
    }
}

// MARK: - Previews

#Preview {
    VStack(spacing: 20) {
        // Primary and Secondary Buttons
        VStack(spacing: 16) {
            PrimaryButton("Normal Button") { }
            PrimaryButton("Disabled Button", isDisabled: true) { }
            PrimaryButton("Loading Button", isLoading: true) { }
            
            SecondaryButton("Normal Button") { }
            SecondaryButton("Disabled Button", isDisabled: true) { }
            SecondaryButton("Loading Button", isLoading: true) { }
        }
        
        // Icon Buttons - Styles
        HStack(spacing: 16) {
            IconButton(icon: "plus", style: .primary) { }
            IconButton(icon: "minus", style: .secondary) { }
            IconButton(icon: "xmark", style: .tertiary) { }
            IconButton(icon: "trash", style: .destructive) { }
        }
        
        // Icon Buttons - Sizes
        HStack(spacing: 16) {
            IconButton(icon: "plus", style: .primary, size: .small) { }
            IconButton(icon: "plus", style: .primary, size: .medium) { }
            IconButton(icon: "plus", style: .primary, size: .large) { }
        }
    }
    .padding()
} 