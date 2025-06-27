//
//  ClaudeAPIService+Protocol.swift
//  cerebral
//
//  Created by Assistant on 26/06/2025.
//

import Foundation

// MARK: - ClaudeAPIService Protocol Conformance

extension ClaudeAPIService: ChatServiceProtocol {
    
    func sendMessage(_ text: String, context: [Document] = [], conversationHistory: [ChatMessage] = []) async throws -> String {
        print("🚀 Starting sendMessage request...")
        print("📝 Message length: \(text.count) characters")
        print("📄 Document context count: \(context.count)")
        print("💬 Conversation history count: \(conversationHistory.count)")
        
        guard !settingsManager.apiKey.isEmpty else {
            print("❌ No API key configured")
            throw ChatError.noAPIKey
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
        var currentMessageContent = text
        
        // Only add separate document context if there are documents and the message doesn't already contain them
        if !context.isEmpty && !text.contains("ATTACHED DOCUMENTS:") {
            let contextInfo = buildDocumentContext(from: context)
            currentMessageContent = """
            Document Context:
            \(contextInfo)
            
            User Question: \(text)
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
        
        do {
            let response = try await performAPIRequest(requestBody)
            let responseText = extractTextFromResponse(response)
            print("✅ Received response from Claude API")
            return responseText
        } catch let error as APIError {
            // Convert legacy APIError to ChatError
            switch error {
            case .noAPIKey:
                throw ChatError.noAPIKey
            case .connectionFailed(let message):
                throw ChatError.connectionFailed(message)
            case .requestFailed(let message):
                throw ChatError.requestFailed(message)
            case .invalidResponse(let message):
                throw ChatError.invalidResponse(message)
            }
        } catch {
            print("❌ Unexpected error: \(error)")
            throw ChatError.requestFailed("Unexpected error: \(error.localizedDescription)")
        }
    }
    
    func sendStreamingMessage(_ text: String, context: [Document] = [], conversationHistory: [ChatMessage] = []) -> AsyncThrowingStream<StreamingResponse, Error> {
        return sendMessageStream(text, context: context, conversationHistory: conversationHistory)
    }
    
    func validateConnection() async throws -> Bool {
        do {
            return try await validateConnection()
        } catch let error as APIError {
            // Convert legacy APIError to ChatError
            switch error {
            case .noAPIKey:
                throw ChatError.noAPIKey
            case .connectionFailed(let message):
                throw ChatError.connectionFailed(message)
            case .requestFailed(let message):
                throw ChatError.requestFailed(message)
            case .invalidResponse(let message):
                throw ChatError.invalidResponse(message)
            }
        } catch {
            throw ChatError.connectionFailed(error.localizedDescription)
        }
    }
} 