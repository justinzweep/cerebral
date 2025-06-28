//
//  MessageBuilder.swift
//  cerebral
//
//  Created by Assistant on 26/06/2025.
//

import Foundation
import PDFKit

/// Enhanced service responsible for building and enhancing messages with structured document context
@MainActor
final class EnhancedMessageBuilder: MessageBuilderServiceProtocol {
    static let shared = EnhancedMessageBuilder()
    
    private let contextService = ContextManagementService.shared
    private let documentResolver = DocumentReferenceResolver.shared
    private let documentService = DocumentService.shared
    private let settingsManager = SettingsManager.shared
    
    private init() {}
    
    // MARK: - New Enhanced Implementation
    
    func buildMessage(
        userInput: String,
        contextBundle: ChatContextBundle,
        sessionId: UUID
    ) async throws -> (processedText: String, contexts: [DocumentContext]) {
        var contexts: [DocumentContext] = []
        var processedText = userInput
        
        // 1. Process @ references
        let referencedDocs = documentResolver.extractDocumentReferences(from: userInput)
        for doc in referencedDocs {
            let context = try await contextService.createContext(
                from: doc,
                type: .reference,
                selection: nil
            )
            contexts.append(context)
            
            // Replace @ reference with a placeholder for tracking
            processedText = processedText.replacingOccurrences(
                of: "@\(doc.title)",
                with: "[REF:\(doc.id.uuidString.prefix(8))]"
            )
        }
        
        // 2. Add explicit context from bundle
        contexts.append(contentsOf: contextBundle.contexts)
        
        // 3. Add active document context if configured
        if let activeDocId = contextBundle.activeDocumentId,
           let activeDoc = documentService.findDocument(byId: activeDocId),
           shouldIncludeActiveDocument() {
            if let cachedContext = contextService.getCachedContext(for: activeDoc, type: .fullDocument) {
                contexts.append(cachedContext)
            } else {
                let context = try await contextService.createContext(
                    from: activeDoc,
                    type: .fullDocument,
                    selection: nil
                )
                contexts.append(context)
            }
        }
        
        // 4. Optimize for token limit
        let optimizedContexts = contextService.optimizeContextsForTokenLimit(
            contexts,
            limit: getContextTokenLimit()
        )
        
        return (processedText, optimizedContexts)
    }
    
    func formatForLLM(text: String, contexts: [DocumentContext]) -> String {
        var formatted = ""
        
        // Group contexts by document
        let groupedContexts = Dictionary(grouping: contexts, by: { $0.documentId })
        
        for (_, docContexts) in groupedContexts {
            guard let first = docContexts.first else { continue }
            
            formatted += "=== Document: \(first.documentTitle) ===\n"
            
            for context in docContexts {
                switch context.contextType {
                case .fullDocument:
                    formatted += "Full Document Content:\n"
                case .pageRange:
                    let pages = context.metadata.pageNumbers?.map(String.init).joined(separator: ", ") ?? ""
                    formatted += "Pages \(pages):\n"
                case .textSelection:
                    formatted += "Selected Text:\n"
                case .semanticChunk:
                    formatted += "Relevant Section:\n"
                case .reference:
                    formatted += "Referenced Content:\n"
                }
                
                formatted += context.content + "\n\n"
            }
            
            formatted += String(repeating: "=", count: 50) + "\n\n"
        }
        
        formatted += "User Query: " + text
        
        return formatted
    }
    
    private func shouldIncludeActiveDocument() -> Bool {
        // Check settings - this would be configured by the user
        return settingsManager.includeActiveDocumentByDefault
    }
    
    private func getContextTokenLimit() -> Int {
        // Get from settings or use default
        return settingsManager.contextTokenLimit
    }
    
    // MARK: - Async Context Creation Helper
    
    /// Creates contexts from documents synchronously for legacy support
    private func createContextsSynchronously(from documents: [Document]) -> [DocumentContext] {
        // For legacy support, we create simplified contexts without full async processing
        var contexts: [DocumentContext] = []
        
        for document in documents {
            // Extract text synchronously
            let content = PDFService.shared.extractText(from: document, maxLength: 4000) ?? ""
            let tokenCount = TokenizerService.shared.estimateTokenCount(for: content)
            let checksum = TokenizerService.shared.calculateChecksum(for: content)
            
            let metadata = ContextMetadata(
                extractionMethod: "legacy.synchronous",
                tokenCount: tokenCount,
                checksum: checksum
            )
            
            let context = DocumentContext(
                documentId: document.id,
                documentTitle: document.title,
                contextType: .fullDocument,
                content: content,
                metadata: metadata
            )
            
            contexts.append(context)
        }
        
        return contexts
    }
    
    // MARK: - Legacy MessageBuilderServiceProtocol Implementation (for backward compatibility)
    
    @MainActor
    func buildMessage(
        userInput: String,
        documents: [Document],
        hiddenContext: String?
    ) -> String {
        // For the synchronous protocol method, fall back to the old implementation
        // The new async context system is used in the new async methods
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
        // Use the DocumentReferenceResolver service for consistency
        let referencedDocuments = ServiceContainer.shared.documentReferenceService.extractDocumentReferences(from: text)
        
        if referencedDocuments.isEmpty {
            return text
        }
        
        // Build replacement content for each referenced document
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
            
            // Try to find the document using the service
            if let document = ServiceContainer.shared.documentService.findDocument(byName: documentName) {
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