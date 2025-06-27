//
//  MessageView.swift
//  cerebral
//
//  Created by Justin Zweep on 26/06/2025.
//

import SwiftUI

struct MessageView: View {
    let message: ChatMessage
    let shouldGroup: Bool
    @State private var isHovered = false
    
    init(message: ChatMessage, shouldGroup: Bool = false) {
        self.message = message
        self.shouldGroup = shouldGroup
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: DesignSystem.Spacing.sm) {
            if message.isUser {
                Spacer(minLength: DesignSystem.Spacing.xxl)
                
                VStack(alignment: .trailing, spacing: shouldGroup ? DesignSystem.Spacing.xxxs : DesignSystem.Spacing.xs) {
                    // Message bubble
                    HStack {
                        Text(message.text)
                            .font(DesignSystem.Typography.body)
                            .foregroundColor(.white)
                            .padding(.horizontal, DesignSystem.Spacing.md)
                            .padding(.vertical, DesignSystem.Spacing.sm)
                            .background(
                                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                                    .fill(DesignSystem.Colors.accent)
                                    .shadow(
                                        color: DesignSystem.Colors.accent.opacity(0.3),
                                        radius: 4,
                                        x: 0,
                                        y: 2
                                    )
                            )
                            .animation(DesignSystem.Animation.microInteraction, value: isHovered)
                    }
                    
                    // Timestamp and status
                    if !shouldGroup {
                        HStack(spacing: DesignSystem.Spacing.xs) {
                            Text(message.timestamp, style: .time)
                                .font(DesignSystem.Typography.caption2)
                                .foregroundColor(DesignSystem.Colors.textTertiary)
                            
                            // Status indicator (delivered/read)
                            Image(systemName: "checkmark")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(DesignSystem.Colors.accent.opacity(0.6))
                        }
                        .opacity(isHovered ? 1.0 : 0.7)
                        .animation(DesignSystem.Animation.microInteraction, value: isHovered)
                    }
                }
                
                // User Avatar (only show if not grouped)
                if !shouldGroup {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [DesignSystem.Colors.accent, DesignSystem.Colors.accentSecondary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 32, height: 32)
                        .overlay {
                            Image(systemName: "person.fill")
                                .foregroundColor(.white)
                                .font(.system(size: 14, weight: .medium))
                        }
                        .shadow(
                            color: DesignSystem.Shadows.light,
                            radius: 2,
                            y: 1
                        )
                        .accessibilityLabel("User message")
                } else {
                    // Spacer to maintain alignment when grouped
                    Rectangle()
                        .fill(Color.clear)
                        .frame(width: 32, height: 32)
                }
            } else {
                // AI Avatar (only show if not grouped)
                if !shouldGroup {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    DesignSystem.Colors.accentTertiary,
                                    DesignSystem.Colors.accentSecondary
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 32, height: 32)
                        .overlay {
                            Image(systemName: "brain.head.profile")
                                .foregroundColor(.white)
                                .font(.system(size: 14, weight: .medium))
                        }
                        .shadow(
                            color: DesignSystem.Shadows.light,
                            radius: 2,
                            y: 1
                        )
                        .accessibilityLabel("AI Assistant message")
                } else {
                    // Spacer to maintain alignment when grouped
                    Rectangle()
                        .fill(Color.clear)
                        .frame(width: 32, height: 32)
                }
                
                VStack(alignment: .leading, spacing: shouldGroup ? DesignSystem.Spacing.xxxs : DesignSystem.Spacing.xs) {
                    // Message bubble
                    HStack {
                        Text(message.text)
                            .font(DesignSystem.Typography.body)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                            .padding(.horizontal, DesignSystem.Spacing.md)
                            .padding(.vertical, DesignSystem.Spacing.sm)
                            .textSelection(.enabled)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                            .fill(Material.thin)
                            .shadow(
                                color: DesignSystem.Shadows.subtle,
                                radius: isHovered ? 3 : 1,
                                x: 0,
                                y: isHovered ? 2 : 0.5
                            )
                    )
                    .animation(DesignSystem.Animation.microInteraction, value: isHovered)
                    
                    // Timestamp and document references
                    if !shouldGroup {
                        HStack(spacing: DesignSystem.Spacing.xs) {
                            Text(message.timestamp, style: .time)
                                .font(DesignSystem.Typography.caption2)
                                .foregroundColor(DesignSystem.Colors.textTertiary)
                            
                            if !message.documentReferences.isEmpty {
                                HStack(spacing: DesignSystem.Spacing.xxxs) {
                                    Image(systemName: "doc.text")
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundColor(DesignSystem.Colors.accent)
                                    
                                    Text("\(message.documentReferences.count)")
                                        .font(DesignSystem.Typography.caption2)
                                        .foregroundColor(DesignSystem.Colors.accent)
                                }
                                .padding(.horizontal, DesignSystem.Spacing.xs)
                                .padding(.vertical, DesignSystem.Spacing.xxxs)
                                .background(
                                    Capsule()
                                        .fill(DesignSystem.Colors.accent.opacity(0.1))
                                )
                            }
                        }
                        .opacity(isHovered ? 1.0 : 0.7)
                        .animation(DesignSystem.Animation.microInteraction, value: isHovered)
                    }
                }
                
                Spacer(minLength: DesignSystem.Spacing.xxl)
            }
        }
        .padding(.vertical, shouldGroup ? DesignSystem.Spacing.xxxs : DesignSystem.Spacing.xs)
        .onHover { isHovered = $0 }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(message.isUser ? "You" : "AI Assistant") said: \(message.text)")
        .accessibilityHint("Message sent at \(message.timestamp, style: .time)")
        .contextMenu {
            Button("Copy Message") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(message.text, forType: .string)
            }
            .accessibleButton(label: "Copy message text", hint: "Copies the message text to clipboard")
            
            if !message.isUser {
                Divider()
                
                Button("Regenerate Response") {
                    // TODO: Implement regenerate functionality
                }
                .accessibleButton(label: "Regenerate AI response", hint: "Asks the AI to provide a new response")
            }
        }
    }
}

#Preview {
    VStack(spacing: DesignSystem.Spacing.md) {
        MessageView(message: ChatMessage(
            text: "Hello, how can I help you with your documents today? I can analyze PDFs, answer questions about their content, and help you understand complex information.",
            isUser: false
        ))
        
        MessageView(message: ChatMessage(
            text: "Can you help me understand this PDF?",
            isUser: true
        ))
        
        // Grouped messages example
        MessageView(message: ChatMessage(
            text: "Sure! I can definitely help you with that.",
            isUser: false
        ), shouldGroup: false)
        
        MessageView(message: ChatMessage(
            text: "What specific aspects would you like me to explain?",
            isUser: false
        ), shouldGroup: true)
    }
    .padding()
    .frame(width: 400)
} 