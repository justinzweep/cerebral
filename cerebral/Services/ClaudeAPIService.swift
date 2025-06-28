//
//  ClaudeAPIService.swift
//  cerebral
//
//  Created by Justin Zweep on 26/06/2025.
//

import Foundation
import OSLog

@MainActor
class ClaudeAPIService: ObservableObject, ChatServiceProtocol {
    
    // MARK: - Dependencies
    private let settingsManager: SettingsManager
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "cerebral", category: "ClaudeAPI")
    
    // MARK: - Configuration
    private let baseURL = "https://api.anthropic.com"
    private let apiVersion = "2023-06-01"
    
    private struct Configuration {
        static let maxRetries = 3
        static let baseDelay: TimeInterval = 1.0
        static let maxDelay: TimeInterval = 32.0
        static let requestTimeout: TimeInterval = 60.0
        static let maxTokens = 4000
        static let maxContextLength = 100_000
        static let rateLimitWindow: TimeInterval = 60.0
        static let maxRequestsPerWindow = 50
    }
    
    // MARK: - Rate Limiting & Circuit Breaker
    private var requestTimestamps: [Date] = []
    private var circuitBreakerFailureCount = 0
    private var circuitBreakerLastFailureTime: Date?
    private let circuitBreakerThreshold = 5
    private let circuitBreakerRecoveryTime: TimeInterval = 300 // 5 minutes
    
    // MARK: - Active Requests Management
    private var activeRequests: Set<UUID> = []
    private let requestsQueue = DispatchQueue(label: "claudeapi.requests", qos: .userInitiated)
    
    init(settingsManager: SettingsManager) {
        self.settingsManager = settingsManager
        logger.info("ClaudeAPIService initialized")
    }
    
    // MARK: - Public API
    
    func sendMessageStream(
        _ message: String,
        context: [Document] = [],
        conversationHistory: [ChatMessage] = []
    ) -> AsyncThrowingStream<StreamingResponse, Error> {
        let requestId = UUID()
        
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    // Track active request
                    await addActiveRequest(requestId)
                    defer { Task { await removeActiveRequest(requestId) } }
                    
                    logger.info("Starting streaming request - requestId: \(requestId), messageLength: \(message.count), contextCount: \(context.count), historyCount: \(conversationHistory.count)")
                    
                    // Validate prerequisites
                    try await validateRequest(message: message, context: context)
                    
                    // Check circuit breaker
                    try checkCircuitBreaker()
                    
                    // Check rate limits
                    try await checkRateLimit()
                    
                    // Prepare request
                    let request = try await prepareStreamingRequest(
                        message: message,
                        context: context,
                        conversationHistory: conversationHistory
                    )
                    
                    // Execute with retry logic
                    try await executeStreamingRequestWithRetry(
                        request: request,
                        requestId: requestId,
                        continuation: continuation
                    )
                    
                } catch {
                    logger.error("Streaming request failed - requestId: \(requestId), error: \(error)")
                    recordFailure()
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Request Validation
    
    private func validateRequest(message: String, context: [Document]) async throws {
        guard !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ChatError.messageProcessingFailed("Message cannot be empty")
        }
        
        guard !settingsManager.apiKey.isEmpty else {
            throw ChatError.noAPIKey
        }
        
        // Validate API key format
        guard settingsManager.validateAPIKey(settingsManager.apiKey) else {
            throw ChatError.requestFailed("Invalid API key format")
        }
        
        // Estimate context size and validate
        let estimatedTokens = estimateTokenCount(message: message, context: context)
        guard estimatedTokens <= Configuration.maxContextLength else {
            logger.warning("Context too large - estimatedTokens: \(estimatedTokens)")
            throw ChatError.contextTooLarge
        }
    }
    
    private func estimateTokenCount(message: String, context: [Document]) -> Int {
        // Rough estimation: ~4 characters per token
        let messageTokens = message.count / 4
        let contextTokens = context.reduce(0) { total, doc in
            // Estimate based on document size or use cached value
            return total + (doc.title.count / 4) + 500 // Base estimate per document
        }
        return messageTokens + contextTokens
    }
    
    // MARK: - Circuit Breaker
    
    private func checkCircuitBreaker() throws {
        guard circuitBreakerFailureCount < circuitBreakerThreshold else {
            if let lastFailure = circuitBreakerLastFailureTime,
               Date().timeIntervalSince(lastFailure) < circuitBreakerRecoveryTime {
                throw ChatError.connectionFailed("Service temporarily unavailable. Please try again later.")
            } else {
                // Reset circuit breaker
                circuitBreakerFailureCount = 0
                circuitBreakerLastFailureTime = nil
                return // Allow the request to proceed after reset
            }
        }
    }
    
    private func recordFailure() {
        circuitBreakerFailureCount += 1
        circuitBreakerLastFailureTime = Date()
        logger.warning("Circuit breaker failure recorded - failureCount: \(self.circuitBreakerFailureCount)")
    }
    
    private func recordSuccess() {
        if circuitBreakerFailureCount > 0 {
            circuitBreakerFailureCount = 0
            circuitBreakerLastFailureTime = nil
            logger.info("Circuit breaker reset after successful request")
        }
    }
    
    // MARK: - Rate Limiting
    
    private func checkRateLimit() async throws {
        let now = Date()
        let windowStart = now.addingTimeInterval(-Configuration.rateLimitWindow)
        
        // Clean old timestamps
        requestTimestamps.removeAll { $0 < windowStart }
        
        guard requestTimestamps.count < Configuration.maxRequestsPerWindow else {
            logger.warning("Rate limit exceeded - requestCount: \(self.requestTimestamps.count), windowSize: \(Configuration.rateLimitWindow)")
            throw ChatError.rateLimitExceeded
        }
        
        requestTimestamps.append(now)
    }
    
    // MARK: - Request Preparation
    
    private func prepareStreamingRequest(
        message: String,
        context: [Document],
        conversationHistory: [ChatMessage]
    ) async throws -> ClaudeStreamRequest {
        
        // Build conversation messages with size limits
        var messages: [ClaudeMessage] = []
        let maxHistoryMessages = 20 // Limit conversation history
        
        // Add recent conversation history
        for historyMessage in conversationHistory.suffix(maxHistoryMessages) {
            let role: String = historyMessage.isUser ? "user" : "assistant"
            messages.append(ClaudeMessage(role: role, content: historyMessage.text))
        }
        
        // Prepare current message with context
        let currentMessageContent = try await buildMessageWithContext(
            message: message,
            context: context
        )
        
        messages.append(ClaudeMessage(role: "user", content: currentMessageContent))
        
        return ClaudeStreamRequest(
            model: "claude-3-5-sonnet-20241022",
            maxTokens: Configuration.maxTokens,
            messages: messages,
            system: buildSystemPrompt(),
            stream: true
        )
    }
    
    private func buildMessageWithContext(message: String, context: [Document]) async throws -> String {
        // Only add separate document context if there are documents and message doesn't already contain them
        guard !context.isEmpty && !message.contains("ATTACHED DOCUMENTS:") else {
            return message
        }
        
        let contextInfo = try await buildDocumentContext(from: context)
        
        return """
        Document Context:
        \(contextInfo)
        
        User Question: \(message)
        """
    }
    
    private func buildDocumentContext(from documents: [Document]) async throws -> String {
        var context = ""
        let maxDocuments = 5 // Limit number of documents to prevent context overflow
        
        for document in documents.prefix(maxDocuments) {
            context += "Document: \(document.title)\n"
            context += "Added: \(document.dateAdded.formatted(date: .abbreviated, time: .omitted))\n"
            
            // Extract metadata safely
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
            
            // Extract text content with length limit
            if let extractedText = PDFService.shared.extractText(from: document, maxLength: 3000) {
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
    
    // MARK: - Request Execution with Retry Logic
    
    private func executeStreamingRequestWithRetry(
        request: ClaudeStreamRequest,
        requestId: UUID,
        continuation: AsyncThrowingStream<StreamingResponse, Error>.Continuation
    ) async throws {
        
        var lastError: Error?
        
        for attempt in 1...Configuration.maxRetries {
            do {
                logger.info("Executing streaming request - requestId: \(requestId), attempt: \(attempt), maxRetries: \(Configuration.maxRetries)")
                
                try await performStreamingAPIRequest(
                    request,
                    requestId: requestId,
                    continuation: continuation
                )
                
                recordSuccess()
                return
                
            } catch {
                lastError = error
                logger.error("Request attempt failed - requestId: \(requestId), attempt: \(attempt), error: \(error)")
                
                // Don't retry certain types of errors
                if !shouldRetryError(error) || attempt == Configuration.maxRetries {
                    break
                }
                
                // Exponential backoff with jitter
                let delay = min(
                    Configuration.baseDelay * pow(2.0, Double(attempt - 1)),
                    Configuration.maxDelay
                )
                let jitteredDelay = delay * (0.5 + Double.random(in: 0...0.5))
                
                logger.info("Retrying after delay - requestId: \(requestId), delay: \(jitteredDelay), nextAttempt: \(attempt + 1)")
                
                try await Task.sleep(nanoseconds: UInt64(jitteredDelay * 1_000_000_000))
            }
        }
        
        if let error = lastError {
            throw error
        }
    }
    
    private func shouldRetryError(_ error: Error) -> Bool {
        if let urlError = error as? URLError {
            switch urlError.code {
            case .timedOut, .networkConnectionLost, .cannotConnectToHost:
                return true
            case .badURL, .unsupportedURL, .cannotFindHost:
                return false
            default:
                return true
            }
        }
        
        if let chatError = error as? ChatError {
            switch chatError {
            case .rateLimitExceeded, .connectionFailed:
                return true
            case .noAPIKey, .contextTooLarge:
                return false
            default:
                return true
            }
        }
        
        return true
    }
    
    // MARK: - HTTP Request Execution
    
    private func performStreamingAPIRequest(
        _ requestBody: ClaudeStreamRequest,
        requestId: UUID,
        continuation: AsyncThrowingStream<StreamingResponse, Error>.Continuation
    ) async throws {
        
        guard let url = URL(string: "\(baseURL)/v1/messages") else {
            throw ChatError.requestFailed("Invalid API URL")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = Configuration.requestTimeout
        
        // Set headers
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(settingsManager.apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue(apiVersion, forHTTPHeaderField: "anthropic-version")
        request.setValue("cerebral/1.0", forHTTPHeaderField: "User-Agent")
        
        // Encode request body
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .sortedKeys // For consistent logging
            let jsonData = try encoder.encode(requestBody)
            request.httpBody = jsonData
            
            logger.debug("Request prepared - requestId: \(requestId), bodySize: \(jsonData.count), model: \(requestBody.model)")
            
        } catch {
            throw ChatError.requestFailed("Failed to encode request: \(error.localizedDescription)")
        }
        
        // Execute streaming request
        do {
            let (asyncBytes, urlResponse) = try await URLSession.shared.bytes(for: request)
            
            // Validate HTTP response
            guard let httpResponse = urlResponse as? HTTPURLResponse else {
                throw ChatError.requestFailed("Invalid response type")
            }
            
            logger.info("Received HTTP response - requestId: \(requestId), statusCode: \(httpResponse.statusCode)")
            
            guard httpResponse.statusCode == 200 else {
                let errorMessage = try await extractErrorFromResponse(asyncBytes, statusCode: httpResponse.statusCode)
                throw ChatError.requestFailed("API Error: HTTP \(httpResponse.statusCode) - \(errorMessage)")
            }
            
            // Process streaming response
            try await processStreamingResponse(
                asyncBytes: asyncBytes,
                requestId: requestId,
                continuation: continuation
            )
            
        } catch let error as URLError {
            logger.error("Network error - requestId: \(requestId), urlError: \(error)")
            
            switch error.code {
            case .cannotFindHost:
                throw ChatError.connectionFailed("Cannot find Anthropic API server. This might be due to DNS resolution issues. Try disabling iCloud Private Relay in Settings > Apple ID > iCloud > Private Relay, or check your network connection.")
            case .notConnectedToInternet:
                throw ChatError.connectionFailed("No internet connection available.")
            case .timedOut:
                throw ChatError.connectionFailed("Request timed out. Please try again.")
            case .networkConnectionLost:
                throw ChatError.connectionFailed("Network connection lost during request.")
            default:
                throw ChatError.connectionFailed("Network error: \(error.localizedDescription)")
            }
        }
    }
    
    private func extractErrorFromResponse(_ asyncBytes: URLSession.AsyncBytes, statusCode: Int) async throws -> String {
        var errorData = Data()
        
        // Collect error response data (with size limit)
        for try await byte in asyncBytes.prefix(1024) { // Limit error response size
            errorData.append(byte)
        }
        
        if let errorString = String(data: errorData, encoding: .utf8),
           !errorString.isEmpty {
            return errorString
        }
        
        return "Unknown error (HTTP \(statusCode))"
    }
    
    // MARK: - Streaming Response Processing
    
    private func processStreamingResponse(
        asyncBytes: URLSession.AsyncBytes,
        requestId: UUID,
        continuation: AsyncThrowingStream<StreamingResponse, Error>.Continuation
    ) async throws {
        
        var buffer = Data()
        var processedLines = 0
        let maxBufferSize = 10_000 // Prevent memory issues
        
        for try await byte in asyncBytes {
            buffer.append(byte)
            
            // Prevent buffer overflow
            if buffer.count > maxBufferSize {
                buffer = buffer.suffix(maxBufferSize / 2)
                logger.warning("Buffer size limit reached, truncating - requestId: \(requestId)")
            }
            
            // Convert buffer to string and process complete lines
            if let bufferString = String(data: buffer, encoding: .utf8) {
                var remainingString = bufferString
                
                while let newlineRange = remainingString.range(of: "\n") {
                    let line = String(remainingString[..<newlineRange.lowerBound])
                    remainingString.removeSubrange(..<newlineRange.upperBound)
                    
                    if let streamingResponse = parseSSELine(line, requestId: requestId) {
                        continuation.yield(streamingResponse)
                        processedLines += 1
                        
                        // Check for stream end
                        if case .messageStop = streamingResponse {
                            logger.info("Stream completed - requestId: \(requestId), processedLines: \(processedLines)")
                            continuation.finish()
                            return
                        }
                    }
                }
                
                // Update buffer with remaining incomplete data
                if let remainingData = remainingString.data(using: .utf8) {
                    buffer = remainingData
                }
            }
        }
        
        // Process any remaining buffer content
        if let finalString = String(data: buffer, encoding: .utf8),
           !finalString.isEmpty,
           let streamingResponse = parseSSELine(finalString, requestId: requestId) {
            continuation.yield(streamingResponse)
        }
        
        logger.info("Stream finished - requestId: \(requestId), processedLines: \(processedLines)")
        continuation.finish()
    }
    
    private func parseSSELine(_ line: String, requestId: UUID) -> StreamingResponse? {
        // Skip empty lines and comments
        let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedLine.isEmpty || trimmedLine.hasPrefix(":") {
            return nil
        }
        
        // Parse event type
        if trimmedLine.hasPrefix("event: ") {
            let prefix = "event: "
            guard trimmedLine.count > prefix.count else { return nil }
            let eventType = String(trimmedLine.dropFirst(prefix.count))
            return .event(eventType)
        }
        
        // Parse data
        if trimmedLine.hasPrefix("data: ") {
            let prefix = "data: "
            guard trimmedLine.count > prefix.count else { return nil }
            let dataString = String(trimmedLine.dropFirst(prefix.count))
            
            guard let data = dataString.data(using: .utf8) else {
                logger.warning("Failed to parse SSE data - requestId: \(requestId), line: \(trimmedLine)")
                return nil
            }
            
            do {
                guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let type = json["type"] as? String else {
                    return nil
                }
                
                return parseEventType(type, json: json, requestId: requestId)
                
            } catch {
                logger.warning("Failed to parse JSON - requestId: \(requestId), error: \(error)")
                return nil
            }
        }
        
        return nil
    }
    
    private func parseEventType(_ type: String, json: [String: Any], requestId: UUID) -> StreamingResponse? {
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
                logger.error("API error received - requestId: \(requestId), errorMessage: \(message)")
                return .error(message)
            }
            
        default:
            logger.debug("Unknown event type - requestId: \(requestId), eventType: \(type)")
        }
        
        return nil
    }
    
    // MARK: - Active Request Management
    
    private func addActiveRequest(_ requestId: UUID) async {
        await requestsQueue.sync {
            activeRequests.insert(requestId)
        }
    }
    
    private func removeActiveRequest(_ requestId: UUID) async {
        await requestsQueue.sync {
            activeRequests.remove(requestId)
        }
    }
    
    // MARK: - System Prompt
    
    private func buildSystemPrompt() -> String {
        return """
        You are an AI assistant integrated into Cerebral, a PDF reading and document management application for macOS. Your role is to:
        
        1. Help users understand and analyze their PDF documents
        2. Answer questions about document content when provided
        3. Assist with research and provide insights based on the documents
        4. Be helpful, accurate, and concise in your responses
        
        When a user message contains "Document Context:" followed by document content, prioritize information from those documents in your responses. The document content will be clearly marked with document titles and metadata.
        
        Focus on the user's actual question while using the provided document content to give accurate, relevant answers. If asked about content not in the provided documents, clearly state that and offer general knowledge if helpful.
        
        Keep responses conversational and helpful while being precise about document-specific information. Always format your responses in clean, readable markdown.
        """
    }
    
    // MARK: - ChatServiceProtocol Implementation
    
    func sendStreamingMessage(
        _ text: String, 
        context: [Document] = [], 
        conversationHistory: [ChatMessage] = []
    ) -> AsyncThrowingStream<StreamingResponse, Error> {
        return sendMessageStream(text, context: context, conversationHistory: conversationHistory)
    }
    
    // MARK: - Cleanup
    deinit {
        logger.info("ClaudeAPIService deallocated")
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


