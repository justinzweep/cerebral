# PDF Text Selection to Chat Feature Specification

## Problem Statement

Users reading PDFs frequently want to ask questions about specific passages, but the current workflow is friction-heavy: select text → copy → switch to chat → paste → formulate question. This breaks reading flow and creates cognitive overhead, reducing user engagement with both the PDF content and AI assistant.

## Solution Overview

**Core Feature**: When a user selects text in the PDF viewer and begins typing, automatically transition focus to the chat input field and include all selected text as context for the AI query. Multiple selections can be accumulated and managed before sending.

**User Journey**: 
1. User highlights text in PDF with cursor (creates first selection)
2. User can optionally make additional selections or remove existing ones
3. User starts typing their question
4. Chat input gains focus seamlessly
5. All selected text appears as quoted context
6. User continues typing their question
7. AI receives both context and question for RAG processing
8. Upon sending message, all PDF selections are cleared

## Detailed Behavior Specification

### Primary Flow

**Text Selection State**
- User selects text in PDF using standard text selection (click + drag)
- Selected text remains visually highlighted with distinct selection color
- Multiple selections can be made by holding modifier key (Cmd) while selecting additional text
- Selections persist until chat message is sent or manually removed
- Individual selections can be removed by Cmd+clicking on highlighted text
- All selections can be cleared with Escape key when PDF viewer has focus

**Typing Trigger**
- Any alphanumeric key press while text is selected triggers the feature
- Special keys (Escape, Arrow keys, Tab) should NOT trigger transition
- Modifier keys (Cmd+C, Ctrl+V) should NOT trigger transition

**Chat Transition**
- Focus immediately shifts to chat input field
- Chat input field becomes active with cursor positioned after context block
- PDF selection remains visually highlighted during chat interaction

**Context Formatting**
- All selected text appears in chat input as separate quoted blocks
- Format: `> [SELECTION_1]\n\n> [SELECTION_2]\n\n` etc.
- Selections appear in chronological order (first selected appears first)
- User's typed character appears immediately after all context blocks
- Context blocks are read-only (user cannot edit them directly)
- Upon message send, all PDF selections are automatically cleared

### Example Flow
```
PDF contains: "Machine learning algorithms require large datasets..." and later "Neural networks excel at pattern recognition..."

User selects: "Machine learning algorithms"
User Cmd+selects: "Neural networks"
User types: "w"

Chat input auto-populates with:
> Machine learning algorithms

> Neural networks

w[cursor here]
```

## Implementation Specification

### Architecture Overview

This feature integrates into the existing SwiftUI architecture using:
- **AppState**: Extended for PDF-to-chat coordination state
- **KeyboardShortcutService**: Enhanced for typing detection
- **PDFViewCoordinator**: Extended for multiple selection management
- **ChatInputView**: Enhanced for context insertion
- **ServiceContainer**: Coordinating service dependencies

### 1. AppState Extensions

**File**: `cerebral/Services/ServiceContainer.swift` (AppState class)

Add new state properties to coordinate PDF selections with chat:

```swift
// MARK: - PDF to Chat Feature State
var pdfSelections: [PDFSelectionInfo] = []
var isReadyForChatTransition: Bool = false
var pendingChatContext: String?

// Methods for PDF-to-chat coordination
func addPDFSelection(_ selection: PDFSelection, selectionId: UUID = UUID()) {
    let selectionInfo = PDFSelectionInfo(
        id: selectionId,
        selection: selection,
        text: selection.string ?? "",
        timestamp: Date()
    )
    pdfSelections.append(selectionInfo)
    updateChatTransitionState()
}

func removePDFSelection(withId id: UUID) {
    pdfSelections.removeAll { $0.id == id }
    updateChatTransitionState()
}

func clearAllPDFSelections() {
    pdfSelections.removeAll()
    isReadyForChatTransition = false
    pendingChatContext = nil
}

private func updateChatTransitionState() {
    isReadyForChatTransition = !pdfSelections.isEmpty
    pendingChatContext = formatSelectionsForChat()
}

private func formatSelectionsForChat() -> String? {
    guard !pdfSelections.isEmpty else { return nil }
    
    let sortedSelections = pdfSelections.sorted { $0.timestamp < $1.timestamp }
    let quotedTexts = sortedSelections.map { "> \($0.text)" }
    return quotedTexts.joined(separator: "\n\n") + "\n\n"
}

func triggerChatTransition(withCharacter character: String) {
    guard isReadyForChatTransition,
          let context = pendingChatContext else { return }
    
    // This will be observed by ChatInputView
    pendingChatContext = context + character
}
```

