# Cerebral Codebase Analysis and Refactoring Plan

This document outlines a comprehensive plan to simplify the Cerebral codebase based on a detailed analysis of all files. The analysis reveals several areas where complexity has grown beyond necessity, creating maintenance challenges and architectural debt.

## Executive Summary

The Cerebral app is a sophisticated PDF reader with AI chat integration, featuring highlighting, context management, and document organization. However, the codebase has accumulated significant complexity through:

1. **Massive state objects** that violate single responsibility
2. **Over-engineered service architecture** with excessive abstraction layers  
3. **Complex highlighting system** with deep PDF integration in state management
4. **Inconsistent dependency injection** mixing singletons with service containers
5. **Business logic scattered across views** instead of being centralized
6. **Custom implementations of native functionality** that could use SwiftUI/macOS APIs
7. **Over-engineered UI components** that duplicate system capabilities

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

## 7. Native SwiftUI/macOS API Replacements

### Analysis

The codebase contains numerous custom implementations that duplicate native SwiftUI/macOS functionality, adding unnecessary complexity and maintenance burden. These custom solutions often lack the accessibility, performance, and system integration benefits of native APIs.

### Critical Replacements (High Impact, Low Risk)

**KeyboardShortcutService.swift (195 lines) → Native SwiftUI Commands**
```swift
// Current: Complex NSEvent monitoring with manual key code handling
class KeyboardShortcutService {
    private func handleKeyEvent(_ event: NSEvent) -> NSEvent? {
        let keyCode = event.keyCode
        let modifierFlags = event.modifierFlags
        // ... 150+ lines of manual key handling
    }
}

// Replace with: Native SwiftUI commands (5 lines)
.commands {
    CommandGroup(after: .toolbar) {
        Button("Toggle Sidebar") { appState.toggleSidebar() }
            .keyboardShortcut("k", modifiers: .command)
        Button("Toggle Chat") { appState.toggleChatPanel() }
            .keyboardShortcut("l", modifiers: .command)
    }
}
```

**Custom Button Styles (Components.swift, 200+ lines) → Native Button Styles**
```swift
// Current: Manual hover/press state management
struct PrimaryButtonStyle: ButtonStyle {
    @State private var isHovered = false
    func makeBody(configuration: Configuration) -> some View {
        // ... 40+ lines of manual state handling
    }
}

// Replace with: Native button styles (1 line)
.buttonStyle(.borderedProminent)
.buttonStyle(.bordered)
.buttonStyle(.borderless)
```

**Custom Design System (Theme.swift, 400+ lines) → System Design Tokens**
```swift
// Current: Manual color/typography definitions
struct Colors {
    static let primaryText = Color.adaptive(light: Light.gray900, dark: Dark.gray100)
    static let secondaryText = Color.adaptive(light: Light.gray700, dark: Dark.gray300)
    // ... 300+ lines of manual color definitions
}

// Replace with: Native system colors (automatic dark mode)
Color.primary, Color.secondary, Color.accentColor
@Environment(\.colorScheme) var colorScheme
```

### Important Replacements (Medium Impact, Low Risk)

**Custom Error Alerts (ErrorAlert.swift, 217 lines) → Native Alert Modifier**
```swift
// Current: Custom alert view with manual button handling
struct ErrorAlert: View {
    // ... 200+ lines of custom alert implementation
}

// Replace with: Native alert modifier (10 lines)
.alert("Error", isPresented: $showingError, presenting: error) { error in
    Button("Retry") { handleRetry() }
    Button("Settings") { openSettings() }
    Button("OK") { }
} message: { error in
    Text(error.localizedDescription)
}
```

**Custom Typography System (Layout.swift, 220 lines) → Dynamic Type**
```swift
// Current: Manual font size definitions
struct Typography {
    static let body = Font.system(size: 13, weight: .regular)
    static let caption = Font.system(size: 10, weight: .medium)
    // ... 100+ lines of manual typography
}

// Replace with: System text styles (automatic Dynamic Type)
.font(.body)
.font(.caption)
.font(.headline)
```

**Manual State Preservation (PDFViewerRepresentable.swift) → Native State Management**
```swift
// Current: Complex manual state capture/restore
private struct PDFViewState {
    let scaleFactor: CGFloat
    let visibleRect: CGRect
    // ... manual state preservation logic
}

// Replace with: SwiftUI's automatic state management
@StateObject private var pdfCoordinator = PDFCoordinator()
```

### Lower Priority Replacements

**Custom Autocomplete (ChatInputView.swift, 522 lines) → Native Searchable/Popover**
```swift
// Current: Manual dropdown positioning and keyboard handling
@State private var showingAutocomplete = false
@State private var autocompleteDocuments: [Document] = []
// ... 100+ lines of manual autocomplete

// Replace with: Native popover or searchable modifier
.popover(isPresented: $showingAutocomplete) {
    DocumentSuggestionsList()
}
```

