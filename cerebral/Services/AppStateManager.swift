//
//  AppStateManager.swift
//  cerebral
//
//  Created by Assistant on 26/06/2025.
//

import Foundation
import SwiftUI
import PDFKit

// MARK: - PDF Selection Support Model

struct PDFSelectionInfo: Identifiable {
    let id: UUID
    let selection: PDFSelection
    let text: String
    let timestamp: Date
}

// MARK: - Undo/Redo Support Models

enum HighlightOperation {
    case add(PDFHighlight)
    case remove(PDFHighlight)
    case update(old: PDFHighlight, new: PDFHighlight)
    case batch([HighlightOperation])
}

enum HighlightBatchOperation {
    case add(PDFHighlight)
    case remove(PDFHighlight)
}

// MARK: - App State Management

@MainActor
@Observable
final class AppState {
    // Document state
    var selectedDocument: Document?
    
    // UI state
    var showingChat = true
    var showingSidebar = true
    var showingImporter = false
    
    // Document import
    var pendingDocumentImport = false
    
    // Documents to add to chat
    var documentToAddToChat: Document?
    
    // MARK: - PDF to Chat Feature State
    var pdfSelections: [PDFSelectionInfo] = []
    var isReadyForChatTransition: Bool = false
    var shouldFocusChatInput: Bool = false // Simple focus trigger
    var showPDFSelectionPills: Bool = false // Controls when to show selection pills
    var pendingTypedCharacter: String? = nil // NEW: Store the initial typed character
    
    // MARK: - PDF Navigation
    var pendingPageNavigation: Int?
    
    // Methods for state management
    func selectDocument(_ document: Document?) {
        withAnimation(DesignSystem.Animation.smooth) {
            selectedDocument = document
        }
    }
    
    func toggleChatPanel() {
        withAnimation(DesignSystem.Animation.smooth) {
            showingChat.toggle()
        }
    }
    
    func toggleSidebar() {
        withAnimation(DesignSystem.Animation.smooth) {
            showingSidebar.toggle()
        }
    }
    
    func requestDocumentImport() {
        showingImporter = true
    }
    
    func addDocumentToChat(_ document: Document) {
        documentToAddToChat = document
    }
    
    // MARK: - Highlighting State Management
    var highlightingState = HighlightingState()
    var highlights: [UUID: PDFHighlight] = [:]
    
    // Undo/Redo functionality
    private var undoStack: [HighlightOperation] = []
    private var redoStack: [HighlightOperation] = []
    private let maxUndoStackSize = 50
    
    func setHighlightingMode(_ mode: HighlightingMode) {
        highlightingState.mode = mode
        print("🎨 Highlighting mode: \(mode)")
    }
    
    func setHighlightingColor(_ color: HighlightColor) {
        highlightingState.setColor(color)
        print("🎨 Highlighting color: \(color)")
    }
    
    func addHighlight(_ highlight: PDFHighlight) {
        highlights[highlight.id] = highlight
        recordUndoOperation(.add(highlight))
    }
    
    func removeHighlight(_ highlight: PDFHighlight) {
        highlights.removeValue(forKey: highlight.id)
        recordUndoOperation(.remove(highlight))
    }
    
    func updateHighlight(_ oldHighlight: PDFHighlight, with newHighlight: PDFHighlight) {
        highlights.removeValue(forKey: oldHighlight.id)
        highlights[newHighlight.id] = newHighlight
        recordUndoOperation(.update(old: oldHighlight, new: newHighlight))
    }
    
    func getHighlights(for documentURL: URL) -> [PDFHighlight] {
        return highlights.values.filter { $0.documentURL == documentURL }
    }
    
    // Batch operations for complex highlight changes
    func performHighlightBatch(_ operations: [HighlightBatchOperation]) {
        var undoOperations: [HighlightOperation] = []
        
        for operation in operations {
            switch operation {
            case .add(let highlight):
                highlights[highlight.id] = highlight
                undoOperations.append(.remove(highlight))
            case .remove(let highlight):
                highlights.removeValue(forKey: highlight.id)
                undoOperations.append(.add(highlight))
            }
        }
        
        // Record the batch as a single undo operation
        recordUndoOperation(.batch(undoOperations.reversed()))
    }
    
    // Undo/Redo implementation
    func performUndo() {
        guard let operation = undoStack.popLast() else {
            print("📚 Nothing to undo")
            return
        }
        
        // Apply the reverse operation with PDF document integration
        Task { @MainActor in
            let redoOperation = await applyReverseOperationWithPDF(operation)
            redoStack.append(redoOperation)
            print("↩️ Undo applied")
        }
    }
    
