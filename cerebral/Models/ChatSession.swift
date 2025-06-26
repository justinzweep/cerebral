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
    let text: String
    let isUser: Bool
    let timestamp: Date
    let documentReferences: [UUID]
    
    init(text: String, isUser: Bool, documentReferences: [UUID] = []) {
        self.text = text
        self.isUser = isUser
        self.timestamp = Date()
        self.documentReferences = documentReferences
    }
} 