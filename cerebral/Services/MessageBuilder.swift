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
    
    // MARK: - Enhanced Implementation
    
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
    
    // MARK: - MessageBuilderServiceProtocol Implementation
    
    @MainActor
    func buildMessage(
        userInput: String,
        documents: [Document]
    ) -> String {
        // Create contexts synchronously for legacy support
        let contexts = createContextsSynchronously(from: documents)
        return formatForLLM(text: userInput, contexts: contexts)
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
        documentContext: String
    ) -> String {
        var formattedMessage = ""
        
        if !documentContext.isEmpty {
            formattedMessage += "ATTACHED DOCUMENTS:\n\n"
            formattedMessage += documentContext
        }
        
        formattedMessage += userInput
        
        return formattedMessage
    }
    
    // MARK: - Helper Methods
    
    /// Creates contexts from documents synchronously for legacy support
    private func createContextsSynchronously(from documents: [Document]) -> [DocumentContext] {
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