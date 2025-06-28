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

## Technical Implementation

### Event Handling
- Implement key event monitoring at application level to detect typing while PDF has selections
- Use PDFKit selection APIs to track and manage multiple text selections
- Coordinate between PDFView and chat input components through shared state management

### State Management
- **Selection Collection**: Track multiple PDF text selections with ability to add/remove
- **Chat State**: Manage chat input focus and content with context integration
- **Context State**: Aggregate all selected text for RAG processing
- **Selection Persistence**: Maintain selections across view transitions until message sent

### SwiftUI Component Architecture
- PDF viewer component manages selection state using PDFKit selection APIs
- Chat component observes selection changes and handles automatic focus transition
- Shared ViewModel coordinates state between PDF and chat components
- Selection overlay UI for visual feedback and individual selection management

## User Experience Considerations

### Visual Feedback
- **Selection Persistence**: All PDF selections remain highlighted until message is sent
- **Multi-selection Indication**: Clear visual distinction between individual selections
- **Selection Management**: Hover states and visual cues for removing individual selections
- **Smooth Transition**: Native macOS animation patterns for focus changes
- **Clear Context**: Quoted text in chat clearly distinguishes context from user input

### Interaction Patterns
- **Natural Flow**: Feels like a continuation of the reading experience
- **macOS Conventions**: Follows standard macOS selection patterns (Cmd+click for multi-select)
- **Selection Management**: Intuitive removal via Cmd+click on highlighted text
- **Escape Hatch**: Escape key clears all selections when PDF has focus
- **Progressive Building**: Users can build context incrementally across document sections

### Error Prevention
- **Invalid Selections**: Handle cases where selection contains non-text elements
- **Large Selections**: Truncate excessively long selections (>500 chars) with ellipsis
- **Empty Selections**: Ignore trigger if no meaningful text selected

## Edge Cases & Error Handling

### Selection Edge Cases
- **Cross-page selections**: Handle text spanning multiple PDF pages using PDFKit APIs
- **Mixed content**: Text + images/tables (extract text only using PDFKit text extraction)
- **Special characters**: Preserve formatting, handle Unicode properly
- **Empty/whitespace**: Ignore selections of only whitespace
- **Overlapping selections**: Prevent or merge overlapping text selections
- **Selection limits**: Handle cases with excessive number of selections (suggest limit of 10-15)

### Input Edge Cases
- **Chat already focused**: If chat input already has content, prepend context with separator
- **Rapid typing**: Handle fast keystrokes without dropping characters
- **Selection order**: Maintain chronological order of selections in context formatting
- **Selection removal**: Handle removal of selections that are already in chat context

### Performance Considerations
- **Large PDFs**: Efficient text extraction using PDFKit's optimized selection APIs
- **Memory management**: Proper cleanup of selection state and observers in SwiftUI lifecycle
- **Multiple selections**: Efficient storage and rendering of selection collection
- **Real-time updates**: Smooth UI updates when adding/removing selections without blocking main thread

## Accessibility Requirements

- **Screen readers**: Announce context transition and chat focus change
- **Keyboard navigation**: Support Tab-based navigation flow
- **High contrast**: Ensure selection highlighting works with accessibility themes
- **Voice control**: Compatible with voice input systems

## Success Metrics

### Engagement Metrics
- **Adoption rate**: % of users who use the feature
- **Frequency**: Average uses per session
- **Retention**: Feature usage correlation with user retention

### UX Quality Metrics
- **Time to query**: Measure reduction in time from selection to question submission
- **Error rate**: Failed transitions or malformed context
- **User feedback**: Qualitative feedback on interaction smoothness

## Implementation Priority

### Phase 1 (MVP)
- Basic text selection detection
- Chat focus transition
- Context formatting in chat input

### Phase 2 (Enhancement)
- Visual polish and animations
- Advanced selection handling (cross-page, mixed content)
- User customization options

### Phase 3 (Advanced)
- Smart context understanding (auto-expand selections)
- Integration with PDF annotations
- Multi-modal context (text + images)

## Development Considerations

### Dependencies
- PDFKit for text selection and extraction APIs
- SwiftUI for reactive UI components and state management
- Combine for coordinating events between PDF viewer and chat components

### Testing Strategy
- **Unit tests**: Selection detection, context formatting, multi-selection management
- **Integration tests**: PDFView ↔ chat communication and state synchronization
- **UI tests**: Complete user workflows using XCTest UI testing
- **Accessibility tests**: VoiceOver and keyboard navigation support

### Performance Targets
- **Response time**: <50ms from keystroke to chat focus transition
- **Memory**: Minimal overhead for multiple selection tracking
- **Rendering**: No impact on PDF scroll/zoom performance in PDFView