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
    let textSelectionChunks: [TextSelectionChunk]
    let onSend: () -> Void
    let onRemoveDocument: (Document) -> Void
    let onRemoveTextChunk: (TextSelectionChunk) -> Void
    
    @State private var isHovered = false
    
    // Autocomplete state
    @State private var showingAutocomplete = false
    @State private var autocompleteDocuments: [Document] = []
    @State private var selectedAutocompleteIndex = 0
    @State private var currentAtMentionRange: Range<String.Index>?
    @State private var cursorPosition: Int = 0
    @State private var showAutocompleteAbove = false
    
    private let maxHeight: CGFloat = 120
    private let minHeight: CGFloat = 66 // Height for 2 lines of text
    
    init(
        text: Binding<String>,
        isLoading: Bool,
        isStreaming: Bool = false,
        attachedDocuments: [Document] = [],
        textSelectionChunks: [TextSelectionChunk] = [],
        onSend: @escaping () -> Void,
        onRemoveDocument: @escaping (Document) -> Void = { _ in },
        onRemoveTextChunk: @escaping (TextSelectionChunk) -> Void = { _ in }
    ) {
        self._text = text
        self.isLoading = isLoading
        self.isStreaming = isStreaming
        self.attachedDocuments = attachedDocuments
        self.textSelectionChunks = textSelectionChunks
        self.onSend = onSend
        self.onRemoveDocument = onRemoveDocument
        self.onRemoveTextChunk = onRemoveTextChunk
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // Attachment preview area
            AttachmentList(
                documents: attachedDocuments,
                textChunks: textSelectionChunks,
                onRemoveDocument: onRemoveDocument,
                onRemoveTextChunk: onRemoveTextChunk
            )
            
            // Input container with integrated send button
            HStack(spacing: 0) {
                // Integrated text field with send button
                ZStack(alignment: .trailing) {
                    // Enhanced text input with overlay highlighting
                    ChatTextEditor(
                        text: $text,
                        isDisabled: isLoading || isStreaming,
                        onSubmit: {
                            if !showingAutocomplete && canSend && !isLoading && !isStreaming {
                                onSend()
                            }
                        },
                        onTextChange: handleTextChange
                    )
                    
                    // Send button positioned inside text field
                    ChatActions(
                        canSend: canSend,
                        isLoading: isLoading,
                        isStreaming: isStreaming,
                        onSend: onSend
                    )
                    .padding(.trailing, 8)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .overlay(alignment: .topLeading) {
                // Autocomplete dropdown overlay - completely independent of input layout
                if showingAutocomplete && !autocompleteDocuments.isEmpty {
                    AutocompleteDropdown(
                        documents: autocompleteDocuments,
                        selectedIndex: selectedAutocompleteIndex,
                        onSelect: { document in
                            insertDocumentReference(document)
                        }
                    )
                    .background(
                        GeometryReader { geometry in
                            Color.clear
                                .onAppear {
                                    // Calculate optimal position based on screen space
                                    let dropdownHeight: CGFloat = CGFloat(min(autocompleteDocuments.count, 5)) * 40 + 16
                                    let globalFrame = geometry.frame(in: .global)
                                    let screenHeight = NSScreen.main?.frame.height ?? 800
                                    let spaceBelow = screenHeight - globalFrame.minY - 50
                                    
                                    showAutocompleteAbove = spaceBelow < dropdownHeight
                                }
                        }
                    )
                    .offset(
                        x: 16,
                        y: showAutocompleteAbove ? -(CGFloat(min(autocompleteDocuments.count, 5)) * 40 + 24) : (minHeight + 8)
                    )
                    .zIndex(1000)
                }
            }
        }

        .animation(.easeInOut(duration: 0.2), value: attachedDocuments.count)
        .animation(.easeInOut(duration: 0.2), value: textSelectionChunks.count)
        .animation(.easeInOut(duration: 0.15), value: showingAutocomplete)
        .onKeyPress(KeyEquivalent.tab) {
            if showingAutocomplete && !autocompleteDocuments.isEmpty {
                insertDocumentReference(autocompleteDocuments[selectedAutocompleteIndex])
                return .handled
            }
            return .ignored
        }
        .onKeyPress(KeyEquivalent.return) {
            if showingAutocomplete && !autocompleteDocuments.isEmpty {
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
        .onKeyPress(KeyEquivalent.escape) {
            if showingAutocomplete {
                hideAutocomplete()
                return .handled
            }
            return .ignored
        }
    }
    
    private var canSend: Bool {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return false }
        
        // Check if all @ references are valid
        return areAllDocumentReferencesValid(in: trimmedText)
    }
    
    // MARK: - Autocomplete Logic
    
    private func handleTextChange(_ newValue: String) {
        // Find @ mentions and trigger autocomplete
        checkForAtMention(in: newValue)
    }
    
    private func checkForAtMention(in text: String) {
        // Find the current cursor position (approximation - we'll use the end of text for simplicity)
        let cursorIndex = text.endIndex
        
        // Look backwards from cursor to find @ symbol
        var searchIndex = cursorIndex
        var foundAt = false
        var mentionStart: String.Index?
        
        while searchIndex > text.startIndex {
            searchIndex = text.index(before: searchIndex)
            let char = text[searchIndex]
            
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
        // Use the same improved pattern that handles dots correctly
        let pattern = #"@([a-zA-Z0-9\s\-_]+(?:\.[a-zA-Z0-9\s\-_]+)*\.pdf|[a-zA-Z0-9\s\-_]+(?:\.[a-zA-Z0-9\s\-_]+)*)"#
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return true // If regex fails, allow sending
        }
        
        let nsString = text as NSString
        let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))
        
        for match in matches {
            let fullMatch = nsString.substring(with: match.range)
            let documentName = extractDocumentName(from: fullMatch)
            
            // Check if document exists
            let foundDocument = ServiceContainer.shared.documentService.findDocument(byName: documentName)
            if foundDocument == nil {
                return false // Invalid reference found
            }
        }
        
        return true // All references are valid
    }
    
    private func extractDocumentName(from matchText: String) -> String {
        // Remove the @ symbol
        var documentName = String(matchText.dropFirst())
        
        // If it ends with .pdf, remove only the final .pdf extension
        if documentName.lowercased().hasSuffix(".pdf") {
            documentName = String(documentName.dropLast(4))
        }
        
        return documentName
    }
}

