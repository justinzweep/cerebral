//
//  ChatView.swift
//  cerebral
//
//  Created by Justin Zweep on 26/06/2025.
//

import SwiftUI

struct ChatView: View {
    @StateObject private var chatManager = ChatManager()
    @EnvironmentObject var settingsManager: SettingsManager
    @State private var inputText = ""
    @State private var selectedDocument: Document?
    
    var body: some View {
        VStack(spacing: 0) {
            // Chat Header
            HStack(spacing: DesignSystem.Spacing.md) {
                Text("AI Assistant")
                    .font(DesignSystem.Typography.headline)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .accessibleHeading(level: .h2)
                
                Spacer()
                
                if selectedDocument != nil {
                    Button {
                        withAnimation(DesignSystem.Animation.smooth) {
                            selectedDocument = nil
                            chatManager.clearDocumentContext()
                        }
                    } label: {
                        Image(systemName: "doc.badge.minus")
                            .foregroundColor(DesignSystem.Colors.accent)
                    }
                    .buttonStyle(.borderless)
                    .minimumTouchTarget()
                    .accessibleButton(
                        label: "Clear document context",
                        hint: "Remove the current document from the chat context"
                    )
                }
            }
            .padding(DesignSystem.Spacing.md)
            .background(DesignSystem.Colors.surfacePrimary)
            
            // Document Context Banner
            if let document = selectedDocument {
                HStack(spacing: DesignSystem.Spacing.xs) {
                    Image(systemName: "doc.fill")
                        .foregroundColor(DesignSystem.Colors.accent)
                        .font(.caption)
                    
                    Text("Discussing: \(document.title)")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Button {
                        withAnimation(DesignSystem.Animation.smooth) {
                            selectedDocument = nil
                            chatManager.clearDocumentContext()
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                            .font(.caption)
                    }
                    .buttonStyle(.borderless)
                    .minimumTouchTarget()
                    .accessibleButton(
                        label: "Remove document from context",
                        hint: "Stop discussing this document"
                    )
                }
                .padding(.horizontal, DesignSystem.Spacing.md)
                .padding(.vertical, DesignSystem.Spacing.xs)
                .background(DesignSystem.Colors.accent.opacity(0.1))
            }
            
            Divider()
            
            if settingsManager.isAPIKeyValid {
                // Chat Messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: DesignSystem.Spacing.md) {
                            if chatManager.messages.isEmpty {
                                EmptyStateView(selectedDocument: selectedDocument)
                                    .padding(.top, DesignSystem.Spacing.huge)
                            } else {
                                ForEach(chatManager.messages) { message in
                                    MessageView(message: message)
                                        .id(message.id)
                                        .accessibilityElement(children: .combine)
                                }
                            }
                        }
                        .padding(DesignSystem.Spacing.md)
                    }
                    .onChange(of: chatManager.messages.count) { _, _ in
                        if let lastMessage = chatManager.messages.last {
                            withAnimation {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }
                
                Divider()
                
                // Chat Input
                ChatInputView(
                    text: $inputText,
                    isLoading: chatManager.isLoading
                ) {
                    Task {
                        await chatManager.sendMessage(
                            inputText, 
                            settingsManager: settingsManager,
                            documentContext: selectedDocument != nil ? [selectedDocument!] : []
                        )
                        inputText = ""
                    }
                }
                .disabled(!settingsManager.isAPIKeyValid)
            } else {
                // API Key Required State
                APIKeyRequiredView()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .documentSelected)) { notification in
            if let document = notification.object as? Document {
                selectedDocument = document
                chatManager.startNewConversation(with: document)
            }
        }
        .onAppear {
            if settingsManager.isAPIKeyValid {
                Task {
                    _ = await chatManager.validateAPIConnection(settingsManager: settingsManager)
                }
            }
        }
    }
    

}

// Notification for document selection
extension Notification.Name {
    static let documentSelected = Notification.Name("documentSelected")
    static let importPDF = Notification.Name("importPDF")
    static let toggleChatPanel = Notification.Name("toggleChatPanel")
    static let focusSearch = Notification.Name("focusSearch")
}

// MARK: - Empty State Components

struct EmptyStateView: View {
    let selectedDocument: Document?
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            // Icon
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: DesignSystem.Spacing.huge))
                .foregroundColor(DesignSystem.Colors.accent)
                .accessibilityHidden(true)
            
            // Title
            Text("Start a conversation")
                .font(DesignSystem.Typography.title3)
                .foregroundColor(DesignSystem.Colors.textPrimary)
                .accessibleHeading(level: .h3)
            
            // Description
            Text(selectedDocument == nil ? 
                 "Ask me anything about your documents or any topic you'd like to discuss." :
                 "Ask me questions about '\(selectedDocument!.title)' or anything else you'd like to know.")
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
            
            // Suggestions
            if selectedDocument == nil {
                VStack(spacing: DesignSystem.Spacing.xs) {
                    Text("Try asking:")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.textTertiary)
                    
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                        Text("• \"Summarize this document\"")
                        Text("• \"What are the main points?\"")
                        Text("• \"Explain this concept\"")
                    }
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.top, DesignSystem.Spacing.sm)
            }
        }
        .frame(maxWidth: 300)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Chat is empty. \(selectedDocument == nil ? "Ask me anything about your documents or any topic you'd like to discuss." : "Ask me questions about \(selectedDocument!.title) or anything else you'd like to know.")")
    }
}

struct APIKeyRequiredView: View {
    @Environment(\.openSettings) private var openSettings
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            // Icon
            Image(systemName: "key.slash")
                .font(.system(size: DesignSystem.Spacing.huge))
                .foregroundColor(DesignSystem.Colors.warningOrange)
                .accessibilityHidden(true)
            
            VStack(spacing: DesignSystem.Spacing.sm) {
                // Title
                Text("Claude API Key Required")
                    .font(DesignSystem.Typography.title2)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .accessibleHeading(level: .h2)
                
                // Description
                Text("Configure your Claude API key in Settings to use AI chat functionality.")
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            VStack(spacing: DesignSystem.Spacing.xs) {
                Button("Open Settings") {
                    openSettings()
                }
                .buttonStyle(PrimaryButtonStyle())
                .accessibleButton(
                    label: "Open settings to configure API key",
                    hint: "Opens the settings window where you can add your Claude API key"
                )
                
                Text("Or press ⌘, to open settings")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.textTertiary)
            }
        }
        .frame(maxWidth: 400)
        .padding(DesignSystem.Spacing.xl)
        .frame(maxHeight: .infinity)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    ChatView()
        .environmentObject(SettingsManager())
        .frame(width: 300, height: 600)
} 
