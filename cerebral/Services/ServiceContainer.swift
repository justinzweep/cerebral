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
/// Simplified to focus on service coordination and dependency management
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
    
    let pdfService: PDFServiceProtocol = PDFService.shared
    let documentService: DocumentServiceProtocol = DocumentService.shared
    let settingsService: SettingsServiceProtocol = SettingsManager.shared
    let messageBuilderService: MessageBuilderServiceProtocol = EnhancedMessageBuilder.shared
    let documentReferenceService: DocumentReferenceServiceProtocol = DocumentReferenceResolver.shared
    let toolbarService: PDFToolbarServiceProtocol = PDFToolbarService.shared
    let contextManagementService: ContextManagementServiceProtocol = ContextManagementService.shared
    let tokenizerService = TokenizerService.shared
    
    // Chat-related services (created on demand)
    private var _chatService: ChatServiceProtocol?
    private var _streamingChatService: StreamingChatServiceProtocol?
    
    // MARK: - Service Accessors
    
    func chatService() -> ChatServiceProtocol {
        if _chatService == nil {
            let settingsManager = settingsService as! SettingsManager
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
        // Configure TokenizerService with SettingsManager for API access
        let settingsManager = settingsService as! SettingsManager
        tokenizerService.configure(with: settingsManager)
        
        print("🔧 ServiceContainer: Initialized with services")
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