//
//  ChatView.swift
//  cerebral
//
//  Created by Justin Zweep on 26/06/2025.
//

import SwiftUI

struct ChatView: View {
    let selectedDocument: Document?
    @State private var chatManager = ChatManager()
    @StateObject private var settingsManager = SettingsManager()
    @State private var inputText = ""
    @State private var attachedDocuments: [Document] = []
    
    init(selectedDocument: Document? = nil) {
        self.selectedDocument = selectedDocument
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Chat Header with session info and actions
            ChatHeaderView(
                hasMessages: !chatManager.messages.isEmpty,
                onNewSession: {
                    startNewSession()
                }
            )
            
            if settingsManager.isAPIKeyValid {
                // Chat Messages Area
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            if chatManager.messages.isEmpty {
                                EmptyStateView(hasAttachedDocuments: !attachedDocuments.isEmpty)
                                    .padding(.top, DesignSystem.Spacing.huge)
                            } else {
                                ForEach(Array(chatManager.messages.enumerated()), id: \.element.id) { index, message in
                                    let shouldGroup = chatManager.shouldGroupMessage(at: index)
                                    
                                    MessageView(
                                        message: message,
                                        shouldGroup: shouldGroup
                                    )
                                    .id(message.id)
                                    .padding(.horizontal, DesignSystem.Spacing.md)
                                    .padding(.vertical, shouldGroup ? DesignSystem.Spacing.xxxs : DesignSystem.Spacing.xs)
                                }
                            }
                        }
                        .padding(.bottom, DesignSystem.Spacing.md)
                    }
                    .onChange(of: chatManager.messages.count) { _, _ in
                        if let lastMessage = chatManager.messages.last {
                            withAnimation(.easeOut(duration: 0.3)) {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }
                
                
                // Enhanced Chat Input
                ChatInputView(
                    text: $inputText,
                    isLoading: chatManager.isLoading,
                    attachedDocuments: attachedDocuments,
                    onSend: {
                        sendMessage()
                    },
                    onRemoveDocument: { document in
                        withAnimation(DesignSystem.Animation.smooth) {
                            attachedDocuments.removeAll { $0.id == document.id }
                        }
                    }
                )
                .disabled(!settingsManager.isAPIKeyValid)
                
            } else {
                // API Key Required State
                APIKeyRequiredView()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .documentAddedToChat)) { notification in
            if let document = notification.object as? Document {
                withAnimation(DesignSystem.Animation.smooth) {
                    // Add to attached documents instead of replacing
                    if !attachedDocuments.contains(where: { $0.id == document.id }) {
                        attachedDocuments.append(document)
                    }
                }
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
    
    // MARK: - Private Methods
    
    private func sendMessage() {
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let messageText = inputText
        var documentsToSend = attachedDocuments
        
        // ALWAYS append the currently selected document if there is one
        if let selectedDoc = selectedDocument {
            // Only add if it's not already in the attached documents
            if !documentsToSend.contains(where: { $0.id == selectedDoc.id }) {
                documentsToSend.append(selectedDoc)
            }
        }
        
        // Clear input and attachments immediately
        inputText = ""
        withAnimation(DesignSystem.Animation.smooth) {
            attachedDocuments.removeAll()
        }
        
        Task {
            await chatManager.sendMessage(
                messageText,
                settingsManager: settingsManager,
                documentContext: documentsToSend
            )
        }
    }
    
    private func startNewSession() {
        withAnimation(DesignSystem.Animation.smooth) {
            chatManager.startNewSession()
            attachedDocuments.removeAll()
            inputText = ""
        }
    }
}

// MARK: - Chat Header

struct ChatHeaderView: View {
    let hasMessages: Bool
    let onNewSession: () -> Void
    
    var body: some View {
        HStack {
            if hasMessages {
                Text("Conversation active")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
            
            Spacer()
            
            HStack(spacing: DesignSystem.Spacing.xs) {
                // New session button
                Button(action: onNewSession) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 14, weight: .medium))
                }
                .buttonStyle(.borderless)
                .foregroundColor(DesignSystem.Colors.textSecondary)
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.md)
        .padding(.vertical, DesignSystem.Spacing.sm)
        // .background(Material.thin)
        // .overlay(
        //     Rectangle()
        //         .fill(DesignSystem.Colors.border.opacity(0.3))
        //         .frame(height: 1),
        //     alignment: .bottom
        // )
    }
}

// Notification for document selection
extension Notification.Name {
    static let documentSelected = Notification.Name("documentSelected")
    static let documentAddedToChat = Notification.Name("documentAddedToChat")
    static let importPDF = Notification.Name("importPDF")
    static let toggleChatPanel = Notification.Name("toggleChatPanel")
}

// MARK: - Empty State Components

struct EmptyStateView: View {
    let hasAttachedDocuments: Bool
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {                  
        }
        .frame(maxWidth: 320)
    }
}

struct APIKeyRequiredView: View {
    @Environment(\.openSettings) private var openSettings
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            // Icon
            Image(systemName: "key.slash")
                .font(.system(size: 42))
                .foregroundColor(DesignSystem.Colors.warningOrange)
            
            VStack(spacing: DesignSystem.Spacing.sm) {
                // Title
                Text("API Key Required")
                    .font(DesignSystem.Typography.title3)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
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

                
                Text("Or press ⌘, to open settings")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.textTertiary)
            }
        }
        .frame(maxWidth: 280)
        .padding(DesignSystem.Spacing.xl)
        .frame(maxHeight: .infinity)
    }
}

// accessibleHeading is already defined in DesignSystem.swift

#Preview {
    ChatView(selectedDocument: nil)
        .frame(width: 400, height: 600)
}
