//
//  ContextItem.swift
//  cerebral
//
//  Created on 27/11/2024.
//

import SwiftData
import Foundation

enum ContextItemType: String, Codable, CaseIterable {
    case selection = "selection"
    case document = "document"
}

@Model
final class ContextItem: @unchecked Sendable {
    @Attribute(.unique) var id: UUID = UUID()
    var type: ContextItemType
    var content: String // Either selected text or document reference
    var documentId: UUID? // Reference to Document
    var pageNumber: Int?
    var boundingBox: BoundingBox?
    var dateAdded: Date = Date()
    
    init(type: ContextItemType, content: String, documentId: UUID? = nil) {
        self.type = type
        self.content = content
        self.documentId = documentId
    }
} 