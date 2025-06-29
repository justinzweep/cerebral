//
//  ChatSession.swift
//  cerebral
//
//  Created by Justin Zweep on 26/06/2025.
//

import SwiftData
import Foundation

@Model
class ChatSession {
    @Attribute(.unique) var id: UUID = UUID()
    var title: String = ""
    var createdAt: Date = Date()
    @Attribute(.externalStorage) var messagesData: Data = Data()
    @Relationship var documentReferences: [Document] = []
    
    // New properties to track context
    @Relationship var contextItems: [ContextItem] = []
    var contextDocumentIds: [UUID] = [] // Track which documents are in context
    
    init(title: String) {
        self.title = title
    }
    
    var messages: [ChatMessage] {
        get {
            (try? JSONDecoder().decode([ChatMessage].self, from: messagesData)) ?? []
        }
        set {
            messagesData = (try? JSONEncoder().encode(newValue)) ?? Data()
        }
    }
}

struct ChatMessage: Codable, Identifiable, Sendable {
    let id = UUID()
    var text: String
    let isUser: Bool
    let timestamp: Date
    var contexts: [DocumentContext] // Unified context system
    var chunkIds: [UUID] // Store chunk IDs instead of full chunks for Codable conformance
    var isStreaming: Bool
    var streamingComplete: Bool
    
    init(
        text: String,
        isUser: Bool,
        contexts: [DocumentContext] = [],
        chunks: [DocumentChunk] = [],
        isStreaming: Bool = false
    ) {
        self.text = text
        self.isUser = isUser
        self.timestamp = Date()
        self.contexts = contexts
        self.chunkIds = Array(Set(chunks.map { $0.id })) // Store only unique IDs
        self.isStreaming = isStreaming
        self.streamingComplete = !isStreaming
    }
    
    // Computed properties for context management
    var referencedDocumentIds: [UUID] {
        Array(Set(contexts.map { $0.documentId }))
    }
    
    var totalTokenCount: Int {
        contexts.reduce(0) { $0 + $1.metadata.tokenCount }
    }
    
    var hasContext: Bool {
        !contexts.isEmpty
    }
    
    var hasChunks: Bool {
        !chunkIds.isEmpty
    }
    
    // Helper methods for streaming
    mutating func startStreaming() {
        isStreaming = true
        streamingComplete = false
    }
    
    mutating func appendStreamingText(_ newText: String) {
        text += newText
    }
    
    mutating func completeStreaming() {
        isStreaming = false
        streamingComplete = true
    }
    
    // Context management methods
    mutating func addContext(_ context: DocumentContext) {
        if !contexts.contains(where: { $0.id == context.id }) {
            contexts.append(context)
        }
    }
    
    mutating func removeContext(_ context: DocumentContext) {
        contexts.removeAll { $0.id == context.id }
    }
    
    // Chunk management methods
    mutating func addChunkId(_ chunkId: UUID) {
        if !chunkIds.contains(chunkId) {
            chunkIds.append(chunkId)
        }
    }
    
    mutating func addChunkIds(_ newChunkIds: [UUID]) {
        let uniqueNewIds = newChunkIds.filter { !chunkIds.contains($0) }
        chunkIds.append(contentsOf: uniqueNewIds)
    }
    
    mutating func removeChunkId(_ chunkId: UUID) {
        chunkIds.removeAll { $0 == chunkId }
    }
} 