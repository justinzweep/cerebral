//
//  MessageActions.swift
//  cerebral
//
//  Reusable Message Actions Component
//

import SwiftUI

struct MessageContextMenu: View {
    let message: ChatMessage
    
    var body: some View {
        Button("Copy Message") {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(message.text, forType: .string)
        }
        
        if !message.isUser {
            Button("Copy Response") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(message.text, forType: .string)
            }
        }
    }
}

struct MessageToolbar: View {
    let message: ChatMessage
    let onCopy: () -> Void
    let onRegenerate: (() -> Void)?
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 4) {
            IconButton(
                icon: "doc.on.doc",
                style: .tertiary,
                size: .small
            ) {
                onCopy()
            }
            
            if let onRegenerate = onRegenerate, !message.isUser {
                IconButton(
                    icon: "arrow.clockwise",
                    style: .tertiary,
                    size: .small
                ) {
                    onRegenerate()
                }
            }
        }
        .opacity(isHovered ? 1.0 : 0.0)
        .animation(DesignSystem.Animation.quick, value: isHovered)
        .onHover { isHovered = $0 }
    }
}

#Preview {
    VStack(spacing: 20) {
        MessageToolbar(
            message: ChatMessage(text: "Sample message", isUser: false),
            onCopy: { print("Copy") },
            onRegenerate: { print("Regenerate") }
        )
        
        MessageToolbar(
            message: ChatMessage(text: "User message", isUser: true),
            onCopy: { print("Copy") },
            onRegenerate: nil
        )
    }
    .padding()
} 