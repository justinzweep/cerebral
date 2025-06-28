//
//  PDFAnnotationService.swift
//  cerebral
//
//  Created by Assistant on 26/06/2025.
//

import Foundation
import PDFKit
import SwiftUI

// MARK: - Protocol

@MainActor
protocol PDFAnnotationServiceProtocol {
    func saveAnnotations(in document: PDFDocument, to url: URL) async throws
    func loadHighlights(from document: PDFDocument) -> [PDFHighlight]
    func saveDocumentIfPossible(_ document: PDFDocument, to url: URL) async throws
}

// MARK: - Implementation

@MainActor
final class PDFAnnotationService: PDFAnnotationServiceProtocol {
    
    func saveAnnotations(in document: PDFDocument, to url: URL) async throws {
        try await saveDocumentIfPossible(document, to: url)
    }
    
    func loadHighlights(from document: PDFDocument) -> [PDFHighlight] {
        var highlightGroups: [String: (color: HighlightColor, pageIndex: Int, bounds: [CGRect], text: String)] = [:]
        
        for pageIndex in 0..<document.pageCount {
            guard let page = document.page(at: pageIndex) else { continue }
            
            for annotation in page.annotations {
                // Only process highlight annotations created by Cerebral
                guard annotation.type == "Highlight",
                      let contents = annotation.contents,
                      let (color, groupID) = decodeAnnotationContents(contents) else {
                    continue
                }
                
                // Extract text from the annotation bounds
                let selection = page.selection(for: annotation.bounds)
                let text = selection?.string ?? ""
                
                // Group annotations by their highlight ID
                if var existingGroup = highlightGroups[groupID] {
                    existingGroup.bounds.append(annotation.bounds)
                    existingGroup.text += text
                    highlightGroups[groupID] = existingGroup
                } else {
                    highlightGroups[groupID] = (
                        color: color,
                        pageIndex: pageIndex,
                        bounds: [annotation.bounds],
                        text: text
                    )
                }
            }
        }
        
        // Convert grouped annotations back to highlights
        let highlights = highlightGroups.map { (groupID, group) in
            // Use the first bounds as representative bounds
            let representativeBounds = group.bounds.first ?? CGRect.zero
            
            return PDFHighlight(
                bounds: representativeBounds,
                color: group.color,
                pageIndex: group.pageIndex,
                text: group.text,
                createdAt: Date(), // Could be stored in annotation if needed
                documentURL: document.documentURL ?? URL(fileURLWithPath: "")
            )
        }
        
        print("📖 Loaded \(highlights.count) highlights from document")
        return highlights
    }
    
    func saveDocumentIfPossible(_ document: PDFDocument, to url: URL) async throws {
        // Check if document allows modifications
        guard document.allowsCommenting || document.allowsContentAccessibility else {
            print("⚠️ Document is read-only, highlights will not persist")
            return
        }
        
        // Save document in background
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    if document.write(to: url) {
                        continuation.resume()
                    } else {
                        continuation.resume(throwing: PDFAnnotationError.saveFailed)
                    }
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func decodeAnnotationContents(_ contents: String) -> (color: HighlightColor, groupID: String)? {
        let components = contents.components(separatedBy: "_")
        guard components.count >= 5,
              components[0] == "CEREBRAL",
              components[1] == "HIGHLIGHT",
              components[3] == "GROUP",
              let color = HighlightColor(rawValue: components[2]) else {
            return nil
        }
        
        let groupID = components[4...].joined(separator: "_")
        return (color: color, groupID: groupID)
    }
}

// MARK: - Errors

enum PDFAnnotationError: LocalizedError {
    case saveFailed
    case documentReadOnly
    
    var errorDescription: String? {
        switch self {
        case .saveFailed:
            return "Failed to save the PDF document"
        case .documentReadOnly:
            return "This PDF document is read-only and cannot be modified"
        }
    }
} 