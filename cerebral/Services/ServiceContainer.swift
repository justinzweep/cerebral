//
//  ServiceContainer.swift
//  cerebral
//
//  Created by Assistant on 26/06/2025.
//

import Foundation
import SwiftData

/// Dependency injection container for managing service instances
@MainActor
final class ServiceContainer {
    static let shared = ServiceContainer()
    
    private init() {
        setupServices()
    }
    
    // MARK: - Service Instances
    
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
        
        // Update DocumentLookupService for backward compatibility
        DocumentLookupService.shared.setModelContext(context)
    }
    
    private func setupServices() {
        // Any initial service configuration can go here
        print("🔧 ServiceContainer: Initialized with services")
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
    
    // MARK: - Error Manager
    
    private(set) lazy var errorManager = ErrorManager()
}

// MARK: - Error Manager

@MainActor
@Observable
final class ErrorManager {
    var currentError: AppError?
    var showingError: Bool = false
    
    func handle(_ error: Error) {
        let appError: AppError
        
        // Convert different error types to AppError
        switch error {
        case let chatError as ChatError:
            appError = .chatError(chatError)
        case let documentError as DocumentError:
            appError = .documentError(documentError)
        case let pdfError as PDFError:
            appError = .pdfError(pdfError)
        case let settingsError as SettingsError:
            appError = .settingsError(settingsError)
        case let apiError as APIError:
            // Convert legacy APIError to ChatError
            switch apiError {
            case .noAPIKey:
                appError = .chatError(.noAPIKey)
            case .connectionFailed(let message):
                appError = .chatError(.connectionFailed(message))
            case .requestFailed(let message):
                appError = .chatError(.requestFailed(message))
            case .invalidResponse(let message):
                appError = .chatError(.invalidResponse(message))
            }
        default:
            appError = .networkFailure(error.localizedDescription)
        }
        
        currentError = appError
        showingError = true
        
        print("❌ ErrorManager: \(appError.errorDescription ?? "Unknown error")")
    }
    
    func clearError() {
        currentError = nil
        showingError = false
    }
} 