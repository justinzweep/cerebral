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
    var currentSessionTitle: String = "Chat"
    
    private var claudeAPIService: ClaudeAPIService?
    private var currentDocumentContext: [Document] = []
    
    func sendMessage(_ text: String, settingsManager: SettingsManager, documentContext: [Document] = []) async {
        // Store the original user message for UI display (clean, without document content)
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
        
        // Build the enhanced message for LLM (includes document content)
        let documentsToProcess = documentContext.isEmpty ? currentDocumentContext : documentContext
        let enhancedMessageForLLM = await buildEnhancedMessage(userText: text, documents: documentsToProcess)
        
        do {
            let response = try await claudeAPIService?.sendMessage(
                enhancedMessageForLLM,
                context: [], // Pass empty context since we're including it in the message
                conversationHistory: filterValidMessages(Array(messages.dropLast())) // Exclude the just-added user message and error messages
            ) ?? "No response received"
            
            let aiMessage = ChatMessage(
                text: response,
                isUser: false,
                documentReferences: documentsToProcess.map { $0.id }
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
    
    func startNewSession(title: String = "Chat") {
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
            currentSessionTitle = "Chat"
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
        currentSessionTitle = "Chat"
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
    
    private func filterValidMessages(_ messages: [ChatMessage]) -> [ChatMessage] {
        return messages.filter { message in
            // Filter out error messages from conversation history
            !message.text.contains("Sorry, I encountered an error") &&
            !message.text.contains("Please configure your Claude API key") &&
            !message.text.contains("Connection failed") &&
            !message.text.contains("Request failed")
        }
    }
    
    // MARK: - Private Helper Methods
    
    private func buildEnhancedMessage(userText: String, documents: [Document]) async -> String {
        // First, process @pdf_name.pdf references in the user text
        let processedText = await processDocumentReferences(in: userText)
        
        var enhancedMessage = ""
        
        // Add explicitly attached documents
        if !documents.isEmpty {
            enhancedMessage += "ATTACHED DOCUMENTS:\n\n"
            
            for (index, document) in documents.enumerated() {
                enhancedMessage += "=== Document \(index + 1): \(document.title) ===\n"
                
                // Add metadata
                if let metadata = PDFTextExtractionService.shared.getDocumentMetadata(from: document) {
                    if let pageCount = metadata["pageCount"] as? Int {
                        enhancedMessage += "Pages: \(pageCount)\n"
                    }
                    if let author = metadata["author"] as? String, !author.isEmpty {
                        enhancedMessage += "Author: \(author)\n"
                    }
                    if let subject = metadata["subject"] as? String, !subject.isEmpty {
                        enhancedMessage += "Subject: \(subject)\n"
                    }
                }
                
                // Extract and add text content
                if let extractedText = PDFTextExtractionService.shared.extractText(from: document, maxLength: 4000) {
                    enhancedMessage += "\nDocument Content:\n"
                    enhancedMessage += extractedText
                } else {
                    enhancedMessage += "\nContent: [Unable to extract text from this PDF]\n"
                }
                
                enhancedMessage += "\n" + String(repeating: "=", count: 50) + "\n\n"
            }
        }
        
        // Add the processed user message (with @references replaced with content)
        enhancedMessage += processedText.isEmpty ? userText : processedText
        
        return enhancedMessage
    }
    
    private func processDocumentReferences(in text: String) async -> String {
        // Regex pattern to match @pdf_name.pdf or @pdf_name (with or without .pdf extension)
        let pattern = #"@([a-zA-Z0-9\s\-_\.]+\.pdf|[a-zA-Z0-9\s\-_]+)"#
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return text
        }
        
        let nsString = text as NSString
        let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))
        
        // Process matches in reverse order to maintain string indices
        var processedText = text
        for match in matches.reversed() {
            let matchRange = match.range
            let fullMatch = nsString.substring(with: matchRange)
            
            // Extract the document name (remove @ and potentially .pdf)
            var documentName = String(fullMatch.dropFirst()) // Remove @
            if documentName.hasSuffix(".pdf") {
                documentName = String(documentName.dropLast(4)) // Remove .pdf
            }
            
            // Try to find the document
            if let document = DocumentLookupService.shared.findDocument(byName: documentName) {
                // Extract content from the referenced document
                if let extractedText = PDFTextExtractionService.shared.extractText(from: document, maxLength: 3000) {
                    let replacement = """
                    
                    [REFERENCED DOCUMENT: \(document.title)]
                    \(extractedText)
                    [END REFERENCED DOCUMENT]
                    
                    """
                    
                    let nsProcessedText = processedText as NSString
                    processedText = nsProcessedText.replacingCharacters(in: matchRange, with: replacement)
                } else {
                    // Replace with error message if can't extract content
                    let replacement = "[REFERENCED DOCUMENT: \(document.title) - Unable to extract content]"
                    let nsProcessedText = processedText as NSString
                    processedText = nsProcessedText.replacingCharacters(in: matchRange, with: replacement)
                }
            } else {
                // Replace with error message if document not found
                let replacement = "[DOCUMENT NOT FOUND: \(documentName)]"
                let nsProcessedText = processedText as NSString
                processedText = nsProcessedText.replacingCharacters(in: matchRange, with: replacement)
            }
        }
        
        return processedText
    }
} 