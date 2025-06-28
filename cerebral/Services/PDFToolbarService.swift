//
//  PDFToolbarService.swift
//  cerebral
//
//  Created by Assistant on 26/06/2025.
//

import Foundation
import PDFKit
import SwiftUI

// MARK: - Protocol

@MainActor
protocol PDFToolbarServiceProtocol {
    func calculateToolbarPosition(for selection: PDFSelection, in view: PDFView) -> CGPoint
    func saveHighlight(_ highlight: PDFHighlight, to document: PDFDocument) async throws
    func loadHighlights(from document: PDFDocument) -> [PDFHighlight]
    func applyHighlight(color: HighlightColor, to selection: PDFSelection, in document: PDFDocument, documentURL: URL) async throws -> PDFHighlight
    func removeHighlight(_ highlight: PDFHighlight, from document: PDFDocument) async throws
    func findExistingHighlight(for selection: PDFSelection, in document: PDFDocument) -> PDFHighlight?
    func updateHighlight(_ highlight: PDFHighlight, newColor: HighlightColor, in document: PDFDocument) async throws -> PDFHighlight
}

// MARK: - Implementation

@MainActor
final class PDFToolbarService: PDFToolbarServiceProtocol {
    static let shared = PDFToolbarService()
    
    private init() {}
    
    // MARK: - Position Calculation
    
    func calculateToolbarPosition(for selection: PDFSelection, in view: PDFView) -> CGPoint {
        return ToolbarPositionCalculator.calculatePosition(for: selection, in: view)
    }
    
    // MARK: - Highlight Management
    
    func applyHighlight(
        color: HighlightColor,
        to selection: PDFSelection,
        in document: PDFDocument,
        documentURL: URL
    ) async throws -> PDFHighlight {
        guard selection.isValidForHighlighting,
              let page = selection.pages.first else {
            throw PDFToolbarError.invalidSelection
        }
        
        let pageIndex = document.index(for: page)
        
        let selectionBounds = selection.bounds(for: page)
        let text = selection.string ?? ""
        
        // Create PDFKit annotation
        let annotation = PDFAnnotation(bounds: selectionBounds, forType: .highlight, withProperties: nil)
        annotation.color = color.nsColor
        annotation.contents = "Cerebral Highlight"
        
        // Add metadata to annotation
        let highlight = PDFHighlight(
            bounds: selectionBounds,
            color: color,
            pageIndex: pageIndex,
            text: text,
            createdAt: Date(),
            documentURL: documentURL
        )
        
        // Store highlight ID in annotation for later retrieval
        annotation.setValue(highlight.annotationID, forAnnotationKey: .textLabel)
        annotation.setValue(color.rawValue, forAnnotationKey: .contents)
        
        // Add annotation to page
        page.addAnnotation(annotation)
        
        // Save the document if possible
        try await saveDocumentIfPossible(document, to: documentURL)
        
        print("✅ Applied \(color.rawValue) highlight to: '\(text.prefix(50))...'")
        return highlight
    }
    
    func saveHighlight(_ highlight: PDFHighlight, to document: PDFDocument) async throws {
        // Highlights are automatically saved when annotations are added to pages
        // This method exists for interface compliance and future extensibility
        try await saveDocumentIfPossible(document, to: highlight.documentURL)
    }
    
    func loadHighlights(from document: PDFDocument) -> [PDFHighlight] {
        var highlights: [PDFHighlight] = []
        
        for pageIndex in 0..<document.pageCount {
            guard let page = document.page(at: pageIndex) else { continue }
            
            for annotation in page.annotations {
                // Only process highlight annotations created by Cerebral
                guard annotation.type == "Highlight",
                      annotation.contents == "Cerebral Highlight",
                      let colorString = annotation.value(forAnnotationKey: .contents) as? String,
                      let color = HighlightColor(rawValue: colorString),
                      let highlightID = annotation.value(forAnnotationKey: .textLabel) as? String else {
                    continue
                }
                
                // Extract text from the annotation bounds
                let selection = page.selection(for: annotation.bounds)
                let text = selection?.string ?? ""
                
                let highlight = PDFHighlight(
                    bounds: annotation.bounds,
                    color: color,
                    pageIndex: pageIndex,
                    text: text,
                    createdAt: Date(), // Could be stored in annotation if needed
                    documentURL: document.documentURL ?? URL(fileURLWithPath: "")
                )
                
                highlights.append(highlight)
            }
        }
        
        print("📖 Loaded \(highlights.count) highlights from document")
        return highlights
    }
    
