//
//  StreamingChatService.swift
//  cerebral
//
//  Created by Assistant on 26/06/2025.
//

import Foundation

/// Service responsible for handling streaming chat functionality
final class StreamingChatService: StreamingChatServiceProtocol {
    private var claudeAPIService: ClaudeAPIService?
    private var streamingTask: Task<Void, Never>?
    
    private weak var delegate: StreamingChatServiceDelegate?
    
    // Performance monitoring
    private let performanceMonitor = PerformanceMonitor.shared
    
    init(delegate: StreamingChatServiceDelegate) {
        self.delegate = delegate
    }
    
    deinit {
        // Ensure cleanup on deinitialization
        streamingTask?.cancel()
        streamingTask = nil
        claudeAPIService = nil
    }
    
    /// Send a streaming message to Claude API
    @MainActor
    func sendStreamingMessage(
        _ text: String,
        settingsManager: SettingsManager,
        documentContext: [Document] = [],
        hiddenContext: String? = nil,
        conversationHistory: [ChatMessage]
    ) async {
        performanceMonitor.startMeasuring(identifier: "streaming_message")
        
        // Cancel any existing streaming task to prevent memory leaks
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
        
        // Extract document IDs for cross-actor communication
        let documentContextIds = documentContext.map { $0.id }
        
        // Use structured concurrency for better memory management
        streamingTask = Task { [weak self, weak delegate] in
            guard let self = self, let delegate = delegate else { return }
            
            do {
                guard let apiService = self.claudeAPIService else {
                    throw ChatError.requestFailed("API service not initialized")
                }
                
                let streamingResponse = apiService.sendMessageStream(
                    text,
                    context: [], // Pass empty context since we're including it in the message
                    conversationHistory: conversationHistory
                )
                
                var accumulatedText = ""
                let maxAccumulatedLength = 100_000 // Prevent excessive memory usage
                
                for try await response in streamingResponse {
                    // Check if task was cancelled early
                    try Task.checkCancellation()
                    
                    switch response {
                    case .textDelta(let deltaText):
                        // Prevent memory bloat from extremely long responses
                        if accumulatedText.count + deltaText.count > maxAccumulatedLength {
                            print("⚠️ Response truncated for memory management")
                            break
                        }
                        
                        accumulatedText += deltaText
                        await MainActor.run {
                            delegate.streamingDidReceiveText(accumulatedText, for: aiMessage.id)
                        }
                        
                    case .messageStop:
                        print("✅ Streaming complete")
                        await MainActor.run {
                            delegate.streamingDidComplete(
                                with: accumulatedText,
                                messageId: aiMessage.id,
                                documentReferences: documentContextIds
                            )
                        }
                        break
                        
                    case .error(let errorMessage):
                        print("❌ Streaming error: \(errorMessage)")
                        throw ChatError.requestFailed(errorMessage)
                        
                    default:
                        // Handle other streaming events (messageStart, contentBlockStart, etc.)
                        print("🔄 Streaming event: \(response)")
                    }
                }
                
            } catch is CancellationError {
                print("🛑 Streaming task was cancelled")
                // Clean cancellation, no need to report as error
            } catch {
                print("❌ Streaming error: \(error)")
                await MainActor.run {
                    delegate.streamingDidFail(
                        with: error,
                        messageId: aiMessage.id
                    )
                }
            }
            
            // Clean up task reference
            await MainActor.run { [weak self] in
                self?.streamingTask = nil
                self?.performanceMonitor.endMeasuring(identifier: "streaming_message")
            }
        }
    }
    
    /// Cancel any ongoing streaming operation
    func cancelCurrentStreaming() {
        streamingTask?.cancel()
        streamingTask = nil
        Task { @MainActor in
            performanceMonitor.endMeasuring(identifier: "streaming_message")
        }
    }
    
    /// Validate API connection
    @MainActor
    func validateAPIConnection(settingsManager: SettingsManager) async -> Bool {
        guard settingsManager.isAPIKeyValid else {
            return false
        }
        
        if claudeAPIService == nil {
            claudeAPIService = ClaudeAPIService(settingsManager: settingsManager)
        }
        
        do {
            let isValid = try await claudeAPIService?.validateConnection() ?? false
            
            // Clear API service if validation fails to force re-initialization
            if !isValid {
                claudeAPIService = nil
            }
            
            return isValid
        } catch {
            // Clear API service on error to force re-initialization
            claudeAPIService = nil
            return false
        }
    }
}

// MARK: - StreamingChatServiceDelegate

@MainActor
protocol StreamingChatServiceDelegate: AnyObject {
    func streamingDidStart()
    func streamingDidCreateMessage(_ message: ChatMessage)
    func streamingDidReceiveText(_ text: String, for messageId: UUID)
    func streamingDidComplete(with text: String, messageId: UUID, documentReferences: [UUID])
    func streamingDidFail(with error: Error, messageId: UUID)
} 