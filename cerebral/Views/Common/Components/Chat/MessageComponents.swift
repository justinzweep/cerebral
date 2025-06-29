//
//  MessageComponents.swift
//  cerebral
//
//  Consolidated Message Components
//

import SwiftUI

// MARK: - User Message

struct UserMessage: View {
    let message: ChatMessage
    let shouldGroup: Bool
    @State private var isHovered = false
    
    var body: some View {
        VStack(alignment: .trailing, spacing: DesignSystem.Spacing.xs) {
            HStack(alignment: .top, spacing: DesignSystem.Spacing.sm) {
                Spacer(minLength: DesignSystem.Spacing.lg)
                
                // User message with inline clickable @mentions
                HighlightedMessageText(
                    text: message.text, 
                    contexts: message.contexts
                )
                    .padding(.horizontal, DesignSystem.Spacing.md)
                    .padding(.vertical, DesignSystem.Spacing.sm)
                    .animation(DesignSystem.Animation.microInteraction, value: isHovered)
                    .onHover { isHovered = $0 }
                    .contextMenu {
                        MessageContextMenu(message: message)
                    }
            }
            
            // No context indicator for user messages anymore
        }
        .padding(.vertical, shouldGroup ? DesignSystem.Spacing.xxxs : DesignSystem.Spacing.xs)
    }
}

// MARK: - AI Message

struct AIMessage: View {
    let message: ChatMessage
    let shouldGroup: Bool
    @State private var isHovered = false
    @State private var displayedText: String = ""
    @State private var showCursor = false
    
    // Performance optimization: use debounced text updates
    @State private var textUpdateTimer: Timer?
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            HStack(alignment: .top, spacing: DesignSystem.Spacing.xs) {
                // AI message with streaming support
                HStack(alignment: .top, spacing: DesignSystem.Spacing.xs) {
                    // Streaming text with waiting animation
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
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
                    
    
                }
                
                Spacer(minLength: DesignSystem.Spacing.lg)
            }
            
            // Unified context indicator for AI messages (shows both text selections and chunks)
            // Only show context indicators when streaming is complete
            if !message.isStreaming && (message.hasContext || message.hasChunks) {
                UnifiedContextIndicator(
                    contexts: message.contexts,
                    chunkIds: message.chunkIds
                )
            }
        }
        .padding(.vertical, shouldGroup ? DesignSystem.Spacing.xxxs : DesignSystem.Spacing.xxxs)
    }
    
    @ViewBuilder
    private var messageText: some View {
        // Use HighlightedMessageText for clickable document references in AI messages
        HighlightedMessageText(
            text: displayedText, 
            contexts: message.contexts
        )
        .animation(.none, value: displayedText) // Disable animation for performance
    }
}

// MARK: - Streaming Waiting Animation

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
    }
}

// MARK: - Previews

#Preview {
    VStack(spacing: 16) {
        UserMessage(
            message: ChatMessage(
                text: "Can you help me understand @document.pdf and also reference @research_paper.pdf?",
                isUser: true
            ),
            shouldGroup: false
        )
        
        UserMessage(
            message: ChatMessage(
                text: "Follow-up question about the same topic.",
                isUser: true
            ),
            shouldGroup: true
        )
        
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
    .frame(width: 480)
    .padding()
} 
