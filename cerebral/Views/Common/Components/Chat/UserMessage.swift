//
//  UserMessage.swift
//  cerebral
//
//  Reusable User Message Component
//

import SwiftUI

struct UserMessage: View {
    let message: ChatMessage
    let shouldGroup: Bool
    @State private var isHovered = false
    
    var body: some View {
        VStack(alignment: .trailing, spacing: DesignSystem.Spacing.xs) {
            HStack(alignment: .top, spacing: DesignSystem.Spacing.sm) {
                Spacer(minLength: DesignSystem.Spacing.xxl)
                
                // User message with inline clickable @mentions
                FlowMessageText(text: message.text, documentReferences: message.documentReferences)
                    .padding(.horizontal, DesignSystem.Spacing.md)
                    .padding(.vertical, DesignSystem.Spacing.sm)
                    .animation(DesignSystem.Animation.microInteraction, value: isHovered)
                    .onHover { isHovered = $0 }
                    .contextMenu {
                        MessageContextMenu(message: message)
                    }
            }
            
            // Context indicator
            if message.hasContext {
                HStack {
                    Spacer(minLength: DesignSystem.Spacing.xxl)
                    MessageContextIndicator(contexts: message.contexts)
                        .frame(maxWidth: 300)
                }
            }
        }
        .padding(.vertical, shouldGroup ? DesignSystem.Spacing.xxxs : DesignSystem.Spacing.xs)
    }
}

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
    }
    .frame(width: 400)
    .padding()
} 