    func performRedo() {
        guard let operation = redoStack.popLast() else {
            print("📚 Nothing to redo")
            return
        }
        
        // Apply the operation with PDF document integration
        Task { @MainActor in
            let undoOperation = await applyReverseOperationWithPDF(operation)
            undoStack.append(undoOperation)
            print("↪️ Redo applied")
        }
    }
    
    private func recordUndoOperation(_ operation: HighlightOperation) {
        undoStack.append(operation)
        
        // Limit stack size
        if undoStack.count > maxUndoStackSize {
            undoStack.removeFirst()
        }
        
        // Clear redo stack when new operation is performed
        redoStack.removeAll()
    }
    
    private func applyReverseOperation(_ operation: HighlightOperation) -> HighlightOperation {
        switch operation {
        case .add(let highlight):
            highlights.removeValue(forKey: highlight.id)
            return .remove(highlight)
            
        case .remove(let highlight):
            highlights[highlight.id] = highlight
            return .add(highlight)
            
        case .update(let old, let new):
            highlights.removeValue(forKey: new.id)
            highlights[old.id] = old
            return .update(old: new, new: old)
            
        case .batch(let operations):
            var reverseOps: [HighlightOperation] = []
            for op in operations.reversed() {
                reverseOps.append(applyReverseOperation(op))
            }
            return .batch(reverseOps)
        }
    }
    
    private func applyReverseOperationWithPDF(_ operation: HighlightOperation) async -> HighlightOperation {
        let toolbarService = ServiceContainer.shared.toolbarService
        
        switch operation {
        case .add(let highlight):
            // Remove highlight from memory
            highlights.removeValue(forKey: highlight.id)
            
            // Remove from PDF document if we have access to it
            if let document = getCurrentPDFDocument() {
                do {
                    try await toolbarService.removeHighlight(highlight, from: document)
                    print("🗑️ Removed highlight from PDF during undo: '\(highlight.text.prefix(30))...'")
                } catch {
                    print("❌ Failed to remove highlight from PDF during undo: \(error)")
                }
            }
            
            return .remove(highlight)
            
        case .remove(let highlight):
            // Add highlight back to memory
            highlights[highlight.id] = highlight
            
            // Re-add to PDF document if we have access to it
            if let document = getCurrentPDFDocument() {
                do {
                    // Create a selection for the highlight and re-apply it
                    _ = try await toolbarService.applyHighlight(
                        color: highlight.color,
                        to: createSelectionForHighlight(highlight, in: document),
                        in: document,
                        documentURL: highlight.documentURL
                    )
                    print("✅ Re-added highlight to PDF during redo: '\(highlight.text.prefix(30))...'")
                } catch {
                    print("❌ Failed to re-add highlight to PDF during redo: \(error)")
                }
            }
            
            return .add(highlight)
            
        case .update(let old, let new):
            // Remove new highlight and restore old one
            highlights.removeValue(forKey: new.id)
            highlights[old.id] = old
            
            if let document = getCurrentPDFDocument() {
                do {
                    // Remove new highlight and re-apply old one
                    try await toolbarService.removeHighlight(new, from: document)
                    _ = try await toolbarService.applyHighlight(
                        color: old.color,
                        to: createSelectionForHighlight(old, in: document),
                        in: document,
                        documentURL: old.documentURL
                    )
                    print("🔄 Updated highlight in PDF during undo")
                } catch {
                    print("❌ Failed to update highlight in PDF during undo: \(error)")
                }
            }
            
            return .update(old: new, new: old)
            
        case .batch(let operations):
            var reverseOps: [HighlightOperation] = []
            for op in operations.reversed() {
                let reverseOp = await applyReverseOperationWithPDF(op)
                reverseOps.append(reverseOp)
            }
            return .batch(reverseOps)
        }
    }
    
    private func saveCurrentDocumentHighlights() async {
        guard let document = selectedDocument else { return }
        
        // This would trigger the PDF service to save highlights
        // Implementation depends on how highlights are persisted
        print("💾 Saving highlights after undo/redo operation")
    }
    
    // Helper methods for PDF integration
    private func getCurrentPDFDocument() -> PDFDocument? {
        guard let document = selectedDocument else { 
            print("⚠️ No selected document for undo/redo operation")
            return nil 
        }
        
        // Try to load the PDF document
        do {
            let pdfDocument = PDFDocument(url: document.filePath)
            return pdfDocument
        } catch {
            print("❌ Failed to load PDF document for undo/redo: \(error)")
            return nil
        }
    }
    