**Custom Token Counting (TokenizerService.swift, 359 lines) → Foundation NLP**
```swift
// Current: Manual character-based token estimation
func estimateTokenCount(for text: String) -> Int {
    let characterCount = cleanedText.count
    let estimatedTokens = Int(ceil(Double(characterCount) / averageCharactersPerToken))
    // ... manual calculation logic
}

// Replace with: Foundation's Natural Language framework
import NaturalLanguage
let tokenizer = NLTokenizer(unit: .word)
tokenizer.string = text
let tokenCount = tokenizer.tokens(for: text.startIndex..<text.endIndex).count
```

### Benefits of Native API Adoption

1. **Massive Code Reduction**: ~60% reduction in custom UI code
2. **Automatic Accessibility**: VoiceOver, keyboard navigation, Dynamic Type
3. **System Consistency**: Matches macOS design guidelines and behaviors
4. **Performance**: Native implementations are highly optimized
5. **Future-Proof**: Automatic updates with new macOS versions
6. **Reduced Maintenance**: Less custom code to debug and maintain
7. **Better Testing**: System components are already tested by Apple

### Migration Strategy

**Phase A: Immediate Wins (Week 1)**
- Replace KeyboardShortcutService with native commands
- Replace custom button styles with native variants
- Replace custom colors with system semantic colors

**Phase B: UI Simplification (Week 2)**  
- Replace custom error alerts with native alert modifiers
- Replace custom typography with system text styles
- Simplify design system to use native tokens

**Phase C: Advanced Components (Week 3)**
- Replace custom autocomplete with native components
- Simplify state management using native SwiftUI patterns
- Replace token counting with Foundation NLP APIs

## Implementation Priority

### Phase 1: Immediate Wins (Week 1)
**Native API Replacements (High Impact, Low Risk)**
1. **Replace KeyboardShortcutService** with native SwiftUI commands (195 → 20 lines)
2. **Replace custom button styles** with native `.buttonStyle()` variants (200+ → 10 lines)
3. **Replace custom colors** with system semantic colors (400+ → 50 lines)
4. **Replace custom error alerts** with native `.alert()` modifiers (217 → 15 lines)

**Architectural Improvements**
5. **Extract HighlightingManager** from AppState (reduce god object)

### Phase 2: Core Refactoring (Week 2-3)
**Architectural Simplification**
1. **Extract PDFChatInteractionManager** from AppState
2. **Remove ServiceContainer** and implement environment-based DI
3. **Simplify ChatView** by moving business logic to ChatManager

**Native API Integration**
4. **Replace custom typography** with system text styles and Dynamic Type
5. **Simplify state management** using native SwiftUI patterns

### Phase 3: Advanced Simplification (Week 4-5)
**System Integration**
1. **Replace custom autocomplete** with native components
2. **Replace TokenizerService** with Foundation NLP APIs
3. **Simplify ContentView** with native layout management

**Architecture Polish**
4. **Consolidate context management** system
5. **Complete design system** migration to native tokens

### Phase 4: Final Cleanup (Week 6)
1. **Remove redundant service layers**
2. **Simplify error handling** architecture
3. **Performance optimization** and testing
4. **Documentation** updates

## Expected Outcomes

### Code Quality & Architecture
- **Massive complexity reduction**: ~60% reduction in custom UI code, ~40% reduction in core architecture files
- **Improved testability**: Clear separation of concerns enables comprehensive unit testing
- **Better maintainability**: Single responsibility principle followed throughout
- **Clearer architecture**: Explicit dependencies and focused components

### System Integration & Performance  
- **Native system integration**: Automatic dark mode, accessibility, and macOS design consistency
- **Enhanced performance**: Native implementations + reduced object graph complexity
- **Future-proof codebase**: Automatic updates with new macOS versions
- **Reduced maintenance burden**: ~1000+ lines of custom code replaced with native APIs

### User Experience
- **Automatic accessibility**: VoiceOver, keyboard navigation, Dynamic Type support
- **System consistency**: Matches macOS behavior patterns users expect
- **Better performance**: Native rendering and interaction handling
- **Improved reliability**: Battle-tested system components vs. custom implementations

## Risk Mitigation

### Low Risk: Native API Replacements (Phase 1)
- **Drop-in replacements**: Most native APIs are direct replacements for custom code
- **System tested**: Native APIs are thoroughly tested by Apple
- **Reversible**: Easy to revert if issues arise
- **Incremental**: Each component can be replaced independently

### Medium Risk: Architectural Changes (Phases 2-3)
- **Incremental refactoring**: Each phase can be implemented and tested separately
- **Backward compatibility**: Maintain existing APIs during transition
- **Feature preservation**: All current functionality will be preserved
- **Testing strategy**: Add comprehensive tests for extracted components

### Overall Risk Management
- **Phase-based approach**: Start with lowest risk, highest impact changes
- **Continuous validation**: Test after each major change
- **Rollback capability**: Git branches for each phase enable easy rollback
- **User testing**: Validate that user experience remains consistent throughout