    func findExistingHighlight(for selection: PDFSelection, in document: PDFDocument) -> PDFHighlight? {
        guard let page = selection.pages.first else {
            return nil
        }
        
        let pageIndex = document.index(for: page)
        
        let selectionBounds = selection.bounds(for: page)
        
        // Check if selection overlaps with any existing highlights
        for annotation in page.annotations {
            guard annotation.type == "Highlight",
                  annotation.contents == "Cerebral Highlight" else {
                continue
            }
            
            // Check for bounds overlap
            if annotation.bounds.intersects(selectionBounds) {
                guard let colorString = annotation.value(forAnnotationKey: .contents) as? String,
                      let color = HighlightColor(rawValue: colorString) else {
                    continue
                }
                
                let text = selection.string ?? ""
                
                return PDFHighlight(
                    bounds: annotation.bounds,
                    color: color,
                    pageIndex: pageIndex,
                    text: text,
                    createdAt: Date(),
                    documentURL: document.documentURL ?? URL(fileURLWithPath: "")
                )
            }
        }
        
        return nil
    }
    
    func updateHighlight(
        _ highlight: PDFHighlight,
        newColor: HighlightColor,
        in document: PDFDocument
    ) async throws -> PDFHighlight {
        guard let page = document.page(at: highlight.pageIndex) else {
            throw PDFToolbarError.pageNotFound
        }
        
        // Find and update the existing annotation
        for annotation in page.annotations {
            guard annotation.type == "Highlight",
                  annotation.contents == "Cerebral Highlight",
                  annotation.bounds == highlight.bounds else {
                continue
            }
            
            // Update annotation color and metadata
            annotation.color = newColor.nsColor
            annotation.setValue(newColor.rawValue, forAnnotationKey: .contents)
            
            // Save document
            try await saveDocumentIfPossible(document, to: highlight.documentURL)
            
            // Return updated highlight
            let updatedHighlight = PDFHighlight(
                bounds: highlight.bounds,
                color: newColor,
                pageIndex: highlight.pageIndex,
                text: highlight.text,
                createdAt: highlight.createdAt,
                documentURL: highlight.documentURL
            )
            
            print("🔄 Updated highlight color to \(newColor.rawValue)")
            return updatedHighlight
        }
        
        throw PDFToolbarError.highlightNotFound
    }
    
    func removeHighlight(_ highlight: PDFHighlight, from document: PDFDocument) async throws {
        guard let page = document.page(at: highlight.pageIndex) else {
            throw PDFToolbarError.pageNotFound
        }
        
        // Find and remove the annotation
        for annotation in page.annotations {
            guard annotation.type == "Highlight",
                  annotation.contents == "Cerebral Highlight",
                  annotation.bounds == highlight.bounds else {
                continue
            }
            
            page.removeAnnotation(annotation)
            
            // Save document
            try await saveDocumentIfPossible(document, to: highlight.documentURL)
            
            print("🗑️ Removed highlight")
            return
        }
        
        throw PDFToolbarError.highlightNotFound
    }
    
    // MARK: - Helper Methods
    
    private func saveDocumentIfPossible(_ document: PDFDocument, to url: URL) async throws {
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
                        continuation.resume(throwing: PDFToolbarError.saveFailed)
                    }
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

// MARK: - Errors

enum PDFToolbarError: LocalizedError {
    case invalidSelection
    case pageNotFound
    case highlightNotFound
    case saveFailed
    case documentReadOnly
    
    var errorDescription: String? {
        switch self {
        case .invalidSelection:
            return "The selected text is not valid for highlighting"
        case .pageNotFound:
            return "The PDF page could not be found"
        case .highlightNotFound:
            return "The highlight could not be found"
        case .saveFailed:
            return "Failed to save the PDF document"
        case .documentReadOnly:
            return "This PDF document is read-only and cannot be modified"
        }
    }
} 