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
        let text = selection.string ?? ""
        
        // Get precise line-by-line selections for accurate highlighting
        let lineSelections = selection.selectionsByLine()
        
        // Create highlight annotations for each line to ensure precision
        var allBounds: [CGRect] = []
        let highlightID = UUID().uuidString
        
        for (index, lineSelection) in lineSelections.enumerated() {
            guard let linePage = lineSelection.pages.first else { continue }
            
            let lineBounds = lineSelection.bounds(for: linePage)
            allBounds.append(lineBounds)
            
            // Create precise annotation for this line
            let annotation = PDFAnnotation(bounds: lineBounds, forType: .highlight, withProperties: nil)
            annotation.color = color.nsColor
            annotation.contents = encodeAnnotationContents(color: color, groupID: highlightID)
            
            // Store line metadata
            annotation.setValue("\(highlightID)_line_\(index)", forAnnotationKey: .textLabel)
            
            // Add annotation to page
            linePage.addAnnotation(annotation)
        }
        
        // Use the bounds of the first line for the highlight model
        // (This is for compatibility with existing code that expects a single bounds)
        let representativeBounds = allBounds.first ?? selection.bounds(for: page)
        
        // Create highlight model
        let highlight = PDFHighlight(
            bounds: representativeBounds,
            color: color,
            pageIndex: pageIndex,
            text: text,
            createdAt: Date(),
            documentURL: documentURL
        )
        
        // Save the document if possible
        try await saveDocumentIfPossible(document, to: documentURL)
        
        print("✅ Applied precise \(color.rawValue) highlight to \(lineSelections.count) line(s): '\(text.prefix(50))...'")
        return highlight
    }
    
    func saveHighlight(_ highlight: PDFHighlight, to document: PDFDocument) async throws {
        // Highlights are automatically saved when annotations are added to pages
        // This method exists for interface compliance and future extensibility
        try await saveDocumentIfPossible(document, to: highlight.documentURL)
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
    
    func findExistingHighlight(for selection: PDFSelection, in document: PDFDocument) -> PDFHighlight? {
        guard let page = selection.pages.first else {
            return nil
        }
        
        let pageIndex = document.index(for: page)
        let selectionBounds = selection.bounds(for: page)
        
        // Check if selection overlaps with any existing highlights
        for annotation in page.annotations {
            guard annotation.type == "Highlight",
                  let contents = annotation.contents,
                  let (color, groupID) = decodeAnnotationContents(contents) else {
                continue
            }
            
            // Check for bounds overlap
            if annotation.bounds.intersects(selectionBounds) {
                
                // Find all annotations that belong to this highlight group
                var allText = ""
                var representativeBounds = annotation.bounds
                
                for pageNum in 0..<document.pageCount {
                    guard let checkPage = document.page(at: pageNum) else { continue }
                    
                    for checkAnnotation in checkPage.annotations {
                        guard checkAnnotation.type == "Highlight",
                              let checkContents = checkAnnotation.contents,
                              let (_, checkGroupID) = decodeAnnotationContents(checkContents),
                              checkGroupID == groupID else {
                            continue
                        }
                        
                        // Add text from this part of the highlight
                        let annotationSelection = checkPage.selection(for: checkAnnotation.bounds)
                        allText += annotationSelection?.string ?? ""
                    }
                }
                
                return PDFHighlight(
                    bounds: representativeBounds,
                    color: color,
                    pageIndex: pageIndex,
                    text: allText,
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
        var groupID: String?
        var updatedAnnotations = 0
        
        // First pass: find the group ID by looking for any annotation with matching bounds
        for pageIndex in 0..<document.pageCount {
            guard let page = document.page(at: pageIndex) else { continue }
            
            for annotation in page.annotations {
                guard annotation.type == "Highlight",
                      let contents = annotation.contents,
                      let (_, foundGroupID) = decodeAnnotationContents(contents),
                      annotation.bounds == highlight.bounds else {
                    continue
                }
                
                groupID = foundGroupID
                break
            }
            if groupID != nil { break }
        }
        
        guard let foundGroupID = groupID else {
            throw PDFToolbarError.highlightNotFound
        }
        
        // Second pass: update all annotations in this group
        for pageIndex in 0..<document.pageCount {
            guard let page = document.page(at: pageIndex) else { continue }
            
            for annotation in page.annotations {
                guard annotation.type == "Highlight",
                      let contents = annotation.contents,
                      let (_, annotationGroupID) = decodeAnnotationContents(contents),
                      annotationGroupID == foundGroupID else {
                    continue
                }
                
                // Update annotation color and metadata
                annotation.color = newColor.nsColor
                annotation.contents = encodeAnnotationContents(color: newColor, groupID: foundGroupID)
                updatedAnnotations += 1
            }
        }
        
        if updatedAnnotations == 0 {
            throw PDFToolbarError.highlightNotFound
        }
        
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
        
        print("🔄 Updated \(updatedAnnotations) annotation(s) to \(newColor.rawValue)")
        return updatedHighlight
    }
    
    func removeHighlight(_ highlight: PDFHighlight, from document: PDFDocument) async throws {
        var groupID: String?
        var removedAnnotations = 0
        
        // First pass: find the group ID by looking for any annotation with matching bounds
        for pageIndex in 0..<document.pageCount {
            guard let page = document.page(at: pageIndex) else { continue }
            
            for annotation in page.annotations {
                guard annotation.type == "Highlight",
                      let contents = annotation.contents,
                      let (_, foundGroupID) = decodeAnnotationContents(contents),
                      annotation.bounds == highlight.bounds else {
                    continue
                }
                
                groupID = foundGroupID
                break
            }
            if groupID != nil { break }
        }
        
        guard let foundGroupID = groupID else {
            throw PDFToolbarError.highlightNotFound
        }
        
        // Second pass: remove all annotations in this group
        for pageIndex in 0..<document.pageCount {
            guard let page = document.page(at: pageIndex) else { continue }
            
            // Collect annotations to remove (can't modify array while iterating)
            var annotationsToRemove: [PDFAnnotation] = []
            
            for annotation in page.annotations {
                guard annotation.type == "Highlight",
                      let contents = annotation.contents,
                      let (_, annotationGroupID) = decodeAnnotationContents(contents),
                      annotationGroupID == foundGroupID else {
                    continue
                }
                
                annotationsToRemove.append(annotation)
            }
            
            // Remove the annotations
            for annotation in annotationsToRemove {
                page.removeAnnotation(annotation)
                removedAnnotations += 1
            }
        }
        
        if removedAnnotations == 0 {
            throw PDFToolbarError.highlightNotFound
        }
        
        // Save document
        try await saveDocumentIfPossible(document, to: highlight.documentURL)
        
        print("🗑️ Removed \(removedAnnotations) annotation(s)")
    }
    
    // MARK: - Helper Methods
    
    private func encodeAnnotationContents(color: HighlightColor, groupID: String) -> String {
        return "CEREBRAL_HIGHLIGHT_\(color.rawValue)_GROUP_\(groupID)"
    }
    
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
