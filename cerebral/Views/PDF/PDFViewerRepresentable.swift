//
//  PDFViewerRepresentable.swift
//  cerebral
//
//  Created by Justin Zweep on 26/06/2025.
//

import SwiftUI
import PDFKit

struct PDFViewerRepresentable: NSViewRepresentable {
    let document: PDFDocument?
    @Binding var currentPage: Int
    @Binding var coordinator: PDFViewCoordinator?
    
    func makeNSView(context: Context) -> PDFView {
        let pdfView = PDFView()
        
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
        
        return pdfView
    }
    
    func updateNSView(_ nsView: PDFView, context: Context) {
        // Update document if changed
        if nsView.document !== document {
            nsView.document = document
            
            // Reset to first page when loading new document
            if let document = document, document.pageCount > 0 {
                nsView.go(to: document.page(at: 0)!)
                currentPage = 0
            }
        }
        
        // Ensure coordinator has reference to PDFView
        context.coordinator.pdfView = nsView
        
        // Always update coordinator reference
        DispatchQueue.main.async {
            coordinator = context.coordinator
        }
    }
    
    @MainActor func makeCoordinator() -> PDFViewCoordinator {
        return PDFViewCoordinator()
    }
    
    static func dismantleNSView(_ nsView: PDFView, coordinator: PDFViewCoordinator) {
        // Clean up all notifications for this specific PDFView instance
        NotificationCenter.default.removeObserver(coordinator, name: .PDFViewPageChanged, object: nsView)
    }
}

// MARK: - Coordinator

@MainActor
class PDFViewCoordinator: NSObject, PDFViewDelegate, ObservableObject {
    weak var pdfView: PDFView?
    
    // Multiple selection management for chat integration
    private var currentSelections: [UUID: PDFSelection] = [:]
    private var appState = ServiceContainer.shared.appState
    
    // Toolbar integration
    private var toolbarService = ServiceContainer.shared.toolbarService
    
    // Store a strong reference to prevent deallocation
    @MainActor static var sharedCoordinator: PDFViewCoordinator?
    
    override init() {
        super.init()
        
        // Keep a strong reference
        PDFViewCoordinator.sharedCoordinator = self
        print("📋 PDFViewCoordinator initialized")
        
        // Listen for selection changes
        NotificationCenter.default.addObserver(
            forName: .PDFViewSelectionChanged,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self,
                  let pdfView = notification.object as? PDFView else { return }
            self.handleSelectionChanged(pdfView: pdfView)
        }
    }
    
    // MARK: - Performance Optimized Debouncing
    
    nonisolated(unsafe) private var _selectionDebounceTimer: Timer?
    
    private var selectionDebounceTimer: Timer? {
        get { _selectionDebounceTimer }
        set {
            _selectionDebounceTimer?.invalidate()
            _selectionDebounceTimer = newValue
        }
    }
    
    func handleSelectionChanged(pdfView: PDFView) {
        // Cancel previous timer to debounce rapid selection changes
        selectionDebounceTimer?.invalidate()
        
        // Use shorter debounce for toolbar responsiveness
        selectionDebounceTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { [weak self] timer in
            defer { timer.invalidate() } // Ensure timer cleanup
            
            guard let self = self else { return }
            
            guard let selection = pdfView.currentSelection,
                  let selectionString = selection.string,
                  !selectionString.isEmpty,
                  selectionString.count > 1 else { // Ignore single character selections
                // No meaningful selection - already on MainActor
                self.clearMultipleSelections()
                self.appState.hideToolbar()
                return
            }
            
            print("📝 Final selection: '\(selectionString.prefix(50))...'")
            
            // Already on MainActor, no need for DispatchQueue.main.async
            // Check for Cmd key to add to multiple selections
            let currentEvent = NSApp.currentEvent
            if currentEvent?.modifierFlags.contains(.command) == true {
                // Add to multiple selections for chat
                self.addToMultipleSelections(selection)
                // Don't show toolbar for multi-selection mode
                self.appState.hideToolbar()
            } else {
                // Single selection - handle both chat and toolbar
                self.handleSingleSelection(selection)
                
                // Show toolbar for highlighting if selection is valid
                if selection.isValidForHighlighting {
                    self.showToolbarForSelection(selection, in: pdfView)
                }
            }
        }
    }
    
    // Multiple selection handling
    private func addToMultipleSelections(_ selection: PDFSelection) {
        let selectionId = UUID()
        currentSelections[selectionId] = selection
        
        // Add to AppState for coordination with chat
        appState.addPDFSelection(selection, selectionId: selectionId)
    }
    
    // Single selection handling
    private func handleSingleSelection(_ selection: PDFSelection) {
        // Clear previous multiple selections
        clearMultipleSelections()
        
        // Add current selection to AppState
        let selectionId = UUID()
        currentSelections[selectionId] = selection
        appState.addPDFSelection(selection, selectionId: selectionId)
    }
    
    // Clear multiple selections
    func clearMultipleSelections() {
        currentSelections.removeAll()
        appState.clearAllPDFSelections()
    }
    
    // Remove specific selection (for Cmd+click removal)
    func removeSelection(withId id: UUID) {
        currentSelections.removeValue(forKey: id)
        appState.removePDFSelection(withId: id)
    }
    
    // MARK: - Toolbar Integration
    
    private func showToolbarForSelection(_ selection: PDFSelection, in pdfView: PDFView) {
        // Calculate toolbar position
        let position = toolbarService.calculateToolbarPosition(for: selection, in: pdfView)
        
        // Check for existing highlight at selection
        let existingHighlight = findExistingHighlight(for: selection, in: pdfView)
        
        // Show toolbar
        appState.showToolbar(at: position, for: selection, existingHighlight: existingHighlight)
    }
    
    private func findExistingHighlight(for selection: PDFSelection, in pdfView: PDFView) -> PDFHighlight? {
        guard let document = pdfView.document else { return nil }
        
        return toolbarService.findExistingHighlight(for: selection, in: document)
    }
    
    // Cleanup method to prevent memory leaks
    func cleanup() {
        selectionDebounceTimer = nil
    }
    
    deinit {
        // Handle cleanup safely from deinit using nonisolated storage
        _selectionDebounceTimer?.invalidate()
        NotificationCenter.default.removeObserver(self)
    }
}

#Preview {
    PDFViewerRepresentable(
        document: nil,
        currentPage: .constant(0),
        coordinator: .constant(nil)
    )
} 
