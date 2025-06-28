# Chat Context Management Architecture

## Overview
This document outlines a comprehensive redesign of the context management system for Cerebral, following RAG (Retrieval-Augmented Generation) best practices and modern GenAI application patterns.

## Current Issues
1. **Fragmented Context Sources**: Context comes from multiple sources (sidebar buttons, text selection, @ mentions, default open PDF) with no unified handling
2. **Poor Structure**: Context is stored as raw strings (hiddenContext) without metadata or structure
3. **No Provenance Tracking**: Can't track which parts of which documents were used
4. **Repeated Processing**: Text extraction happens multiple times for the same content
5. **Limited Visibility**: Users can't see what context was sent with each message
6. **No Caching**: Extracted text and embeddings aren't cached

## Proposed Architecture

### 1. Core Data Models

```swift
// Represents a single piece of context from a document
struct DocumentContext: Codable, Identifiable, Sendable {
    let id: UUID
    let documentId: UUID
    let documentTitle: String
    let contextType: ContextType
    let content: String
    let metadata: ContextMetadata
    let extractedAt: Date
    
    enum ContextType: String, Codable {
        case fullDocument      // Entire document
        case pageRange        // Specific pages
        case textSelection    // User-selected text
        case semanticChunk    // AI-extracted relevant chunk
        case reference        // @ mention reference
    }
}

struct ContextMetadata: Codable {
    let pageNumbers: [Int]?
    let selectionBounds: [CGRect]?
    let characterRange: NSRange?
    let extractionMethod: String
    let tokenCount: Int
    let checksum: String  // For cache validation
}

// Enhanced ChatMessage with structured context
struct ChatMessage: Codable, Identifiable, Sendable {
    let id: UUID
    var text: String
    let isUser: Bool
    let timestamp: Date
    var contexts: [DocumentContext]  // Replaces documentReferences and hiddenContext
    var isStreaming: Bool
    var streamingComplete: Bool
    
    // Computed properties
    var referencedDocumentIds: [UUID] {
        Array(Set(contexts.map { $0.documentId }))
    }
    
    var totalTokenCount: Int {
        contexts.reduce(0) { $0 + $1.metadata.tokenCount }
    }
}

// Context bundle for a chat session
struct ChatContextBundle: Codable {
    let sessionId: UUID
    var contexts: [DocumentContext]
    var activeDocumentId: UUID?  // Currently viewed document
    
    func tokenCount() -> Int {
        contexts.reduce(0) { $0 + $1.metadata.tokenCount }
    }
    
    func documentSummary() -> [UUID: Int] {
        // Returns document ID -> number of context pieces
        Dictionary(grouping: contexts, by: { $0.documentId })
            .mapValues { $0.count }
    }
}
```

### 2. Context Management Service

```swift
@MainActor
protocol ContextManagementServiceProtocol {
    // Context creation
    func createContext(from document: Document, type: DocumentContext.ContextType, selection: PDFSelection?) async throws -> DocumentContext
    func createContextFromText(_ text: String, document: Document, metadata: ContextMetadata) -> DocumentContext
    
    // Context retrieval
    func getContextsForSession(_ sessionId: UUID) -> [DocumentContext]
    func getContextsForDocument(_ documentId: UUID) -> [DocumentContext]
    
    // Context caching
    func getCachedContext(for document: Document, type: DocumentContext.ContextType) -> DocumentContext?
    func cacheContext(_ context: DocumentContext)
    func invalidateCache(for documentId: UUID)
    
    // Token management
    func estimateTokenCount(for text: String) -> Int
    func optimizeContextsForTokenLimit(_ contexts: [DocumentContext], limit: Int) -> [DocumentContext]
}

@MainActor
final class ContextManagementService: ContextManagementServiceProtocol {
    static let shared = ContextManagementService()
    
    private var contextCache = NSCache<NSString, DocumentContext>()
    private let tokenizer = TokenizerService() // New service for accurate token counting
    private let pdfService = PDFService.shared
    
    // Implementation details...
}
```

### 3. Enhanced Message Builder

