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
    
    // MARK: - Streaming Message Support
    
    func sendMessageStream(
        _ message: String,
        context: [Document] = [],
        conversationHistory: [ChatMessage] = []
    ) -> AsyncThrowingStream<StreamingResponse, Error> {
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    print("🚀 Starting streaming sendMessage request...")
                    print("📝 Message length: \(message.count) characters")
                    print("📄 Document context count: \(context.count)")
                    print("💬 Conversation history count: \(conversationHistory.count)")
                    
                    guard !settingsManager.apiKey.isEmpty else {
                        print("❌ No API key configured")
                        throw APIError.noAPIKey
                    }
                    
                    print("✅ API key available, preparing streaming request...")
                    
                    // Build the conversation messages
                    var messages: [ClaudeMessage] = []
                    
                    // Add conversation history (limit to last 10 messages for context)
                    for historyMessage in conversationHistory.suffix(10) {
                        let role: String = historyMessage.isUser ? "user" : "assistant"
                        messages.append(ClaudeMessage(role: role, content: historyMessage.text))
                    }
                    
                    // Add the current message (which may already include document content)
                    var currentMessageContent = message
                    
                    // Only add separate document context if there are documents and the message doesn't already contain them
                    if !context.isEmpty && !message.contains("ATTACHED DOCUMENTS:") {
                        let contextInfo = buildDocumentContext(from: context)
                        currentMessageContent = """
                        Document Context:
                        \(contextInfo)
                        
                        User Question: \(message)
                        """
                    }
                    
                    messages.append(ClaudeMessage(role: "user", content: currentMessageContent))
                    
                    let requestBody = ClaudeStreamRequest(
                        model: "claude-3-5-sonnet-20241022",
                        maxTokens: 1000,
                        messages: messages,
                        system: buildSystemPrompt(),
                        stream: true
                    )
                    
                    print("📋 Streaming request configured:")
                    print("   Model: \(requestBody.model)")
                    print("   Messages count: \(requestBody.messages.count)")
                    print("   Max tokens: \(requestBody.maxTokens)")
                    print("🌐 Making streaming request to Claude API...")
                    
                    try await performStreamingAPIRequest(requestBody, continuation: continuation)
                    
                } catch {
                    print("❌ Streaming error: \(error)")
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    private func performStreamingAPIRequest(
        _ requestBody: ClaudeStreamRequest,
        continuation: AsyncThrowingStream<StreamingResponse, Error>.Continuation
    ) async throws {
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
                print("📤 Streaming Request JSON: \(jsonString)")
            }
        } catch {
            print("❌ Failed to encode streaming request: \(error)")
            throw APIError.requestFailed("Failed to encode request: \(error.localizedDescription)")
        }
        
        // Perform the streaming request
        do {
            let (asyncBytes, urlResponse) = try await URLSession.shared.bytes(for: request)
            
            // Check HTTP status
            if let httpResponse = urlResponse as? HTTPURLResponse {
                print("📥 HTTP Status: \(httpResponse.statusCode)")
                
                if httpResponse.statusCode != 200 {
                    throw APIError.requestFailed("API Error: HTTP \(httpResponse.statusCode)")
                }
            }
            
            // Process the streaming response
            var buffer = ""
            for try await byte in asyncBytes {
                buffer += String(bytes: [byte], encoding: .utf8) ?? ""
                
                // Process complete lines
                let lines = buffer.components(separatedBy: "\n")
                
                // Keep the last (potentially incomplete) line in the buffer
                if lines.count > 1 {
                    buffer = lines.last ?? ""
                    
                    // Process all complete lines (all except the last)
                    for line in lines.dropLast() {
                        if let streamingResponse = parseSSELine(line) {
                            continuation.yield(streamingResponse)
                            
                            // Check if this is the end of the stream
                            if case .messageStop = streamingResponse {
                                continuation.finish()
                                return
                            }
                        }
                    }
                }
            }
            
            // Process any remaining buffer
            if !buffer.isEmpty, let streamingResponse = parseSSELine(buffer) {
                continuation.yield(streamingResponse)
            }
            
            continuation.finish()
            
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
            print("❌ Unexpected streaming error: \(error)")
            throw APIError.requestFailed("Unexpected error: \(error.localizedDescription)")
        }
    }
    
    private func parseSSELine(_ line: String) -> StreamingResponse? {
        // Skip empty lines and ping events
        if line.isEmpty || line.hasPrefix(": ") {
            return nil
        }
        
        // Parse event type
        if line.hasPrefix("event: ") {
            let eventPrefix = "event: "
            guard line.count > eventPrefix.count else { return nil }
            let eventType = String(line.dropFirst(eventPrefix.count)).trimmingCharacters(in: .whitespacesAndNewlines)
            return .event(eventType)
        }
        
        // Parse data
        if line.hasPrefix("data: ") {
            let dataPrefix = "data: "
            guard line.count > dataPrefix.count else { return nil }
            let dataString = String(line.dropFirst(dataPrefix.count))
            
            guard let data = dataString.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let type = json["type"] as? String else {
                return nil
            }
            
            switch type {
            case "message_start":
                return .messageStart
                
            case "content_block_start":
                return .contentBlockStart
                
            case "content_block_delta":
                if let delta = json["delta"] as? [String: Any],
                   let deltaType = delta["type"] as? String,
                   deltaType == "text_delta",
                   let text = delta["text"] as? String {
                    return .textDelta(text)
                }
                
            case "content_block_stop":
                return .contentBlockStop
                
            case "message_delta":
                return .messageDelta
                
            case "message_stop":
                return .messageStop
                
            case "ping":
                return .ping
                
            case "error":
                if let error = json["error"] as? [String: Any],
                   let message = error["message"] as? String {
                    return .error(message)
                }
                
            default:
                print("🔄 Unknown streaming event type: \(type)")
            }
        }
        
        return nil
    }
    
    // MARK: - Original Non-Streaming Method (kept for backward compatibility)
    
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
        
        // Add the current message (which may already include document content)
        var currentMessageContent = message
        
        // Only add separate document context if there are documents and the message doesn't already contain them
        if !context.isEmpty && !message.contains("ATTACHED DOCUMENTS:") {
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
        
        When a user message contains "ATTACHED DOCUMENTS:" followed by document content, prioritize information from those documents in your responses. The document content will be clearly marked with document titles and metadata.
        
        The user message format may include:
        - ATTACHED DOCUMENTS: (document content and metadata)
        - USER MESSAGE: (the actual user question)
        
        Focus on the user's actual question while using the attached document content to provide accurate, relevant answers. If asked about content not in the provided documents, clearly state that and offer general knowledge if helpful.
        
        Keep responses conversational and helpful while being precise about document-specific information.

        Always return your answer in neatly formatted markdown.
        """
    }
    
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

// MARK: - Streaming Response Types

enum StreamingResponse {
    case event(String)
    case messageStart
    case contentBlockStart
    case textDelta(String)
    case contentBlockStop
    case messageDelta
    case messageStop
    case ping
    case error(String)
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

struct ClaudeStreamRequest: Codable {
    let model: String
    let maxTokens: Int
    let messages: [ClaudeMessage]
    let system: String?
    let stream: Bool
    
    enum CodingKeys: String, CodingKey {
        case model
        case maxTokens = "max_tokens"
        case messages
        case system
        case stream
    }
    
    init(model: String, maxTokens: Int, messages: [ClaudeMessage], system: String? = nil, stream: Bool = true) {
        self.model = model
        self.maxTokens = maxTokens
        self.messages = messages
        self.system = system
        self.stream = stream
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
