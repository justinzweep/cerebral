//
//  ChatActions.swift
//  cerebral
//
//  Reusable Chat Actions Component
//

import SwiftUI

struct ChatActions: View {
    let canSend: Bool
    let isLoading: Bool
    let isStreaming: Bool
    let onSend: () -> Void
    
    var body: some View {
        HStack(spacing: 8) {
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
    
    var body: some View {
        Button(action: onSend) {
            if isLoading || isStreaming {
                LoadingSpinner(size: .small, color: .white)
            } else {
                Image(systemName: "arrow.up")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
            }
        }
        .frame(width: 32, height: 32)
        .background(
            Circle()
                .fill(buttonBackgroundColor)
        )
        .scaleEffect(buttonScale)
        .animation(.easeInOut(duration: 0.15), value: canSend)
        .animation(.easeInOut(duration: 0.15), value: isLoading)
        .animation(.easeInOut(duration: 0.15), value: isStreaming)
        .buttonStyle(.plain)
        .disabled(!canSend || isLoading || isStreaming)
        .keyboardShortcut(.return, modifiers: [])
    }
    
    private var buttonBackgroundColor: Color {
        if canSend && !isLoading && !isStreaming {
            return DesignSystem.Colors.accent
        } else {
            return DesignSystem.Colors.tertiaryText.opacity(0.3)
        }
    }
    
    private var buttonScale: CGFloat {
        if canSend && !isLoading && !isStreaming {
            return 1.0
        } else {
            return 0.9
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        // Normal state
        ChatActions(
            canSend: true,
            isLoading: false,
            isStreaming: false
        ) {
            print("Send message")
        }
        
        // Disabled state
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
    .padding()
} 