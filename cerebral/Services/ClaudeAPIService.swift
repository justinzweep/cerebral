//
//  ClaudeAPIService.swift
//  cerebral
//
//  Created by Justin Zweep on 26/06/2025.
//

import Foundation

@MainActor
class ClaudeAPIService: ObservableObject {
    private let settingsManager: SettingsManager
    private let baseURL = "https://api.anthropic.com"
    private let apiVersion = "2023-06-01"
    
    init(settingsManager: SettingsManager) {
        self.settingsManager = settingsManager
    }
    
    func sendMessage(
        _ message: String,
        context: [Document] = [],
        conversationHistory: [ChatMessage] = []
    ) async throws -> String {
        print("🚀 Starting sendMessage request...")
        print("📝 Message length: \(message.count) characters")
        print("📄 Document context count: \(context.count)")
        print("💬 Conversation history count: \(conversationHistory.count)")
        
        guard !settingsManager.apiKey.isEmpty else {
            print("❌ No API key configured")
            throw APIError.noAPIKey
        }
        
        print("✅ API key available, preparing request...")
        
        // Build the conversation messages
        var messages: [ClaudeMessage] = []
        
        // Add conversation history (limit to last 10 messages for context)
        for historyMessage in conversationHistory.suffix(10) {
            let role: String = historyMessage.isUser ? "user" : "assistant"
            messages.append(ClaudeMessage(role: role, content: historyMessage.text))
        }
        
        // Build the current message with document context
        var currentMessageContent = message
        
        if !context.isEmpty {
            let contextInfo = buildDocumentContext(from: context)
            currentMessageContent = """
            Document Context:
            \(contextInfo)
            
            User Question: \(message)
            """
        }
        
        messages.append(ClaudeMessage(role: "user", content: currentMessageContent))
        
        let requestBody = ClaudeRequest(
            model: "claude-3-5-sonnet-20241022",
            maxTokens: 1000,
            messages: messages,
            system: buildSystemPrompt()
        )
        
        print("📋 Request configured:")
        print("   Model: \(requestBody.model)")
        print("   Messages count: \(requestBody.messages.count)")
        print("   Max tokens: \(requestBody.maxTokens)")
        print("🌐 Making request to Claude API...")
        
        let response = try await performAPIRequest(requestBody)
        let responseText = extractTextFromResponse(response)
        print("✅ Response received, text length: \(responseText.count) characters")
        return responseText
    }
    
