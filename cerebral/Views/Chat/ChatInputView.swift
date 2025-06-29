//
//  ChatInputView.swift
//  cerebral
//
//  Created by Justin Zweep on 26/06/2025.
//

import SwiftUI

struct ChatInputView: View {
    @Binding var text: String
    let isLoading: Bool
    let isStreaming: Bool
    let attachedDocuments: [Document]
    let onSend: () -> Void
    let onRemoveDocument: (Document) -> Void
    
    @State private var isHovered = false
    
    // NEW: PDF context state
    @State private var appState = ServiceContainer.shared.appState
    @State private var shouldFocusInput = false
    
    // Autocomplete state
    @State private var showingAutocomplete = false
    @State private var autocompleteDocuments: [Document] = []
    @State private var selectedAutocompleteIndex = 0
    @State private var currentAtMentionRange: Range<String.Index>?
    @State private var cursorPosition: Int = 0
    @State private var showAutocompleteAbove = false
    
    private let maxHeight: CGFloat = DesignSystem.ComponentSizes.chatInputMaxHeight
    private let minHeight: CGFloat = DesignSystem.ComponentSizes.chatInputMinHeight // Height for 2 lines of text
    
    init(
        text: Binding<String>,
        isLoading: Bool,
        isStreaming: Bool = false,
        attachedDocuments: [Document] = [],
        onSend: @escaping () -> Void,
        onRemoveDocument: @escaping (Document) -> Void = { _ in }
    ) {
        self._text = text
        self.isLoading = isLoading
        self.isStreaming = isStreaming
        self.attachedDocuments = attachedDocuments
        self.onSend = onSend
        self.onRemoveDocument = onRemoveDocument
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // PDF Selections List (only shown when user starts typing)
            if appState.showPDFSelectionPills {
                PDFSelectionList(
                    pdfSelections: appState.pdfSelections,
                    onRemoveSelection: { id in
                        appState.removePDFSelection(withId: id)
                    }
                )
            }
            
            // Attachments List
            AttachmentList(
                attachedDocuments: attachedDocuments,
                onRemoveDocument: onRemoveDocument
            )
            .frame(maxWidth: 400)
            
            // Input container with integrated send button
            HStack(spacing: 0) {
                // Integrated text field with send button
                ZStack(alignment: .trailing) {
                    // Enhanced text input with overlay highlighting
                    ChatTextEditor(
                        text: $text,
                        isDisabled: isLoading || isStreaming,
                        shouldFocus: $shouldFocusInput, // NEW: External focus control
                        onSubmit: {
                            print("🔄 ChatTextEditor onSubmit triggered")
                            print("   - showingAutocomplete: \(showingAutocomplete)")
                            print("   - canSend: \(canSend)")
                            print("   - isLoading: \(isLoading)")
                            print("   - isStreaming: \(isStreaming)")
                            
                            // Handle autocomplete selection first
                            if showingAutocomplete && !autocompleteDocuments.isEmpty && selectedAutocompleteIndex < autocompleteDocuments.count {
                                print("📝 Autocomplete showing - inserting document reference")
                                insertDocumentReference(autocompleteDocuments[selectedAutocompleteIndex])
                            } else if canSend && !isLoading && !isStreaming {
                                print("✅ All conditions met - calling handleSendMessage()")
                                handleSendMessage()
                            } else {
                                print("❌ Conditions not met - submission blocked")
                            }
                        },
                        onTextChange: handleTextChange
                    )
                    
                    // Send button positioned inside text field
                    ChatActions(
                        canSend: canSend,
                        isLoading: isLoading,
                        isStreaming: isStreaming,
                        onSend: handleSendMessage // NEW: Enhanced send handling
                    )
                    .padding(.trailing, DesignSystem.Spacing.sm)
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.vertical, DesignSystem.Spacing.md)
            .shadow(
                color: DesignSystem.Shadows.subtle,
                radius: DesignSystem.Shadows.large.radius,
                x: DesignSystem.Shadows.large.x,
                y: DesignSystem.Shadows.large.y
            )
            .overlay(alignment: .topLeading) {
                // Autocomplete dropdown overlay - positioned relative to input
                if showingAutocomplete && !autocompleteDocuments.isEmpty {
                    AutocompleteDropdown(
                        documents: autocompleteDocuments,
                        selectedIndex: selectedAutocompleteIndex,
                        onSelect: { document in
                            insertDocumentReference(document)
                        }
                    )
                    .offset(
                        x: DesignSystem.Spacing.md, // Align with text input padding
                        y: showAutocompleteAbove 
                            ? -(CGFloat(min(autocompleteDocuments.count, DesignSystem.ComponentSizes.dropdownMaxItems)) * DesignSystem.ComponentSizes.dropdownItemHeight + DesignSystem.Spacing.md + DesignSystem.Spacing.sm) 
                            : (minHeight + DesignSystem.Spacing.xs)
                    )
                    .zIndex(1000)
                    .background(
                        GeometryReader { geometry in
                            Color.clear
                                .onAppear {
                                    // Calculate actual dropdown height
                                    let itemHeight: CGFloat = DesignSystem.ComponentSizes.dropdownItemHeight + DesignSystem.Spacing.xxxs
                                    let containerPadding = DesignSystem.Spacing.xs * 2
                                    let shadowPadding: CGFloat = DesignSystem.Spacing.sm // Account for shadow
                                    let actualItemCount = min(autocompleteDocuments.count, DesignSystem.ComponentSizes.dropdownMaxItems)
                                    let dropdownHeight = CGFloat(actualItemCount) * itemHeight + containerPadding + shadowPadding
                                    
                                    // Get input field position in global coordinates
                                    let globalFrame = geometry.frame(in: .global)
                                    let screenHeight = NSScreen.main?.frame.height ?? 1000
                                    let spaceBelow = screenHeight - globalFrame.maxY - 20 // Buffer for safety
                                    
                                    // Show above only if genuinely not enough space below
                                    showAutocompleteAbove = spaceBelow < dropdownHeight && globalFrame.minY > dropdownHeight
                                }
                        }
                    )
                }
            }
        }

        .animation(DesignSystem.Animation.quick, value: attachedDocuments.count)
        .animation(DesignSystem.Animation.micro, value: showingAutocomplete)
        .animation(DesignSystem.Animation.quick, value: appState.showPDFSelectionPills) // Watch for pill visibility, not count
        // NEW: Observe focus trigger
        .onChange(of: appState.shouldFocusChatInput) { _, shouldFocus in
            if shouldFocus {
                shouldFocusInput = true
                
                // Insert the pending typed character if there is one
                if let character = appState.pendingTypedCharacter {
                    text += character
                    appState.pendingTypedCharacter = nil // Clear after using
                }
                
                appState.shouldFocusChatInput = false // Reset the trigger
            }
        }
        .onKeyPress(KeyEquivalent.tab) {
            if showingAutocomplete && !autocompleteDocuments.isEmpty && selectedAutocompleteIndex < autocompleteDocuments.count {
                insertDocumentReference(autocompleteDocuments[selectedAutocompleteIndex])
                return .handled
            }
            return .ignored
        }
        .onKeyPress(KeyEquivalent.upArrow) {
            if showingAutocomplete {
                selectedAutocompleteIndex = max(0, selectedAutocompleteIndex - 1)
                return .handled
            }
            return .ignored
        }
        .onKeyPress(KeyEquivalent.downArrow) {
            if showingAutocomplete {
                selectedAutocompleteIndex = min(autocompleteDocuments.count - 1, selectedAutocompleteIndex + 1)
                return .handled
            }
            return .ignored
        }
        .onReceive(NotificationCenter.default.publisher(for: .escapeKeyPressed)) { notification in
            if let context = notification.userInfo?["context"] as? String, 
               context == "autocomplete",
               showingAutocomplete {
                hideAutocomplete()
            }
        }


    }
    
