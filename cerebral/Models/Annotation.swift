//
//  Annotation.swift
//  cerebral
//
//  Created by Justin Zweep on 26/06/2025.
//

import SwiftData
import Foundation

@Model
class Annotation {
    @Attribute(.unique) var id: UUID = UUID()
    var type: AnnotationType = AnnotationType.highlight
    var color: String?
    var text: String?
    var pageNumber: Int = 0
    var boundsX: Double = 0
    var boundsY: Double = 0
    var boundsWidth: Double = 0
    var boundsHeight: Double = 0
    var document: Document?
    
    init(type: AnnotationType, pageNumber: Int, bounds: CGRect, document: Document) {
        self.type = type
        self.pageNumber = pageNumber
        self.boundsX = bounds.origin.x
        self.boundsY = bounds.origin.y
        self.boundsWidth = bounds.width
        self.boundsHeight = bounds.height
        self.document = document
    }
    
    var bounds: CGRect {
        CGRect(x: boundsX, y: boundsY, width: boundsWidth, height: boundsHeight)
    }
}

enum AnnotationType: String, Codable, CaseIterable {
    case highlight = "highlight"
    case note = "note"
} 