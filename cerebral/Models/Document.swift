//
//  Document.swift
//  cerebral
//
//  Created by Justin Zweep on 26/06/2025.
//

import SwiftData
import Foundation

@Model
class Document {
    @Attribute(.unique) var id: UUID = UUID()
    var title: String = ""
    var filePath: URL
    var dateAdded: Date = Date()
    var lastOpened: Date?
    
    var folder: Folder?
    @Relationship(deleteRule: .cascade) var annotations: [Annotation] = []
    @Relationship var chatSessions: [ChatSession] = []
    
    init(title: String, filePath: URL, folder: Folder? = nil) {
        self.title = title
        self.filePath = filePath
        self.folder = folder
    }
} 