```swift
@MainActor
final class EnhancedMessageBuilder: MessageBuilderServiceProtocol {
    private let contextService = ContextManagementService.shared
    private let documentResolver = DocumentReferenceResolver.shared
    
    func buildMessage(
        userInput: String,
        contextBundle: ChatContextBundle,
        sessionId: UUID
    ) async throws -> (processedText: String, contexts: [DocumentContext]) {
        var contexts: [DocumentContext] = []
        var processedText = userInput
        
        // 1. Process @ references
        let referencedDocs = documentResolver.extractDocumentReferences(from: userInput)
        for doc in referencedDocs {
            let context = try await contextService.createContext(
                from: doc,
                type: .reference,
                selection: nil
            )
            contexts.append(context)
            
            // Replace @ reference with a placeholder
            processedText = processedText.replacingOccurrences(
                of: "@\(doc.title)",
                with: "[REF:\(doc.id.uuidString)]"
            )
        }
        
        // 2. Add explicit context from bundle
        contexts.append(contentsOf: contextBundle.contexts)
        
        // 3. Add active document context if configured
        if let activeDocId = contextBundle.activeDocumentId,
           let activeDoc = await documentService.findDocument(byId: activeDocId),
           shouldIncludeActiveDocument() {
            if let cachedContext = contextService.getCachedContext(for: activeDoc, type: .fullDocument) {
                contexts.append(cachedContext)
            } else {
                let context = try await contextService.createContext(
                    from: activeDoc,
                    type: .fullDocument,
                    selection: nil
                )
                contexts.append(context)
            }
        }
        
        // 4. Optimize for token limit
        let optimizedContexts = contextService.optimizeContextsForTokenLimit(
            contexts,
            limit: getContextTokenLimit()
        )
        
        return (processedText, optimizedContexts)
    }
    
    func formatForLLM(text: String, contexts: [DocumentContext]) -> String {
        var formatted = ""
        
        // Group contexts by document
        let groupedContexts = Dictionary(grouping: contexts, by: { $0.documentId })
        
        for (_, docContexts) in groupedContexts {
            guard let first = docContexts.first else { continue }
            
            formatted += "=== Document: \(first.documentTitle) ===\n"
            
            for context in docContexts {
                switch context.contextType {
                case .fullDocument:
                    formatted += "Full Document Content:\n"
                case .pageRange:
                    let pages = context.metadata.pageNumbers?.map(String.init).joined(separator: ", ") ?? ""
                    formatted += "Pages \(pages):\n"
                case .textSelection:
                    formatted += "Selected Text:\n"
                case .semanticChunk:
                    formatted += "Relevant Section:\n"
                case .reference:
                    formatted += "Referenced Content:\n"
                }
                
                formatted += context.content + "\n\n"
            }
            
            formatted += String(repeating: "=", count: 50) + "\n\n"
        }
        
        formatted += "User Query: " + text
        
        return formatted
    }
}
```

### 4. UI Components for Context Visibility

```swift
// Context indicator for messages
struct MessageContextIndicator: View {
    let contexts: [DocumentContext]
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Summary view
            HStack {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.caption)
                
                Text(contextSummary)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Button(action: { isExpanded.toggle() }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption2)
                }
                .buttonStyle(.plain)
            }
            
            // Expanded details
            if isExpanded {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(contexts) { context in
                        ContextDetailRow(context: context)
                    }
                }
                .padding(.leading, 20)
            }
        }
    }
    
    private var contextSummary: String {
        let docCount = Set(contexts.map { $0.documentId }).count
        let tokenCount = contexts.reduce(0) { $0 + $1.metadata.tokenCount }
        return "\(docCount) document(s), ~\(tokenCount) tokens"
    }
}

// Active context panel for chat input
struct ActiveContextPanel: View {
    @Binding var contextBundle: ChatContextBundle
    let onRemoveContext: (DocumentContext) -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(contextBundle.contexts) { context in
                    ContextChip(
                        context: context,
                        onRemove: { onRemoveContext(context) }
                    )
                }
            }
        }
        .padding(.horizontal)
    }
}
```

### 5. Context Persistence and Caching

