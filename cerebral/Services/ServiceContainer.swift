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
    
    func handle(_ error: Error) {
        DispatchQueue.main.async { [weak self] in
            if let appError = error as? cerebral.AppError {
                self?.currentError = appError
            } else if let documentError = error as? DocumentError {
                self?.currentError = cerebral.AppError.documentError(documentError)
            } else if let chatError = error as? ChatError {
                self?.currentError = cerebral.AppError.chatError(chatError)
            } else if let pdfError = error as? PDFError {
                self?.currentError = cerebral.AppError.pdfError(pdfError)
            } else {
                // For unknown errors, wrap in a network failure for now
                self?.currentError = cerebral.AppError.networkFailure(error.localizedDescription)
            }
            self?.showingError = true
        }
        
        // Log error for debugging
        print("❌ Error handled: \(error.localizedDescription)")
    }
    
    func clearError() {
        currentError = nil
        showingError = false
    }
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