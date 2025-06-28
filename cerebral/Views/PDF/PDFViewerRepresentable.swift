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
    let documentURL: URL?
    @Binding var currentPage: Int
    @Binding var coordinator: PDFViewCoordinator?
    
    func makeNSView(context: Context) -> PDFView {
        let pdfView = HighlightRemovalPDFView()
        
        // Configure PDF view with enhanced settings
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displaysPageBreaks = true
        pdfView.displayBox = .mediaBox
        pdfView.interpolationQuality = .high
        
        // Enhanced appearance - match sidepanel background
        let backgroundColor = NSColor(DesignSystem.Colors.secondaryBackground)
        pdfView.backgroundColor = backgroundColor
        
        // Set document view background using layer approach
        if let documentView = pdfView.documentView {
            documentView.wantsLayer = true
            documentView.layer?.backgroundColor = backgroundColor.cgColor
        }
        
        // Set up delegate for handling selections
        pdfView.delegate = context.coordinator
        context.coordinator.pdfView = pdfView
        context.coordinator.documentURL = documentURL
        
        // Set up the coordinator for mouse click handling
        pdfView.clickCoordinator = context.coordinator
        
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
    var documentURL: URL?
    
    // Multiple selection management for chat integration
    private var currentSelections: [UUID: PDFSelection] = [:]
    private var appState = ServiceContainer.shared.appState
    
    // Highlighting integration
    private var toolbarService = ServiceContainer.shared.toolbarService
    
    // Store a strong reference to prevent deallocation
    @MainActor static var sharedCoordinator: PDFViewCoordinator?
    
    // MARK: - PDF State Preservation
    private struct PDFViewState {
        let scaleFactor: CGFloat
        let visibleRect: CGRect
        let currentPage: PDFPage?
        let pagePoint: CGPoint // Point on the current page that should remain visible
        let timestamp: Date
    }
    
    private var preservedState: PDFViewState?
    
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
        
        // Listen for layout change notifications
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("PDFLayoutWillChange"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.capturePDFState()
        }
        
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("PDFLayoutDidChange"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.restorePDFStateAfterDelay()
        }
        
        // Listen for PDF page navigation requests
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("NavigateToPDFPage"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self,
                  let pageNumber = notification.userInfo?["pageNumber"] as? Int else { return }
            self.navigateToPage(pageNumber)
        }
        
        // Listen for precise selection bounds navigation
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("NavigateToSelectionBounds"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self,
                  let bounds = notification.userInfo?["bounds"] as? [CGRect],
                  let pageNumber = notification.userInfo?["pageNumber"] as? Int else { return }
            self.navigateToSelectionBounds(bounds: bounds, onPage: pageNumber)
        }
    }
    
    // MARK: - PDF State Preservation Methods
    
    func capturePDFState() {
        guard let pdfView = pdfView,
              let currentPage = pdfView.currentPage else {
            print("⚠️ Cannot capture PDF state - no view or page")
            return
        }
        
        let visibleRect = pdfView.visibleRect
        let scaleFactor = pdfView.scaleFactor
        
        // Calculate the center point of the visible area in page coordinates
        let visibleCenter = CGPoint(
            x: visibleRect.midX,
            y: visibleRect.midY
        )
        let pagePoint = pdfView.convert(visibleCenter, to: currentPage)
        
        preservedState = PDFViewState(
            scaleFactor: scaleFactor,
            visibleRect: visibleRect,
            currentPage: currentPage,
            pagePoint: pagePoint,
            timestamp: Date()
        )
        
        print("📸 Captured PDF state: scale=\(scaleFactor), page=\(pdfView.document?.index(for: currentPage) ?? -1)")
    }
    
    private func restorePDFStateAfterDelay() {
        // Small delay to allow layout to settle
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.restorePDFState()
        }
    }
    
    func restorePDFState() {
        guard let pdfView = pdfView,
              let state = preservedState,
              let currentPage = state.currentPage else {
            print("⚠️ Cannot restore PDF state - no view, preserved state, or page")
            return
        }
        
        // Only restore if the state is recent (within last 2 seconds)
        guard Date().timeIntervalSince(state.timestamp) < 2.0 else {
            print("⚠️ PDF state too old, not restoring")
            preservedState = nil
            return
        }
        
        // Temporarily disable auto-scaling to prevent interference
        let originalAutoScales = pdfView.autoScales
        pdfView.autoScales = false
        
        // Restore the scale factor first
        pdfView.scaleFactor = state.scaleFactor
        
        // Convert the preserved page point back to view coordinates
        let viewPoint = pdfView.convert(state.pagePoint, from: currentPage)
        
        // Calculate where this point should be positioned (center of view)
        let targetCenter = CGPoint(
            x: pdfView.bounds.midX,
            y: pdfView.bounds.midY
        )
        
        // Calculate the scroll offset needed
        let scrollOffset = CGPoint(
            x: viewPoint.x - targetCenter.x,
            y: viewPoint.y - targetCenter.y
        )
        
        // Apply the scroll offset
        if let documentView = pdfView.documentView,
           let scrollView = documentView.enclosingScrollView {
            let currentOrigin = scrollView.contentView.bounds.origin
            let newOrigin = CGPoint(
                x: max(0, currentOrigin.x + scrollOffset.x),
                y: max(0, currentOrigin.y + scrollOffset.y)
            )
            scrollView.contentView.scroll(to: newOrigin)
        }
        
        // Restore auto-scaling setting
        pdfView.autoScales = originalAutoScales
        
        print("🎯 Restored PDF state: scale=\(state.scaleFactor)")
        
        // Clear the preserved state
        preservedState = nil
    }
    
    // MARK: - PDF Navigation
    
    func navigateToPage(_ pageNumber: Int) {
        guard let pdfView = pdfView,
              let document = pdfView.document else {
            print("❌ Cannot navigate to page - no PDF view or document")
            return
        }
        
        // Convert to 0-based index (PDF pages are typically 1-based in UI)
        let pageIndex = pageNumber - 1
        
        guard pageIndex >= 0 && pageIndex < document.pageCount else {
            print("❌ Page number \(pageNumber) is out of range (1-\(document.pageCount))")
            return
        }
        
        guard let page = document.page(at: pageIndex) else {
            print("❌ Could not get page at index \(pageIndex)")
            return
        }
        
        print("📖 Navigating to page \(pageNumber) (index \(pageIndex))")
        
        // Use PDFView's built-in navigation
        pdfView.go(to: page)
        
        // Optionally scroll to top of page
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let pageRect = pdfView.convert(page.bounds(for: .mediaBox), from: page)
            let scrollPoint = CGPoint(x: pageRect.minX, y: pageRect.maxY) // Top of page
            pdfView.scroll(scrollPoint)
        }
        
        // Clear the pending navigation in app state
        appState.clearPendingNavigation()
    }
    
    func navigateToSelectionBounds(bounds: [CGRect], onPage pageNumber: Int) {
        guard let pdfView = pdfView,
              let document = pdfView.document else {
            print("❌ Cannot navigate to selection bounds - no PDF view or document")
            return
        }
        
        // Convert to 0-based index
        let pageIndex = pageNumber - 1
        
        guard pageIndex >= 0 && pageIndex < document.pageCount,
              let page = document.page(at: pageIndex) else {
            print("❌ Invalid page number for selection navigation")
            return
        }
        
        print("📖 Navigating to page \(pageNumber) for text selection")
        
        // Simply navigate to the page where the selection is located
        pdfView.go(to: page)
    }
    

    
    // MARK: - PDFViewDelegate Methods
    
    func pdfViewWillClick(onLink sender: PDFView, with url: URL) {
        // Handle link clicks if needed
    }
    
    func pdfViewPerformFind(_ sender: PDFView) {
        // Handle find operations if needed
    }
    
    // MARK: - Mouse Event Handling for Highlight Removal
    
    func handleMouseClick(at point: CGPoint, in pdfView: PDFView, event: NSEvent) {
        // Check if Option key is held for highlight removal
        guard event.modifierFlags.contains(.option),
              let page = pdfView.page(for: point, nearest: true) else {
            return
        }
        
        // Convert view coordinates to page coordinates using PDFKit's native method
        let pagePoint = pdfView.convert(point, to: page)
        
        // Use PDFKit's native annotation detection
        if let annotation = page.annotation(at: pagePoint),
           annotation.type == "Highlight" {
            
            Task { @MainActor in
                await removeHighlightAnnotation(annotation, from: pdfView)
            }
        }
    }
    
    private func removeHighlightAnnotation(_ annotation: PDFAnnotation, from pdfView: PDFView) async {
        guard let document = pdfView.document,
              let contents = annotation.contents,
              let (color, groupID) = decodeAnnotationContents(contents) else {
            print("❌ Could not decode highlight annotation")
            return
        }
        
        do {
            // Find the highlight model that corresponds to this annotation
            if let highlight = findHighlightByGroupID(groupID, in: document) {
                
                // Remove using the existing service method
                try await toolbarService.removeHighlight(highlight, from: document)
                
                // Update app state
                appState.removeHighlight(highlight)
                
                print("🗑️ Removed highlight via Option+click")
                
            } else {
                print("⚠️ Could not find highlight model for annotation")
            }
            
        } catch {
            print("❌ Failed to remove highlight: \(error)")
            ServiceContainer.shared.errorManager.handle(error, context: "highlight_removal")
        }
    }
    
    private func findHighlightByGroupID(_ groupID: String, in document: PDFDocument) -> PDFHighlight? {
        // Search through app state highlights to find matching group ID
        for highlight in appState.highlights.values {
            // We need to find a way to match the group ID with the highlight
            // For now, we'll reconstruct the highlight from the document
            if let reconstructed = toolbarService.reconstructHighlight(groupID: groupID, in: document) {
                return reconstructed
            }
        }
        return nil
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
            } else {
                // Single selection - handle both chat and highlighting
                self.handleSingleSelection(selection)
                
                // Apply highlighting if enabled and selection is valid
                if selection.isValidForHighlighting && appState.highlightingState.isHighlightingEnabled {
                    self.applyHighlightToSelection(selection, in: pdfView)
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
    
    // MARK: - Highlighting Integration
    
    private func applyHighlightToSelection(_ selection: PDFSelection, in pdfView: PDFView) {
        guard let document = pdfView.document else { return }
        
        Task { @MainActor in
            do {
                let documentURL = getCurrentDocumentURL()
                let selectedColor = appState.highlightingState.selectedColor
                
                // Find all overlapping highlights
                let overlappingHighlights = toolbarService.findOverlappingHighlights(for: selection, in: document)
                
                if overlappingHighlights.isEmpty {
                    // No overlap - create new highlight
                    let newHighlight = try await toolbarService.applyHighlight(
                        color: selectedColor,
                        to: selection,
                        in: document,
                        documentURL: documentURL
                    )
                    appState.addHighlight(newHighlight)
                    print("🎨 Applied new \(selectedColor) highlight")
                    
                } else {
                    // Handle overlapping highlights
                    let result = try await toolbarService.handleOverlappingHighlights(
                        newSelection: selection,
                        newColor: selectedColor,
                        overlappingHighlights: overlappingHighlights,
                        in: document,
                        documentURL: documentURL
                    )
                    
                    // Update app state with the results using batch operation
                    var batchOperations: [HighlightBatchOperation] = []
                    
                    for removedHighlight in result.removedHighlights {
                        batchOperations.append(.remove(removedHighlight))
                    }
                    
                    for addedHighlight in result.addedHighlights {
                        batchOperations.append(.add(addedHighlight))
                    }
                    
                    appState.performHighlightBatch(batchOperations)
                    
                    print("🔄 Processed overlapping highlights: removed \(result.removedHighlights.count), added \(result.addedHighlights.count)")
                }
            } catch {
                print("❌ Failed to apply highlight: \(error)")
                ServiceContainer.shared.errorManager.handle(error, context: "highlight_apply")
            }
        }
    }
    
    private func getCurrentDocumentURL() -> URL {
        return documentURL ?? URL(fileURLWithPath: "")
    }
    
    // Cleanup method to prevent memory leaks
    func cleanup() {
        selectionDebounceTimer = nil
    }
    
    deinit {
        // Handle cleanup safely from deinit using nonisolated storage
        _selectionDebounceTimer?.invalidate()
        NotificationCenter.default.removeObserver(self, name: .PDFViewSelectionChanged, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name("PDFLayoutWillChange"), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name("PDFLayoutDidChange"), object: nil)
    }
}

#Preview {
    PDFViewerRepresentable(
        document: nil,
        documentURL: nil,
        currentPage: .constant(0),
        coordinator: .constant(nil)
    )
} 