    // NEW: Enhanced send handling that includes PDF context and clears selections
    private func handleSendMessage() {
        print("🚀 handleSendMessage called")
        print("   - text: '\(text)'")
        print("   - text length: \(text.count)")
        
        // Don't modify the text field - just send it as-is
        // The PDF context will be passed as explicitContexts to the AI
        onSend()
        
        print("✅ onSend() called successfully")
        
        // Note: PDF selections and text clearing are handled by ChatView.sendMessage()
    }
    
    private var canSend: Bool {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmedText.isEmpty
    }
    
    // MARK: - Autocomplete Logic
    
    private func handleTextChange(_ newValue: String) {
        // ONLY process @ functionality if text actually contains @ symbol
        // This completely isolates @ behavior from normal text input
        if newValue.contains("@") {
            checkForAtMention(in: newValue)
        } else {
            // No @ symbol present - hide autocomplete and act like normal text field
            hideAutocomplete()
        }
    }
    
    private func checkForAtMention(in text: String) {
        // Only proceed if there's actually an @ symbol in the text
        guard text.contains("@") else {
            hideAutocomplete()
            return
        }
        
        // Find the current cursor position (approximation - we'll use the end of text for simplicity)
        let cursorIndex = text.endIndex
        
        // Look backwards from cursor to find @ symbol
        var searchIndex = cursorIndex
        var foundAt = false
        var mentionStart: String.Index?
        
        // Only search back a reasonable distance (max 50 characters)
        let maxSearchDistance = min(50, text.count)
        var searchDistance = 0
        
        while searchIndex > text.startIndex && searchDistance < maxSearchDistance {
            searchIndex = text.index(before: searchIndex)
            let char = text[searchIndex]
            searchDistance += 1
            
            if char == "@" {
                foundAt = true
                mentionStart = searchIndex
                break
            } else if char.isWhitespace || char.isNewline {
                // Stop searching if we hit whitespace
                break
            }
        }
        
        if foundAt, let start = mentionStart {
            let mentionText = String(text[text.index(after: start)..<cursorIndex])
            currentAtMentionRange = start..<cursorIndex
            showAutocomplete(for: mentionText)
        } else {
            hideAutocomplete()
        }
    }
    