    private func createSelectionForHighlight(_ highlight: PDFHighlight, in document: PDFDocument) -> PDFSelection {
        // Create a selection based on the highlight's stored information
        guard let page = document.page(at: highlight.pageIndex) else {
            print("⚠️ Could not find page \(highlight.pageIndex) for highlight")
            return PDFSelection(document: document)
        }
        
        // Try to find a selection that matches the highlight text and bounds
        let fullPageSelection = page.selection(for: page.bounds(for: .mediaBox))
        guard let pageText = fullPageSelection?.string else {
            print("⚠️ Could not get page text for highlight reconstruction")
            return PDFSelection(document: document)
        }
        
        // Find the text in the page and create a selection for it
        let highlightText = highlight.text
        if let range = pageText.range(of: highlightText) {
            // Convert string range to character indices
            let startIndex = pageText.distance(from: pageText.startIndex, to: range.lowerBound)
            let endIndex = pageText.distance(from: pageText.startIndex, to: range.upperBound)
            
            // Use PDFKit's native selection creation from character range
            let startBounds = page.characterBounds(at: startIndex)
            let endBounds = page.characterBounds(at: endIndex - 1)
            
            // Extract points from the character bounds (use the center-left for start, center-right for end)
            let startPoint = CGPoint(x: startBounds.minX, y: startBounds.midY)
            let endPoint = CGPoint(x: endBounds.maxX, y: endBounds.midY)
            
            if let selection = page.selection(from: startPoint, to: endPoint) {
                return selection
            }
        }
        
        // Fallback: create selection from stored bounds
        print("⚠️ Using fallback bounds-based selection for highlight")
        return page.selection(for: highlight.bounds) ?? PDFSelection(document: document)
    }

    // MARK: - PDF-to-Chat Coordination Methods
    
    func addPDFSelection(_ selection: PDFSelection, selectionId: UUID = UUID()) {
        let selectionInfo = PDFSelectionInfo(
            id: selectionId,
            selection: selection,
            text: selection.string ?? "",
            timestamp: Date()
        )
        pdfSelections.append(selectionInfo)
        updateChatTransitionState()
        // Don't show pills yet - wait for user to start typing
    }
    
    func removePDFSelection(withId id: UUID) {
        pdfSelections.removeAll { $0.id == id }
        updateChatTransitionState()
        
        // Hide pills if no selections remain
        if pdfSelections.isEmpty {
            showPDFSelectionPills = false
        }
    }
    
    func clearAllPDFSelections() {
        pdfSelections.removeAll()
        isReadyForChatTransition = false
        showPDFSelectionPills = false
        pendingTypedCharacter = nil // Clear pending character
    }
    
    private func updateChatTransitionState() {
        isReadyForChatTransition = !pdfSelections.isEmpty
    }
    
    func formatSelectionsForMessage() -> String? {
        guard !pdfSelections.isEmpty else { return nil }
        
        let sortedSelections = pdfSelections.sorted { $0.timestamp < $1.timestamp }
        let quotedTexts = sortedSelections.map { "> \($0.text)" }
        return quotedTexts.joined(separator: "\n\n") + "\n\n"
    }
    
    func triggerChatFocus(withCharacter character: String) {
        shouldFocusChatInput = true
        pendingTypedCharacter = character // Store the typed character
        // Show pills when user starts typing
        if !pdfSelections.isEmpty {
            showPDFSelectionPills = true
        }
    }
    
    func navigateToPDFPage(_ pageNumber: Int) {
        print("📖 Requesting navigation to page \(pageNumber)")
        pendingPageNavigation = pageNumber
        
        // Post notification for PDFViewCoordinator to handle
        NotificationCenter.default.post(
            name: NSNotification.Name("NavigateToPDFPage"), 
            object: nil, 
            userInfo: ["pageNumber": pageNumber]
        )
    }
    
    func navigateToSelectionBounds(bounds: [CGRect], onPage pageNumber: Int) {
        print("🎯 Requesting navigation to selection bounds on page \(pageNumber)")
        
        // Post notification for PDFViewCoordinator to handle precise bounds navigation
        NotificationCenter.default.post(
            name: NSNotification.Name("NavigateToSelectionBounds"),
            object: nil,
            userInfo: [
                "bounds": bounds,
                "pageNumber": pageNumber
            ]
        )
    }
    
    func clearPendingNavigation() {
        pendingPageNavigation = nil
    }
} 