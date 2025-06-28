//
//  ServiceProtocols.swift
//  cerebral
//
//  Created by Assistant on 26/06/2025.
//

import Foundation
import SwiftData
import AppKit

// MARK: - Chat Service Protocol

protocol ChatServiceProtocol {
    func sendStreamingMessage(_ text: String, context: [Document], conversationHistory: [ChatMessage]) -> AsyncThrowingStream<StreamingResponse, Error>
}

// MARK: - PDF Service Protocol

protocol PDFServiceProtocol {
    func extractText(from document: Document, maxLength: Int) -> String?
    func extractTextFromPage(document: Document, pageIndex: Int) -> String?
    func getDocumentMetadata(from document: Document) -> [String: Any]?
    func generateThumbnail(for document: Document, size: CGSize) -> NSImage?
    func clearThumbnailCache()
    func validatePDF(at url: URL) throws
}

// MARK: - Document Service Protocol

protocol DocumentServiceProtocol {
    func setModelContext(_ context: ModelContext)
    func importDocument(from url: URL, to modelContext: ModelContext) async throws -> Document
    func importDocuments(_ result: Result<[URL], Error>, to modelContext: ModelContext) async throws
    func findDocument(byName name: String) -> Document?
    func findDocument(byId id: UUID) -> Document?
    func findDocuments(matching pattern: String) -> [Document]
    func getAllDocuments() -> [Document]
    func deleteDocument(_ document: Document, from modelContext: ModelContext) throws
}

// MARK: - Settings Service Protocol

@MainActor
protocol SettingsServiceProtocol {
    var apiKey: String { get set }
    func saveAPIKey(_ key: String) throws
    func deleteAPIKey() throws
    func loadAPIKey()
}

// MARK: - Streaming Chat Service Protocol

protocol StreamingChatServiceProtocol {
    @MainActor
    func sendStreamingMessage(
        _ text: String,
        settingsManager: SettingsManager,
        documentContext: [Document],
        conversationHistory: [ChatMessage],
        contexts: [DocumentContext]
    ) async
    
    func cancelCurrentStreaming()
}

// MARK: - Document Reference Service Protocol

@MainActor
protocol DocumentReferenceServiceProtocol {
    func extractDocumentReferences(from text: String) -> [Document]
    func getDocumentUUIDs(from documents: [Document]) -> [UUID]
    func combineUniqueDocuments(_ documentArrays: [Document]...) -> [Document]
}

// MARK: - Message Builder Service Protocol

@MainActor
protocol MessageBuilderServiceProtocol {
    func buildMessage(
        userInput: String,
        documents: [Document]
    ) -> String
    func extractDocumentContext(from documents: [Document]) -> String
    func formatMessageWithContext(
        userInput: String,
        documentContext: String
    ) -> String
} 