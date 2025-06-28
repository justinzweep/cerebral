//
//  ContextManagementService.swift
//  cerebral
//
//  Created on 26/06/2025.
//

import Foundation
import PDFKit
import SwiftUI

// MARK: - Context Management Protocol

@MainActor
protocol ContextManagementServiceProtocol {
    // Context creation
    func createContext(from document: Document, type: DocumentContext.ContextType, selection: PDFSelection?) async throws -> DocumentContext
    func createContextFromText(_ text: String, document: Document, metadata: ContextMetadata) -> DocumentContext
    
    // Context retrieval
    func getContextsForSession(_ sessionId: UUID) -> [DocumentContext]
    func getContextsForDocument(_ documentId: UUID) -> [DocumentContext]
    
    // Context caching
    func getCachedContext(for document: Document, type: DocumentContext.ContextType) -> DocumentContext?
    func cacheContext(_ context: DocumentContext)
    func invalidateCache(for documentId: UUID)
    
    // Token management
    func estimateTokenCount(for text: String) -> Int
    func optimizeContextsForTokenLimit(_ contexts: [DocumentContext], limit: Int) -> [DocumentContext]
}

// MARK: - Context Management Service

@MainActor
final class ContextManagementService: ContextManagementServiceProtocol {
    static let shared = ContextManagementService()
    
    private var contextCache: [String: DocumentContext] = [:]
    private let tokenizer = TokenizerService.shared
    private let pdfService = PDFService.shared
    private let cacheManager: ContextCacheManager
    
    // In-memory storage for session contexts (in production, this would be persisted)
    private var sessionContexts: [UUID: [DocumentContext]] = [:]
    
    private init() {
        self.cacheManager = ContextCacheManager()
        setupCache()
    }
    
    private func setupCache() {
        // No special setup needed for dictionary cache
        // We'll implement manual cleanup if cache gets too large
    }
    
    // MARK: - Context Creation
    
    func createContext(from document: Document, type: DocumentContext.ContextType, selection: PDFSelection? = nil) async throws -> DocumentContext {
        // Check cache first
        if let cachedContext = getCachedContext(for: document, type: type) {
            return cachedContext
        }
        
        let content: String
        let metadata: ContextMetadata
        
        switch type {
        case .fullDocument:
            content = pdfService.extractText(from: document, maxLength: 50000) ?? ""
            metadata = ContextMetadata(
                pageNumbers: Array(1...(pdfService.getDocumentMetadata(from: document)?["pageCount"] as? Int ?? 1)),
                extractionMethod: "PDFKit.fullDocument",
                tokenCount: tokenizer.estimateTokenCount(for: content),
                checksum: tokenizer.calculateChecksum(for: content)
            )
            
        case .pageRange:
            // Extract pages based on selection
            if let selection = selection {
                let pages = extractPagesFromSelection(selection)
                content = extractTextFromPages(document: document, pages: pages)
                metadata = ContextMetadata(
                    pageNumbers: pages,
                    extractionMethod: "PDFKit.pageRange",
                    tokenCount: tokenizer.estimateTokenCount(for: content),
                    checksum: tokenizer.calculateChecksum(for: content)
                )
            } else {
                throw AppError.pdfError(PDFError.textExtractionFailed("No selection provided for page range extraction"))
            }
            
        case .textSelection:
            if let selection = selection {
                content = selection.string ?? ""
                let pages = extractPagesFromSelection(selection)
                metadata = ContextMetadata(
                    pageNumbers: pages,
                    selectionBounds: selection.selectionsByLine().compactMap { $0.bounds(for: $0.pages.first!) },
                    extractionMethod: "PDFKit.textSelection",
                    tokenCount: tokenizer.estimateTokenCount(for: content),
                    checksum: tokenizer.calculateChecksum(for: content)
                )
            } else {
                throw AppError.pdfError(PDFError.textExtractionFailed("No selection provided for text selection"))
            }
            
        case .semanticChunk:
            // For now, treat as full document - in future, implement smart chunking
            content = pdfService.extractText(from: document, maxLength: 10000) ?? ""
            metadata = ContextMetadata(
                extractionMethod: "PDFKit.semanticChunk",
                tokenCount: tokenizer.estimateTokenCount(for: content),
                checksum: tokenizer.calculateChecksum(for: content)
            )
        }
        
        let context = DocumentContext(
            documentId: document.id,
            documentTitle: document.title,
            contextType: type,
            content: content,
            metadata: metadata
        )
        
        // Cache the context
        cacheContext(context)
        
        // Also save to persistent cache
        Task {
            try? await cacheManager.cacheContext(context)
        }
        
        return context
    }
    
