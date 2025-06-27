//
//  AIMessage.swift
//  cerebral
//
//  Reusable AI Message Component
//

import SwiftUI

struct AIMessage: View {
    let message: ChatMessage
    let shouldGroup: Bool
    @State private var isHovered = false
    @State private var displayedText: String = ""
    @State private var showCursor = false
    
    // Performance optimization: use debounced text updates
    @State private var textUpdateTimer: Timer?
    
    var body: some View {
        HStack(alignment: .top, spacing: DesignSystem.Spacing.sm) {
            // AI message with streaming support
            HStack(alignment: .top, spacing: DesignSystem.Spacing.xs) {
                // Streaming text with waiting animation
                VStack(alignment: .leading, spacing: 0) {
                    if message.isStreaming && displayedText.isEmpty {
                        StreamingWaitingAnimation()
                    } else {
                        messageText
                    }
                }
                .onAppear {
                    displayedText = message.text
                    if message.isStreaming {
                        showCursor = true
                    }
                }
                .onChange(of: message.text) { _, newText in
                    // Debounce rapid text updates during streaming
                    textUpdateTimer?.invalidate()
                    
                    if message.isStreaming {
                        // Update immediately for responsive feel but debounce rapid changes
                        displayedText = newText
                        
                        textUpdateTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: false) { _ in
                            displayedText = newText
                        }
                    } else {
                        // Non-streaming updates immediately
                        displayedText = newText
                    }
                }
                .onChange(of: message.isStreaming) { _, isStreaming in
                    showCursor = isStreaming
                    
                    if !isStreaming {
                        // Final update when streaming completes
                        textUpdateTimer?.invalidate()
                        displayedText = message.text
                    }
                }
                .onDisappear {
                    // Cleanup timer
                    textUpdateTimer?.invalidate()
                }
                
                Spacer()
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.vertical, DesignSystem.Spacing.sm)
            .onHover { isHovered = $0 }
            .contextMenu {
                MessageContextMenu(message: message)
                
                Divider()
                
                Button("Regenerate Response") {
                    // TODO: Implement regenerate functionality
                }
            }
            
            Spacer(minLength: DesignSystem.Spacing.xxl)
        }
        .padding(.vertical, shouldGroup ? DesignSystem.Spacing.xxxs : DesignSystem.Spacing.xs)
        .trackPerformance("ai_message_\(message.id)")
    }
    
    @ViewBuilder
    private var messageText: some View {
        Text(LocalizedStringKey(displayedText))
            .font(DesignSystem.Typography.body)
            .foregroundColor(DesignSystem.Colors.primaryText)
            .textSelection(.enabled)
            .animation(.none, value: displayedText) // Disable animation for performance
            .tint(DesignSystem.Colors.accent)
    }
}

struct StreamingWaitingAnimation: View {
    @State private var showCursor = false
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(DesignSystem.Colors.secondaryText)
                    .frame(width: 6, height: 6)
                    .scaleEffect(showCursor ? 1.0 : 0.6)
                    .animation(
                        .easeInOut(duration: 0.6)
                        .repeatForever(autoreverses: true)
                        .delay(Double(index) * 0.2),
                        value: showCursor
                    )
            }
        }
        .padding(.vertical, 5)
        .onAppear {
            showCursor = true
        }
        .trackPerformance("streaming_animation")
    }
}

#Preview {
    VStack(spacing: 16) {
        AIMessage(
            message: ChatMessage(
                text: "Hello, how can I help you with your documents today? I can analyze PDFs, answer questions about their content, and help you understand complex information.",
                isUser: false
            ),
            shouldGroup: false
        )
        
        AIMessage(
            message: ChatMessage(
                text: "This is a streaming message that's being typed...",
                isUser: false,
                isStreaming: true
            ),
            shouldGroup: false
        )
        
        AIMessage(
            message: ChatMessage(
                text: "Follow-up message from AI.",
                isUser: false
            ),
            shouldGroup: true
        )
    }
    .frame(width: 400)
    .padding()
} 