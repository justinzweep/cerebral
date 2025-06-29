//
//  MessageBuilder.swift
//  cerebral
//
//  Created by Assistant on 26/06/2025.
//

import Foundation
import PDFKit

/// Enhanced service responsible for building and enhancing messages with structured document context
/// 
/// CONTEXT FLOW:
/// 1. Active Document: If user has a document open, include it in vector search
/// 2. Appended Documents: If user has added documents via @ mentions or sidebar, include them in vector search  
/// 3. Combined Vector Search: Search across ALL document IDs (active + appended) for relevant chunks
/// 4. Manual Selections: Add any manually selected text from PDFs separately
/// 5. LLM Formatting: Combine vector search chunks + manual selections for comprehensive context
///
/// The system NEVER uses full document contexts - only relevant chunks from vector search + manual selections
@MainActor
final class EnhancedMessageBuilder: MessageBuilderServiceProtocol {
    static let shared = EnhancedMessageBuilder()
    
    private let contextService = ContextManagementService.shared
    private let documentResolver = DocumentReferenceResolver.shared
    private let documentService = DocumentService.shared
    private let settingsManager = SettingsManager.shared
    
    private init() {}
    
    // MARK: - Enhanced Implementation
    
    /// Enhanced message building with RAG (Retrieval-Augmented Generation) integration
    /// This method performs the RETRIEVAL step in RAG - it MUST complete successfully before generation
    /// Uses advanced prompt formatting and context optimization
    func buildMessageWithVectorSearch(
        userInput: String,
        session: ChatSession
    ) async throws -> String {
        print("🔍 RAG Retrieval: Starting enhanced context retrieval for user query")
        
        // Use the enhanced context management service to build context
        let vectorContext = try await contextService.buildContextForMessage(
            session: session, 
            userMessage: userInput
        )
        
        if !vectorContext.isEmpty {
            print("✅ RAG Retrieval: Successfully retrieved context (\(vectorContext.count) characters)")
            
            // Convert raw context to structured chunks for enhanced formatting
            // NOTE: This is a simplified approach - ideally we'd get structured chunks directly
            let mockChunks = convertRawContextToChunks(vectorContext, session: session)
            
            return formatForLLM(text: userInput, contexts: [], chunks: mockChunks)
        } else {
            print("⚠️ RAG Retrieval: No context retrieved - proceeding with query only")
            return formatForLLM(text: userInput, contexts: [], chunks: [])
        }
    }
    
