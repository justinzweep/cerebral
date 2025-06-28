//
//  TokenizerService.swift
//  cerebral
//
//  Created on 26/06/2025.
//

import Foundation

/// Service for accurate token counting and text processing
@MainActor
final class TokenizerService {
    static let shared = TokenizerService()
    
    // API Configuration
    private let baseURL = "https://api.anthropic.com"
    private let apiVersion = "2023-06-01"
    private var settingsManager: SettingsManager?
    
    // Approximate token/character ratio for Claude models (fallback)
    private let averageCharactersPerToken: Double = 4.0
    
    // Token limits for different Claude models
    enum ModelTokenLimits {
        static let claude3Opus = 200_000
        static let claude3Sonnet = 200_000
        static let claude3Haiku = 200_000
        static let defaultLimit = 100_000
    }
    
    private init() {}
    
    /// Inject SettingsManager dependency for API access
    func configure(with settingsManager: SettingsManager) {
        self.settingsManager = settingsManager
    }
    
    // MARK: - API-Based Token Counting
    
    /// Accurately counts tokens using Claude API (preferred method)
    func countTokensUsingAPI(
        messages: [ClaudeMessage],
        model: String = "claude-3-5-sonnet-20241022",
        system: String? = nil
    ) async throws -> Int {
        guard let settingsManager = settingsManager,
              !settingsManager.apiKey.isEmpty else {
            // Fall back to approximation if no API key
            let allText = messages.map { $0.content }.joined(separator: " ")
            return estimateTokenCount(for: allText)
        }
        
        guard let url = URL(string: "\(baseURL)/v1/messages/count_tokens") else {
            throw TokenCountError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(settingsManager.apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue(apiVersion, forHTTPHeaderField: "anthropic-version")
        
        let requestBody = TokenCountRequest(
            model: model,
            messages: messages,
            system: system
        )
        
        do {
            let jsonData = try JSONEncoder().encode(requestBody)
            request.httpBody = jsonData
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                guard httpResponse.statusCode == 200 else {
                    throw TokenCountError.apiError(httpResponse.statusCode)
                }
            }
            
            let tokenResponse = try JSONDecoder().decode(TokenCountResponse.self, from: data)
            return tokenResponse.inputTokens
            
        } catch let error as TokenCountError {
            throw error
        } catch {
            // Fall back to approximation on any other error
            let allText = messages.map { $0.content }.joined(separator: " ")
            return estimateTokenCount(for: allText)
        }
    }
    
    /// Counts tokens for a simple text message
    func countTokensForMessage(
        _ text: String,
        model: String = "claude-3-5-sonnet-20241022",
        system: String? = nil
    ) async throws -> Int {
        let message = ClaudeMessage(role: "user", content: text)
        return try await countTokensUsingAPI(messages: [message], model: model, system: system)
    }
    
    /// Counts tokens for conversation history and context
    func countTokensForConversation(
        messages: [ChatMessage],
        context: [Document] = [],
        system: String? = nil,
        model: String = "claude-3-5-sonnet-20241022"
    ) async throws -> Int {
        // Convert to Claude messages
        var claudeMessages: [ClaudeMessage] = []
        
        for message in messages {
            let role = message.isUser ? "user" : "assistant"
            claudeMessages.append(ClaudeMessage(role: role, content: message.text))
        }
        
        // Add context if present
        if !context.isEmpty {
            let contextText = buildDocumentContext(from: context)
            if let lastMessage = claudeMessages.last, lastMessage.role == "user" {
                // Combine context with last user message
                claudeMessages[claudeMessages.count - 1] = ClaudeMessage(
                    role: "user",
                    content: "Document Context:\n\(contextText)\n\nUser Question: \(lastMessage.content)"
                )
            } else {
                // Add as separate user message
                claudeMessages.append(ClaudeMessage(role: "user", content: contextText))
            }
        }
        
        return try await countTokensUsingAPI(messages: claudeMessages, model: model, system: system)
    }
    
    // MARK: - Fallback Estimation Methods (Original Implementation)
    
    /// Estimates token count for a given text
    /// Uses a simple character-based approximation suitable for Claude models
    func estimateTokenCount(for text: String) -> Int {
        // Remove excessive whitespace
        let cleanedText = text.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        
        // Estimate based on character count
        // This is a simplified estimation - API counting is preferred
        let characterCount = cleanedText.count
        let estimatedTokens = Int(ceil(Double(characterCount) / averageCharactersPerToken))
        
        // Add a small buffer for safety
        return Int(Double(estimatedTokens) * 1.1)
    }
    
    /// Estimates token count for multiple texts
    func estimateTokenCount(for texts: [String]) -> Int {
        texts.reduce(0) { $0 + estimateTokenCount(for: $1) }
    }
    
    /// Truncates text to fit within a token limit
    func truncateToTokenLimit(_ text: String, limit: Int) -> String {
        let estimatedTokens = estimateTokenCount(for: text)
        
        if estimatedTokens <= limit {
            return text
        }
        
        // Calculate approximate character limit
        let targetCharacters = Int(Double(limit) * averageCharactersPerToken * 0.9) // 90% to be safe
        
        if text.count <= targetCharacters {
            return text
        }
        
        // Truncate and add ellipsis
        let index = text.index(text.startIndex, offsetBy: targetCharacters - 3)
        return String(text[..<index]) + "..."
    }
    
    /// Splits text into chunks that fit within a token limit
    func splitIntoChunks(_ text: String, maxTokensPerChunk: Int) -> [String] {
        let targetCharactersPerChunk = Int(Double(maxTokensPerChunk) * averageCharactersPerToken * 0.9)
        
        var chunks: [String] = []
        var currentChunk = ""
        
        // Split by paragraphs first
        let paragraphs = text.components(separatedBy: "\n\n")
        
        for paragraph in paragraphs {
            let paragraphWithSeparator = paragraph + "\n\n"
            
            if (currentChunk.count + paragraphWithSeparator.count) <= targetCharactersPerChunk {
                currentChunk += paragraphWithSeparator
            } else {
                if !currentChunk.isEmpty {
                    chunks.append(currentChunk.trimmingCharacters(in: .whitespacesAndNewlines))
                }
                
                // If the paragraph itself is too long, split it further
                if paragraphWithSeparator.count > targetCharactersPerChunk {
                    let subChunks = splitLongText(paragraphWithSeparator, maxCharacters: targetCharactersPerChunk)
                    chunks.append(contentsOf: subChunks)
                    currentChunk = ""
                } else {
                    currentChunk = paragraphWithSeparator
                }
            }
        }
        
        if !currentChunk.isEmpty {
            chunks.append(currentChunk.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        
        return chunks
    }
    
    /// Splits a long text into smaller chunks at sentence boundaries
    private func splitLongText(_ text: String, maxCharacters: Int) -> [String] {
        var chunks: [String] = []
        var currentChunk = ""
        
        // Try to split by sentences
        let sentences = text.components(separatedBy: ". ")
        
        for (index, sentence) in sentences.enumerated() {
            let sentenceWithPeriod = sentence + (index < sentences.count - 1 ? ". " : "")
            
            if (currentChunk.count + sentenceWithPeriod.count) <= maxCharacters {
                currentChunk += sentenceWithPeriod
            } else {
                if !currentChunk.isEmpty {
                    chunks.append(currentChunk)
                }
                
                // If a single sentence is too long, we have to break it
                if sentenceWithPeriod.count > maxCharacters {
                    let hardSplit = hardSplitText(sentenceWithPeriod, maxCharacters: maxCharacters)
                    chunks.append(contentsOf: hardSplit)
                    currentChunk = ""
                } else {
                    currentChunk = sentenceWithPeriod
                }
            }
        }
        
        if !currentChunk.isEmpty {
            chunks.append(currentChunk)
        }
        
        return chunks
    }
    
    /// Hard splits text at character boundaries when no better option exists
    private func hardSplitText(_ text: String, maxCharacters: Int) -> [String] {
        var chunks: [String] = []
        var startIndex = text.startIndex
        
        while startIndex < text.endIndex {
            let remainingCharacters = text.distance(from: startIndex, to: text.endIndex)
            let chunkSize = min(maxCharacters - 3, remainingCharacters) // Leave room for ellipsis
            let endIndex = text.index(startIndex, offsetBy: chunkSize)
            
            var chunk = String(text[startIndex..<endIndex])
            if endIndex < text.endIndex {
                chunk += "..."
            }
            
            chunks.append(chunk)
            startIndex = endIndex
        }
        
        return chunks
    }
    
    /// Calculates a checksum for text content (for caching)
    func calculateChecksum(for text: String) -> String {
        let data = text.data(using: .utf8) ?? Data()
        let hash = data.base64EncodedString()
        
        // Return first 16 characters of the hash
        return String(hash.prefix(16))
    }
    
    // MARK: - Helper Methods
    
    private func buildDocumentContext(from documents: [Document]) -> String {
        var context = ""
        
        for document in documents {
            context += "Document: \(document.title)\n"
            context += "Added: \(document.dateAdded.formatted(date: .abbreviated, time: .omitted))\n"
            
            // Extract metadata
            if let metadata = PDFService.shared.getDocumentMetadata(from: document) {
                if let pageCount = metadata["pageCount"] as? Int {
                    context += "Pages: \(pageCount)\n"
                }
                if let author = metadata["author"] as? String, !author.isEmpty {
                    context += "Author: \(author)\n"
                }
                if let subject = metadata["subject"] as? String, !subject.isEmpty {
                    context += "Subject: \(subject)\n"
                }
            }
            
            // Extract text content
            if let extractedText = PDFService.shared.extractText(from: document, maxLength: 2000) {
                context += "\nDocument Content (excerpt):\n"
                context += extractedText
            } else {
                context += "Content: [Unable to extract text from PDF]\n"
            }
            
            if let lastOpened = document.lastOpened {
                context += "\nLast opened: \(lastOpened.formatted(date: .abbreviated, time: .omitted))\n"
            }
            context += "\n---\n\n"
        }
        
        return context
    }
}

// MARK: - Data Models for Token Counting API

struct TokenCountRequest: Codable {
    let model: String
    let messages: [ClaudeMessage]
    let system: String?
}

struct TokenCountResponse: Codable {
    let inputTokens: Int
    
    enum CodingKeys: String, CodingKey {
        case inputTokens = "input_tokens"
    }
}

// MARK: - Token Count Errors

enum TokenCountError: Error, LocalizedError {
    case invalidURL
    case noAPIKey
    case apiError(Int)
    case decodingError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .noAPIKey:
            return "No API key configured"
        case .apiError(let statusCode):
            return "API Error: HTTP \(statusCode)"
        case .decodingError:
            return "Failed to decode API response"
        }
    }
} 