```swift
@MainActor
final class ContextCacheManager {
    private let cacheDirectory: URL
    private let maxCacheSize: Int = 100 * 1024 * 1024 // 100MB
    private let maxCacheAge: TimeInterval = 7 * 24 * 60 * 60 // 7 days
    
    init() {
        let cachePath = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        cacheDirectory = cachePath.appendingPathComponent("cerebral_contexts")
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
    
    func cacheContext(_ context: DocumentContext) async throws {
        let cacheKey = "\(context.documentId.uuidString)-\(context.contextType.rawValue)"
        let cacheFile = cacheDirectory.appendingPathComponent("\(cacheKey).json")
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(context)
        try data.write(to: cacheFile)
        
        // Clean up old cache entries
        await cleanupCache()
    }
    
    func getCachedContext(documentId: UUID, type: DocumentContext.ContextType) -> DocumentContext? {
        let cacheKey = "\(documentId.uuidString)-\(type.rawValue)"
        let cacheFile = cacheDirectory.appendingPathComponent("\(cacheKey).json")
        
        guard FileManager.default.fileExists(atPath: cacheFile.path),
              let data = try? Data(contentsOf: cacheFile),
              let context = try? JSONDecoder().decode(DocumentContext.self, from: data) else {
            return nil
        }
        
        // Validate cache freshness
        if Date().timeIntervalSince(context.extractedAt) > maxCacheAge {
            try? FileManager.default.removeItem(at: cacheFile)
            return nil
        }
        
        return context
    }
    
    private func cleanupCache() async {
        // Implementation for cache cleanup based on size and age
    }
}
```

### 6. Integration with Existing Components

#### Updated ChatManager
```swift
@MainActor
@Observable final class ChatManager {
    // ... existing properties ...
    
    private var currentContextBundle = ChatContextBundle(sessionId: UUID(), contexts: [])
    private let contextService = ContextManagementService.shared
    private let enhancedMessageBuilder = EnhancedMessageBuilder()
    
    func sendMessage(
        _ text: String,
        settingsManager: SettingsManager,
        explicitContexts: [DocumentContext] = []
    ) async {
        // Build message with context
        let (processedText, contexts) = try await enhancedMessageBuilder.buildMessage(
            userInput: text,
            contextBundle: currentContextBundle,
            sessionId: currentContextBundle.sessionId
        )
        
        // Create user message with contexts
        let userMessage = ChatMessage(
            text: text,  // Store original text for display
            isUser: true,
            contexts: contexts
        )
        messages.append(userMessage)
        
        // Format for LLM
        let llmMessage = enhancedMessageBuilder.formatForLLM(
            text: processedText,
            contexts: contexts
        )
        
        // Send to streaming service
        await streamingService.sendStreamingMessage(
            llmMessage,
            settingsManager: settingsManager,
            contexts: contexts,
            conversationHistory: messages
        )
    }
    
    func addContext(_ context: DocumentContext) {
        currentContextBundle.contexts.append(context)
    }
    
    func removeContext(_ context: DocumentContext) {
        currentContextBundle.contexts.removeAll { $0.id == context.id }
    }
    
    func clearContext() {
        currentContextBundle.contexts.removeAll()
    }
}
```

## Migration Strategy

### Phase 1: Core Infrastructure (Week 1)
1. Implement new data models (DocumentContext, enhanced ChatMessage)
2. Create ContextManagementService
3. Add context caching layer
4. Update MessageBuilder to EnhancedMessageBuilder

### Phase 2: Service Integration (Week 2)
1. Update ChatManager to use new context system
2. Modify StreamingChatService to handle structured contexts
3. Update PDFService to work with context service
4. Implement token counting service

### Phase 3: UI Updates (Week 3)
1. Add context visibility indicators to messages
2. Create active context panel for chat input
3. Update chat input to show context token count
4. Add context management UI

### Phase 4: Advanced Features (Week 4)
1. Implement semantic chunking for large documents
2. Add context search and filtering
3. Create context templates/presets
4. Add analytics for context usage

## Benefits

1. **Unified Context Management**: Single source of truth for all context types
2. **Better Performance**: Caching prevents repeated text extraction
3. **Improved Transparency**: Users can see exactly what context was sent
4. **Token Optimization**: Smart context selection based on token limits
5. **Better UX**: Clear indication of active context and easy management
6. **Extensibility**: Easy to add new context types (e.g., web search, embeddings)
7. **Analytics**: Track which contexts are most useful for improving RAG

## Technical Considerations

### Performance
- Use actor isolation for thread-safe context management
- Implement lazy loading for large contexts
- Cache frequently used contexts
- Use background queues for text extraction

### Storage
- Store contexts in SwiftData with relationships to messages
- Implement cleanup policies for old contexts
- Consider using compression for large text content