    func createContextFromText(_ text: String, document: Document, metadata: ContextMetadata) -> DocumentContext {
        let context = DocumentContext(
            documentId: document.id,
            documentTitle: document.title,
            contextType: .textSelection,
            content: text,
            metadata: metadata
        )
        
        cacheContext(context)
        return context
    }
    
    // MARK: - Context Retrieval
    
    func getContextsForSession(_ sessionId: UUID) -> [DocumentContext] {
        sessionContexts[sessionId] ?? []
    }
    
    func getContextsForDocument(_ documentId: UUID) -> [DocumentContext] {
        var contexts: [DocumentContext] = []
        
        // Search through all session contexts
        for (_, sessionContexts) in sessionContexts {
            contexts.append(contentsOf: sessionContexts.filter { $0.documentId == documentId })
        }
        
        return contexts
    }
    
    func addContextToSession(_ context: DocumentContext, sessionId: UUID) {
        if sessionContexts[sessionId] == nil {
            sessionContexts[sessionId] = []
        }
        sessionContexts[sessionId]?.append(context)
    }
    
    // MARK: - Context Caching
    
    func getCachedContext(for document: Document, type: DocumentContext.ContextType) -> DocumentContext? {
        let cacheKey = "\(document.id.uuidString)-\(type.rawValue)"
        
        // Check in-memory cache first
        if let cachedContext = contextCache[cacheKey] {
            return cachedContext
        }
        
        // Check persistent cache
        if let persistentContext = cacheManager.getCachedContext(documentId: document.id, type: type) {
            // Validate the content hasn't changed
            if let currentChecksum = pdfService.extractText(from: document, maxLength: 100).map(tokenizer.calculateChecksum) {
                if currentChecksum == String(persistentContext.metadata.checksum.prefix(16)) {
                    // Re-add to in-memory cache
                    contextCache[cacheKey] = persistentContext
                    return persistentContext
                }
            }
        }
        
        return nil
    }
    
    func cacheContext(_ context: DocumentContext) {
        let cacheKey = "\(context.documentId.uuidString)-\(context.contextType.rawValue)"
        contextCache[cacheKey] = context
        
        // Simple cache cleanup if it gets too large
        if contextCache.count > 100 {
            // Remove oldest entries (this is a simple approach)
            let keysToRemove = Array(contextCache.keys.prefix(10))
            for key in keysToRemove {
                contextCache.removeValue(forKey: key)
            }
        }
    }
    
    func invalidateCache(for documentId: UUID) {
        // Remove from in-memory cache
        for type in DocumentContext.ContextType.allCases {
            let cacheKey = "\(documentId.uuidString)-\(type.rawValue)"
            contextCache.removeValue(forKey: cacheKey)
        }
        
        // Remove from persistent cache
        Task {
            await cacheManager.invalidateCache(for: documentId)
        }
    }
    
    // MARK: - Token Management
    
    func estimateTokenCount(for text: String) -> Int {
        tokenizer.estimateTokenCount(for: text)
    }
    
    func optimizeContextsForTokenLimit(_ contexts: [DocumentContext], limit: Int) -> [DocumentContext] {
        var optimizedContexts: [DocumentContext] = []
        var currentTokenCount = 0
        
        // Sort contexts by priority (references first, then selections, then full documents)
        let sortedContexts = contexts.sorted { ctx1, ctx2 in
            let priority1 = contextPriority(ctx1.contextType)
            let priority2 = contextPriority(ctx2.contextType)
            return priority1 < priority2
        }
        
        for context in sortedContexts {
            let contextTokens = context.metadata.tokenCount
            
            if currentTokenCount + contextTokens <= limit {
                optimizedContexts.append(context)
                currentTokenCount += contextTokens
            } else if currentTokenCount < limit {
                // Try to fit a truncated version
                let remainingTokens = limit - currentTokenCount
                if remainingTokens > 1000 { // Only include if we have reasonable space
                    let truncatedText = tokenizer.truncateToTokenLimit(context.content, limit: remainingTokens)
                    let newTokenCount = tokenizer.estimateTokenCount(for: truncatedText)
                    let newMetadata = ContextMetadata(
                        pageNumbers: context.metadata.pageNumbers,
                        selectionBounds: context.metadata.selectionBounds,
                        characterRange: context.metadata.characterRange,
                        extractionMethod: context.metadata.extractionMethod + ".truncated",
                        tokenCount: newTokenCount,
                        checksum: context.metadata.checksum
                    )
                    let truncatedContext = DocumentContext(
                        id: context.id,
                        documentId: context.documentId,
                        documentTitle: context.documentTitle,
                        contextType: context.contextType,
                        content: truncatedText,
                        metadata: newMetadata,
                        extractedAt: context.extractedAt
                    )
                    optimizedContexts.append(truncatedContext)
                    break
                }
            }
        }
        
        return optimizedContexts
    }
    