// MARK: - Custom PDFView for Highlight Removal

class HighlightRemovalPDFView: PDFView {
    weak var clickCoordinator: PDFViewCoordinator?
    private var trackingArea: NSTrackingArea?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupTrackingArea()
    }
    
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        setupTrackingArea()
    }
    
    private func setupTrackingArea() {
        // Remove existing tracking area
        if let trackingArea = trackingArea {
            removeTrackingArea(trackingArea)
        }
        
        // Create new tracking area for mouse movement
        trackingArea = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .mouseMoved, .activeInKeyWindow],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(trackingArea!)
    }
    
    override func mouseMoved(with event: NSEvent) {
        super.mouseMoved(with: event)
        updateCursorForHighlightRemoval(event: event)
    }
    
    override func flagsChanged(with event: NSEvent) {
        super.flagsChanged(with: event)
        updateCursorForHighlightRemoval(event: event)
    }
    
    private func updateCursorForHighlightRemoval(event: NSEvent) {
        // Check if Option key is pressed
        if event.modifierFlags.contains(.option) {
            let locationInView = convert(event.locationInWindow, from: nil)
            
            // Check if we're over a highlight annotation
            if let page = page(for: locationInView, nearest: true) {
                let pagePoint = convert(locationInView, to: page)
                
                if let annotation = page.annotation(at: pagePoint),
                   annotation.type == "Highlight" {
                    // Show delete cursor when over highlight with Option key
                    NSCursor.disappearingItem.set()
                    return
                }
            }
        }
        
        // Reset to default cursor
        NSCursor.arrow.set()
    }
    
    override func mouseDown(with event: NSEvent) {
        // Convert event location to view coordinates
        let locationInView = self.convert(event.locationInWindow, from: nil)
        
        // Handle highlight removal if Option key is pressed
        if event.modifierFlags.contains(.option) {
            clickCoordinator?.handleMouseClick(at: locationInView, in: self, event: event)
        }
        
        // Always call super to maintain normal PDFView behavior
        super.mouseDown(with: event)
    }
    
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        setupTrackingArea()
    }
} 