// MARK: - Autocomplete Dropdown

struct AutocompleteDropdown: View {
    let documents: [Document]
    let selectedIndex: Int
    let onSelect: (Document) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(documents.enumerated()), id: \.element.id) { index, document in
                Button(action: {
                    onSelect(document)
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(DesignSystem.Colors.accent)
                            .frame(width: 16)
                        
                        Text(document.title)
                            .font(.system(size: 14))
                            .foregroundColor(DesignSystem.Colors.primaryText)
                            .lineLimit(1)
                            .truncationMode(.middle)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(index == selectedIndex ? DesignSystem.Colors.accent.opacity(0.1) : Color.clear)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(DesignSystem.Colors.background)
                .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
        )
        .frame(maxWidth: 300)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(DesignSystem.Colors.border.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Highlight Overlay for @mentions

struct HighlightOverlay: View {
    let text: String
    
    var body: some View {
        Text(buildHighlightedAttributedString())
            .font(.system(size: 16))
    }
    
    private func buildHighlightedAttributedString() -> AttributedString {
        var result = AttributedString(text)
        
        // Make ALL text completely transparent - no foreground text at all
        result.foregroundColor = Color.clear
        
        // Improved regex pattern to handle filenames with dots better
        // Matches @filename.pdf (with any number of dots in filename)
        let pattern = #"@([a-zA-Z0-9\s\-_]+(?:\.[a-zA-Z0-9\s\-_]+)*\.pdf|[a-zA-Z0-9\s\-_]+(?:\.[a-zA-Z0-9\s\-_]+)*)"#
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return result
        }
        
        let nsString = text as NSString
        let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))
        
        for match in matches {
            let matchText = nsString.substring(with: match.range)
            let documentName = extractDocumentName(from: matchText)
            
            // Check if document exists to determine highlight color
            let documentExists = ServiceContainer.shared.documentService.findDocument(byName: documentName) != nil
            
            // Convert NSRange to AttributedString range using proper conversion
            let utf16Range = match.range
            let utf16Start = String.Index(utf16Offset: utf16Range.location, in: text)
            let utf16End = String.Index(utf16Offset: utf16Range.location + utf16Range.length, in: text)
            
            // Convert to AttributedString indices
            if let attrStart = AttributedString.Index(utf16Start, within: result),
               let attrEnd = AttributedString.Index(utf16End, within: result) {
                let attributedRange = attrStart..<attrEnd
                
                // Only add background color, keep text transparent
                if documentExists {
                    // Valid reference - blue background only
                    result[attributedRange].backgroundColor = Color.blue.opacity(0.2)
                } else {
                    // Invalid reference - red background only
                    result[attributedRange].backgroundColor = Color.red.opacity(0.2)
                }
                // Keep foregroundColor transparent - no text rendering
                result[attributedRange].foregroundColor = Color.clear
            }
        }
        
        return result
    }
    
    private func extractDocumentName(from matchText: String) -> String {
        // Remove the @ symbol
        var documentName = String(matchText.dropFirst())
        
        // If it ends with .pdf, remove only the final .pdf extension
        if documentName.lowercased().hasSuffix(".pdf") {
            documentName = String(documentName.dropLast(4))
        }
        
        return documentName
    }
}



#Preview {
    @Previewable @State var inputText = "Hello @document.pdf"
    
    return VStack {
        Spacer()
        
        ChatInputView(
            text: $inputText,
            isLoading: false,
            isStreaming: false,
            attachedDocuments: [
                Document(title: "Sample Document.pdf", filePath: URL(fileURLWithPath: "/path/to/document.pdf")),
                Document(title: "Research Paper.pdf", filePath: URL(fileURLWithPath: "/path/to/research.pdf"))
            ],
            textSelectionChunks: [
                TextSelectionChunk(text: "This is a sample text selection from a PDF document.", source: "Sample Document"),
                TextSelectionChunk(text: "Another text selection example that demonstrates the feature.", source: "Research Paper")
            ]
        ) {
            print("Send message")
        } onRemoveDocument: { document in
            print("Remove document: \(document.title)")
        } onRemoveTextChunk: { chunk in
            print("Remove text chunk: \(chunk.previewText)")
        }
    }
    .frame(width: 600, height: 400)
    .background(Color(NSColor.windowBackgroundColor))
}

