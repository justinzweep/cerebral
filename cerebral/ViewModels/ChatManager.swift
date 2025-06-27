//
//  ChatManager.swift
//  cerebral
//
//  Created by Justin Zweep on 26/06/2025.
//

import Foundation

@MainActor
@Observable final class ChatManager {
    var messages: [ChatMessage] = []
    var isLoading: Bool = false
    var lastError: String?
    var hasConnectionError: Bool = false
    var currentSessionTitle: String = "New Chat"
    
    private var claudeAPIService: ClaudeAPIService?
    private var currentDocumentContext: [Document] = []
    
    func sendMessage(_ text: String, settingsManager: SettingsManager, documentContext: [Document] = []) async {
        let userMessage = ChatMessage(text: text, isUser: true)
        messages.append(userMessage)
        
        guard settingsManager.isAPIKeyValid else {
            let errorMessage = ChatMessage(
                text: "Please configure your Claude API key in Settings to use the chat feature.",
                isUser: false
            )
            messages.append(errorMessage)
            return
        }
        
        // Initialize API service if needed
        if claudeAPIService == nil {
            claudeAPIService = ClaudeAPIService(settingsManager: settingsManager)
        }
        
        isLoading = true
        lastError = nil
        hasConnectionError = false
        
        do {
            let response = try await claudeAPIService?.sendMessage(
                text,
                context: documentContext.isEmpty ? currentDocumentContext : documentContext,
                conversationHistory: filterValidMessages(Array(messages.dropLast())) // Exclude the just-added user message and error messages
            ) ?? "No response received"
            
            let aiMessage = ChatMessage(
                text: response,
                isUser: false,
                documentReferences: documentContext.isEmpty ? 
                    currentDocumentContext.map { $0.id } : 
                    documentContext.map { $0.id }
            )
            messages.append(aiMessage)
        } catch {
            let errorMessage = ChatMessage(
                text: "Sorry, I encountered an error: \(error.localizedDescription)",
                isUser: false
            )
            messages.append(errorMessage)
            lastError = error.localizedDescription
            hasConnectionError = true
        }
        
        isLoading = false
    }
    
    // MARK: - Session Management
    
    func startNewSession(title: String = "New Chat") {
        messages.removeAll()
        currentDocumentContext.removeAll()
        currentSessionTitle = title
        lastError = nil
        hasConnectionError = false
        isLoading = false
    }
    
    func startNewConversation(with document: Document? = nil) {
        messages.removeAll()
        lastError = nil
        hasConnectionError = false
        isLoading = false
        
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
            currentSessionTitle = "New Chat"
        }
    }
    
    func setDocumentContext(_ documents: [Document]) {
        currentDocumentContext = documents
        if documents.count == 1 {
            currentSessionTitle = "Chat with \(documents.first!.title)"
        } else if documents.count > 1 {
            currentSessionTitle = "Chat with \(documents.count) documents"
        }
    }
    
    func clearDocumentContext() {
        currentDocumentContext.removeAll()
        currentSessionTitle = "New Chat"
    }
    
    func clearMessages() {
        messages.removeAll()
        lastError = nil
        hasConnectionError = false
        isLoading = false
    }
    
    // MARK: - Message Grouping
    
    func shouldGroupMessage(at index: Int) -> Bool {
        guard index > 0 && index < messages.count else { return false }
        
        let currentMessage = messages[index]
        let previousMessage = messages[index - 1]
        
        // Same sender
        guard currentMessage.isUser == previousMessage.isUser else { return false }
        
        // Within 5 minutes
        let timeDifference = currentMessage.timestamp.timeIntervalSince(previousMessage.timestamp)
        return timeDifference < 300 // 5 minutes
    }
    
    // MARK: - Utility Methods
    
    func validateAPIConnection(settingsManager: SettingsManager) async -> Bool {
        guard settingsManager.isAPIKeyValid else { 
            hasConnectionError = true
            return false 
        }
        
        if claudeAPIService == nil {
            claudeAPIService = ClaudeAPIService(settingsManager: settingsManager)
        }
        
        do {
            let isValid = try await claudeAPIService?.validateConnection() ?? false
            hasConnectionError = !isValid
            return isValid
        } catch {
            lastError = error.localizedDescription
            hasConnectionError = true
            return false
        }
    }
    
    func exportMessages() -> String {
        return messages.map { message in
            let sender = message.isUser ? "User" : "Assistant"
            let timestamp = message.timestamp.formatted(date: .abbreviated, time: .shortened)
            return "[\(timestamp)] \(sender): \(message.text)"
        }.joined(separator: "\n\n")
    }
    
    private func filterValidMessages(_ messages: [ChatMessage]) -> [ChatMessage] {
        return messages.filter { message in
            // Filter out error messages from conversation history
            !message.text.contains("Sorry, I encountered an error") &&
            !message.text.contains("Please configure your Claude API key") &&
            !message.text.contains("Connection failed") &&
            !message.text.contains("Request failed")
        }
    }
} 