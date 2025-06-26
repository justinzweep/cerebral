//
//  ChatInputView.swift
//  cerebral
//
//  Created by Justin Zweep on 26/06/2025.
//

import SwiftUI

struct ChatInputView: View {
    @Binding var text: String
    let isLoading: Bool
    let onSend: () -> Void
    
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .bottom, spacing: DesignSystem.Spacing.sm) {
                // Text Input
                TextField("Ask anything...", text: $text, axis: .vertical)
                    .textFieldStyle(CerebralTextFieldStyle())
                    .focused($isTextFieldFocused)
                    .lineLimit(1...6)
                    .font(DesignSystem.Typography.body)
                    .onSubmit {
                        if canSend && !isLoading {
                            onSend()
                        }
                    }
                    .disabled(isLoading)
                    .accessibilityLabel("Message input")
                    .accessibilityHint("Type your message here and press Enter or click send")
                
                // Send Button
                Button(action: onSend) {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                            .frame(width: 20, height: 20)
                            .accessibilityLabel("Sending message")
                    } else {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                            .foregroundColor(canSend ? DesignSystem.Colors.accent : DesignSystem.Colors.textTertiary)
                    }
                }
                .buttonStyle(.borderless)
                .minimumTouchTarget()
                .disabled(!canSend || isLoading)
                .accessibleButton(
                    label: canSend ? "Send message" : "Cannot send empty message",
                    hint: canSend ? "Sends your message to the AI assistant" : "Type a message to enable sending"
                )
                .keyboardShortcut(.return, modifiers: [])
            }
            .padding(DesignSystem.Spacing.md)
            .background(DesignSystem.Colors.surfaceSecondary)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isTextFieldFocused = true
            }
        }
    }
    
    private var canSend: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

#Preview {
    VStack {
        Spacer()
        
        ChatInputView(
            text: .constant(""),
            isLoading: false
        ) {
            print("Send message")
        }
    }
    .frame(width: 300, height: 200)
} 