    private func performAPIRequest(_ requestBody: ClaudeRequest) async throws -> ClaudeResponse {
        guard let url = URL(string: "\(baseURL)/v1/messages") else {
            throw APIError.requestFailed("Invalid API URL")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // Set headers
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(settingsManager.apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue(apiVersion, forHTTPHeaderField: "anthropic-version")
        
        // Encode request body
        do {
            let jsonData = try JSONEncoder().encode(requestBody)
            request.httpBody = jsonData
            
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                print("📤 Request JSON: \(jsonString)")
            }
        } catch {
            print("❌ Failed to encode request: \(error)")
            throw APIError.requestFailed("Failed to encode request: \(error.localizedDescription)")
        }
        
        // Perform the request
        do {
            let (data, urlResponse) = try await URLSession.shared.data(for: request)
            
            // Check HTTP status
            if let httpResponse = urlResponse as? HTTPURLResponse {
                print("📥 HTTP Status: \(httpResponse.statusCode)")
                
                if httpResponse.statusCode != 200 {
                    // Try to parse error response
                    if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let error = errorData["error"] as? [String: Any],
                       let message = error["message"] as? String {
                        throw APIError.requestFailed("API Error (\(httpResponse.statusCode)): \(message)")
                    } else {
                        throw APIError.requestFailed("API Error: HTTP \(httpResponse.statusCode)")
                    }
                }
            }
            
            // Parse response
            if let responseString = String(data: data, encoding: .utf8) {
                print("📥 Response JSON: \(responseString)")
            }
            
            let response = try JSONDecoder().decode(ClaudeResponse.self, from: data)
            print("✅ Successfully decoded API response")
            return response
            
        } catch let error as DecodingError {
            print("❌ JSON decoding error: \(error)")
            throw APIError.invalidResponse("Failed to decode response: \(error.localizedDescription)")
        } catch let error as URLError {
            print("❌ Network error: \(error)")
            switch error.code {
            case .cannotFindHost:
                throw APIError.requestFailed("Cannot find Anthropic API server. This might be due to DNS resolution issues. Try disabling iCloud Private Relay in Settings > Apple ID > iCloud > Private Relay, or check your network connection.")
            case .notConnectedToInternet:
                throw APIError.requestFailed("No internet connection available.")
            case .timedOut:
                throw APIError.requestFailed("Request timed out. Please try again.")
            default:
                throw APIError.requestFailed("Network error: \(error.localizedDescription)")
            }
        } catch {
            print("❌ Unexpected error: \(error)")
            throw APIError.requestFailed("Unexpected error: \(error.localizedDescription)")
        }
    }
    
    private func buildSystemPrompt() -> String {
        return """
        You are an AI assistant integrated into Cerebral, a PDF reading and document management application for macOS. Your role is to:
        
        1. Help users understand and analyze their PDF documents
        2. Answer questions about document content when provided
        3. Assist with research and provide insights
        4. Be helpful, accurate, and concise in your responses
        
        When document context is provided, prioritize information from those documents in your responses. If asked about content not in the provided documents, clearly state that and offer general knowledge if helpful.
        
        Keep responses conversational and helpful while being precise about document-specific information.
        """
    }
    
    private func buildDocumentContext(from documents: [Document]) -> String {
        var context = ""
        
        for document in documents {
            context += "Document: \(document.title)\n"
            context += "Added: \(document.dateAdded.formatted(date: .abbreviated, time: .omitted))\n"
            
            // Extract metadata
            if let metadata = PDFTextExtractionService.shared.getDocumentMetadata(from: document) {
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
            if let extractedText = PDFTextExtractionService.shared.extractText(from: document, maxLength: 2000) {
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
    
    private func extractTextFromResponse(_ response: ClaudeResponse) -> String {
        return response.content.compactMap { content in
            switch content.type {
            case "text":
                return content.text
            default:
                return nil
            }
        }.joined(separator: "\n")
    }
    
    func validateConnection() async throws -> Bool {
        guard !settingsManager.apiKey.isEmpty else {
            throw APIError.noAPIKey
        }
        
        let testMessage = ClaudeMessage(role: "user", content: "Hello")
        let testRequest = ClaudeRequest(
            model: "claude-3-5-sonnet-20241022",
            maxTokens: 10,
            messages: [testMessage]
        )
        
        do {
            _ = try await performAPIRequest(testRequest)
            return true
        } catch {
            print("Claude API Validation Error: \(error)")
            if let urlError = error as? URLError {
                switch urlError.code {
                case .cannotFindHost:
                    throw APIError.connectionFailed("Cannot reach Anthropic API servers. Please check your internet connection and API key.")
                case .notConnectedToInternet:
                    throw APIError.connectionFailed("No internet connection available.")
                case .timedOut:
                    throw APIError.connectionFailed("Connection timed out. Please try again.")
                default:
                    throw APIError.connectionFailed("Network error: \(urlError.localizedDescription)")
                }
            }
            throw APIError.connectionFailed(error.localizedDescription)
        }
    }
}

// MARK: - Data Models for Claude API

struct ClaudeRequest: Codable {
    let model: String
    let maxTokens: Int
    let messages: [ClaudeMessage]
    let system: String?
    
    enum CodingKeys: String, CodingKey {
        case model
        case maxTokens = "max_tokens"
        case messages
        case system
    }
    
    init(model: String, maxTokens: Int, messages: [ClaudeMessage], system: String? = nil) {
        self.model = model
        self.maxTokens = maxTokens
        self.messages = messages
        self.system = system
    }
}

struct ClaudeMessage: Codable {
    let role: String
    let content: String
}

struct ClaudeResponse: Codable {
    let id: String
    let type: String
    let role: String
    let content: [ClaudeContent]
    let model: String
    let stopReason: String?
    let stopSequence: String?
    let usage: ClaudeUsage
    
    enum CodingKeys: String, CodingKey {
        case id, type, role, content, model
        case stopReason = "stop_reason"
        case stopSequence = "stop_sequence"
        case usage
    }
}

struct ClaudeContent: Codable {
    let type: String
    let text: String?
}

struct ClaudeUsage: Codable {
    let inputTokens: Int
    let outputTokens: Int
    
    enum CodingKeys: String, CodingKey {
        case inputTokens = "input_tokens"
        case outputTokens = "output_tokens"
    }
}

enum APIError: LocalizedError {
    case noAPIKey
    case connectionFailed(String)
    case requestFailed(String)
    case invalidResponse(String)
    
    var errorDescription: String? {
        switch self {
        case .noAPIKey:
            return "No API key configured. Please add your Claude API key in Settings."
        case .connectionFailed(let message):
            return "Connection failed: \(message)"
        case .requestFailed(let message):
            return "Request failed: \(message)"
        case .invalidResponse(let message):
            return "Invalid response from Claude API: \(message)"
        }
    }
} 