**Create supporting model**:

```swift
struct PDFSelectionInfo: Identifiable {
    let id: UUID
    let selection: PDFSelection
    let text: String
    let timestamp: Date
}
```

### 2. KeyboardShortcutService Enhancement

**File**: `cerebral/Services/KeyboardShortcutService.swift`

Extend the existing service to detect typing while PDF has selections:

```swift
// Add to existing handleKeyEvent method
private func handleKeyEvent(_ event: NSEvent) -> NSEvent? {
    let keyCode = event.keyCode
    let modifierFlags = event.modifierFlags
    let characters = event.characters ?? ""
    
    // Existing keyboard shortcuts...
    // ESC key (keyCode 53) - Clear document selection AND PDF selections
    if keyCode == 53 {
        appState.selectDocument(nil)
        appState.clearAllPDFSelections() // New functionality
        return nil
    }
    
    // NEW: PDF-to-Chat typing detection
    // Only trigger if we have PDF selections and user types alphanumeric
    if appState.isReadyForChatTransition,
       !characters.isEmpty,
       !modifierFlags.contains(.command), // Ignore cmd shortcuts
       !modifierFlags.contains(.control),  // Ignore ctrl shortcuts
       !modifierFlags.contains(.option),   // Ignore option shortcuts
       isAlphanumericCharacter(characters.first!) {
        
        // Trigger chat transition with the typed character
        appState.triggerChatTransition(withCharacter: characters)
        
        // Ensure chat panel is visible
        if !appState.showingChat {
            appState.toggleChatPanel()
        }
        
        return nil // Consume the event
    }
    
    // Existing shortcuts (Command + L, Command + K)...
    
    return event
}

private func isAlphanumericCharacter(_ char: Character) -> Bool {
    return char.isLetter || char.isNumber || char.isWhitespace || char.isPunctuation
}
```

### 3. PDFViewCoordinator Enhancement

**File**: `cerebral/Views/PDF/PDFViewerRepresentable.swift`

Extend the coordinator to support multiple selections and coordinate with AppState:

```swift
class PDFViewCoordinator: NSObject, PDFViewDelegate, ObservableObject {
    // Existing properties...
    
    // NEW: Multiple selection management
    private var currentSelections: [UUID: PDFSelection] = [:]
    private var appState = ServiceContainer.shared.appState
    
    // Existing init and methods...
    
    // ENHANCED: Selection handling for multiple selections
    func handleSelectionChanged(pdfView: PDFView) {
        selectionDebounceTimer?.invalidate()
        
        selectionDebounceTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { [weak self] timer in
            defer { timer.invalidate() }
            
            guard let self = self else { return }
            
            guard let selection = pdfView.currentSelection,
                  let selectionString = selection.string,
                  !selectionString.isEmpty,
                  selectionString.count > 1 else {
                DispatchQueue.main.async { [weak self] in
                    self?.selectedText.wrappedValue = nil
                    self?.showHighlightPopup.wrappedValue = false
                }
                return
            }
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                self.selectedText.wrappedValue = selection
                
                // NEW: Check for Cmd key to add to multiple selections
                let currentEvent = NSApp.currentEvent
                if currentEvent?.modifierFlags.contains(.command) == true {
                    // Add to multiple selections
                    self.addToMultipleSelections(selection)
                } else {
                    // Single selection - clear previous and show highlight popup
                    self.handleSingleSelection(selection, pdfView: pdfView)
                }
            }
        }
    }
    
    // NEW: Multiple selection handling
    private func addToMultipleSelections(_ selection: PDFSelection) {
        let selectionId = UUID()
        currentSelections[selectionId] = selection
        
        // Add to AppState for coordination with chat
        appState.addPDFSelection(selection, selectionId: selectionId)
        
        // Update visual state - hide highlight popup when multiple selections
        showHighlightPopup.wrappedValue = false
    }
    
    // NEW: Single selection handling (existing behavior)
    private func handleSingleSelection(_ selection: PDFSelection, pdfView: PDFView) {
        // Clear previous multiple selections
        clearMultipleSelections()
        
        // Add current selection to AppState
        let selectionId = UUID()
        currentSelections[selectionId] = selection
        appState.addPDFSelection(selection, selectionId: selectionId)
        
        // Show highlight popup for single selections (existing behavior)
        if let firstPage = selection.pages.first,
           let pdfView = pdfView as? PDFView {
            let bounds = selection.bounds(for: firstPage)
            let convertedBounds = pdfView.convert(bounds, from: firstPage)
            
            let popupX = convertedBounds.midX
            let popupY = convertedBounds.minY - 10
            
            self.highlightPopupPosition.wrappedValue = CGPoint(x: popupX, y: popupY)
            self.showHighlightPopup.wrappedValue = true
        }
    }
    
    // NEW: Clear multiple selections
    func clearMultipleSelections() {
        currentSelections.removeAll()
        appState.clearAllPDFSelections()
        showHighlightPopup.wrappedValue = false
    }
    
    // NEW: Remove specific selection (for Cmd+click removal)
    func removeSelection(withId id: UUID) {
        currentSelections.removeValue(forKey: id)
        appState.removePDFSelection(withId: id)
    }
}
```

