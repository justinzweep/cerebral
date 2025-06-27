//
//  PDFViewerRepresentable.swift
//  cerebral
//
//  Created by Justin Zweep on 26/06/2025.
//

import SwiftUI
import PDFKit

// Custom PDFView that handles keyboard events
class KeyboardHandlingPDFView: PDFView {
    weak var coordinator: PDFViewCoordinator?
    
    override func keyDown(with event: NSEvent) {
        // Check if we have a text selection and a printable character was typed
        if let selection = currentSelection,
           let selectionText = selection.string,
           !selectionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
           selectionText.count > 1,
           event.characters?.isEmpty == false,
           let characters = event.characters,
           characters.rangeOfCharacter(from: CharacterSet.controlCharacters) == nil {
            
            // We have a valid selection and user is typing - trigger the flow
            coordinator?.handleTypingWithSelection(selection: selection, typedCharacter: characters)
            return
        }
        
        // Otherwise, handle the key event normally
        super.keyDown(with: event)
    }
    
    override var acceptsFirstResponder: Bool {
        return true
    }
}

struct PDFViewerRepresentable: NSViewRepresentable {
    let document: PDFDocument?
    @Binding var currentPage: Int
    @Binding var selectedText: PDFSelection?
    @Binding var showHighlightPopup: Bool
    @Binding var highlightPopupPosition: CGPoint
    @Binding var coordinator: PDFViewCoordinator?
    
    func makeNSView(context: Context) -> KeyboardHandlingPDFView {
        let pdfView = KeyboardHandlingPDFView()
        
        // Configure PDF view with enhanced settings
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displaysPageBreaks = true
        pdfView.displayBox = .mediaBox
        pdfView.interpolationQuality = .high
        
        // Enhanced appearance
        pdfView.backgroundColor = NSColor.controlBackgroundColor
        
        // Set document view background using layer approach
        if let documentView = pdfView.documentView {
            documentView.wantsLayer = true
            documentView.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        }
        
        // Set up delegate for handling selections
        pdfView.delegate = context.coordinator
        pdfView.coordinator = context.coordinator
        context.coordinator.pdfView = pdfView
        
        // Set up notifications with better handling
        NotificationCenter.default.addObserver(
            forName: .PDFViewPageChanged,
            object: pdfView,
            queue: .main
        ) { [weak pdfView] _ in
            guard let pdfView = pdfView,
                  let page = pdfView.currentPage,
                  let pageIndex = pdfView.document?.index(for: page) else { return }
            currentPage = pageIndex
        }
        
        // Listen for selection changes
        NotificationCenter.default.addObserver(
            forName: .PDFViewSelectionChanged,
            object: pdfView,
            queue: nil  // Use nil to avoid main queue issues
        ) { [weak coordinator = context.coordinator] notification in
            guard let coordinator = coordinator,
                  let pdfView = notification.object as? PDFView else { return }
            coordinator.handleSelectionChanged(pdfView: pdfView)
        }
        
        return pdfView
    }
    
    func updateNSView(_ nsView: KeyboardHandlingPDFView, context: Context) {
        // Update document if changed
        if nsView.document !== document {
            nsView.document = document
            
            // Reset to first page when loading new document
            if let document = document, document.pageCount > 0 {
                nsView.go(to: document.page(at: 0)!)
                currentPage = 0
            }
        }
        
        // Update coordinator bindings
        context.coordinator.updateBindings(
            selectedText: $selectedText,
            showHighlightPopup: $showHighlightPopup,
            highlightPopupPosition: $highlightPopupPosition
        )
        
        // Ensure coordinator has reference to PDFView
        nsView.coordinator = context.coordinator
        context.coordinator.pdfView = nsView
        
        // Always update coordinator reference
        DispatchQueue.main.async {
            coordinator = context.coordinator
        }
    }
    
    func makeCoordinator() -> PDFViewCoordinator {
        return PDFViewCoordinator(
            selectedText: $selectedText,
            showHighlightPopup: $showHighlightPopup,
            highlightPopupPosition: $highlightPopupPosition
        )
    }
    
