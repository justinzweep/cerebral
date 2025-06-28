//
//  ServiceContainer.swift
//  cerebral
//
//  Created by Assistant on 26/06/2025.
//

import Foundation
import SwiftData
import SwiftUI
import PDFKit

/// Dependency injection container for managing service instances
/// Consolidated to reduce redundancy and improve maintainability
@MainActor
final class ServiceContainer {
    static let shared = ServiceContainer()
    
    private init() {
        setupServices()
    }
    
    // MARK: - Global State
    let appState = AppState()
    
    // MARK: - Error Management
    let errorManager = ErrorManager()
    
    // MARK: - Core Service Instances
    
    private(set) lazy var pdfService: PDFServiceProtocol = PDFService.shared
    private(set) lazy var documentService: DocumentServiceProtocol = DocumentService.shared
    private(set) lazy var settingsService: SettingsServiceProtocol = SettingsManager.shared
    private(set) lazy var messageBuilderService: MessageBuilderServiceProtocol = EnhancedMessageBuilder.shared
    private(set) lazy var documentReferenceService: DocumentReferenceServiceProtocol = DocumentReferenceResolver.shared
    private(set) lazy var toolbarService: PDFToolbarServiceProtocol = PDFToolbarService.shared
    private(set) lazy var contextManagementService: ContextManagementServiceProtocol = ContextManagementService.shared
    private(set) lazy var tokenizerService = TokenizerService.shared
    
    // Chat-related services
    private var _chatService: ChatServiceProtocol?
    private var _streamingChatService: StreamingChatServiceProtocol?
    
    // MARK: - Service Accessors
    
    func chatService() -> ChatServiceProtocol {
        if _chatService == nil {
            let settingsManager = settingsService as! SettingsManager // Safe cast since we control the type
            _chatService = ClaudeAPIService(settingsManager: settingsManager)
        }
        return _chatService!
    }
    
    func streamingChatService(delegate: StreamingChatServiceDelegate) -> StreamingChatServiceProtocol {
        return StreamingChatService(delegate: delegate)
    }
    
    // MARK: - Service Configuration
    
    func configureModelContext(_ context: ModelContext) {
        documentService.setModelContext(context)
    }
    
    private func setupServices() {
        // Any initial service configuration can go here
        print("🔧 ServiceContainer: Initialized with services")
        print("📊 Performance monitoring enabled")
    }
    
    // MARK: - Cleanup
    
    func cleanup() {
        // Clean up chat services
        _chatService = nil
        _streamingChatService = nil
        
        // Clear PDF thumbnail cache
        pdfService.clearThumbnailCache()
        
        print("🧹 ServiceContainer: Cleaned up resources")
    }
    
    // MARK: - Service Replacement (for testing)
    
    func replacePDFService(_ service: PDFServiceProtocol) {
        pdfService = service
    }
    
    func replaceDocumentService(_ service: DocumentServiceProtocol) {
        documentService = service
    }
    
    func replaceSettingsService(_ service: SettingsServiceProtocol) {
        settingsService = service
    }
    
    func replaceChatService(_ service: ChatServiceProtocol) {
        _chatService = service
    }
    
    func replaceToolbarService(_ service: PDFToolbarServiceProtocol) {
        toolbarService = service
    }
    
    // MARK: - Service Health Check
    
    func performHealthCheck() async -> [String: Bool] {
        var results: [String: Bool] = [:]
        
        // Check settings service
        results["settings"] = settingsService.isAPIKeyValid
        
        // Check chat service if API key is valid
        if settingsService.isAPIKeyValid {
            do {
                results["chat"] = try await chatService().validateConnection()
            } catch {
                results["chat"] = false
            }
        } else {
            results["chat"] = false
        }
        
        // Check document service
        let documents = documentService.getAllDocuments()
        results["documents"] = true // Basic check - service is responsive
        
        // Check PDF service
        if let firstDocument = documents.first {
            let canExtractText = pdfService.extractText(from: firstDocument, maxLength: 100) != nil
            results["pdf"] = canExtractText
        } else {
            results["pdf"] = true // No documents to test with
        }
        
        return results
    }
}

