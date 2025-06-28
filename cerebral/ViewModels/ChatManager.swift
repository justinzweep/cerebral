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
    private var currentContextBundle = ChatContextBundle(sessionId: UUID(), contexts: [])
    
    // MARK: - Services
    private var _streamingService: StreamingChatService?
    private var streamingService: StreamingChatService {
        if _streamingService == nil {
            _streamingService = StreamingChatService(delegate: self)
        }
        return _streamingService!
    }
    private let enhancedMessageBuilder = EnhancedMessageBuilder.shared
    private let contextService = ContextManagementService.shared
    // Legacy MessageBuilder is now part of EnhancedMessageBuilder
    private let documentResolver = DocumentReferenceResolver.shared
    
    // MARK: - Public Interface
    
    /// Send a message using streaming with new context system
    func sendMessage(
        _ text: String,
        settingsManager: SettingsManager,
        documentContext: [Document] = [],
        hiddenContext: String? = nil,
        explicitContexts: [DocumentContext] = []
    ) async {
        // Validate API key
        guard settingsManager.isAPIKeyValid else {
            let errorMessage = ChatMessage(
                text: "Please configure your Claude API key in Settings to use the chat feature.",
                isUser: false,
                contexts: []
            )
            messages.append(errorMessage)
            return
        }
        
        do {
            // Add explicit contexts to bundle
            currentContextBundle.contexts.append(contentsOf: explicitContexts)
            
            // Convert legacy document context to new format if needed
            if !documentContext.isEmpty || hiddenContext != nil {
                for doc in documentContext {
                    if let context = try? await contextService.createContext(
                        from: doc,
                        type: .fullDocument,
                        selection: nil
                    ) {
                        currentContextBundle.addContext(context)
                    }
                }
            }
            
            // Build message with new context system
            let (processedText, contexts) = try await enhancedMessageBuilder.buildMessage(
                userInput: text,
                contextBundle: currentContextBundle,
                sessionId: currentContextBundle.sessionId
            )
            
            // Create user message with contexts
            let userMessage = ChatMessage(
                text: text,  // Store original text for display
                isUser: true,
                hiddenContext: hiddenContext, contexts: contexts // Keep for backward compatibility
            )
            messages.append(userMessage)
            
            // Format for LLM
            let llmMessage = enhancedMessageBuilder.formatForLLM(
                text: processedText,
                contexts: contexts
            )
            
            // Send to streaming service
            await streamingService.sendStreamingMessage(
                llmMessage,
                settingsManager: settingsManager,
                documentContext: documentContext,
                hiddenContext: nil, // Already included in contexts
                conversationHistory: filterValidMessages(Array(messages.dropLast(2))),
                contexts: contexts
            )
            
        } catch {
            // Handle error
            let errorMessage = ChatMessage(
                text: "Failed to process message: \(error.localizedDescription)",
                isUser: false,
                contexts: []
            )
            messages.append(errorMessage)
            lastError = error.localizedDescription
        }
    }
    
    // Legacy support - redirect to new method
    func sendMessageLegacy(
        _ text: String,
        settingsManager: SettingsManager,
        documentContext: [Document] = [],
        hiddenContext: String? = nil
    ) async {
        await sendMessage(
            text,
            settingsManager: settingsManager,
            documentContext: documentContext,
            hiddenContext: hiddenContext,
            explicitContexts: []
        )
    }
    
    // MARK: - Context Management
    
    func addContext(_ context: DocumentContext) {
        currentContextBundle.addContext(context)
    }
    
    func removeContext(_ context: DocumentContext) {
        currentContextBundle.removeContext(context)
    }
    
    func clearContext() {
        currentContextBundle.clearContexts()
    }
    
    func getActiveContexts() -> [DocumentContext] {
        currentContextBundle.contexts
    }
    
    func getContextTokenCount() -> Int {
        currentContextBundle.tokenCount()
    }
    
    // MARK: - Session Management
    
    func startNewSession(title: String = "Chat") {
        Task { @MainActor in
            streamingService.cancelCurrentStreaming()
        }
        
        messages.removeAll()
        currentDocumentContext.removeAll()
        currentContextBundle = ChatContextBundle(sessionId: UUID(), contexts: [])
        currentSessionTitle = title
        resetState()
    }
    
    func startNewConversation(with document: Document? = nil) {
        Task { @MainActor in
            streamingService.cancelCurrentStreaming()
        }
        
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
        Task { @MainActor in
            streamingService.cancelCurrentStreaming()
        }
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
    
    /// Filter out error messages from conversation history
    private func filterValidMessages(_ messages: [ChatMessage]) -> [ChatMessage] {
        return messages.filter { message in
            // Filter out error messages from conversation history
            !message.text.contains("Sorry, I encountered an error") &&
            !message.text.contains("Please configure your Claude API key") &&
            !message.text.contains("Connection failed") &&
            !message.text.contains("Request failed") &&
            !message.text.contains("Failed to process message")
        }
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
