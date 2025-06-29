//
//  DocumentChunk.swift
//  cerebral
//
//  Created on 27/11/2024.
//

import SwiftData
import Foundation

@Model
final class DocumentChunk: @unchecked Sendable {
    @Attribute(.unique) var id: UUID = UUID()
    var chunkId: String // Format: "{uuid}_{index}" from API
    var text: String
    var embedding: [Float] // Vector embedding from API  
    var boundingBoxes: [BoundingBox] = []
    
    // Metadata from API response
    var originalFilename: String?
    var mimetype: String?
    var binaryHash: UInt64?
    
    // Relationships
    @Relationship(inverse: \Document.chunks) var document: Document?
    
    init(chunkId: String, text: String, embedding: [Float]) {
        self.chunkId = chunkId
        self.text = text
        self.embedding = embedding
    }
    
    // Convenience initializer from API response
    convenience init(from apiResponse: DocumentChunkResponse, document: Document) {
        self.init(
            chunkId: apiResponse.chunkId,
            text: apiResponse.text,
            embedding: apiResponse.embedding
        )
        
        self.document = document
        self.originalFilename = apiResponse.metadata.origin.filename
        self.mimetype = apiResponse.metadata.origin.mimetype
        self.binaryHash = apiResponse.metadata.origin.binaryHash
        
        // Extract bounding boxes from metadata
        for docItem in apiResponse.metadata.docItems {
            for prov in docItem.prov {
                let boundingBox = BoundingBox(from: prov.bbox, pageNumber: prov.pageNo)
                self.boundingBoxes.append(boundingBox)
            }
        }
    }
    
    // Computed property to get all page numbers this chunk appears on
    var pageNumbers: [Int] {
        Array(Set(boundingBoxes.map { $0.pageNumber })).sorted()
    }
    
    // Get primary page number (most common or first)
    var primaryPageNumber: Int? {
        return pageNumbers.first
    }
} 