### 4. ChatInputView Enhancement

**File**: `cerebral/Views/Chat/ChatInputView.swift`

Add context insertion capability and observe AppState for PDF selections:

```swift
struct ChatInputView: View {
    // Existing properties...
    
    // NEW: PDF context state
    @State private var appState = ServiceContainer.shared.appState
    @State private var shouldFocusInput = false
    
    // Existing body implementation...
    
    var body: some View {
        VStack(spacing: 0) {
            // Existing AttachmentList...
            
            HStack(spacing: 0) {
                ZStack(alignment: .trailing) {
                    ChatTextEditor(
                        text: $text,
                        isDisabled: isLoading || isStreaming,
                        shouldFocus: $shouldFocusInput, // NEW: External focus control
                        onSubmit: {
                            if !showingAutocomplete && canSend && !isLoading && !isStreaming {
                                handleSendMessage() // NEW: Enhanced send handling
                            }
                        },
                        onTextChange: handleTextChange
                    )
                    
                    // Existing ChatActions...
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            
            // Existing autocomplete overlay...
        }
        // Existing animations and key press handlers...
        
        // NEW: Observe PDF selections for context insertion
        .onChange(of: appState.pendingChatContext) { _, newContext in
            if let context = newContext {
                insertPDFContext(context)
            }
        }
    }
    
    // NEW: Insert PDF context and focus input
    private func insertPDFContext(_ context: String) {
        text = context
        shouldFocusInput = true
        
        // Clear the pending context after insertion
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            appState.pendingChatContext = nil
        }
    }
    
    // NEW: Enhanced send handling that clears PDF selections
    private func handleSendMessage() {
        onSend()
        
        // Clear PDF selections after sending
        appState.clearAllPDFSelections()
    }
}
```

### 5. ChatTextEditor Enhancement

**File**: `cerebral/Views/Common/Components/Chat/ChatTextEditor.swift`

Add external focus control:

```swift
struct ChatTextEditor: View {
    @Binding var text: String
    @FocusState private var isFocused: Bool
    @Binding var shouldFocus: Bool // NEW: External focus control
    
    // Existing properties...
    
    init(
        text: Binding<String>,
        isDisabled: Bool = false,
        shouldFocus: Binding<Bool> = .constant(false), // NEW: Parameter
        onSubmit: @escaping () -> Void = {},
        onTextChange: @escaping (String) -> Void = { _ in }
    ) {
        self._text = text
        self.isDisabled = isDisabled
        self._shouldFocus = shouldFocus // NEW: Binding
        self.onSubmit = onSubmit
        self.onTextChange = onTextChange
    }
    
    var body: some View {
        // Existing ZStack and TextField implementation...
        
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isFocused = true
            }
        }
        // NEW: External focus control
        .onChange(of: shouldFocus) { _, newValue in
            if newValue {
                isFocused = true
                shouldFocus = false // Reset the trigger
            }
        }
    }
}
```

### 6. Visual Selection Enhancements

