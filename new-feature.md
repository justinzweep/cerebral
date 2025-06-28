# PDF Highlighter Feature Specification

**Product:** Cursor IDE for PDFs  
**Feature:** Text Highlighting with Color Selection Modal  
**Platform:** macOS (SwiftUI + PDFKit)  
**Version:** 1.0  
**Date:** June 2025

## Executive Summary

Implement an intuitive text highlighting system that allows users to quickly select and highlight text in PDFs with visual color coding. The feature should feel as natural as highlighting in physical books while providing the precision and convenience of digital tools.

## Feature Overview

### Vision Statement
Enable users to effortlessly highlight and organize information in PDFs through an elegant, context-aware color selection interface that appears exactly when and where they need it.

### Core Value Proposition
- **Instant feedback**: Immediate visual confirmation of selections
- **Minimal friction**: No menu diving or toolbar hunting
- **Contextual interaction**: Modal appears precisely where the user is working
- **Persistent memory**: All highlights are automatically saved to the PDF

## User Experience Flow

### Primary Happy Path

1. **Text Selection**
   - User clicks and drags to select text in PDF
   - Selection is visually indicated with system selection styling
   - Cursor changes to indicate active selection mode

2. **Modal Appearance**
   - Small, elegant modal appears 8px above the end of selection
   - Modal contains 4 color options in a horizontal row
   - Smooth fade-in animation (150ms ease-out)
   - Modal is positioned to avoid screen edges and PDF boundaries

3. **Color Selection**
   - User clicks desired highlight color
   - Selected text immediately transforms with chosen highlight color
   - Modal disappears with fade-out animation (100ms ease-out)
   - Highlight data is automatically saved to the PDF

4. **Completion**
   - Text remains selected briefly (500ms) to confirm action
   - Selection clears automatically
   - User can immediately make new selections

### Secondary Flows

**Cancellation Behavior**
- User clicks elsewhere in PDF → Modal disappears, no highlight applied
- User presses Escape key → Modal disappears, no highlight applied
- User starts new selection → Previous modal disappears, new selection begins

**Existing Highlight Interaction**
- User selects already-highlighted text → Modal shows current color as "selected" state
- User can change highlight color or remove highlight entirely
- Remove option appears as small "×" icon in modal

## Design Specifications

### Modal Design

**Dimensions**
- Width: 140px
- Height: 36px
- Corner radius: 8px
- Shadow: 0px 4px 12px rgba(0, 0, 0, 0.15)

**Color Palette**
1. **Yellow** (#FFEB3B) - Default/most common highlighting
2. **Green** (#4CAF50) - Important concepts, definitions
3. **Blue** (#2196F3) - References, citations, links
4. **Pink** (#E91E63) - Questions, unclear items, review needed

**Color Swatches**
- Size: 24px × 24px circles
- Spacing: 8px between swatches
- Border: 2px white border when selected
- Hover state: Slight scale (1.1x) and shadow enhancement

**Positioning Logic**
- **Primary**: 8px above selection end point
- **Fallback 1**: 8px below selection start point (if insufficient space above)
- **Fallback 2**: 8px to the right of selection end (if vertical space limited)
- **Constraint**: Always keep modal fully within PDF view bounds

### Highlight Appearance

**Visual Treatment**
- Opacity: 0.4 for optimal text readability
- Blend mode: Multiply for natural appearance
- Border radius: 2px for subtle softness
- No border or outline to maintain clean aesthetic

**Animation**
- Highlight appears with 200ms fade-in
- Color changes use 150ms cross-fade transition

## Technical Considerations

### PDFKit Integration

**Text Selection Detection**
- Leverage PDFKit's native text selection capabilities
- Hook into `PDFSelection` objects for precise text boundaries
- Monitor selection change notifications for modal triggering

**Coordinate Mapping**
- Convert PDF coordinate space to view coordinate space for modal positioning
- Handle zoom levels and document scaling correctly
- Account for page margins and multi-column layouts

**Persistence Strategy**
- Store highlights as PDF annotations using PDFKit's annotation system
- Ensure highlights persist when PDF is saved and reopened

### Performance Requirements

**Responsiveness**
- Modal must appear within 100ms of selection completion
- No perceptible lag during highlight application
- Smooth scrolling performance maintained with multiple highlights

**Memory Management**
- Efficient handling of large PDFs with extensive highlighting
- Proper cleanup of animation resources

## Edge Cases & Error Handling

### Selection Edge Cases

**Multi-page selections**
- If selection spans pages: Show modal at end of first page
- Apply highlighting to all selected text across pages
- Provide visual feedback that multi-page highlighting occurred

**Partial word selections**
- Allow highlighting of partial words (letter-level precision)
- Maintain readable highlight boundaries

**Overlapping highlights**
- New highlight overwrites existing highlight color
- Maintain original highlight boundaries unless new selection extends beyond
- Provide visual preview of overlap before confirming

### Error States

**PDF Write Permissions**
- If PDF is read-only: Show gentle error message in modal location
- Clear error messaging without breaking user flow

## Success Metrics

### User Engagement
- **Primary**: Highlight usage frequency (highlights per session)
- **Secondary**: Color distribution usage patterns
- **Tertiary**: Time from selection to highlight completion

### User Experience
- **Modal appearance latency**: < 100ms for 95% of interactions
- **User error rate**: < 5% accidental highlight applications
- **Feature discovery**: > 80% of users discover highlighting within first session

### Technical Performance
- **Rendering performance**: No dropped frames during highlight application
- **Memory usage**: < 10MB additional memory for 100 highlights
- **Persistence reliability**: 99.9% highlight save success rate to PDF

## Future Enhancement Opportunities

### Phase 2 Features
- Highlight notes/annotations
- Additional highlight colors
- Highlight removal tool
- Undo/redo for highlight actions

## Implementation Timeline

**Week 1-2**: Core text selection and modal positioning
**Week 3**: Color application and persistence
**Week 4**: Polish, animations, and edge case handling
**Week 5**: Testing and performance optimization

## Acceptance Criteria

- [ ] User can select text and see modal appear consistently
- [ ] All 4 colors apply correctly and persist when PDF is reopened
- [ ] Modal positioning works correctly across different zoom levels
- [ ] Highlighting works on all PDF types (text-based, not image-based)
- [ ] Performance remains smooth with 100+ highlights in document
- [ ] Feature works correctly with existing PDF annotations
- [ ] Keyboard shortcuts work (Escape to cancel)
- [ ] Color accessibility meets WCAG guidelines

---

*This specification prioritizes user experience while ensuring technical feasibility within the SwiftUI/PDFKit ecosystem. The design balances simplicity with functionality, creating a highlighting experience that feels both familiar and delightfully responsive.*