    static func dismantleNSView(_ nsView: KeyboardHandlingPDFView, coordinator: PDFViewCoordinator) {
        // Clean up all notifications for this specific PDFView instance
        NotificationCenter.default.removeObserver(coordinator, name: .PDFViewPageChanged, object: nsView)
        NotificationCenter.default.removeObserver(coordinator, name: .PDFViewSelectionChanged, object: nsView)
    }
}

// MARK: - Coordinator

class PDFViewCoordinator: NSObject, PDFViewDelegate, ObservableObject {
    var selectedText: Binding<PDFSelection?>
    var showHighlightPopup: Binding<Bool>
    var highlightPopupPosition: Binding<CGPoint>
    weak var pdfView: PDFView?
    
    // Store a strong reference to prevent deallocation
    static var sharedCoordinator: PDFViewCoordinator?
    
    init(selectedText: Binding<PDFSelection?>, showHighlightPopup: Binding<Bool>, highlightPopupPosition: Binding<CGPoint>) {
        self.selectedText = selectedText
        self.showHighlightPopup = showHighlightPopup
        self.highlightPopupPosition = highlightPopupPosition
        super.init()
        
        // Keep a strong reference
        PDFViewCoordinator.sharedCoordinator = self
        print("📋 PDFViewCoordinator initialized")
    }
    
    // Handle typing when text is selected
    func handleTypingWithSelection(selection: PDFSelection, typedCharacter: String) {
        guard let selectionText = selection.string,
              !selectionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        // Get the document name from the selection
        let documentName = selection.pages.first?.document?.documentURL?.deletingPathExtension().lastPathComponent ?? "Unknown Document"
        
        // Create text selection chunk
        let textChunk = TextSelectionChunk(text: selectionText, source: documentName)
        
        print("🔤 User typed '\(typedCharacter)' with selection: '\(selectionText.prefix(50))...'")
        
        // Hide highlight popup if showing
        DispatchQueue.main.async {
            self.showHighlightPopup.wrappedValue = false
            self.selectedText.wrappedValue = nil
        }
        
        // Clear the selection to prevent further typing events
        pdfView?.clearSelection()
        
        // Use AppState to handle text selection with typing
        DispatchQueue.main.async {
            ServiceContainer.shared.appState.addTextSelection(textChunk, withTypedCharacter: typedCharacter)
        }
    }
    
    func updateBindings(selectedText: Binding<PDFSelection?>, showHighlightPopup: Binding<Bool>, highlightPopupPosition: Binding<CGPoint>) {
        self.selectedText = selectedText
        self.showHighlightPopup = showHighlightPopup
        self.highlightPopupPosition = highlightPopupPosition
    }
    
    // MARK: - Performance Optimized Debouncing
    
    private var selectionDebounceTimer: Timer? {
        willSet {
            // Ensure proper cleanup of existing timer
            selectionDebounceTimer?.invalidate()
        }
    }
    