**File**: `cerebral/Views/PDF/PDFViewerView.swift`

Add visual feedback for multiple selections:

```swift
struct PDFViewerView: View {
    // Existing properties...
    
    // NEW: Multiple selection state
    @State private var multipleSelections: [PDFSelectionInfo] = []
    @State private var appState = ServiceContainer.shared.appState
    
    var body: some View {
        Group {
            if let currentDocument = document {
                if let pdfDocument = pdfDocument {
                    ZStack {
                        PDFViewerRepresentable(
                            // Existing parameters...
                        )
                        // Existing implementation...
                        
                        // NEW: Multiple selection indicators
                        ForEach(appState.pdfSelections) { selectionInfo in
                            MultipleSelectionIndicator(
                                selectionInfo: selectionInfo,
                                onRemove: { id in
                                    pdfViewCoordinator?.removeSelection(withId: id)
                                }
                            )
                        }
                        
                        // Existing highlight popup...
                    }
                } else {
                    // Existing loading state...
                }
            } else {
                // Existing empty state...
            }
        }
        // Existing modifiers...
        
        // NEW: Clear selections on Escape key
        .onKeyPress(KeyEquivalent.escape) {
            if !appState.pdfSelections.isEmpty {
                pdfViewCoordinator?.clearMultipleSelections()
                return .handled
            }
            return .ignored
        }
    }
}

// NEW: Multiple selection indicator component
struct MultipleSelectionIndicator: View {
    let selectionInfo: PDFSelectionInfo
    let onRemove: (UUID) -> Void
    
    var body: some View {
        // Visual indicator for multiple selections
        // Position based on selection bounds
        // Show remove button on hover
        // Implementation details...
    }
}
```

## Edge Cases & Error Handling

### Selection Edge Cases
- **Cross-page selections**: Use PDFKit's existing cross-page support in `PDFSelection`
- **Mixed content**: Extract text-only using `selection.string` property
- **Empty selections**: Filter out in `handleSelectionChanged` with existing validation
- **Overlapping selections**: Prevent by clearing previous selections unless Cmd is held
- **Selection limits**: Implement maximum of 10 selections with user feedback

### Input Edge Cases
- **Chat already focused**: If input already has content, prepend context with newline separator
- **Rapid typing**: Use existing debouncing in `KeyboardShortcutService`
- **Selection removal**: Handle via `removePDFSelection(withId:)` method

### Performance Considerations
- **Large PDFs**: Use existing PDFKit optimization in `PDFViewCoordinator`
- **Memory management**: Leverage existing cleanup patterns in coordinator
- **Real-time updates**: Use existing SwiftUI `@Observable` pattern for reactive updates

## Success Metrics

### Engagement Metrics
- **Adoption rate**: Track usage via AppState analytics hooks
- **Frequency**: Monitor selection-to-chat conversion rate
- **User retention**: Correlate feature usage with overall app engagement

### UX Quality Metrics
- **Time to query**: Measure via existing performance monitoring
- **Error rate**: Track failed transitions through existing error management
- **User feedback**: Integrate with existing feedback systems

## Implementation Priority

### Phase 1 (MVP - Estimated 2-3 days)
1. AppState extensions for selection coordination
2. KeyboardShortcutService typing detection
3. Basic ChatInputView context insertion
4. Simple selection clearing on message send

### Phase 2 (Enhancement - Estimated 2-3 days)
1. Multiple selection support in PDFViewCoordinator
2. Visual selection indicators
3. Advanced selection management (Cmd+click removal)
4. Escape key clearing

### Phase 3 (Polish - Estimated 1-2 days)
1. Visual animations and transitions
2. Error handling edge cases
3. Performance optimization
4. User testing and refinement

## Testing Strategy

### Unit Tests
- `AppState` selection management methods
- `KeyboardShortcutService` typing detection logic
- Context formatting in `formatSelectionsForChat`

### Integration Tests
- PDF selection → Chat context flow
- Multiple selection coordination
- Selection clearing on message send

### UI Tests (using existing XCTest framework)
- Complete user workflow automation
- Keyboard shortcut integration
- Cross-component state synchronization

This implementation leverages your existing architecture patterns and maintains consistency with the current codebase design while adding the new PDF-to-chat functionality.