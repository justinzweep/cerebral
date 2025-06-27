//
//  StreamingChatService.swift
//  cerebral
//
//  Created by Assistant on 26/06/2025.
//

import Foundation

/// Service responsible for handling streaming chat functionality
@MainActor
final class StreamingChatService {
    private var claudeAPIService: ClaudeAPIService?
    private var streamingTask: Task<Void, Never>?
    
    private weak var delegate: StreamingChatServiceDelegate?
    
    init(delegate: StreamingChatServiceDelegate) {
        self.delegate = delegate
    }
    
    /// Send a streaming message to Claude API
    func sendStreamingMessage(
        _ text: String,
        settingsManager: SettingsManager,
        documentContext: [Document] = [],
        hiddenContext: String? = nil,
        conversationHistory: [ChatMessage]
    ) async {
        // Cancel any existing streaming task
        cancelCurrentStreaming()
        
        // Initialize API service if needed
        if claudeAPIService == nil {
            claudeAPIService = ClaudeAPIService(settingsManager: settingsManager)
        }
        
        delegate?.streamingDidStart()
        
        // Create initial AI message for streaming
        let aiMessage = ChatMessage(
            text: "",
            isUser: false,
            documentReferences: [],
            isStreaming: true
        )
        
        delegate?.streamingDidCreateMessage(aiMessage)
        
        streamingTask = Task {
            do {
                guard let apiService = claudeAPIService else {
                    throw APIError.requestFailed("API service not initialized")
                }
                
                let streamingResponse = apiService.sendMessageStream(
                    text,
                    context: [], // Pass empty context since we're including it in the message
                    conversationHistory: conversationHistory
                )
                
                var accumulatedText = ""
                
                for try await response in streamingResponse {
                    // Check if task was cancelled
                    if Task.isCancelled {
                        print("🛑 Streaming task was cancelled")
                        break
                    }
                    
                    switch response {
                    case .textDelta(let deltaText):
                        accumulatedText += deltaText
                        delegate?.streamingDidReceiveText(accumulatedText, for: aiMessage.id)
                        
                    case .messageStop:
                        print("✅ Streaming complete")
                        delegate?.streamingDidComplete(
                            with: accumulatedText,
                            messageId: aiMessage.id,
                            documentReferences: documentContext.map { $0.id }
                        )
                        break
                        
                    case .error(let errorMessage):
                        print("❌ Streaming error: \(errorMessage)")
                        throw APIError.requestFailed(errorMessage)
                        
                    default:
                        // Handle other streaming events (messageStart, contentBlockStart, etc.)
                        print("🔄 Streaming event: \(response)")
                    }
                }
                
            } catch {
                print("❌ Streaming error: \(error)")
                delegate?.streamingDidFail(
                    with: error,
                    messageId: aiMessage.id
                )
            }
        }
    }
    
    /// Cancel any ongoing streaming operation
    func cancelCurrentStreaming() {
        streamingTask?.cancel()
        streamingTask = nil
    }
    
    /// Validate API connection
    func validateAPIConnection(settingsManager: SettingsManager) async -> Bool {
        guard settingsManager.isAPIKeyValid else {
            return false
        }
        
        if claudeAPIService == nil {
            claudeAPIService = ClaudeAPIService(settingsManager: settingsManager)
        }
        
        do {
            return try await claudeAPIService?.validateConnection() ?? false
        } catch {
            return false
        }
    }
}

// MARK: - StreamingChatServiceDelegate

protocol StreamingChatServiceDelegate: AnyObject {
    func streamingDidStart()
    func streamingDidCreateMessage(_ message: ChatMessage)
    func streamingDidReceiveText(_ text: String, for messageId: UUID)
    func streamingDidComplete(with text: String, messageId: UUID, documentReferences: [UUID])
    func streamingDidFail(with error: Error, messageId: UUID)
} 