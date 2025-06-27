//
//  IconButton.swift
//  cerebral
//
//  Reusable Icon Button Component
//

import SwiftUI

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
            case .small: return .system(size: 12, weight: .medium)
            case .medium: return .system(size: 14, weight: .medium)
            case .large: return .system(size: 16, weight: .medium)
            }
        }
        
        var frameSize: CGFloat {
            switch self {
            case .small: return 24
            case .medium: return 32
            case .large: return 40
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

// Helper to type-erase button styles
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

#Preview {
    VStack(spacing: 16) {
        HStack(spacing: 16) {
            IconButton(icon: "plus", style: .primary) { }
            IconButton(icon: "minus", style: .secondary) { }
            IconButton(icon: "xmark", style: .tertiary) { }
            IconButton(icon: "trash", style: .destructive) { }
        }
        
        HStack(spacing: 16) {
            IconButton(icon: "plus", style: .primary, size: .small) { }
            IconButton(icon: "plus", style: .primary, size: .medium) { }
            IconButton(icon: "plus", style: .primary, size: .large) { }
        }
    }
    .padding()
} 