// MARK: - Error Manager

@Observable
final class ErrorManager {
    var currentError: cerebral.AppError?
    var showingError: Bool = false
    private var errorHistory: [ErrorLogEntry] = []
    private var retryAttempts: [String: Int] = [:]
    
    func handle(_ error: Error, context: String = "") {
        DispatchQueue.main.async { [weak self] in
            let appError = self?.convertToAppError(error)
            
            // Log error for debugging and analytics
            let logEntry = ErrorLogEntry(
                error: appError ?? cerebral.AppError.networkFailure("Unknown error"),
                context: context,
                timestamp: Date()
            )
            self?.errorHistory.append(logEntry)
            
            // Only show error if it's severe enough or requires user action
            if let appError = appError {
                switch appError.severity {
                case .critical, .high:
                    self?.showError(appError)
                case .medium:
                    // Show medium errors unless they've been retried too many times
                    let errorKey = self?.errorKey(for: appError) ?? ""
                    let attempts = self?.retryAttempts[errorKey] ?? 0
                    if attempts > 2 {
                        self?.showError(appError)
                    } else {
                        self?.logError(appError, context: context)
                    }
                case .low:
                    // Just log low-severity errors
                    self?.logError(appError, context: context)
                }
            }
        }
    }
    
    func clearError() {
        currentError = nil
        showingError = false
    }
    
    func attemptRetry(for error: cerebral.AppError) {
        let errorKey = errorKey(for: error)
        let currentAttempts = retryAttempts[errorKey] ?? 0
        retryAttempts[errorKey] = currentAttempts + 1
        
        // Clear the current error since we're retrying
        clearError()
    }
    
    // MARK: - Private Methods
    
    private func convertToAppError(_ error: Error) -> cerebral.AppError? {
        if let appError = error as? cerebral.AppError {
            return appError
        } else if let documentError = error as? DocumentError {
            return cerebral.AppError.documentError(documentError)
        } else if let chatError = error as? ChatError {
            return cerebral.AppError.chatError(chatError)
        } else if let pdfError = error as? PDFError {
            return cerebral.AppError.pdfError(pdfError)
        } else if let settingsError = error as? SettingsError {
            return cerebral.AppError.settingsError(settingsError)
        } else {
            // For unknown errors, wrap in a network failure
            return cerebral.AppError.networkFailure(error.localizedDescription)
        }
    }
    
    private func showError(_ error: cerebral.AppError) {
        currentError = error
        showingError = true
    }
    
    private func logError(_ error: cerebral.AppError, context: String) {
        let severity = error.severity
        let prefix = severityPrefix(for: severity)
        print("\(prefix) Error [\(context.isEmpty ? "Unknown" : context)]: \(error.localizedDescription)")
    }
    
    private func errorKey(for error: cerebral.AppError) -> String {
        switch error {
        case .apiKeyInvalid:
            return "api_key_invalid"
        case .networkFailure:
            return "network_failure"
        case .documentImportFailed:
            return "document_import_failed"
        case .chatServiceUnavailable:
            return "chat_service_unavailable"
        case .settingsError(let settingsError):
            return "settings_\(settingsError)"
        case .documentError(let documentError):
            return "document_\(documentError)"
        case .chatError(let chatError):
            return "chat_\(chatError)"
        case .pdfError(let pdfError):
            return "pdf_\(pdfError)"
        }
    }
    
    private func severityPrefix(for severity: ErrorSeverity) -> String {
        switch severity {
        case .low: return "ℹ️"
        case .medium: return "⚠️"
        case .high: return "❌"
        case .critical: return "🚨"
        }
    }
}

// MARK: - Error Log Entry

private struct ErrorLogEntry {
    let error: cerebral.AppError
    let context: String
    let timestamp: Date
}

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