    private func showAutocomplete(for query: String) {
        let allDocuments = ServiceContainer.shared.documentService.getAllDocuments()
        
        if query.isEmpty {
            autocompleteDocuments = Array(allDocuments.prefix(5)) // Show first 5 documents
        } else {
            autocompleteDocuments = allDocuments.filter { document in
                document.title.lowercased().contains(query.lowercased())
            }.prefix(5).map { $0 } // Limit to 5 results
        }
        
        selectedAutocompleteIndex = 0
        showingAutocomplete = !autocompleteDocuments.isEmpty
        
        // Reset positioning - will be recalculated in onAppear
        showAutocompleteAbove = false
    }
    
    private func hideAutocomplete() {
        showingAutocomplete = false
        autocompleteDocuments = []
        currentAtMentionRange = nil
        selectedAutocompleteIndex = 0
    }
    
    private func insertDocumentReference(_ document: Document) {
        guard let range = currentAtMentionRange else { return }
        
        let beforeAt = String(text[..<range.lowerBound])
        let afterMention = String(text[range.upperBound...])
        
        // Ensure the document reference includes the .pdf extension
        let documentTitle = document.title
        let documentReference: String
        if documentTitle.lowercased().hasSuffix(".pdf") {
            documentReference = "@\(documentTitle)"
        } else {
            documentReference = "@\(documentTitle).pdf"
        }
        
        text = beforeAt + documentReference + afterMention
        hideAutocomplete()
    }
    
    private func areAllDocumentReferencesValid(in text: String) -> Bool {
        return DocumentReferenceResolver.validateDocumentReferences(in: text)
    }
    
    private func extractDocumentName(from matchText: String) -> String {
        return DocumentReferenceResolver.extractDocumentName(from: matchText)
    }
}

// MARK: - Autocomplete Dropdown

struct AutocompleteDropdown: View {
    let documents: [Document]
    let selectedIndex: Int
    let onSelect: (Document) -> Void
    
    @State private var hoveredIndex: Int? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxxs) {
            ForEach(Array(documents.enumerated()), id: \.element.id) { index, document in
                Button(action: {
                    onSelect(document)
                }) {
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        Image(systemName: "doc.text")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.accent)
                            .frame(width: DesignSystem.ComponentSizes.smallIconFrame.width, height: DesignSystem.ComponentSizes.smallIconFrame.height)
                        
                        Text(document.title)
                            .font(DesignSystem.Typography.body)
                            .foregroundColor(
                                index == selectedIndex 
                                    ? DesignSystem.Colors.accent 
                                    : DesignSystem.Colors.primaryText
                            )
                            .fontWeight(index == selectedIndex ? .medium : .regular)
                            .lineLimit(1)
                            .truncationMode(.middle)
                        
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, DesignSystem.Spacing.sm)
                    .padding(.vertical, DesignSystem.Spacing.sm)
                    .frame(minHeight: 44) // Apple's minimum touch target
                    .background(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                            .fill(
                                index == selectedIndex 
                                    ? DesignSystem.Colors.selectedBackground
                                    : (hoveredIndex == index ? DesignSystem.Colors.hoverBackground : Color.clear)
                            )
                    )
                }
                .buttonStyle(.plain)
                .contentShape(Rectangle()) // Ensure entire area is tappable
                .onHover { isHovered in
                    hoveredIndex = isHovered ? index : nil
                }
            }
        }
        .padding(DesignSystem.Spacing.xs)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                .fill(DesignSystem.Colors.cardBackground)
                .shadow(
                    color: DesignSystem.Shadows.medium,
                    radius: DesignSystem.Shadows.large.radius,
                    x: DesignSystem.Shadows.large.x,
                    y: DesignSystem.Shadows.large.y
                )
        )
        .frame(maxWidth: 320)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                .stroke(DesignSystem.Colors.border, lineWidth: 0.5)
        )
        .opacity(1.0)
        .scaleEffect(1.0)
        .animation(DesignSystem.Animation.quick, value: documents.count)
    }
}