    private func contextPriority(_ type: DocumentContext.ContextType) -> Int {
        switch type {
        case .textSelection: return 1
        case .semanticChunk: return 2
        case .pageRange: return 3
        case .fullDocument: return 4
        }
    }
    
    // MARK: - Helper Methods
    
    private func extractPagesFromSelection(_ selection: PDFSelection) -> [Int] {
        var pageNumbers: Set<Int> = []
        
        for page in selection.pages {
            if let pageNumber = page.document?.index(for: page) {
                pageNumbers.insert(pageNumber + 1) // Convert to 1-based indexing
            }
        }
        
        return Array(pageNumbers).sorted()
    }
    
    private func extractTextFromPages(document: Document, pages: [Int]) -> String {
        var text = ""
        
        for pageNumber in pages {
            if let pageText = pdfService.extractTextFromPage(document: document, pageIndex: pageNumber - 1) {
                text += "Page \(pageNumber):\n\(pageText)\n\n"
            }
        }
        
        return text
    }
}

// MARK: - Context Cache Manager

@MainActor
final class ContextCacheManager {
    private let cacheDirectory: URL
    private let maxCacheSize: Int = 100 * 1024 * 1024 // 100MB
    private let maxCacheAge: TimeInterval = 7 * 24 * 60 * 60 // 7 days
    
    init() {
        let cachePath = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        cacheDirectory = cachePath.appendingPathComponent("cerebral_contexts")
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
    
    func cacheContext(_ context: DocumentContext) async throws {
        let cacheKey = "\(context.documentId.uuidString)-\(context.contextType.rawValue)"
        let cacheFile = cacheDirectory.appendingPathComponent("\(cacheKey).json")
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(context)
        try data.write(to: cacheFile)
        
        // Clean up old cache entries
        await cleanupCache()
    }
    
    func getCachedContext(documentId: UUID, type: DocumentContext.ContextType) -> DocumentContext? {
        let cacheKey = "\(documentId.uuidString)-\(type.rawValue)"
        let cacheFile = cacheDirectory.appendingPathComponent("\(cacheKey).json")
        
        guard FileManager.default.fileExists(atPath: cacheFile.path),
              let data = try? Data(contentsOf: cacheFile),
              let context = try? JSONDecoder().decode(DocumentContext.self, from: data) else {
            return nil
        }
        
        // Validate cache freshness
        if Date().timeIntervalSince(context.extractedAt) > maxCacheAge {
            try? FileManager.default.removeItem(at: cacheFile)
            return nil
        }
        
        return context
    }
    
    func invalidateCache(for documentId: UUID) async {
        for type in DocumentContext.ContextType.allCases {
            let cacheKey = "\(documentId.uuidString)-\(type.rawValue)"
            let cacheFile = cacheDirectory.appendingPathComponent("\(cacheKey).json")
            try? FileManager.default.removeItem(at: cacheFile)
        }
    }
    
    private func cleanupCache() async {
        guard let enumerator = FileManager.default.enumerator(at: cacheDirectory, 
                                                              includingPropertiesForKeys: [.fileSizeKey, .creationDateKey]) else {
            return
        }
        
        var cacheFiles: [(url: URL, size: Int, date: Date)] = []
        var totalSize = 0
        
        // Collect all cache files
        for case let fileURL as URL in enumerator {
            guard let attributes = try? fileURL.resourceValues(forKeys: [.fileSizeKey, .creationDateKey]),
                  let size = attributes.fileSize,
                  let creationDate = attributes.creationDate else {
                continue
            }
            
            cacheFiles.append((url: fileURL, size: size, date: creationDate))
            totalSize += size
        }
        
        // Remove old files
        let cutoffDate = Date().addingTimeInterval(-maxCacheAge)
        for file in cacheFiles where file.date < cutoffDate {
            try? FileManager.default.removeItem(at: file.url)
            totalSize -= file.size
        }
        
        // If still over size limit, remove oldest files
        if totalSize > maxCacheSize {
            let sortedFiles = cacheFiles.sorted { $0.date < $1.date }
            for file in sortedFiles {
                if totalSize <= maxCacheSize { break }
                try? FileManager.default.removeItem(at: file.url)
                totalSize -= file.size
            }
        }
    }
} 