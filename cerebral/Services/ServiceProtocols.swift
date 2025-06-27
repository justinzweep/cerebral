//
//  ServiceProtocols.swift
//  cerebral
//
//  Created by Assistant on 26/06/2025.
//

import Foundation
import SwiftData

// MARK: - Chat Service Protocol

protocol ChatServiceProtocol {
    func sendMessage(_ text: String, context: [Document], conversationHistory: [ChatMessage]) async throws -> String
    func sendStreamingMessage(_ text: String, context: [Document], conversationHistory: [ChatMessage]) -> AsyncThrowingStream<StreamingResponse, Error>
    func validateConnection() async throws -> Bool
}

// MARK: - PDF Service Protocol

protocol PDFServiceProtocol {
    func extractText(from document: Document, maxLength: Int) -> String?
    func extractTextFromPage(document: Document, pageIndex: Int) -> String?
    func getDocumentMetadata(from document: Document) -> [String: Any]?
    func generateThumbnail(for document: Document, size: CGSize) -> NSImage?
    func clearThumbnailCache()
}

// MARK: - Document Service Protocol

protocol DocumentServiceProtocol {
    func importDocument(from url: URL, to modelContext: ModelContext) async throws -> Document
    func importDocuments(_ result: Result<[URL], Error>, to modelContext: ModelContext) async throws
    func findDocument(byName name: String) -> Document?
    func findDocument(byId id: UUID) -> Document?
    func findDocuments(matching pattern: String) -> [Document]
    func getAllDocuments() -> [Document]
    func deleteDocument(_ document: Document, from modelContext: ModelContext) throws
}

// MARK: - Settings Service Protocol

protocol SettingsServiceProtocol {
    var apiKey: String { get set }
    var isAPIKeyValid: Bool { get }
    func validateSettings() async -> Bool
    func saveAPIKey(_ key: String) throws
    func deleteAPIKey() throws
    func loadAPIKey()
}

// MARK: - Streaming Chat Service Protocol

protocol StreamingChatServiceProtocol {
    func sendStreamingMessage(
        _ text: String,
        settingsManager: SettingsManager,
        documentContext: [Document],
        hiddenContext: String?,
        conversationHistory: [ChatMessage]
    ) async
    func cancelCurrentStreaming()
    func validateAPIConnection(settingsManager: SettingsManager) async -> Bool
}

// MARK: - Document Reference Service Protocol

protocol DocumentReferenceServiceProtocol {
    func resolveDocumentReferences(in text: String) async -> ([DocumentReference], String)
    func processMessage(_ message: String, with documents: [Document]) -> String
}

// MARK: - Message Builder Service Protocol

protocol MessageBuilderServiceProtocol {
    func buildMessage(
        userInput: String,
        documents: [Document],
        hiddenContext: String?
    ) -> String
    func extractDocumentContext(from documents: [Document]) -> String
    func formatMessageWithContext(
        userInput: String,
        documentContext: String,
        hiddenContext: String?
    ) -> String
} 