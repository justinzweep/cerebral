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
    func reconstructHighlight(groupID: String, in document: PDFDocument) -> PDFHighlight?
}

// MARK: - Implementation

@MainActor
final class PDFToolbarService: PDFToolbarServiceProtocol {
    static let shared = PDFToolbarService()
    
    // MARK: - Specialized Services
    private let highlightManager = PDFHighlightManager()
    private let annotationService = PDFAnnotationService()
    private let positionCalculator = PDFPositionCalculator()
    private let overlapHandler = PDFOverlapHandler()
    
    private init() {}
    
    // MARK: - Position Calculation
    
    func calculateToolbarPosition(for selection: PDFSelection, in view: PDFView) -> CGPoint {
        return positionCalculator.calculateToolbarPosition(for: selection, in: view)
    }
    
    // MARK: - Highlight Management (Delegated to specialized services)
    
    func applyHighlight(
        color: HighlightColor,
        to selection: PDFSelection,
        in document: PDFDocument,
        documentURL: URL
    ) async throws -> PDFHighlight {
        let highlight = try await highlightManager.applyHighlight(
            color: color,
            to: selection,
            in: document,
            documentURL: documentURL
        )
        
        // Save the document after applying highlight
        try await annotationService.saveDocumentIfPossible(document, to: documentURL)
        
        return highlight
    }
    
    func saveHighlight(_ highlight: PDFHighlight, to document: PDFDocument) async throws {
        try await annotationService.saveAnnotations(in: document, to: highlight.documentURL)
    }
    
    func loadHighlights(from document: PDFDocument) -> [PDFHighlight] {
        return annotationService.loadHighlights(from: document)
    }
    
    func findExistingHighlight(for selection: PDFSelection, in document: PDFDocument) -> PDFHighlight? {
        return highlightManager.findExistingHighlight(for: selection, in: document)
    }
    
    func updateHighlight(
        _ highlight: PDFHighlight,
        newColor: HighlightColor,
        in document: PDFDocument
    ) async throws -> PDFHighlight {
        let updatedHighlight = try await highlightManager.updateHighlight(
            highlight,
            newColor: newColor,
            in: document
        )
        
        // Save document after update
        try await annotationService.saveDocumentIfPossible(document, to: highlight.documentURL)
        
        return updatedHighlight
    }
    
    func removeHighlight(_ highlight: PDFHighlight, from document: PDFDocument) async throws {
        try await highlightManager.removeHighlight(highlight, from: document)
        
        // Save document after removal
        try await annotationService.saveDocumentIfPossible(document, to: highlight.documentURL)
    }
    
    func findOverlappingHighlights(for selection: PDFSelection, in document: PDFDocument) -> [PDFHighlight] {
        return highlightManager.findOverlappingHighlights(for: selection, in: document)
    }
    
    func handleOverlappingHighlights(
        newSelection: PDFSelection,
        newColor: HighlightColor,
        overlappingHighlights: [PDFHighlight],
        in document: PDFDocument,
        documentURL: URL
    ) async throws -> HighlightOperationResult {
        return try await overlapHandler.handleOverlappingHighlights(
            newSelection: newSelection,
            newColor: newColor,
            overlappingHighlights: overlappingHighlights,
            in: document,
            documentURL: documentURL,
            highlightManager: highlightManager
        )
    }
    
    func reconstructHighlight(groupID: String, in document: PDFDocument) -> PDFHighlight? {
        return highlightManager.reconstructHighlight(groupID: groupID, in: document)
    }
}

// MARK: - Errors

enum PDFToolbarError: LocalizedError {
    case pageNotFound
    
    var errorDescription: String? {
        switch self {
        case .pageNotFound:
            return "The PDF page could not be found"
        }
    }
}
