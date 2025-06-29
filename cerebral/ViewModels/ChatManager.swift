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
    private var currentSession = ChatSession(title: "Chat") // Add current session for context management
    
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
    
    /// Send a message using streaming with RAG (Retrieval-Augmented Generation) flow
    /// This ensures vector search completes BEFORE sending message to AI
    func sendMessage(
        _ text: String,
        settingsManager: SettingsManager,
        documentContext: [Document] = [],
        explicitContexts: [DocumentContext] = []
    ) async {
        // Validate API key
        guard !settingsManager.apiKey.isEmpty && settingsManager.validateAPIKey(settingsManager.apiKey) else {
            let errorMessage = ChatMessage(
                text: "Please configure your Claude API key in Settings to use the chat feature.",
                isUser: false,
                contexts: []
            )
            messages.append(errorMessage)
            return
        }
        
        // Start loading state immediately
        isLoading = true
        isStreaming = false
        
        do {
            print("🔄 RAG Flow: Starting message processing...")
            
            // CLEAR context bundle at the start of each message for fresh context
            currentContextBundle = ChatContextBundle(sessionId: UUID(), contexts: [])
            print("🧹 RAG Flow: Cleared context bundle for new message")
            
            // Step 1: Set active document ID if we have a currently selected/open document
            if let activeDocument = ServiceContainer.shared.appState.selectedDocument {
                currentContextBundle.activeDocumentId = activeDocument.id
                print("📄 RAG Flow: Set active document: \(activeDocument.title)")
            }
            
            // Step 2: Add explicit contexts (manual text selections) to bundle
            if !explicitContexts.isEmpty {
                currentContextBundle.contexts.append(contentsOf: explicitContexts)
                print("📝 RAG Flow: Added \(explicitContexts.count) explicit contexts (text selections)")
            }
            
            // Step 3: Process appended document context (from @ or sidebar) - add to session for vector search
            if !documentContext.isEmpty {
                print("📄 RAG Flow: Processing \(documentContext.count) appended documents for vector search")
                
                for doc in documentContext {
                    do {
                        try await contextService.addDocumentToContext(doc, for: currentSession)
                        print("✅ RAG Flow: Added appended document to vector search: \(doc.title)")
                    } catch {
                        print("❌ RAG Flow: Failed to add appended document to vector search: \(error)")
                        throw error // Fail fast if we can't add documents
                    }
                }
            }
            
            // Step 4: If we have an active document, also add it to session for vector search
            if let activeDocId = currentContextBundle.activeDocumentId,
               let activeDoc = ServiceContainer.shared.documentService.findDocument(byId: activeDocId) {
                do {
                    try await contextService.addDocumentToContext(activeDoc, for: currentSession)
                    print("✅ RAG Flow: Added active document to vector search: \(activeDoc.title)")
                } catch {
                    print("❌ RAG Flow: Failed to add active document to vector search: \(error)")
                    throw error // Fail fast if we can't add active document
                }
            }
            
            // Step 5: CRITICAL RAG STEP - Build message with vector search and WAIT for completion
            print("🔍 RAG Flow: Starting vector search and context building...")
            let (processedText, contexts, chunks) = try await enhancedMessageBuilder.buildMessage(
                userInput: text,
                contextBundle: currentContextBundle,
                sessionId: currentContextBundle.sessionId
            )
            
            // Step 6: Verify we have retrieved context before proceeding
            let hasVectorContext = !chunks.isEmpty
            let hasManualContext = !contexts.isEmpty
            
            if !hasVectorContext && !hasManualContext {
                print("⚠️ RAG Flow: No context retrieved - proceeding with user query only")
            } else {
                print("✅ RAG Flow: Successfully retrieved context - \(chunks.count) chunks, \(contexts.count) manual selections")
            }
            
            // Step 7: Create RAG-enhanced message for LLM (this includes retrieved context + user query)
            let ragEnhancedMessage = enhancedMessageBuilder.formatForLLM(
                text: processedText,
                contexts: contexts,
                chunks: chunks
            )
            
            print("📤 RAG Flow: Message ready to send (\(ragEnhancedMessage.count) characters)")
            
            // Step 8: Create user message for display (original text only)
            let userMessage = ChatMessage(
                text: text,  // Store original text for display
                isUser: true,
                contexts: [], // No contexts shown in user messages
                chunks: []    // No chunks shown in user messages
            )
            messages.append(userMessage)
            
            print("📝 RAG Flow: Created user message (no chunks shown for user messages)")
            
            // Step 9: Send RAG-enhanced message to AI (only after successful retrieval)
            print("🚀 RAG Flow: Sending enhanced message to AI...")
            await streamingService.sendStreamingMessage(
                ragEnhancedMessage, // This contains user query + retrieved context
                settingsManager: settingsManager,
                documentContext: documentContext,
                conversationHistory: filterValidMessages(Array(messages.dropLast(2))),
                contexts: contexts,
                chunks: chunks
            )
            
        } catch {
            // Handle RAG pipeline errors
            isLoading = false
            isStreaming = false
            
            let errorMessage = ChatMessage(
                text: "RAG Pipeline Error: Failed to retrieve document context - \(error.localizedDescription)",
                isUser: false,
                contexts: []
            )
            messages.append(errorMessage)
            lastError = error.localizedDescription
            print("❌ RAG Flow: Pipeline failed with error: \(error)")
        }
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
        currentSession = ChatSession(title: title) // Create new session
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
            currentSession = ChatSession(title: currentSessionTitle) // Create new session
            
            let welcomeMessage = ChatMessage(
                text: "I'm ready to help you with '\(document.title)'. Feel free to ask me any questions about this document!",
                isUser: false,
                contexts: []
            )
            messages.append(welcomeMessage)
        } else {
            clearDocumentContext()
            currentSessionTitle = "Chat"
            currentSession = ChatSession(title: "Chat") // Create new session
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
    
    func streamingDidComplete(with text: String, messageId: UUID) {
        if let messageIndex = messages.firstIndex(where: { $0.id == messageId }) {
            messages[messageIndex].text = text
            messages[messageIndex].completeStreaming()
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


