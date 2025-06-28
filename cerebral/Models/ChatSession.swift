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
    var isStreaming: Bool
    var streamingComplete: Bool
    
    init(
        text: String,
        isUser: Bool,
        contexts: [DocumentContext] = [],
        isStreaming: Bool = false
    ) {
        self.text = text
        self.isUser = isUser
        self.timestamp = Date()
        self.contexts = contexts
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
} 