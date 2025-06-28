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
    func findOverlappingHighlights(for selection: PDFSelection, in document: PDFDocument) -> [PDFHighlight]
    func handleOverlappingHighlights(newSelection: PDFSelection, newColor: HighlightColor, overlappingHighlights: [PDFHighlight], in document: PDFDocument, documentURL: URL) async throws -> HighlightOperationResult
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
        
        // Disable animations during highlight operations
        let previousAnimationsEnabled = NSAnimationContext.current.allowsImplicitAnimation
        NSAnimationContext.current.allowsImplicitAnimation = false
        
        defer {
            // Restore animation state
            NSAnimationContext.current.allowsImplicitAnimation = previousAnimationsEnabled
        }
        
        // Use PDFKit's native selectionsByLine() for precise line-by-line highlighting
        let lineSelections = selection.selectionsByLine()
        let highlightID = UUID().uuidString
        var allBounds: [CGRect] = []
        
        for (index, lineSelection) in lineSelections.enumerated() {
            guard let linePage = lineSelection.pages.first else { continue }
            
            // Use native PDFKit bounds calculation
            let lineBounds = lineSelection.bounds(for: linePage)
            allBounds.append(lineBounds)
            
            // Create annotation using PDFKit's native annotation creation
            let annotation = PDFAnnotation(bounds: lineBounds, forType: .highlight, withProperties: nil)
            annotation.color = color.nsColor
            annotation.contents = encodeAnnotationContents(color: color, groupID: highlightID)
            
            // Use PDFKit's native annotation key for metadata
            annotation.setValue("\(highlightID)_line_\(index)", forAnnotationKey: .textLabel)
            
            // Add annotation using native PDFKit method
            linePage.addAnnotation(annotation)
        }
        
        // Use the bounds of the first line for the highlight model
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
        
        // Disable animations during highlight update operations
        let previousAnimationsEnabled = NSAnimationContext.current.allowsImplicitAnimation
        NSAnimationContext.current.allowsImplicitAnimation = false
        
        defer {
            // Restore animation state
            NSAnimationContext.current.allowsImplicitAnimation = previousAnimationsEnabled
        }
        
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
                
                // Update annotation color and metadata without animations
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
        
        // Disable animations during highlight removal operations
        let previousAnimationsEnabled = NSAnimationContext.current.allowsImplicitAnimation
        NSAnimationContext.current.allowsImplicitAnimation = false
        
        defer {
            // Restore animation state
            NSAnimationContext.current.allowsImplicitAnimation = previousAnimationsEnabled
        }
        
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
            
            // Remove the annotations without animations
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
    
    func findOverlappingHighlights(for selection: PDFSelection, in document: PDFDocument) -> [PDFHighlight] {
        guard let page = selection.pages.first,
              let selectionString = selection.string else { return [] }
        
        let pageIndex = document.index(for: page)
        let selectionBounds = selection.bounds(for: page)
        var overlappingHighlights: [PDFHighlight] = []
        var processedGroupIDs: Set<String> = []
        
        // Use character-based intersection detection for more accuracy
        let selectionStartChar = page.characterIndex(at: CGPoint(x: selectionBounds.minX, y: selectionBounds.midY))
        let selectionEndChar = page.characterIndex(at: CGPoint(x: selectionBounds.maxX, y: selectionBounds.midY))
        
        // Only check the current page for overlapping highlights to be more deterministic
        for annotation in page.annotations {
            guard annotation.type == "Highlight",
                  let contents = annotation.contents,
                  let (color, groupID) = decodeAnnotationContents(contents),
                  !processedGroupIDs.contains(groupID) else {
                continue
            }
            
            // Use character-based overlap detection with native PDFKit
            let annotationBounds = annotation.bounds
            let annotationStartChar = page.characterIndex(at: CGPoint(x: annotationBounds.minX, y: annotationBounds.midY))
            let annotationEndChar = page.characterIndex(at: CGPoint(x: annotationBounds.maxX, y: annotationBounds.midY))
            
            // Check for character range overlap (more precise than geometric bounds)
            let hasOverlap = selectionStartChar < annotationEndChar && selectionEndChar > annotationStartChar
            
            if hasOverlap {
                // Reconstruct the full highlight from all its annotations using native PDFKit
                if let fullHighlight = reconstructHighlight(groupID: groupID, in: document) {
                    overlappingHighlights.append(fullHighlight)
                    processedGroupIDs.insert(groupID)
                }
            }
        }
        
        return overlappingHighlights
    }
    
    func handleOverlappingHighlights(
        newSelection: PDFSelection,
        newColor: HighlightColor,
        overlappingHighlights: [PDFHighlight],
        in document: PDFDocument,
        documentURL: URL
    ) async throws -> HighlightOperationResult {
        var removedHighlights: [PDFHighlight] = []
        var addedHighlights: [PDFHighlight] = []
        
        guard let page = newSelection.pages.first else {
            throw PDFToolbarError.pageNotFound
        }
        
        let pageIndex = document.index(for: page)
        
        // Step 1: Remove all overlapping highlights and collect their text selections
        var existingSelections: [(PDFSelection, HighlightColor)] = []
        
        for overlappingHighlight in overlappingHighlights {
            guard overlappingHighlight.pageIndex == pageIndex else { continue }
            
            // Find and reconstruct the actual selection for this highlight
            if let highlightSelection = reconstructSelectionFromHighlight(overlappingHighlight, in: document) {
                existingSelections.append((highlightSelection, overlappingHighlight.color))
            }
            
            // Remove the original highlight
            try await removeHighlight(overlappingHighlight, from: document)
            removedHighlights.append(overlappingHighlight)
        }
        
        // Step 2: Process each existing selection against the new selection
        var finalSelections: [(PDFSelection, HighlightColor)] = []
        
        for (existingSelection, existingColor) in existingSelections {
            if existingColor == newColor {
                // Same color: we'll merge this later
                continue
            } else {
                // Different color: subtract the new selection from the existing one
                let remainingSelections = subtractSelection(newSelection, from: existingSelection, on: page)
                for remainingSelection in remainingSelections {
                    finalSelections.append((remainingSelection, existingColor))
                }
            }
        }
        
        // Step 3: Create the new highlight (merge with same-color selections if any)
        var mergedSelection = newSelection
        for (existingSelection, existingColor) in existingSelections {
            if existingColor == newColor {
                // Merge same-color selections
                mergedSelection = mergeSelections(mergedSelection, existingSelection)
            }
        }
        
        // Apply the merged selection in the new color
        let newHighlight = try await applyHighlight(
            color: newColor,
            to: mergedSelection,
            in: document,
            documentURL: documentURL
        )
        addedHighlights.append(newHighlight)
        
        // Step 4: Create highlights for all remaining different-color parts
        for (selection, color) in finalSelections {
            let highlight = try await applyHighlight(
                color: color,
                to: selection,
                in: document,
                documentURL: documentURL
            )
            addedHighlights.append(highlight)
        }
        
        print("🎯 Processed overlapping highlights: removed \(removedHighlights.count), added \(addedHighlights.count)")
        
        return HighlightOperationResult(
            removedHighlights: removedHighlights,
            addedHighlights: addedHighlights
        )
    }
    
    // MARK: - Text-based Selection Operations
    
    private func reconstructSelectionFromHighlight(_ highlight: PDFHighlight, in document: PDFDocument) -> PDFSelection? {
        guard let page = document.page(at: highlight.pageIndex) else { return nil }
        
        // Find all annotations belonging to this highlight
        var groupID: String?
        
        // First, find the group ID by matching bounds
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
        
        guard let targetGroupID = groupID else { return nil }
        
        // Collect all annotations with this group ID and create combined selection
        let combinedSelection = PDFSelection(document: document)
        
        for pageIdx in 0..<document.pageCount {
            guard let checkPage = document.page(at: pageIdx) else { continue }
            
            for annotation in checkPage.annotations {
                guard annotation.type == "Highlight",
                      let contents = annotation.contents,
                      let (_, annotationGroupID) = decodeAnnotationContents(contents),
                      annotationGroupID == targetGroupID else {
                    continue
                }
                
                // Use native PDFKit selection for annotation bounds
                if let annotationSelection = checkPage.selection(for: annotation.bounds) {
                    combinedSelection.add(annotationSelection)
                }
            }
        }
        
        return combinedSelection.string?.isEmpty == false ? combinedSelection : nil
    }
    
    private func subtractSelection(_ toSubtract: PDFSelection, from original: PDFSelection, on page: PDFPage) -> [PDFSelection] {
        // Use character-based approach with native PDFKit APIs
        guard let originalString = original.string,
              let toSubtractString = toSubtract.string,
              let pageString = page.string else {
            return [original]
        }
        
        // Get character ranges for both selections
        let originalBounds = original.bounds(for: page)
        let subtractBounds = toSubtract.bounds(for: page)
        
        // Find character indices using PDFKit's native methods
        let originalStartChar = page.characterIndex(at: CGPoint(x: originalBounds.minX, y: originalBounds.midY))
        let originalEndChar = page.characterIndex(at: CGPoint(x: originalBounds.maxX, y: originalBounds.midY))
        let subtractStartChar = page.characterIndex(at: CGPoint(x: subtractBounds.minX, y: subtractBounds.midY))
        let subtractEndChar = page.characterIndex(at: CGPoint(x: subtractBounds.maxX, y: subtractBounds.midY))
        
        var resultSelections: [PDFSelection] = []
        
        // Left part (before subtraction)
        if originalStartChar < subtractStartChar {
            let leftStartChar = originalStartChar
            let leftEndChar = min(subtractStartChar, originalEndChar)
            
            if let leftSelection = createSelectionFromCharacterRange(
                start: leftStartChar,
                end: leftEndChar,
                on: page
            ), leftSelection.isValidForHighlighting {
                resultSelections.append(leftSelection)
            }
        }
        
        // Right part (after subtraction)
        if originalEndChar > subtractEndChar {
            let rightStartChar = max(subtractEndChar, originalStartChar)
            let rightEndChar = originalEndChar
            
            if let rightSelection = createSelectionFromCharacterRange(
                start: rightStartChar,
                end: rightEndChar,
                on: page
            ), rightSelection.isValidForHighlighting {
                resultSelections.append(rightSelection)
            }
        }
        
        // If we couldn't create proper parts, return the original to avoid data loss
        if resultSelections.isEmpty {
            return [original]
        }
        
        return resultSelections
    }
    
    private func createSelectionFromCharacterRange(start: Int, end: Int, on page: PDFPage) -> PDFSelection? {
        guard start < end,
              let pageString = page.string,
              start >= 0,
              end <= pageString.count else {
            return nil
        }
        
        // Get bounds for the character range using native PDFKit
        let startBounds = page.characterBounds(at: start)
        let endBounds = page.characterBounds(at: end - 1)
        
        // Create a combined bounds rectangle
        let combinedBounds = startBounds.union(endBounds)
        
        // Use PDFKit's native selection method
        return page.selection(for: combinedBounds)
    }
    
    private func mergeSelections(_ selection1: PDFSelection, _ selection2: PDFSelection) -> PDFSelection {
        // Use PDFKit's native selection merging
        guard let document = selection1.pages.first?.document else { return selection1 }
        
        let mergedSelection = PDFSelection(document: document)
        mergedSelection.add(selection1)
        mergedSelection.add(selection2)
        
        // Validate the merged selection has content
        return mergedSelection.string?.isEmpty == false ? mergedSelection : selection1
    }
    
    // MARK: - PDFView Notification Helpers
    
    private func notifyAnnotationChanges(on page: PDFPage, for pdfView: PDFView?) {
        // Use PDFKit's native annotation change notification
        pdfView?.annotationsChanged(on: page)
    }
    
    private func getPDFViewFromDocument(_ document: PDFDocument) -> PDFView? {
        // In a real implementation, we'd maintain a reference to the PDFView
        // For now, we'll return nil and rely on automatic updates
        // This could be improved by maintaining a weak reference to the PDFView
        return nil
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
    
    private func reconstructHighlight(groupID: String, in document: PDFDocument) -> PDFHighlight? {
        var color: HighlightColor?
        var pageIndex: Int = 0
        var allText = ""
        var representativeBounds: CGRect = .zero
        var foundAny = false
        
        for checkPageIndex in 0..<document.pageCount {
            guard let page = document.page(at: checkPageIndex) else { continue }
            
            for annotation in page.annotations {
                guard annotation.type == "Highlight",
                      let contents = annotation.contents,
                      let (annotationColor, annotationGroupID) = decodeAnnotationContents(contents),
                      annotationGroupID == groupID else {
                    continue
                }
                
                if !foundAny {
                    color = annotationColor
                    pageIndex = checkPageIndex
                    representativeBounds = annotation.bounds
                    foundAny = true
                }
                
                // Add text from this annotation
                let selection = page.selection(for: annotation.bounds)
                allText += selection?.string ?? ""
            }
        }
        
        guard foundAny, let highlightColor = color else { return nil }
        
        return PDFHighlight(
            bounds: representativeBounds,
            color: highlightColor,
            pageIndex: pageIndex,
            text: allText,
            createdAt: Date(),
            documentURL: document.documentURL ?? URL(fileURLWithPath: "")
        )
    }
}

// MARK: - Result Types

struct HighlightOperationResult {
    let removedHighlights: [PDFHighlight]
    let addedHighlights: [PDFHighlight]
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
