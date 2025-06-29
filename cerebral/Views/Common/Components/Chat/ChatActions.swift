//
//  ChatActions.swift
//  cerebral
//
//  Reusable Chat Actions Component
//  Modern send button following Cerebral design principles
//

import SwiftUI

struct ChatActions: View {
    let canSend: Bool
    let isLoading: Bool
    let isStreaming: Bool
    let onSend: () -> Void
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            SendButton(
                canSend: canSend,
                isLoading: isLoading,
                isStreaming: isStreaming,
                onSend: onSend
            )
        }
    }
}

struct SendButton: View {
    let canSend: Bool
    let isLoading: Bool
    let isStreaming: Bool
    let onSend: () -> Void
    
    @State private var isHovered = false
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            print("🔲 SendButton clicked")
            print("   - canSend: \(canSend)")
            print("   - isLoading: \(isLoading)")
            print("   - isStreaming: \(isStreaming)")
            print("   - isButtonDisabled: \(isButtonDisabled)")
            
            if !isButtonDisabled {
                print("✅ Button enabled - calling onSend()")
                onSend()
            } else {
                print("❌ Button disabled - not calling onSend()")
            }
        }) {
            buttonContent
        }
                    .frame(width: DesignSystem.ComponentSizes.largeIconFrame.width, height: DesignSystem.ComponentSizes.largeIconFrame.height)
        .background(backgroundShape)
        .scaleEffect(buttonScale)
        .opacity(buttonOpacity)
        .animation(DesignSystem.Animation.micro, value: canSend)
        .animation(DesignSystem.Animation.micro, value: isLoading)
        .animation(DesignSystem.Animation.micro, value: isStreaming)
        .animation(DesignSystem.Animation.micro, value: isHovered)
        .animation(DesignSystem.Animation.micro, value: isPressed)
        .buttonStyle(.plain)
        .disabled(isButtonDisabled)
        .onHover { isHovered = $0 }
        .pressEvents(
            onPress: { isPressed = true },
            onRelease: { isPressed = false }
        )
    }
    
    // MARK: - Button Content
    
    @ViewBuilder
    private var buttonContent: some View {
        if isLoading || isStreaming {
            LoadingSpinner(size: .small, color: contentColor)
        } else {
            Image(systemName: "arrow.up")
                                        .font(DesignSystem.Typography.button)
                .foregroundColor(contentColor)
        }
    }
    
    // MARK: - Background Shape
    
    private var backgroundShape: some View {
        Circle()
            .fill(backgroundFill)
            .overlay(
                Circle()
                    .stroke(borderColor, lineWidth: borderWidth)
            )
    }
    
    // MARK: - Computed Properties
    
    private var isButtonDisabled: Bool {
        !canSend || isLoading || isStreaming
    }
    
    private var isActive: Bool {
        canSend && !isLoading && !isStreaming
    }
    
    private var backgroundFill: Color {
        if isActive {
            if isPressed {
                return DesignSystem.Colors.accentPressed
            } else if isHovered {
                return DesignSystem.Colors.accentHover
            } else {
                return DesignSystem.Colors.accent
            }
        } else {
            return DesignSystem.Colors.tertiaryBackground
        }
    }
    
    private var contentColor: Color {
        if isActive {
            return DesignSystem.Colors.textOnAccent
        } else {
            return DesignSystem.Colors.tertiaryText
        }
    }
    
    private var borderColor: Color {
        if isActive {
            return Color.clear
        } else {
            return DesignSystem.Colors.border.opacity(0.3)
        }
    }
    
    private var borderWidth: CGFloat {
        isActive ? 0 : 0.5
    }
    
    private var buttonScale: CGFloat {
        if isPressed {
            return DesignSystem.Scale.pressed
        } else if isHovered && isActive {
            return DesignSystem.Scale.hover
        } else {
            return 1.0
        }
    }
    
    private var buttonOpacity: Double {
        if isActive {
            return 1.0
        } else {
            return 0.6
        }
    }
}

// MARK: - Press Events Helper

private struct PressEvents: ViewModifier {
    let onPress: () -> Void
    let onRelease: () -> Void
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(1.0)
            .onLongPressGesture(
                minimumDuration: 0,
                maximumDistance: 50,
                pressing: { pressing in
                    if pressing {
                        onPress()
                    } else {
                        onRelease()
                    }
                },
                perform: {}
            )
    }
}

extension View {
    func pressEvents(onPress: @escaping () -> Void, onRelease: @escaping () -> Void) -> some View {
        modifier(PressEvents(onPress: onPress, onRelease: onRelease))
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: DesignSystem.Spacing.lg) {
        // Active state
        ChatActions(
            canSend: true,
            isLoading: false,
            isStreaming: false
        ) {
            print("Send message")
        }
        
        // Disabled state (no text)
        ChatActions(
            canSend: false,
            isLoading: false,
            isStreaming: false
        ) {
            print("Send message")
        }
        
        // Loading state
        ChatActions(
            canSend: true,
            isLoading: true,
            isStreaming: false
        ) {
            print("Send message")
        }
        
        // Streaming state
        ChatActions(
            canSend: true,
            isLoading: false,
            isStreaming: true
        ) {
            print("Send message")
        }
    }
    .padding(DesignSystem.Spacing.xl)
    .background(DesignSystem.Colors.background)
} 
