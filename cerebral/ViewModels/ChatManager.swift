//
//  ChatManager.swift
//  cerebral
//
//  Created by Justin Zweep on 26/06/2025.
//

import Foundation

@MainActor
@Observable final class ChatManager {
    // MARK: - Core State
    var messages: [ChatMessage] = []
    var isLoading: Bool = false
    var lastError: String?
    var hasConnectionError: Bool = false
    var currentSessionTitle: String = "Chat"
    
    // MARK: - Streaming State
    var isStreaming: Bool = false
    var currentStreamingMessageId: UUID?
    
    // MARK: - Document Context
    private var currentDocumentContext: [Document] = []
    
    // MARK: - Services
    private var _streamingService: StreamingChatService?
    private var streamingService: StreamingChatService {
        if _streamingService == nil {
            _streamingService = StreamingChatService(delegate: self)
        }
        return _streamingService!
    }
    private let messageBuilder = MessageBuilder.shared
    private let documentResolver = DocumentReferenceResolver.shared
    
    // MARK: - Public Interface
    
    /// Send a message using streaming (main method - non-streaming method removed)
    func sendMessage(
        _ text: String,
        settingsManager: SettingsManager,
        documentContext: [Document] = [],
        hiddenContext: String? = nil
    ) async {
        // Validate API key
        guard settingsManager.isAPIKeyValid else {
            let errorMessage = ChatMessage(
                text: "Please configure your Claude API key in Settings to use the chat feature.",
                isUser: false
            )
            messages.append(errorMessage)
            return
        }
        
        // Extract document references from @mentions
        let referencedDocuments = documentResolver.extractDocumentReferences(from: text)
        let allReferencedUUIDs = documentResolver.getDocumentUUIDs(from: referencedDocuments)
        
        // Create and store user message
        let userMessage = ChatMessage(
            text: text,
            isUser: true,
            documentReferences: allReferencedUUIDs,
            hiddenContext: hiddenContext
        )
        messages.append(userMessage)
        
        // Prepare document context
        let documentsToProcess = documentContext.isEmpty ? currentDocumentContext : documentContext
        let allDocumentsToProcess = documentResolver.combineUniqueDocuments(documentsToProcess, referencedDocuments)
        
        // Build enhanced message for LLM
        let enhancedMessage = messageBuilder.buildEnhancedMessage(
            userText: text,
            documents: allDocumentsToProcess,
            hiddenContext: hiddenContext
        )
        
        // Send streaming message
        await streamingService.sendStreamingMessage(
            enhancedMessage,
            settingsManager: settingsManager,
            documentContext: allDocumentsToProcess,
            hiddenContext: hiddenContext,
            conversationHistory: messageBuilder.filterValidMessages(Array(messages.dropLast(2)))
        )
    }
    
    // MARK: - Session Management
    
    func startNewSession(title: String = "Chat") {
        streamingService.cancelCurrentStreaming()
        
        messages.removeAll()
        currentDocumentContext.removeAll()
        currentSessionTitle = title
        resetState()
    }
    
    func startNewConversation(with document: Document? = nil) {
        streamingService.cancelCurrentStreaming()
        
        messages.removeAll()
        resetState()
        
        if let document = document {
            setDocumentContext([document])
            currentSessionTitle = "Chat with \(document.title)"
            
            let welcomeMessage = ChatMessage(
                text: "I'm ready to help you with '\(document.title)'. Feel free to ask me any questions about this document!",
                isUser: false,
                documentReferences: [document.id]
            )
            messages.append(welcomeMessage)
        } else {
            clearDocumentContext()
            currentSessionTitle = "Chat"
        }
    }
    
    func setDocumentContext(_ documents: [Document]) {
        currentDocumentContext = documents
        updateSessionTitle(for: documents)
    }
    
    func clearDocumentContext() {
        currentDocumentContext.removeAll()
        currentSessionTitle = "Chat"
    }
    
    func clearMessages() {
        streamingService.cancelCurrentStreaming()
        messages.removeAll()
        resetState()
    }
    
    // MARK: - Utility Methods
    
    func shouldGroupMessage(at index: Int) -> Bool {
        guard index > 0 && index < messages.count else { return false }
        
        let currentMessage = messages[index]
        let previousMessage = messages[index - 1]
        
        // Same sender and within 5 minutes
        guard currentMessage.isUser == previousMessage.isUser else { return false }
        let timeDifference = currentMessage.timestamp.timeIntervalSince(previousMessage.timestamp)
        return timeDifference < 300 // 5 minutes
    }
    
    func validateAPIConnection(settingsManager: SettingsManager) async -> Bool {
        guard settingsManager.isAPIKeyValid else {
            hasConnectionError = true
            return false
        }
        
        let isValid = await streamingService.validateAPIConnection(settingsManager: settingsManager)
        hasConnectionError = !isValid
        
        if !isValid {
            lastError = "Failed to connect to Claude API"
        }
        
        return isValid
    }
    
    // MARK: - Private Helpers
    
    private func resetState() {
        lastError = nil
        hasConnectionError = false
        isLoading = false
        isStreaming = false
        currentStreamingMessageId = nil
    }
    
    private func updateSessionTitle(for documents: [Document]) {
        switch documents.count {
        case 0:
            currentSessionTitle = "Chat"
        case 1:
            currentSessionTitle = "Chat with \(documents.first!.title)"
        default:
            currentSessionTitle = "Chat with \(documents.count) documents"
        }
    }
}

// MARK: - StreamingChatServiceDelegate

extension ChatManager: StreamingChatServiceDelegate {
    func streamingDidStart() {
        isLoading = true
        isStreaming = true
        lastError = nil
        hasConnectionError = false
    }
    
    func streamingDidCreateMessage(_ message: ChatMessage) {
        messages.append(message)
        currentStreamingMessageId = message.id
    }
    
    func streamingDidReceiveText(_ text: String, for messageId: UUID) {
        if let messageIndex = messages.firstIndex(where: { $0.id == messageId }) {
            messages[messageIndex].text = text
        }
    }
    
    func streamingDidComplete(with text: String, messageId: UUID, documentReferences: [UUID]) {
        if let messageIndex = messages.firstIndex(where: { $0.id == messageId }) {
            messages[messageIndex].text = text
            messages[messageIndex].completeStreaming()
            messages[messageIndex].documentReferences = documentReferences
        }
        
        isStreaming = false
        currentStreamingMessageId = nil
        isLoading = false
    }
    
    func streamingDidFail(with error: Error, messageId: UUID) {
        // Remove the failed streaming message
        if let messageIndex = messages.firstIndex(where: { $0.id == messageId }) {
            messages.remove(at: messageIndex)
        }
        
        // Add error message
        let errorMessage = ChatMessage(
            text: "Sorry, I encountered an error: \(error.localizedDescription)",
            isUser: false
        )
        messages.append(errorMessage)
        
        lastError = error.localizedDescription
        hasConnectionError = true
        isStreaming = false
        currentStreamingMessageId = nil
        isLoading = false
    }
} 