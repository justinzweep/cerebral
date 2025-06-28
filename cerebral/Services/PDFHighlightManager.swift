//
//  PDFHighlightManager.swift
//  cerebral
//
//  Created by Assistant on 26/06/2025.
//

import Foundation
import PDFKit
import SwiftUI

// MARK: - Protocol

@MainActor
protocol PDFHighlightManagerProtocol {
    func applyHighlight(color: HighlightColor, to selection: PDFSelection, in document: PDFDocument, documentURL: URL) async throws -> PDFHighlight
    func removeHighlight(_ highlight: PDFHighlight, from document: PDFDocument) async throws
    func updateHighlight(_ highlight: PDFHighlight, newColor: HighlightColor, in document: PDFDocument) async throws -> PDFHighlight
    func findExistingHighlight(for selection: PDFSelection, in document: PDFDocument) -> PDFHighlight?
    func findOverlappingHighlights(for selection: PDFSelection, in document: PDFDocument) -> [PDFHighlight]
    func reconstructHighlight(groupID: String, in document: PDFDocument) -> PDFHighlight?
}

// MARK: - Implementation

@MainActor
final class PDFHighlightManager: PDFHighlightManagerProtocol {
    
    func applyHighlight(
        color: HighlightColor,
        to selection: PDFSelection,
        in document: PDFDocument,
        documentURL: URL
    ) async throws -> PDFHighlight {
        guard selection.isValidForHighlighting,
              let page = selection.pages.first else {
            throw PDFHighlightError.invalidSelection
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
        
        print("✅ Applied precise \(color.rawValue) highlight to \(lineSelections.count) line(s): '\(text.prefix(50))...'")
        return highlight
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
            throw PDFHighlightError.highlightNotFound
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
            throw PDFHighlightError.highlightNotFound
        }
        
        print("🗑️ Removed \(removedAnnotations) annotation(s)")
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
            throw PDFHighlightError.highlightNotFound
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
            throw PDFHighlightError.highlightNotFound
        }
        
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
    
    func reconstructHighlight(groupID: String, in document: PDFDocument) -> PDFHighlight? {
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
}

// MARK: - Errors

enum PDFHighlightError: LocalizedError {
    case invalidSelection
    case highlightNotFound
    
    var errorDescription: String? {
        switch self {
        case .invalidSelection:
            return "The selected text is not valid for highlighting"
        case .highlightNotFound:
            return "The highlight could not be found"
        }
    }
} 