    func handleSelectionChanged(pdfView: PDFView) {
        // Cancel previous timer to debounce rapid selection changes
        selectionDebounceTimer?.invalidate()
        
        // Use weak self to prevent retain cycles
        selectionDebounceTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { [weak self] timer in
            defer { timer.invalidate() } // Ensure timer cleanup
            
            guard let self = self else { return }
            
            guard let selection = pdfView.currentSelection,
                  let selectionString = selection.string,
                  !selectionString.isEmpty,
                  selectionString.count > 1 else { // Ignore single character selections
                // No meaningful selection
                DispatchQueue.main.async { [weak self] in
                    self?.selectedText.wrappedValue = nil
                    self?.showHighlightPopup.wrappedValue = false
                }
                return
            }
            
            print("📝 Final selection: '\(selectionString.prefix(50))...'")
            
            // Update state on main queue with weak references
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                self.selectedText.wrappedValue = selection
                
                // Calculate popup position efficiently
                if let firstPage = selection.pages.first,
                   let pdfView = pdfView as? PDFView {
                    let bounds = selection.bounds(for: firstPage)
                    let convertedBounds = pdfView.convert(bounds, from: firstPage)
                    
                    // Position above the selection with safe margins
                    let popupX = convertedBounds.midX
                    let popupY = convertedBounds.minY - 10
                    
                    self.highlightPopupPosition.wrappedValue = CGPoint(x: popupX, y: popupY)
                    self.showHighlightPopup.wrappedValue = true
                } else {
                    self.showHighlightPopup.wrappedValue = false
                }
            }
        }
    }
    
    // Cleanup method to prevent memory leaks
    func cleanup() {
        selectionDebounceTimer?.invalidate()
        selectionDebounceTimer = nil
    }
    
    func addHighlight(to selection: PDFSelection, color: NSColor) {
        print("=== STARTING HIGHLIGHT PROCESS ===")
        print("Selection text: '\(selection.string?.prefix(50) ?? "nil")...'")
        
        // Get selections by line for proper highlighting
        let selections = selection.selectionsByLine()
        print("Processing \(selections.count) line selections")
        
        for (index, lineSelection) in selections.enumerated() {
            print("Processing line selection \(index + 1)")
            
            for page in lineSelection.pages {
                let bounds = lineSelection.bounds(for: page)
                print("Line \(index + 1) bounds: \(bounds)")
                
                // Create new highlight annotation - simplified approach
                let highlight = PDFAnnotation(bounds: bounds, forType: .highlight, withProperties: nil)
                highlight.color = color.withAlphaComponent(0.5) // Semi-transparent
                
                print("Created highlight:")
                print("  - Type: \(highlight.type ?? "nil")")
                print("  - Bounds: \(highlight.bounds)")
                print("  - Color: \(highlight.color)")
                
                // Add annotation to page
                page.addAnnotation(highlight)
                print("Added annotation to page. Page now has \(page.annotations.count) annotations")
                
                // Force immediate refresh
                DispatchQueue.main.async { [weak self] in
                    guard let pdfView = self?.pdfView else { return }
                    pdfView.annotationsChanged(on: page)
                    pdfView.needsDisplay = true
                    pdfView.documentView?.needsDisplay = true
                }
            }
        }
        
        print("=== HIGHLIGHT PROCESS COMPLETE ===")
        
        // Clear selection after a brief delay to ensure highlighting completes first
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.pdfView?.clearSelection()
        }
        
        // Try to save the document
        if let document = selection.pages.first?.document {
            print("Attempting to save document...")
            saveDocument(document)
        }
    }
    
    private func findExistingHighlight(on page: PDFPage, bounds: CGRect) -> PDFAnnotation? {
        return page.annotations.first { annotation in
            // Check if it's a highlight annotation and bounds overlap significantly
            annotation.type?.lowercased().contains("highlight") == true && 
            annotation.bounds.intersects(bounds)
        }
    }
    
    private func saveDocument(_ document: PDFDocument?) {
        guard let document = document else { 
            print("Cannot save document - no document")
            return 
        }
        
        guard let originalURL = document.documentURL else {
            print("Cannot save document - no original URL")
            return
        }
        
        // Check if we can write to the original location
        let fileManager = FileManager.default
        if fileManager.isWritableFile(atPath: originalURL.path) {
            // Save directly to original location
            let success = document.write(to: originalURL)
            print("Document save to original location result: \(success)")
        } else {
            // Original file is read-only (like from app bundle)
            // Try to save to the same location but this might fail
            print("Original document is read-only at: \(originalURL.path)")
            
            // For now, just try to save anyway (this will update the in-memory document)
            // The annotations will persist in the current session
            let success = document.write(to: originalURL)
            print("Attempted save to read-only location result: \(success)")
            
            // In a real app, you might want to:
            // 1. Copy the PDF to Documents folder first
            // 2. Show a "Save As" dialog
            // 3. Or just keep annotations in memory for the session
        }
    }
}

#Preview {
    PDFViewerRepresentable(
        document: nil,
        currentPage: .constant(0),
        selectedText: .constant(nil),
        showHighlightPopup: .constant(false),
        highlightPopupPosition: .constant(.zero),
        coordinator: .constant(nil)
    )
} 
