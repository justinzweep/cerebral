# Cerebral Codebase Analysis and Refactoring Plan

This document outlines a comprehensive plan to simplify the Cerebral codebase based on a detailed analysis of all files. The analysis reveals several areas where complexity has grown beyond necessity, creating maintenance challenges and architectural debt.

## Executive Summary

The Cerebral app is a sophisticated PDF reader with AI chat integration, featuring highlighting, context management, and document organization. However, the codebase has accumulated significant complexity through:

1. **Massive state objects** that violate single responsibility
2. **Over-engineered service architecture** with excessive abstraction layers
3. **Complex highlighting system** with deep PDF integration in state management
4. **Inconsistent dependency injection** mixing singletons with service containers
5. **Business logic scattered across views** instead of being centralized

## 1. Critical: AppState God Object

### Analysis

The `AppState` class (434 lines) has become a massive god object managing:

- **UI State**: `showingChat`, `showingSidebar`, `showingImporter`
- **Document Selection**: `selectedDocument`, `documentToAddToChat`
- **PDF-to-Chat Feature**: `pdfSelections`, `isReadyForChatTransition`, `shouldFocusChatInput`, `showPDFSelectionPills`, `pendingTypedCharacter`
- **PDF Navigation**: `pendingPageNavigation`
- **Complete Highlighting System**: `highlightingState`, `highlights` dictionary, full undo/redo stacks
- **Complex PDF Operations**: Direct integration with `PDFToolbarService`, PDF document loading, selection recreation

**Most concerning**: The highlighting system includes 150+ lines of PDF manipulation code directly in the state manager, with async operations, error handling, and tight coupling to PDF services.

### Proposed Changes

**Phase 1: Extract Highlighting System**
```swift
@Observable
final class HighlightingManager {
    var highlights: [UUID: PDFHighlight] = [:]
    var highlightingState = HighlightingState()
    private var undoStack: [HighlightOperation] = []
    private var redoStack: [HighlightOperation] = []
    
    // Move all highlighting logic here
    func addHighlight(_ highlight: PDFHighlight) { ... }
    func performUndo() async { ... }
    func performRedo() async { ... }
}
```

**Phase 2: Extract PDF-Chat Interaction**
```swift
@Observable
final class PDFChatInteractionManager {
    var pdfSelections: [PDFSelectionInfo] = []
    var isReadyForChatTransition: Bool = false
    var shouldFocusChatInput: Bool = false
    var showPDFSelectionPills: Bool = false
    var pendingTypedCharacter: String?
    
    // Move all PDF-to-chat coordination here
}
```

**Phase 3: Simplify Core AppState**
```swift
@Observable
final class AppState {
    // Only core UI and document state
    var selectedDocument: Document?
    var showingChat = true
    var showingSidebar = true
    var showingImporter = false
    var pendingDocumentImport = false
    var documentToAddToChat: Document?
    var pendingPageNavigation: Int?
}
```

## 2. Over-Engineered Service Architecture

### Analysis

The service architecture has multiple layers of abstraction that add complexity without clear benefit:

1. **ServiceContainer**: Singleton that manages all services
2. **Service Protocols**: Abstract interfaces for everything
3. **Multiple Singleton Services**: Each service is also a singleton
4. **Complex Service Dependencies**: Services depend on other services through the container

**Example of over-engineering**:
```swift
// Current: 3 layers of indirection
ServiceContainer.shared.documentService.importDocument(...)

// What's actually needed:
DocumentService.importDocument(...)
```

### Proposed Changes

**Eliminate ServiceContainer Singleton**
- Remove the global `ServiceContainer.shared`
- Inject services directly through SwiftUI environment
- Use `@Environment` for service access in views

**Simplify Service Architecture**
```swift
// Create environment keys
extension EnvironmentValues {
    var documentService: DocumentService {
        get { self[DocumentServiceKey.self] }
        set { self[DocumentServiceKey.self] = newValue }
    }
}

// In CerebralApp.swift
ContentView()
    .environment(\.documentService, DocumentService())
    .environment(\.pdfService, PDFService())
```

**Remove Unnecessary Protocols**
- Keep protocols only where actual abstraction is needed (testing, multiple implementations)
- Remove protocols that have only one implementation

## 3. Complex Context Management System

### Analysis

The context management system is overly complex with multiple overlapping concepts:

- `DocumentContext` with 5 different types
- `ChatContextBundle` for session management
- `ContextManagementService` with caching layers
- `MessageBuilder` and `EnhancedMessageBuilder` doing similar things
- Complex token counting and optimization

**The system has 3 different ways to represent document content**:
1. Raw `Document` objects
2. `DocumentContext` with metadata
3. `ChatContextBundle` for sessions

### Proposed Changes

**Simplify Context Representation**
```swift
// Single context type instead of 5
enum DocumentContent {
    case fullDocument(Document)
    case textSelection(text: String, document: Document, metadata: SelectionMetadata)
    case pageRange(pages: [Int], document: Document)
}

// Simplified message context
struct MessageContext {
    let content: DocumentContent
    let tokenCount: Int
}
```

**Eliminate Redundant Services**
- Merge `MessageBuilder` and `EnhancedMessageBuilder`
- Simplify `ContextManagementService` by removing complex caching
- Move token counting to a simple utility function

## 4. Business Logic in Views

### Analysis

Views contain substantial business logic that should be in dedicated managers:

**ChatView.swift** (340 lines):
- Complex `sendMessage()` function (60+ lines)
- PDF selection processing logic
- Document context creation
- Error handling and retry logic

**ContentView.swift** (239 lines):
- Complex layout calculations (6 helper methods)
- Application lifecycle management
- File import handling
- Global error handling

### Proposed Changes

**Extract ChatManager Business Logic**
```swift
// Move from ChatView to ChatManager
func sendMessage(
    text: String,
    attachedDocuments: [Document],
    pdfSelections: [PDFSelectionInfo]
) async {
    // All the complex processing logic goes here
}
```

**Create Layout Manager for ContentView**
```swift
@Observable
final class LayoutManager {
    var sidebarWidth: CGFloat = 280
    var chatWidth: CGFloat = 320
    
    func constrainedSidebarWidth(for totalWidth: CGFloat) -> CGFloat { ... }
    func updateSidebarWidth(delta: CGFloat, availableWidth: CGFloat) { ... }
}
```

## 5. Inconsistent Design System

### Analysis

The design system has been partially consolidated but still has inconsistencies:

- Some components use consolidated files (`Buttons.swift`, `Theme.swift`)
- Others still use individual files or direct styling
- Mixed usage of design tokens vs. hardcoded values

### Proposed Changes

**Complete Design System Consolidation**
- Move all remaining individual component files to consolidated ones
- Ensure all views use design tokens instead of hardcoded values
- Create view modifiers for common styling patterns

## 6. Redundant Error Handling

### Analysis

Error handling is implemented at multiple levels:

- `AppError` enum with nested error types
- `ErrorManager` for global error handling
- Individual service error handling
- View-level error handling

This creates complexity without clear benefit, as most errors end up being displayed the same way.

### Proposed Changes

**Simplify Error Architecture**
```swift
// Single error type instead of nested hierarchy
enum AppError: LocalizedError {
    case apiKeyInvalid(String)
    case networkFailure(String)
    case documentImportFailed(String)
    case pdfError(String)
    
    var errorDescription: String? { ... }
    var recoverySuggestion: String? { ... }
}
```

## Implementation Priority

### Phase 1: Critical (Week 1-2)
1. **Extract HighlightingManager** from AppState
2. **Simplify ChatView** by moving business logic to ChatManager
3. **Remove ServiceContainer** and implement environment-based DI

### Phase 2: Important (Week 3-4)
4. **Extract PDFChatInteractionManager** from AppState
5. **Simplify ContentView** with LayoutManager
6. **Consolidate context management** system

### Phase 3: Polish (Week 5-6)
7. **Complete design system** consolidation
8. **Simplify error handling** architecture
9. **Remove redundant service layers**

## Expected Outcomes

- **Reduced complexity**: ~40% reduction in lines of code in core files
- **Improved testability**: Clear separation of concerns enables unit testing
- **Better maintainability**: Single responsibility principle followed throughout
- **Enhanced performance**: Reduced object graph complexity and better state management
- **Clearer architecture**: Explicit dependencies and focused components

## Risk Mitigation

- **Incremental changes**: Each phase can be implemented and tested separately
- **Backward compatibility**: Maintain existing APIs during transition
- **Feature preservation**: All current functionality will be preserved
- **Testing strategy**: Add tests for extracted components before refactoring
