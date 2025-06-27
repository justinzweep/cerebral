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

struct ChatMessage: Codable, Identifiable {
    let id = UUID()
    var text: String
    let isUser: Bool
    let timestamp: Date
    var documentReferences: [UUID]
    let hiddenContext: String? // Context that's sent to LLM but not displayed
    var isStreaming: Bool // Indicates if the message is still being streamed
    var streamingComplete: Bool // Indicates if the streaming is complete
    
    init(text: String, isUser: Bool, documentReferences: [UUID] = [], hiddenContext: String? = nil, isStreaming: Bool = false) {
        self.text = text
        self.isUser = isUser
        self.timestamp = Date()
        self.documentReferences = documentReferences
        self.hiddenContext = hiddenContext
        self.isStreaming = isStreaming
        self.streamingComplete = !isStreaming
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
}

// Model for text selection chunks that appear as attachments
struct TextSelectionChunk: Identifiable, Equatable {
    let id = UUID()
    let text: String
    let source: String // Document name where the text came from
    let previewText: String // Truncated text for display
    
    init(text: String, source: String) {
        self.text = text
        self.source = source
        self.previewText = Self.createPreviewText(from: text)
    }
    
    private static func createPreviewText(from text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.count <= 50 {
            return trimmed
        }
        return String(trimmed.prefix(47)) + "..."
    }
} 