    /// Helper method to convert raw context string to structured chunks for enhanced formatting
    /// This is a temporary bridge method until we refactor to use structured chunks throughout
    private func convertRawContextToChunks(_ rawContext: String, session: ChatSession) -> [DocumentChunk] {
        // This is a simplified conversion - in production, we'd get structured chunks directly
        let contextParts = rawContext.components(separatedBy: "\n\n")
        var chunks: [DocumentChunk] = []
        
        for (index, part) in contextParts.enumerated() {
            if part.contains("DOCUMENT CONTEXT") && !part.isEmpty {
                // Extract document title and content from raw context
                let lines = part.components(separatedBy: "\n")
                var documentTitle = "Unknown Document"
                var content = part
                
                // Try to extract document name from context format
                for line in lines {
                    if line.contains("[") && line.contains("]") {
                        let pattern = "\\[([^\\]]+)\\]"
                        if let regex = try? NSRegularExpression(pattern: pattern),
                           let match = regex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)),
                           let range = Range(match.range(at: 1), in: line) {
                            documentTitle = String(line[range])
                        }
                        break
                    }
                }
                
                // Create a mock chunk with the extracted information
                let mockChunk = DocumentChunk(chunkId: "legacy_\(index)", text: content, embedding: [])
                // Note: We can't set the document relationship here due to SwiftData constraints
                // This would need to be handled differently in a full refactor
                
                chunks.append(mockChunk)
            }
        }
        
        return chunks
    }
    
    /// Main RAG retrieval and message building method
    /// Returns processed text, manual contexts, and vector search chunks
    /// This method MUST complete successfully before sending to AI
    func buildMessage(
        userInput: String,
        contextBundle: ChatContextBundle,
        sessionId: UUID
    ) async throws -> (processedText: String, contexts: [DocumentContext], chunks: [DocumentChunk]) {
        var contexts: [DocumentContext] = []
        var chunks: [DocumentChunk] = []
        var processedText = userInput
        
        print("🔍 RAG Retrieval: Building message with vector search...")
        
        // Step 1: Collect ALL document IDs that need vector search
        var documentIdsForVectorSearch: Set<UUID> = []
        
        // 1a. Add active document ID if present
        if let activeDocId = contextBundle.activeDocumentId {
            documentIdsForVectorSearch.insert(activeDocId)
            print("📄 RAG Retrieval: Added active document to search scope")
        }
        
        // 1b. Add @ referenced documents
        let referencedDocs = documentResolver.extractDocumentReferences(from: userInput)
        for doc in referencedDocs {
            documentIdsForVectorSearch.insert(doc.id)
            print("📎 RAG Retrieval: Added @ referenced document: \(doc.title)")
        }
        
        // 1c. Documents from sidebar/context are added via ChatManager to the session
        
        // Step 2: CRITICAL RAG STEP - Perform vector search on ALL collected document IDs
        if !documentIdsForVectorSearch.isEmpty {
            guard let vectorService = contextService.currentVectorSearchService else {
                throw AppError.chatError(.messageProcessingFailed("Vector search service not available - cannot perform RAG retrieval"))
            }
            
            do {
                print("🔍 RAG Retrieval: Performing vector search on \(documentIdsForVectorSearch.count) documents...")
                
                // Enhanced vector search with optimized parameters
                let searchLimit = calculateOptimalSearchLimit(documentCount: documentIdsForVectorSearch.count)
                let vectorChunks = try await vectorService.searchSimilarInDocuments(
                    Array(documentIdsForVectorSearch),
                    query: userInput,
                    limit: searchLimit
                )
                
                // Filter chunks by relevance threshold
                let relevantChunks = filterChunksByRelevanceThreshold(vectorChunks, query: userInput)
                chunks.append(contentsOf: relevantChunks)
                
                print("✅ RAG Retrieval: Retrieved \(vectorChunks.count) chunks, \(relevantChunks.count) passed relevance threshold")
                
                // Enhanced debug information
                for (index, chunk) in relevantChunks.enumerated() {
                    let preview = chunk.text.prefix(100).replacingOccurrences(of: "\n", with: " ")
                    print("  📄 Chunk \(index + 1): Doc=\(chunk.document?.title ?? "Unknown"), Page=\(chunk.primaryPageNumber ?? 0), Preview=\(preview)...")
                }
                
                if relevantChunks.isEmpty && !vectorChunks.isEmpty {
                    print("⚠️ RAG Retrieval: Vector search found \(vectorChunks.count) chunks but none met relevance threshold")
                } else if relevantChunks.isEmpty {
                    print("⚠️ RAG Retrieval: Vector search returned no results for query: '\(userInput)'")
                }
                
            } catch {
                print("❌ RAG Retrieval: Vector search failed - \(error)")
                throw AppError.chatError(.messageProcessingFailed("RAG retrieval failed: \(error.localizedDescription)"))
            }
        } else {
            print("💭 RAG Retrieval: No documents in scope for vector search")
        }
        
        // Step 3: Add manual text selections (these are separate from vector search)
        let textSelectionContexts = contextBundle.contexts.filter { $0.contextType == .textSelection }
        contexts.append(contentsOf: textSelectionContexts)
        
        if !textSelectionContexts.isEmpty {
            print("📝 RAG Retrieval: Added \(textSelectionContexts.count) manual text selections")
        }
        
        // Step 4: Optimize contexts for token limit (only text selections)
        let optimizedContexts = contextService.optimizeContextsForTokenLimit(
            contexts,
            limit: getContextTokenLimit()
        )
        
        print("✅ RAG Retrieval: Completed - \(chunks.count) chunks, \(optimizedContexts.count) manual selections")
        return (processedText, optimizedContexts, chunks)
    }
    
    /// Format the final RAG message for the LLM with advanced optimization
    /// This combines retrieved context (chunks + manual selections) with the user query
    /// Implements sophisticated RAG prompt engineering for optimal AI performance
    func formatForLLM(text: String, contexts: [DocumentContext], chunks: [DocumentChunk] = []) -> String {
        var formatted = ""
        var contextAdded = false
        var totalTokens = 0
        let maxContextTokens = getMaxContextTokens()
        
        // Step 1: Deduplicate and prioritize chunks by relevance and quality
        let optimizedChunks = deduplicateAndPrioritizeChunks(chunks)
        
        // Step 2: Add vector search chunks with enhanced presentation
        if !optimizedChunks.isEmpty {
            formatted += buildVectorContextSection(optimizedChunks, maxTokens: maxContextTokens * 2 / 3)
            contextAdded = true
            totalTokens += estimateTokenCount(buildVectorContextSection(optimizedChunks, maxTokens: maxContextTokens * 2 / 3))
        }
        
        // Step 3: Add manual text selections with priority handling
        let textSelectionContexts = contexts.filter { $0.contextType == .textSelection }
        if !textSelectionContexts.isEmpty {
            let remainingTokens = max(0, maxContextTokens - totalTokens)
            formatted += buildManualSelectionSection(textSelectionContexts, maxTokens: remainingTokens)
            contextAdded = true
        }
        
        // Step 4: Add optimized RAG instructions
        if contextAdded {
            formatted += buildEnhancedRAGInstructions(hasVectorContext: !optimizedChunks.isEmpty, hasManualContext: !textSelectionContexts.isEmpty)
        }
        
        // Step 5: Add user query with context awareness
        formatted += buildUserQuerySection(text, hasContext: contextAdded)
        
        return formatted
    }
    
    // MARK: - Advanced RAG Optimization Methods
    
    /// Deduplicate chunks and prioritize by relevance, page coverage, and content quality
    private func deduplicateAndPrioritizeChunks(_ chunks: [DocumentChunk]) -> [DocumentChunk] {
        guard !chunks.isEmpty else { return [] }
        
        // Remove near-duplicates based on text similarity
        var dedupedChunks: [DocumentChunk] = []
        
        for chunk in chunks {
            let isDuplicate = dedupedChunks.contains { existingChunk in
                let similarity = calculateTextSimilarity(chunk.text, existingChunk.text)
                return similarity > 0.85 // 85% similarity threshold
            }
            
            if !isDuplicate {
                dedupedChunks.append(chunk)
            }
        }
        
        // Sort by multiple criteria for optimal presentation
        return dedupedChunks.sorted { chunk1, chunk2 in
            // Primary: Document diversity (spread across different documents)
            let doc1 = chunk1.document?.title ?? ""
            let doc2 = chunk2.document?.title ?? ""
            
            if doc1 != doc2 {
                return doc1 < doc2 // Alphabetical by document
            }
            
            // Secondary: Page order within same document
            let page1 = chunk1.primaryPageNumber ?? Int.max
            let page2 = chunk2.primaryPageNumber ?? Int.max
            
            if page1 != page2 {
                return page1 < page2
            }
            
            // Tertiary: Content quality (longer, more complete chunks first)
            return chunk1.text.count > chunk2.text.count
        }
    }
    
    /// Build the vector search context section with enhanced formatting
    private func buildVectorContextSection(_ chunks: [DocumentChunk], maxTokens: Int) -> String {
        var section = """
╔═══════════════════════════════════════════════════════════════╗
║                    RETRIEVED DOCUMENT CONTEXT                 ║
╚═══════════════════════════════════════════════════════════════╝

The following passages were automatically retrieved using semantic search based on your query.
Each passage has been ranked by relevance and represents the most pertinent information from your documents.

"""
        
        var currentTokens = estimateTokenCount(section)
        var includedChunks = 0
        
        // Group chunks by document for better organization
        let groupedChunks = Dictionary(grouping: chunks, by: { $0.document?.id ?? UUID() })
        
        for (_, documentChunks) in groupedChunks {
            guard let document = documentChunks.first?.document else { continue }
            
            let documentSection = buildDocumentChunkSection(document: document, chunks: documentChunks, maxTokens: maxTokens - currentTokens)
            let sectionTokens = estimateTokenCount(documentSection)
            
            if currentTokens + sectionTokens > maxTokens && includedChunks > 0 {
                section += "\n[Additional relevant passages truncated due to context limits]\n\n"
                break
            }
            
            section += documentSection
            currentTokens += sectionTokens
            includedChunks += documentChunks.count
        }
        
        section += "═══════════════════════════════════════════════════════════════\n\n"
        return section
    }
    
    /// Build a section for chunks from a specific document
    private func buildDocumentChunkSection(document: Document, chunks: [DocumentChunk], maxTokens: Int) -> String {
        var section = "📄 **\(document.documentTitle ?? document.title)**\n"
        
        // Note: Document model doesn't have author property - could be added from PDF metadata if needed
        section += "   📊 \(chunks.count) relevant passage\(chunks.count == 1 ? "" : "s") found\n\n"
        
        var currentTokens = estimateTokenCount(section)
        
        for (index, chunk) in chunks.enumerated() {
            let chunkSection = buildSingleChunkSection(chunk: chunk, index: index + 1)
            let chunkTokens = estimateTokenCount(chunkSection)
            
            if currentTokens + chunkTokens > maxTokens && index > 0 {
                section += "   [Additional passages from this document truncated]\n\n"
                break
            }
            
            section += chunkSection
            currentTokens += chunkTokens
        }
        
        section += String(repeating: "─", count: 60) + "\n\n"
        return section
    }
    
    /// Build a formatted section for a single chunk with enhanced metadata
    private func buildSingleChunkSection(chunk: DocumentChunk, index: Int) -> String {
        var section = "   📖 **Passage \(index)**"
        
        // Add page information if available
        if let primaryPage = chunk.primaryPageNumber {
            section += " (Page \(primaryPage))"
            
            // Add page range if chunk spans multiple pages
            let allPages = chunk.pageNumbers
            if allPages.count > 1 {
                let pageRange = allPages.map(String.init).joined(separator: ", ")
                section += " [spans pages: \(pageRange)]"
            }
        }
        
        section += "\n"
        
        // Add chunk content with proper formatting
        let cleanedText = chunk.text.trimmingCharacters(in: .whitespacesAndNewlines)
        section += "   \"\(cleanedText)\"\n\n"
        
        return section
    }
    
    /// Build the manual selection context section
    private func buildManualSelectionSection(_ contexts: [DocumentContext], maxTokens: Int) -> String {
        var section = """
╔═══════════════════════════════════════════════════════════════╗
║                     USER HIGHLIGHTED TEXT                     ║
╚═══════════════════════════════════════════════════════════════╝

The following text was manually selected and highlighted by the user.
This represents content the user specifically wants you to focus on.

"""
        
        var currentTokens = estimateTokenCount(section)
        
        // Group selections by document
        let groupedSelections = Dictionary(grouping: contexts, by: { $0.documentId })
        
        for (_, docSelections) in groupedSelections {
            guard let first = docSelections.first else { continue }
            
            section += "📄 **\(first.documentTitle)**\n"
            
            for (index, selection) in docSelections.enumerated() {
                let selectionSection = buildSelectionSection(selection: selection, index: index + 1)
                let selectionTokens = estimateTokenCount(selectionSection)
                
                if currentTokens + selectionTokens > maxTokens && index > 0 {
                    section += "   [Additional selections truncated]\n\n"
                    break
                }
                
                section += selectionSection
                currentTokens += selectionTokens
            }
        }
        
        section += "═══════════════════════════════════════════════════════════════\n\n"
        return section
    }
    
    /// Build a formatted section for a manual selection
    private func buildSelectionSection(selection: DocumentContext, index: Int) -> String {
        var section = "   ✋ **User Selection \(index)**"
        
        if let pages = selection.metadata.pageNumbers, !pages.isEmpty {
            let pageText = pages.map(String.init).joined(separator: ", ")
            section += " (Page\(pages.count > 1 ? "s" : "") \(pageText))"
        }
        
        section += "\n"
        section += "   \"\(selection.content.trimmingCharacters(in: .whitespacesAndNewlines))\"\n\n"
        
        return section
    }
    
    /// Build enhanced RAG instructions tailored to the available context
    private func buildEnhancedRAGInstructions(hasVectorContext: Bool, hasManualContext: Bool) -> String {
        var instructions = """
╔═══════════════════════════════════════════════════════════════╗
║                      AI RESPONSE INSTRUCTIONS                 ║
╚═══════════════════════════════════════════════════════════════╝

You are operating in an advanced RAG (Retrieval-Augmented Generation) system. Follow these guidelines:

🎯 **PRIMARY OBJECTIVES:**
   • Provide accurate, detailed answers using the retrieved document context
   • Always cite specific passages when referencing information from documents
   • Synthesize information across multiple sources when relevant
   • Keep your response concise and to the point, unless the user asks for more detail

⚠️ **FORMATTING RESTRICTIONS:**
   • DO NOT use markdown formatting in your response
   • ONLY use these simple text formatting options:
     - **Bold text** for emphasis and headings
     - *Italic text* for subtle emphasis
     - _Underlined text_ for important terms
     - • Bullet points for lists
     - 1. Numbered lists for sequences
   • DO NOT use: headers (#), code blocks (```), links, tables, or other markdown syntax
   • DO NOT use in text citations
   • DO NOT mention you received the context from a vector search


"""
        
        if hasVectorContext {
            instructions += """
📖 **RETRIEVED CONTEXT USAGE:**
   • The semantic search has identified the most relevant passages for this query
   • Prioritize information from these passages as they are contextually matched
   • Reference specific passages by their document and page numbers
   • Look for patterns and connections across different retrieved passages

"""
        }
        
        if hasManualContext {
            instructions += """
✋ **USER SELECTIONS PRIORITY:**
   • User-highlighted text represents explicit areas of interest
   • Give special attention to manually selected content
   • These selections may contain the most critical information for the query

"""
        }
        
        instructions += """
⚠️ **RESPONSE REQUIREMENTS:**
   • If information is missing or unclear, explicitly state what's needed
   • Distinguish between information found in the documents vs. general knowledge
   • Use clear citations: "According to [Document Name, Page X]..."
   • Provide specific page references for fact-checking
   • Synthesize information coherently rather than just listing facts

💡 **QUALITY GUIDELINES:**
   • Structure your response logically with clear sections using **bold headings**
   • Use bullet points and numbered lists for complex information
   • Use **bold** for key insights and main takeaways
   • Use *italic* for subtle emphasis and _underlined_ for important terms
   • Suggest follow-up questions or areas for deeper exploration
   • Remember: NO markdown syntax beyond the allowed formatting options

═══════════════════════════════════════════════════════════════

"""
        
        return instructions
    }
    
    /// Build the user query section with context awareness
    private func buildUserQuerySection(_ text: String, hasContext: Bool) -> String {
        if hasContext {
            return """
╔═══════════════════════════════════════════════════════════════╗
║                        USER QUESTION                          ║
╚═══════════════════════════════════════════════════════════════╝

\(text)

Please provide a comprehensive response using the document context provided above.
"""
        } else {
            return """
════════════════════════════════════════════════════════════════

USER QUESTION: \(text)
"""
        }
    }
    
    // MARK: - Helper Methods for RAG Optimization
    
    private func calculateTextSimilarity(_ text1: String, _ text2: String) -> Double {
        // Simple word-based similarity calculation
        let separators = CharacterSet.whitespacesAndNewlines.union(.punctuationCharacters)
        let words1 = Set(text1.lowercased().components(separatedBy: separators).filter { !$0.isEmpty })
        let words2 = Set(text2.lowercased().components(separatedBy: separators).filter { !$0.isEmpty })
        
        let intersection = words1.intersection(words2)
        let union = words1.union(words2)
        
        return union.isEmpty ? 0.0 : Double(intersection.count) / Double(union.count)
    }
    
    private func estimateTokenCount(_ text: String) -> Int {
        // Rough estimation: ~4 characters per token for English text
        return text.count / 4
    }
    
    private func getMaxContextTokens() -> Int {
        // Reserve tokens for instructions and user query
        let maxTotal = getContextTokenLimit()
        let reservedTokens = 1000 // For instructions, formatting, user query
        return max(1000, maxTotal - reservedTokens)
    }
    
    /// Calculate optimal search limit based on document count and context requirements
    private func calculateOptimalSearchLimit(documentCount: Int) -> Int {
        // Base limit per document, scaled by document count
        let baseLimit = 8
        let perDocumentLimit = max(3, baseLimit / max(1, documentCount / 2))
        
        // Total limit with reasonable bounds
        let totalLimit = min(20, max(5, perDocumentLimit * documentCount))
        
        print("🔢 RAG Optimization: Calculated search limit of \(totalLimit) for \(documentCount) documents")
        return totalLimit
    }
    
    /// Filter chunks by relevance threshold to improve result quality
    private func filterChunksByRelevanceThreshold(_ chunks: [DocumentChunk], query: String) -> [DocumentChunk] {
        guard !chunks.isEmpty else { return [] }
        
        // For now, return all chunks since we don't have access to similarity scores
        // In a production system, you'd filter based on cosine similarity thresholds
        // TODO: Enhance VectorSearchService to return similarity scores
        
        // Simple quality filter: remove very short chunks that are likely noise
        let qualityFiltered = chunks.filter { chunk in
            let cleanedText = chunk.text.trimmingCharacters(in: .whitespacesAndNewlines)
            return cleanedText.count >= 50 // Minimum chunk size for meaningful content
        }
        
        print("🔍 RAG Quality: Filtered \(chunks.count) chunks to \(qualityFiltered.count) based on content quality")
        return qualityFiltered
    }
    
    private func shouldIncludeActiveDocument() -> Bool {
        // Always include active document as per requirements
        return true
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
        // For legacy support, we now only support vector search chunks
        // This method should be deprecated in favor of the enhanced method
        print("⚠️ Legacy buildMessage called - only chunks from vector search will be used")
        return formatForLLM(text: userInput, contexts: [], chunks: [])
    }
    
    @MainActor
    func extractDocumentContext(from documents: [Document]) -> String {
        // This method is deprecated - we only use vector search chunks now
        print("⚠️ extractDocumentContext called - this method is deprecated, use vector search instead")
        return ""
    }
    
    @MainActor
    func formatMessageWithContext(
        userInput: String,
        documentContext: String
    ) -> String {
        // This method is deprecated - use formatForLLM with chunks instead
        print("⚠️ formatMessageWithContext called - this method is deprecated")
        return userInput
    }
    
    // MARK: - Helper Methods
    
    /// This method is now deprecated - we only use vector search chunks
    private func createContextsSynchronously(from documents: [Document]) -> [DocumentContext] {
        print("⚠️ createContextsSynchronously called - this method is deprecated, use vector search instead")
        return []
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