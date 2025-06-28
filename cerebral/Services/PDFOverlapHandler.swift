//
//  PDFOverlapHandler.swift
//  cerebral
//
//  Created by Assistant on 26/06/2025.
//

import Foundation
import PDFKit
import SwiftUI

// MARK: - Protocol

@MainActor
protocol PDFOverlapHandlerProtocol {
    func handleOverlappingHighlights(
        newSelection: PDFSelection,
        newColor: HighlightColor,
        overlappingHighlights: [PDFHighlight],
        in document: PDFDocument,
        documentURL: URL,
        highlightManager: PDFHighlightManagerProtocol
    ) async throws -> HighlightOperationResult
}

// MARK: - Implementation

@MainActor
final class PDFOverlapHandler: PDFOverlapHandlerProtocol {
    
    func handleOverlappingHighlights(
        newSelection: PDFSelection,
        newColor: HighlightColor,
        overlappingHighlights: [PDFHighlight],
        in document: PDFDocument,
        documentURL: URL,
        highlightManager: PDFHighlightManagerProtocol
    ) async throws -> HighlightOperationResult {
        var removedHighlights: [PDFHighlight] = []
        var addedHighlights: [PDFHighlight] = []
        
        guard let page = newSelection.pages.first else {
            throw PDFOverlapError.pageNotFound
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
            try await highlightManager.removeHighlight(overlappingHighlight, from: document)
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
        let newHighlight = try await highlightManager.applyHighlight(
            color: newColor,
            to: mergedSelection,
            in: document,
            documentURL: documentURL
        )
        addedHighlights.append(newHighlight)
        
        // Step 4: Create highlights for all remaining different-color parts
        for (selection, color) in finalSelections {
            let highlight = try await highlightManager.applyHighlight(
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
    
    // MARK: - Private Helper Methods
    
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

// MARK: - Result Types

struct HighlightOperationResult {
    let removedHighlights: [PDFHighlight]
    let addedHighlights: [PDFHighlight]
}

// MARK: - Errors

enum PDFOverlapError: LocalizedError {
    case pageNotFound
    
    var errorDescription: String? {
        switch self {
        case .pageNotFound:
            return "The PDF page could not be found"
        }
    }
} 