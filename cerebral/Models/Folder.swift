//
//  Folder.swift
//  cerebral
//
//  Created by Justin Zweep on 26/06/2025.
//

import SwiftData
import Foundation

@Model
class Folder {
    @Attribute(.unique) var id: UUID = UUID()
    var name: String = ""
    var createdAt: Date = Date()
    var parent: Folder?
    @Relationship(deleteRule: .cascade) var children: [Folder] = []
    @Relationship var documents: [Document] = []
    
    init(name: String, parent: Folder? = nil) {
        self.name = name
        self.parent = parent
    }
} 