// MARK: - Highlight Overlay for @mentions

struct HighlightOverlay: View {
    let text: String
    
    var body: some View {
        Text(buildHighlightedAttributedString())
                            .font(DesignSystem.Typography.body)
    }
    
    private func buildHighlightedAttributedString() -> AttributedString {
        var result = AttributedString(text)
        
        // Make ALL text completely transparent so underlying text input shows through
        result.foregroundColor = Color.clear
        
        // Find and highlight @mentions using shared pattern
        let pattern = DocumentReferenceResolver.documentReferencePattern
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return result
        }
        
        let nsString = text as NSString
        let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))
        
        for match in matches {
            let matchText = nsString.substring(with: match.range)
            let documentName = DocumentReferenceResolver.extractDocumentName(from: matchText)
            
            // Check if document exists to determine highlight color
            let documentExists = DocumentReferenceResolver.documentExists(named: documentName)
            
            // Convert NSRange to AttributedString range
            let utf16Range = match.range
            let utf16Start = String.Index(utf16Offset: utf16Range.location, in: text)
            let utf16End = String.Index(utf16Offset: utf16Range.location + utf16Range.length, in: text)
            
            // Convert to AttributedString indices
            if let attrStart = AttributedString.Index(utf16Start, within: result),
               let attrEnd = AttributedString.Index(utf16End, within: result) {
                let attributedRange = attrStart..<attrEnd
                
                // Apply highlighting with same colors as MessageComponents
                // Background color is visible, foreground text remains transparent (shows underlying input)
                if documentExists {
                    // Valid reference - blue background (matches HighlightedMessageText exactly)
                    result[attributedRange].foregroundColor = DesignSystem.Colors.accent
                    result[attributedRange].backgroundColor = DesignSystem.Colors.accent.opacity(0.15)
                    result[attributedRange].font = .system(size: DesignSystem.Typography.FontSize.body, weight: .medium)
                } else {
                    // Invalid reference - red background (matches HighlightedMessageText exactly) 
                    result[attributedRange].foregroundColor = DesignSystem.Colors.error
                    result[attributedRange].font = .system(size: DesignSystem.Typography.FontSize.body, weight: .medium)
                    result[attributedRange].backgroundColor = DesignSystem.Colors.error.opacity(0.15)

                }
                // Keep foreground transparent so underlying text field text is visible
                result[attributedRange].foregroundColor = Color.clear
            }
        }
        
        return result
    }
}



#Preview {
    VStack(spacing: 20) {
        ChatInputView(
            text: .constant(""),
            isLoading: false,
            attachedDocuments: []
        ) {
            print("Send tapped")
        } onRemoveDocument: { _ in
            print("Remove document")
        }
        ChatInputView(
            text: .constant("This is a longer message to test the multiline behavior and how it looks when the user types more content than fits on a single line."),
            isLoading: false,
            attachedDocuments: [
                Document(
                    title: "Sample Document.pdf", filePath: URL(fileURLWithPath: "/Users/user/Documents/sample.pdf")
                )
            ]
        ) {
            print("Send tapped")
        } onRemoveDocument: { _ in
            print("Remove document")
        }

        ChatInputView(
            text: .constant("Loading state example..."),
            isLoading: true,
            attachedDocuments: []
        ) {
            print("Send tapped")
        } onRemoveDocument: { _ in
            print("Remove document")
        }
        
        Spacer()
    }
    .padding()
            .frame(width: DesignSystem.ComponentSizes.chatPanelWidth, height: DesignSystem.ComponentSizes.previewPanelHeight)  // Increased width from 600 to 480 to match chat panel
}

