//
//  MessageView.swift
//  cerebral
//
//  Created by Justin Zweep on 26/06/2025.
//

import SwiftUI

struct MessageView: View {
    let message: ChatMessage
    
    var body: some View {
        HStack(alignment: .top, spacing: DesignSystem.Spacing.sm) {
            if message.isUser {
                Spacer(minLength: DesignSystem.Spacing.xl)
                
                VStack(alignment: .trailing, spacing: DesignSystem.Spacing.xxs) {
                    HStack {
                        Text(message.text)
                            .font(DesignSystem.Typography.body)
                            .foregroundColor(.white)
                            .padding(.horizontal, DesignSystem.Spacing.md)
                            .padding(.vertical, DesignSystem.Spacing.sm)
                            .background(DesignSystem.Colors.accent)
                            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg))
                            .shadow(color: DesignSystem.Shadows.light, radius: 2, y: 1)
                    }
                    
                    Text(message.timestamp, style: .time)
                        .font(DesignSystem.Typography.caption2)
                        .foregroundColor(DesignSystem.Colors.textTertiary)
                }
                
                // User Avatar
                Circle()
                    .fill(DesignSystem.Colors.accent)
                    .frame(width: 32, height: 32)
                    .overlay {
                        Image(systemName: "person.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 16))
                    }
                    .accessibilityLabel("User message")
            } else {
                // AI Avatar
                Circle()
                    .fill(DesignSystem.Colors.accent.opacity(0.8))
                    .frame(width: 32, height: 32)
                    .overlay {
                        Image(systemName: "brain.head.profile")
                            .foregroundColor(.white)
                            .font(.system(size: 16))
                    }
                    .accessibilityLabel("AI Assistant message")
                
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                    HStack {
                        Text(message.text)
                            .font(DesignSystem.Typography.body)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                            .padding(.horizontal, DesignSystem.Spacing.md)
                            .padding(.vertical, DesignSystem.Spacing.sm)
                            .background(DesignSystem.Colors.background)
                            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg))
                            .shadow(color: DesignSystem.Shadows.subtle, radius: 1, y: 0.5)
                    }
                    
                    HStack(spacing: DesignSystem.Spacing.xs) {
                        Text(message.timestamp, style: .time)
                            .font(DesignSystem.Typography.caption2)
                            .foregroundColor(DesignSystem.Colors.textTertiary)
                        
                        if !message.documentReferences.isEmpty {
                            Image(systemName: "doc.text")
                                .font(DesignSystem.Typography.caption2)
                                .foregroundColor(DesignSystem.Colors.accent)
                        }
                    }
                }
                
                Spacer(minLength: DesignSystem.Spacing.xl)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(message.isUser ? "You" : "AI Assistant") said: \(message.text)")
        .accessibilityHint("Message sent at \(message.timestamp, style: .time)")
        .contextMenu {
            Button("Copy Message") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(message.text, forType: .string)
            }
            .accessibleButton(label: "Copy message text", hint: "Copies the message text to clipboard")
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        MessageView(message: ChatMessage(
            text: "Hello, how can I help you with your documents today?",
            isUser: false
        ))
        
        MessageView(message: ChatMessage(
            text: "Can you help me understand this PDF?",
            isUser: true
        ))
    }
    .padding()
} 