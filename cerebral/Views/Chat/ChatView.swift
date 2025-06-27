//
//  ChatView.swift
//  cerebral
//
//  Created by Justin Zweep on 26/06/2025.
//

import SwiftUI

struct ChatView: View {
    let chatManager = ChatManager()
    @StateObject private var settingsManager = SettingsManager()
    @State private var inputText = ""
    @State private var attachedDocuments: [Document] = []
    @State private var showingNewSessionAlert = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Chat Header with session info and actions
            ChatHeaderView(
                sessionTitle: chatManager.currentSessionTitle,
                hasMessages: !chatManager.messages.isEmpty,
                onNewSession: {
                    showingNewSessionAlert = true
                },
                onExportMessages: {
                    exportMessages()
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
                                    .accessibilityElement(children: .combine)
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
                
                // Input divider
                Rectangle()
                    .fill(DesignSystem.Colors.border.opacity(0.3))
                    .frame(height: 1)
                
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
        .alert("Start New Chat Session", isPresented: $showingNewSessionAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Start New Session") {
                startNewSession()
            }
        } message: {
            Text("This will clear the current conversation. Are you sure you want to continue?")
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
        inputText = ""
        
        Task {
            await chatManager.sendMessage(
                messageText,
                settingsManager: settingsManager,
                documentContext: attachedDocuments
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
    
    private func exportMessages() {
        let exportText = chatManager.exportMessages()
        
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.plainText]
        savePanel.nameFieldStringValue = "Chat Export - \(Date().formatted(date: .abbreviated, time: .shortened)).txt"
        
        if savePanel.runModal() == .OK {
            if let url = savePanel.url {
                do {
                    try exportText.write(to: url, atomically: true, encoding: .utf8)
                } catch {
                    print("Failed to export messages: \(error)")
                }
            }
        }
    }
}

// MARK: - Chat Header

struct ChatHeaderView: View {
    let sessionTitle: String
    let hasMessages: Bool
    let onNewSession: () -> Void
    let onExportMessages: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxxs) {
                Text(sessionTitle)
                    .font(DesignSystem.Typography.headline)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .lineLimit(1)
                
                if hasMessages {
                    Text("Conversation active")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
            }
            
            Spacer()
            
            HStack(spacing: DesignSystem.Spacing.xs) {
                // Export button
                if hasMessages {
                    Button(action: onExportMessages) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .buttonStyle(.borderless)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .accessibleButton(
                        label: "Export conversation",
                        hint: "Exports the current conversation to a text file"
                    )
                }
                
                // New session button
                Button(action: onNewSession) {
                    Image(systemName: "plus.square")
                        .font(.system(size: 14, weight: .medium))
                }
                .buttonStyle(.borderless)
                .foregroundColor(DesignSystem.Colors.textSecondary)
                .accessibleButton(
                    label: "New chat session",
                    hint: "Starts a new clean chat session"
                )
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.md)
        .padding(.vertical, DesignSystem.Spacing.sm)
        .background(Material.thin)
        .overlay(
            Rectangle()
                .fill(DesignSystem.Colors.border.opacity(0.3))
                .frame(height: 1),
            alignment: .bottom
        )
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
            // Icon
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 42))
                .foregroundColor(DesignSystem.Colors.accent.opacity(0.6))
                .accessibilityHidden(true)
            
            // Title & Description
            VStack(spacing: DesignSystem.Spacing.sm) {
                Text("Start a conversation")
                    .font(DesignSystem.Typography.title3)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .accessibleHeading(level: .h3)
                
                Text(hasAttachedDocuments ? 
                     "Ask me questions about your attached documents or anything else you'd like to know." :
                     "Ask me anything about your documents or any topic you'd like to discuss.")
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            // Suggestions
            if hasAttachedDocuments {
                VStack(spacing: DesignSystem.Spacing.xs) {
                    Text("Try asking:")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.textTertiary)
                    
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                        Text("• \"Summarize these documents\"")
                        Text("• \"What are the main points?\"")
                        Text("• \"Compare the key concepts\"")
                    }
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                .padding(.top, DesignSystem.Spacing.sm)
            }
        }
        .frame(maxWidth: 320)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Chat is empty. \(hasAttachedDocuments ? "Ask me questions about your attached documents or anything else you'd like to know." : "Ask me anything about your documents or any topic you'd like to discuss.")")
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
                .accessibilityHidden(true)
            
            VStack(spacing: DesignSystem.Spacing.sm) {
                // Title
                Text("API Key Required")
                    .font(DesignSystem.Typography.title3)
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
        .frame(maxWidth: 280)
        .padding(DesignSystem.Spacing.xl)
        .frame(maxHeight: .infinity)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Accessibility Extensions

// accessibleHeading is already defined in DesignSystem.swift

#Preview {
    ChatView()
        .frame(width: 400, height: 600)
}
