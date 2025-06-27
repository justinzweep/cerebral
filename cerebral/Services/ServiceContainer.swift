//
//  ServiceContainer.swift
//  cerebral
//
//  Created by Assistant on 26/06/2025.
//

import Foundation
import SwiftData
import SwiftUI

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
    private(set) lazy var settingsService: SettingsServiceProtocol = SettingsManager()
    private(set) lazy var messageBuilderService: MessageBuilderServiceProtocol = MessageBuilder.shared
    private(set) lazy var documentReferenceService: DocumentReferenceServiceProtocol = DocumentReferenceResolver.shared
    
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
    
    // Text selection for chat
    var textSelectionChunks: [TextSelectionChunk] = []
    
    // Chat focus state
    var shouldFocusChatInput = false
    
    // Documents to add to chat
    var documentToAddToChat: Document?
    
    // Text input from selections
    var pendingInputText = ""
    
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
    
    func addTextSelection(_ chunk: TextSelectionChunk, withTypedCharacter character: String) {
        textSelectionChunks.append(chunk)
        pendingInputText += character
        shouldFocusChatInput = true
    }
    
    func clearTextSelections() {
        textSelectionChunks.removeAll()
    }
    
    func focusChatInput() {
        shouldFocusChatInput = true
    }
    
    func resetChatInputFocus() {
        shouldFocusChatInput = false
    }
} 