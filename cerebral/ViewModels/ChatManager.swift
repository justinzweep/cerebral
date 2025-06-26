//
//  ChatManager.swift
//  cerebral
//
//  Created by Justin Zweep on 26/06/2025.
//

import Foundation

@MainActor
class ChatManager: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var isLoading: Bool = false
    @Published var lastError: String?
    
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
        }
        
        isLoading = false
    }
    
    func setDocumentContext(_ documents: [Document]) {
        currentDocumentContext = documents
    }
    
    func clearDocumentContext() {
        currentDocumentContext.removeAll()
    }
    
    func clearMessages() {
        messages.removeAll()
        lastError = nil
    }
    
    func validateAPIConnection(settingsManager: SettingsManager) async -> Bool {
        guard settingsManager.isAPIKeyValid else { return false }
        
        if claudeAPIService == nil {
            claudeAPIService = ClaudeAPIService(settingsManager: settingsManager)
        }
        
        do {
            return try await claudeAPIService?.validateConnection() ?? false
        } catch {
            lastError = error.localizedDescription
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
    
    func startNewConversation(with document: Document? = nil) {
        clearMessages()
        
        if let document = document {
            setDocumentContext([document])
            
            let welcomeMessage = ChatMessage(
                text: "I'm ready to help you with '\(document.title)'. Feel free to ask me any questions about this document!",
                isUser: false,
                documentReferences: [document.id]
            )
            messages.append(welcomeMessage)
        } else {
            clearDocumentContext()
        }
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