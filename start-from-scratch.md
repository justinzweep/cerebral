# Cerebral macOS App - Product Specification
## Starting Fresh with Production-Ready Architecture

---

## 🎯 Executive Summary

**Cerebral** is a document-focused AI assistant for macOS that enables intelligent conversations with PDF documents using RAG (Retrieval Augmented Generation). The app combines native macOS document management with on-device vector search and AI-powered chat functionality.

**Vision**: Transform how users interact with their document collections by making information instantly accessible through natural conversation.

---

## 📋 Core Value Proposition

### Primary Use Cases
1. **Research & Analysis**: Academics and professionals analyzing large document collections
2. **Legal Document Review**: Lawyers searching through case files and contracts  
3. **Technical Documentation**: Engineers accessing knowledge from manuals and specifications
4. **Personal Knowledge Management**: Individuals organizing and querying their document libraries

### Key Differentiators
- **Native macOS Experience**: Full document-based app with Finder integration
- **On-Device Vector Search**: Privacy-first approach using ObjectBox
- **Contextual AI Conversations**: Precise document references with visual navigation
- **Seamless PDF Integration**: Native PDF viewing with smart highlighting and navigation

---

## 🏗️ Architecture Overview

### Document-Based App Foundation
Following [Apple's File Management Guidelines](https://developer.apple.com/design/human-interface-guidelines/file-management):

```swift
@main
struct CerebralApp: App {
    var body: some Scene {
        DocumentGroup(newDocument: CerebralDocument()) { file in
            ContentView(document: file.$document)
        }
        .commands {
            CerebralCommands()
        }
    }
}
```

**Benefits:**
- Automatic recent documents menu
- Native file management integration
- iCloud document sync support
- Proper document lifecycle management
- Familiar macOS user experience

### Core Data Models

```swift
// Main document container
final class CerebralDocument: FileDocument, ObservableObject {
    var library: DocumentLibrary
    var chatSessions: [ChatSession]
    var settings: DocumentSettings
}

// Individual PDF document
struct PDFDocument: Identifiable {
    let id: UUID
    var title: String
    var fileURL: URL
    var metadata: DocumentMetadata
    var processingStatus: ProcessingStatus
}

// Chat conversation
struct ChatSession: Identifiable {
    let id: UUID
    var title: String
    var messages: [ChatMessage]
    var contextDocuments: Set<UUID>
    var createdAt: Date
}
```

---

## 🎨 User Interface Design

### Native macOS Design System

Following [macOS Design Guidelines](https://developer.apple.com/design/human-interface-guidelines/macos):

#### Window Structure
```
┌─ Toolbar ──────────────────────────────────────────┐
├─ Sidebar ─┬─ Main Content ─┬─ Inspector/Chat ──────┤  
│          │                │                       │
│ Document │   PDF Viewer   │    AI Assistant       │
│ Library  │      or        │                       │
│          │  Welcome View  │  • Chat Interface     │
│          │                │  • Document Context   │
│          │                │  • Search Results     │
└──────────┴────────────────┴───────────────────────┘
```

#### Visual Hierarchy
- **SF Symbols** for consistent iconography
- **Dynamic Type** support for accessibility
- **Dark/Light mode** adaptive colors
- **Native materials** (sidebar, toolbar, etc.)
- **Proper focus management** with keyboard navigation

### Key Views
1. **Welcome View**: Onboarding and quick actions
2. **Document Library**: Sidebar with document management
3. **PDF Viewer**: Native PDF display with highlighting
4. **Chat Interface**: Conversation view with context indicators
5. **Settings**: Preferences window with API configuration

---

## 🚀 Onboarding Experience

Following [Apple's Onboarding Guidelines](https://developer.apple.com/design/human-interface-guidelines/onboarding):

### Progressive Disclosure Approach

#### 1. Welcome Screen
```swift
struct WelcomeView: View {
    @State private var onboardingStep: OnboardingStep = .welcome
    
    var body: some View {
        NavigationStack {
            switch onboardingStep {
            case .welcome:
                WelcomeScreenView()
            case .documentImport:
                DocumentImportGuide()
            case .apiSetup:
                APIConfigurationView()
            case .firstChat:
                FirstChatExperience()
            }
        }
    }
}
```

#### Onboarding Flow
1. **Welcome & Value Proposition** (30 seconds)
   - Brief app introduction
   - Key benefits visualization
   - Optional quick tour

2. **Import Your First Document** (1 minute)
   - Drag & drop demonstration
   - File picker introduction
   - Processing explanation

3. **Configure AI Assistant** (2 minutes)
   - API key setup with clear instructions
   - Privacy explanation
   - Optional model selection

4. **Your First Chat** (2 minutes)
   - Guided conversation example
   - Context indicators explanation
   - Basic features walkthrough

#### Design Principles
- **Immediate Value**: Show benefits before asking for setup
- **Optional Depth**: Advanced features discoverable later
- **Contextual Help**: Just-in-time guidance
- **Skip-able**: Power users can bypass steps

---

## 🔍 Vector Search Implementation

### ObjectBox Integration

Using [ObjectBox On-Device Vector Search](https://docs.objectbox.io/on-device-vector-search):

```swift
import ObjectBox

@Entity
class DocumentChunk {
    var id: Id = 0
    var text: String = ""
    var documentId: String = ""
    var pageNumber: Int = 0
    
    @HnswIndex(dimensions: 1536, distanceType: .cosine)
    var embedding: [Float] = []
}

class VectorSearchService {
    private let store: Store
    private let chunkBox: Box<DocumentChunk>
    
    func storeChunks(_ chunks: [DocumentChunk]) throws {
        try chunkBox.put(chunks)
    }
    
    func searchSimilar(query: String, limit: Int = 10) async throws -> [DocumentChunk] {
        let queryEmbedding = try await generateEmbedding(query)
        
        let query = chunkBox.query(
            DocumentChunk_.embedding.nearestNeighbors(queryEmbedding, limit)
        ).build()
        
        return try query.find()
    }
}
```

**Benefits over current Python server approach:**
- **No External Dependencies**: Fully on-device processing
- **Better Performance**: Native Swift integration
- **Improved Privacy**: All processing local
- **Simplified Deployment**: Single app bundle
- **Offline Capability**: Works without internet

### Embedding Strategy
1. **Document Processing**: Chunk PDFs into semantic sections
2. **Embedding Generation**: Use local embedding model or OpenAI API
3. **Index Management**: Automatic indexing with progress indicators
4. **Search Optimization**: Configurable similarity thresholds

---

## 🗂️ Information Architecture

### Hierarchical Organization

```
Cerebral Document (.cerebral)
├── Document Library/
│   ├── PDF Files/
│   ├── Metadata/
│   └── Vector Index/
├── Chat Sessions/
│   ├── Conversations/
│   └── Context Maps/
└── Settings/
    ├── AI Configuration/
    └── User Preferences/
```

### Data Flow Architecture

```
User Input → Context Builder → Vector Search → AI Service → Response
     ↓              ↓              ↓           ↓         ↓
   UI State → Document Context → Embeddings → API → Chat Interface
```

---

## ⚙️ Technical Implementation

### Simplified Service Architecture

Replace complex ServiceContainer with focused, single-responsibility services:

```swift
// Core application services
final class DocumentManager: ObservableObject {
    // Document CRUD operations
    // PDF processing coordination
    // File system management
}

final class ChatManager: ObservableObject {
    // Chat session management
    // Message handling
    // Streaming responses
}

final class SearchManager: ObservableObject {
    // Vector search operations  
    // Context building
    // Relevance scoring
}

final class SettingsManager: ObservableObject {
    // User preferences
    // API configuration
    // App settings
}
```

### State Management Strategy

Use SwiftUI's native observation system:

```swift
@Observable
final class AppModel {
    var documentManager = DocumentManager()
    var chatManager = ChatManager()
    var searchManager = SearchManager()
    var settingsManager = SettingsManager()
    
    // Centralized app state
    var currentDocument: CerebralDocument?
    var selectedPDF: PDFDocument?
    var activeChat: ChatSession?
}
```

### SwiftData Integration

```swift
@Model
final class ChatMessage {
    var id: UUID = UUID()
    var content: String = ""
    var isFromUser: Bool = false
    var timestamp: Date = Date()
    var documentReferences: [DocumentReference] = []
}

@Model  
final class DocumentReference {
    var documentId: UUID = UUID()
    var pageNumbers: [Int] = []
    var textSelection: String?
    var relevanceScore: Double = 0
}
```

---

## 🎛️ Feature Specifications

### Core Features (MVP)

#### 1. Document Management
- **Import**: Drag & drop, file picker, folder import
- **Organization**: Collections, tags, search
- **Processing**: Automatic text extraction and chunking
- **Preview**: Thumbnail generation and metadata display

#### 2. PDF Viewer
- **Native Rendering**: PDFKit integration with performance optimization
- **Navigation**: Page thumbnails, outline view, search
- **Annotations**: Highlighting with context preservation
- **Selection**: Text selection with chat integration

#### 3. AI Chat Interface
- **Context-Aware**: Automatic document context detection
- **Visual References**: Click-to-navigate document citations
- **Streaming**: Real-time response generation
- **History**: Persistent chat sessions with search

#### 4. Vector Search
- **Semantic Search**: Natural language document queries
- **Context Building**: Intelligent chunk selection for chat
- **Relevance Scoring**: Configurable similarity thresholds
- **Performance**: Sub-100ms search response times

### Advanced Features (Post-MVP)

#### 1. Smart Collections
- **Auto-categorization**: ML-based document classification
- **Related Documents**: Similarity-based groupings
- **Topic Extraction**: Automatic keyword and theme detection

#### 2. Multi-Modal Search
- **Image Search**: Find documents containing similar images
- **Table Extraction**: Structured data queries
- **Formula Recognition**: Mathematical content search

#### 3. Collaboration
- **Shared Collections**: Team document libraries
- **Annotations Sync**: Collaborative highlighting
- **Chat Sharing**: Export conversations with references

#### 4. Advanced AI Features  
- **Document Summarization**: Automatic chapter/section summaries
- **Question Generation**: Suggested queries based on content
- **Comparative Analysis**: Multi-document insights

---

## 🛡️ Privacy & Security

### Data Protection
- **Local Processing**: All vector search on-device
- **Encrypted Storage**: Document data encrypted at rest
- **API Key Security**: Keychain storage with access controls
- **Network Isolation**: Optional offline mode

### User Control
- **Data Ownership**: Users control all document data
- **Processing Transparency**: Clear indication of AI processing
- **Export/Import**: Full data portability
- **Deletion Guarantees**: Complete data removal on request

---

## 🧪 Testing Strategy

### Automated Testing

```swift
// Unit Tests
class DocumentManagerTests: XCTestCase {
    func testDocumentImport() { }
    func testVectorSearchAccuracy() { }
    func testChatContextBuilding() { }
}

// UI Tests  
class CerebralUITests: XCTestCase {
    func testOnboardingFlow() { }
    func testDocumentToChat() { }
    func testPDFNavigation() { }
}

// Performance Tests
class VectorSearchPerformanceTests: XCTestCase {
    func testSearchResponseTime() { }
    func testBulkDocumentProcessing() { }
}
```

### Manual Testing
- **Device Testing**: Various Mac models and OS versions
- **Document Types**: PDF varieties and edge cases
- **Network Conditions**: Offline functionality verification
- **Accessibility**: VoiceOver and keyboard navigation

---

## 📊 Success Metrics

### User Experience Metrics
- **Time to First Value**: < 5 minutes from launch to first chat
- **Search Response Time**: < 100ms for vector queries
- **Document Processing**: < 30 seconds per PDF
- **App Launch Time**: < 2 seconds cold start

### Feature Adoption
- **Onboarding Completion**: > 80% complete full flow
- **Daily Active Usage**: Average session > 15 minutes
- **Document Import**: Average > 10 documents per user
- **Chat Engagement**: > 5 messages per session

### Technical Performance
- **Memory Usage**: < 500MB with 100 documents
- **Storage Efficiency**: < 2x original document size
- **Search Accuracy**: > 90% relevant results in top 5
- **Crash Rate**: < 0.1% of sessions

---

## 🗓️ Development Roadmap

### Phase 1: Foundation (4-6 weeks)
- [ ] Document-based app architecture
- [ ] Basic PDF viewer with SwiftUI
- [ ] ObjectBox vector search integration
- [ ] Simple chat interface
- [ ] Core data models

### Phase 2: Core Features (4-6 weeks)
- [ ] Onboarding flow implementation
- [ ] Document management UI
- [ ] Context-aware chat system
- [ ] PDF highlighting and navigation
- [ ] Settings and configuration

### Phase 3: Polish & Optimization (3-4 weeks)
- [ ] Performance optimization
- [ ] UI/UX refinements
- [ ] Comprehensive testing
- [ ] Documentation and help system
- [ ] Beta release preparation

### Phase 4: Advanced Features (6-8 weeks)
- [ ] Smart collections
- [ ] Multi-modal search
- [ ] Collaboration features
- [ ] Advanced AI capabilities
- [ ] Public release

---

## 🔧 Development Setup

### Prerequisites
```bash
# Required tools
- Xcode 15.0+
- macOS 14.0+ deployment target
- ObjectBox Swift SDK
- SwiftLint for code quality

# Optional tools
- SF Symbols app for iconography
- Create ML for custom models
- Instruments for performance profiling
```

### Project Structure
```
Cerebral/
├── App/
│   ├── CerebralApp.swift
│   └── AppModel.swift
├── Features/
│   ├── Onboarding/
│   ├── Documents/
│   ├── Chat/
│   └── Settings/
├── Shared/
│   ├── Models/
│   ├── Services/
│   └── DesignSystem/
├── Resources/
│   ├── Assets.xcassets
│   └── Localizable.strings
└── Tests/
    ├── UnitTests/
    ├── UITests/
    └── PerformanceTests/
```

### Code Quality Standards
- **SwiftUI Best Practices**: View composition, state management
- **Accessibility**: Full VoiceOver support, Dynamic Type
- **Performance**: Lazy loading, memory management
- **Documentation**: Comprehensive code documentation
- **Testing**: >80% code coverage target

---

## 🎯 Migration Strategy

### From Current "Vibe Coded" Version

#### Code Audit & Extraction
1. **Identify Keepers**: Well-functioning components to preserve
2. **Extract Learnings**: Document architectural decisions that worked
3. **Map Data**: Understand current data structures and flows
4. **Test Coverage**: Ensure existing functionality is tested

#### Incremental Migration
1. **Parallel Development**: Build new architecture alongside current
2. **Feature Parity**: Ensure no regression in core functionality  
3. **Data Migration**: Seamless transition of user data
4. **A/B Testing**: Compare new vs old implementations

#### Risk Mitigation
- **Rollback Plan**: Ability to revert to current version
- **User Communication**: Clear timeline and benefit explanation
- **Backup Strategy**: Multiple data backup points
- **Gradual Rollout**: Beta testing with subset of users

---

## 💡 Key Architectural Decisions

### Why Document-Based App?
- **Native macOS Experience**: Familiar file management patterns
- **Better Organization**: Natural document-centric workflow
- **iCloud Integration**: Automatic document sync across devices
- **Extensibility**: Easy to add new document types

### Why ObjectBox Over Python Server?
- **Simplified Deployment**: Single app bundle, no external dependencies
- **Better Performance**: Native Swift integration, optimized queries
- **Improved Privacy**: All processing stays on device
- **Offline Capability**: Full functionality without internet

### Why SwiftUI + SwiftData?
- **Modern Development**: Latest Apple frameworks and patterns
- **Performance**: Optimized for Apple Silicon Macs
- **Maintainability**: Declarative UI, automatic view updates
- **Future-Proof**: Aligned with Apple's strategic direction

---

## 🔍 Potential Challenges & Solutions

### Challenge: Vector Search Performance
**Solution**: Implement progressive indexing with background processing and smart caching strategies.

### Challenge: Large Document Handling  
**Solution**: Streaming PDF processing with paginated chunk loading and memory-mapped file access.

### Challenge: API Cost Management
**Solution**: Local embedding models for search, API only for chat generation with usage monitoring.

### Challenge: User Onboarding Complexity
**Solution**: Progressive disclosure with optional advanced features and contextual help system.

---

## 📖 Conclusion

This specification provides a roadmap for rebuilding Cerebral as a production-ready macOS application that follows Apple's design guidelines and modern development practices. The focus on document-based architecture, on-device vector search, and progressive onboarding will create a superior user experience while maintaining the core value proposition of intelligent document interaction.

The modular architecture and comprehensive testing strategy ensure the application can scale effectively while maintaining high performance and reliability standards.

---

*This specification serves as the foundation for the complete rebuild of Cerebral, incorporating lessons learned from the initial "vibe coded" version while establishing a solid architectural foundation for long-term growth and maintenance.*
