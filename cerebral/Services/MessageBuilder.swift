//
//  MessageBuilder.swift
//  cerebral
//
//  Created by Assistant on 26/06/2025.
//

import Foundation

/// Service responsible for building and enhancing messages with document content
final class MessageBuilder: MessageBuilderServiceProtocol {
    static let shared = MessageBuilder()
    
    private init() {}
    
    // MARK: - MessageBuilderServiceProtocol Implementation
    
    @MainActor
    func buildMessage(
        userInput: String,
        documents: [Document] = [],
        hiddenContext: String? = nil
    ) -> String {
        return buildEnhancedMessage(userText: userInput, documents: documents, hiddenContext: hiddenContext)
    }
    
    @MainActor
    func extractDocumentContext(from documents: [Document]) -> String {
        var context = ""
        
        for (index, document) in documents.enumerated() {
            context += "=== Document \(index + 1): \(document.title) ===\n"
            
            // Add metadata
            if let metadata = PDFService.shared.getDocumentMetadata(from: document) {
                if let pageCount = metadata["pageCount"] as? Int {
                    context += "Pages: \(pageCount)\n"
                }
                if let author = metadata["author"] as? String, !author.isEmpty {
                    context += "Author: \(author)\n"
                }
                if let subject = metadata["subject"] as? String, !subject.isEmpty {
                    context += "Subject: \(subject)\n"
                }
            }
            
            // Extract and add text content
            if let extractedText = PDFService.shared.extractText(from: document, maxLength: 4000) {
                context += "\nDocument Content:\n"
                context += extractedText
            } else {
                context += "\nContent: [Unable to extract text from this PDF]\n"
            }
            
            context += "\n" + String(repeating: "=", count: 50) + "\n\n"
        }
        
        return context
    }
    
    @MainActor
    func formatMessageWithContext(
        userInput: String,
        documentContext: String,
        hiddenContext: String? = nil
    ) -> String {
        var formattedMessage = ""
        
        if !documentContext.isEmpty {
            formattedMessage += "ATTACHED DOCUMENTS:\n\n"
            formattedMessage += documentContext
        }
        
        if let hiddenContext = hiddenContext, !hiddenContext.isEmpty {
            formattedMessage += hiddenContext + "\n\n"
        }
        
        formattedMessage += userInput
        
        return formattedMessage
    }
    
    // MARK: - Legacy Methods (for backward compatibility)
    
    /// Build an enhanced message that includes document content for the LLM
    @MainActor
    func buildEnhancedMessage(
        userText: String,
        documents: [Document],
        hiddenContext: String? = nil
    ) -> String {
        // First, process @pdf_name.pdf references in the user text
        let processedText = processDocumentReferences(in: userText)
        
        var enhancedMessage = ""
        
        // Add explicitly attached documents
        if !documents.isEmpty {
            enhancedMessage += "ATTACHED DOCUMENTS:\n\n"
            
            for (index, document) in documents.enumerated() {
                enhancedMessage += "=== Document \(index + 1): \(document.title) ===\n"
                
                // Add metadata
                if let metadata = PDFService.shared.getDocumentMetadata(from: document) {
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
                if let extractedText = PDFService.shared.extractText(from: document, maxLength: 4000) {
                    enhancedMessage += "\nDocument Content:\n"
                    enhancedMessage += extractedText
                } else {
                    enhancedMessage += "\nContent: [Unable to extract text from this PDF]\n"
                }
                
                enhancedMessage += "\n" + String(repeating: "=", count: 50) + "\n\n"
            }
        }
        
        // Add hidden context from text selection chunks (sent to LLM but not displayed in UI)
        if let hiddenContext = hiddenContext, !hiddenContext.isEmpty {
            enhancedMessage += hiddenContext + "\n\n"
        }
        
        // Add the processed user message (with @references replaced with content)
        enhancedMessage += processedText.isEmpty ? userText : processedText
        
        return enhancedMessage
    }
    
    /// Process @document references in text and replace them with document content
    @MainActor
    private func processDocumentReferences(in text: String) -> String {
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
                if let extractedText = PDFService.shared.extractText(from: document, maxLength: 3000) {
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
    
    /// Filter out error messages from conversation history
    func filterValidMessages(_ messages: [ChatMessage]) -> [ChatMessage] {
        return messages.filter { message in
            // Filter out error messages from conversation history
            !message.text.contains("Sorry, I encountered an error") &&
            !message.text.contains("Please configure your Claude API key") &&
            !message.text.contains("Connection failed") &&
            !message.text.contains("Request failed")
        }
    }
} 