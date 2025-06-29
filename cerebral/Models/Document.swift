//
//  Document.swift
//  cerebral
//
//  Created by Justin Zweep on 26/06/2025.
//

import SwiftData
import Foundation

enum ProcessingStatus: String, Codable, CaseIterable {
    case pending = "pending"
    case processing = "processing"
    case completed = "completed"
    case failed = "failed"
}

@Model
final class Document: @unchecked Sendable {
    @Attribute(.unique) var id: UUID = UUID()
    var title: String = ""
    var filePath: URL?
    var dateAdded: Date = Date()
    var lastOpened: Date?
    
    // New properties for vector search
    var processingStatusRawValue: String = "pending"
    var totalChunks: Int = 0
    var documentTitle: String? // From API response
    
    // Computed property for ProcessingStatus enum
    var processingStatus: ProcessingStatus {
        get {
            return ProcessingStatus(rawValue: processingStatusRawValue) ?? .pending
        }
        set {
            processingStatusRawValue = newValue.rawValue
        }
    }
    
    @Relationship var chatSessions: [ChatSession] = []
    @Relationship var chunks: [DocumentChunk] = []
    
    init(title: String, filePath: URL?) {
        self.title = title
        self.filePath = filePath
    }
} 