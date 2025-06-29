//
//  DocumentContext.swift
//  cerebral
//
//  Created on 26/06/2025.
//

import Foundation
import CoreGraphics

// MARK: - Document Context

/// Represents a single piece of context from a document
struct DocumentContext: Codable, Identifiable, Sendable, Equatable {
    let id: UUID
    let documentId: UUID
    let documentTitle: String
    let contextType: ContextType
    let content: String
    let metadata: ContextMetadata
    let extractedAt: Date
    
    init(
        id: UUID = UUID(),
        documentId: UUID,
        documentTitle: String,
        contextType: ContextType,
        content: String,
        metadata: ContextMetadata,
        extractedAt: Date = Date()
    ) {
        self.id = id
        self.documentId = documentId
        self.documentTitle = documentTitle
        self.contextType = contextType
        self.content = content
        self.metadata = metadata
        self.extractedAt = extractedAt
    }
    
    enum ContextType: String, Codable, CaseIterable {
        case fullDocument      // DEPRECATED - use vector search chunks instead
        case pageRange        // Specific pages
        case textSelection    // User-selected text
        case semanticChunk    // AI-extracted relevant chunk (handled by vector search)
        
        var displayName: String {
            switch self {
            case .fullDocument: return "Full Document (Deprecated)"
            case .pageRange: return "Page Range"
            case .textSelection: return "Selected Text"
            case .semanticChunk: return "Relevant Section"
            }
        }
        
        // Available context types for new contexts (excluding deprecated ones)
        static var availableTypes: [ContextType] {
            return [.pageRange, .textSelection]
        }
    }
}

// MARK: - Context Metadata

struct ContextMetadata: Codable, Equatable {
    let pageNumbers: [Int]?
    let selectionBounds: [CGRect]?
    let characterRange: NSRange?
    let extractionMethod: String
    let tokenCount: Int
    let checksum: String  // For cache validation
    
    init(
        pageNumbers: [Int]? = nil,
        selectionBounds: [CGRect]? = nil,
        characterRange: NSRange? = nil,
        extractionMethod: String,
        tokenCount: Int,
        checksum: String
    ) {
        self.pageNumbers = pageNumbers
        self.selectionBounds = selectionBounds
        self.characterRange = characterRange
        self.extractionMethod = extractionMethod
        self.tokenCount = tokenCount
        self.checksum = checksum
    }
}

// MARK: - Chat Context Bundle

/// Context bundle for a chat session
struct ChatContextBundle: Codable {
    let sessionId: UUID
    var contexts: [DocumentContext]
    var activeDocumentId: UUID?  // Currently viewed document
    
    init(sessionId: UUID = UUID(), contexts: [DocumentContext] = [], activeDocumentId: UUID? = nil) {
        self.sessionId = sessionId
        self.contexts = contexts
        self.activeDocumentId = activeDocumentId
    }
    
    func tokenCount() -> Int {
        contexts.reduce(0) { $0 + $1.metadata.tokenCount }
    }
    
    func documentSummary() -> [UUID: Int] {
        // Returns document ID -> number of context pieces
        Dictionary(grouping: contexts, by: { $0.documentId })
            .mapValues { $0.count }
    }
    
    mutating func addContext(_ context: DocumentContext) {
        // Avoid duplicates
        if !contexts.contains(where: { $0.id == context.id }) {
            contexts.append(context)
        }
    }
    
    mutating func removeContext(_ context: DocumentContext) {
        contexts.removeAll { $0.id == context.id }
    }
    
    mutating func clearContexts() {
        contexts.removeAll()
    }
}

// MARK: - Extensions for Codable Support

extension CGRect: Codable {
    enum CodingKeys: String, CodingKey {
        case x, y, width, height
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let x = try container.decode(Double.self, forKey: .x)
        let y = try container.decode(Double.self, forKey: .y)
        let width = try container.decode(Double.self, forKey: .width)
        let height = try container.decode(Double.self, forKey: .height)
        self.init(x: x, y: y, width: width, height: height)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(origin.x, forKey: .x)
        try container.encode(origin.y, forKey: .y)
        try container.encode(size.width, forKey: .width)
        try container.encode(size.height, forKey: .height)
    }
}

extension NSRange: Codable {
    enum CodingKeys: String, CodingKey {
        case location, length
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let location = try container.decode(Int.self, forKey: .location)
        let length = try container.decode(Int.self, forKey: .length)
        self.init(location: location, length: length)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(location, forKey: .location)
        try container.encode(length, forKey: .length)
    }
} 