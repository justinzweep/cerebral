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
    let attachedDocuments: [Document]
    let onSend: () -> Void
    let onRemoveDocument: (Document) -> Void
    
    @FocusState private var isTextFieldFocused: Bool
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
        attachedDocuments: [Document] = [],
        onSend: @escaping () -> Void,
        onRemoveDocument: @escaping (Document) -> Void = { _ in }
    ) {
        self._text = text
        self.isLoading = isLoading
        self.attachedDocuments = attachedDocuments
        self.onSend = onSend
        self.onRemoveDocument = onRemoveDocument
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // Attachment preview area
            if !attachedDocuments.isEmpty {
                AttachmentPreviewView(
                    documents: attachedDocuments,
                    onRemove: onRemoveDocument
                )
                .padding(.horizontal, 16)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
            
            // Input container with integrated send button
            HStack(spacing: 0) {
                // Integrated text field with send button
                ZStack(alignment: .trailing) {
                                            // Enhanced text input with overlay highlighting
                    ZStack(alignment: .topLeading) {
                        // Highlight overlay for @mentions only
                        HighlightOverlay(text: text)
                            .allowsHitTesting(false)
                            .padding(.leading, 16)
                            .padding(.trailing, 48)
                            .padding(.vertical, 12)
                        
                        // Actual text field (normal colors)
                        TextField("Message...", text: $text, axis: .vertical)
                            .textFieldStyle(.plain)
                            .background(Color.clear)
                            .font(.system(size: 16))
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                            .focused($isTextFieldFocused)
                            .padding(.leading, 16)
                            .padding(.trailing, 48) // Make room for send button
                            .padding(.vertical, 12)
                            .onSubmit {
                                if !showingAutocomplete && canSend && !isLoading {
                                    onSend()
                                }
                            }
                            .onChange(of: text) { _, newValue in
                                handleTextChange(newValue)
                            }
                            .disabled(isLoading)
                    }
                    .frame(minHeight: minHeight)
                    .background(
                        RoundedRectangle(cornerRadius: 22)
                            .fill(DesignSystem.Colors.background)
                            .stroke(
                                isTextFieldFocused ? DesignSystem.Colors.accent.opacity(0.5) : DesignSystem.Colors.border.opacity(0.3),
                                lineWidth: 1
                            )
                    )
                    .animation(.easeInOut(duration: 0.2), value: isTextFieldFocused)
                    
                    // Send button positioned inside text field
                    Button(action: onSend) {
                        ZStack {
                            if isLoading {
                                ProgressView()
                                    .scaleEffect(0.7)
                                    .tint(DesignSystem.Colors.accent)
                            } else {
                                Image(systemName: "arrow.up")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(canSend && !isLoading ? DesignSystem.Colors.accent : DesignSystem.Colors.textTertiary.opacity(0.3))
                        )
                        .scaleEffect(canSend && !isLoading ? 1.0 : 0.9)
                        .animation(.easeInOut(duration: 0.15), value: canSend)
                        .animation(.easeInOut(duration: 0.15), value: isLoading)
                    }
                    .buttonStyle(.plain)
                    .disabled(!canSend || isLoading)
                    .keyboardShortcut(.return, modifiers: [])
                    .padding(.trailing, 8) // Position inside the text field
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
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isTextFieldFocused = true
            }
        }
        .animation(.easeInOut(duration: 0.2), value: attachedDocuments.count)
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
        let allDocuments = DocumentLookupService.shared.getAllDocuments()
        
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
        let documentReference = "@\(document.title)"
        
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
            let foundDocument = DocumentLookupService.shared.findDocument(byName: documentName)
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
                            .foregroundColor(DesignSystem.Colors.textPrimary)
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
            let documentExists = DocumentLookupService.shared.findDocument(byName: documentName) != nil
            
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

// MARK: - Attachment Preview

struct AttachmentPreviewView: View {
    let documents: [Document]
    let onRemove: (Document) -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(documents, id: \.id) { document in
                    AttachmentPillView(document: document) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            onRemove(document)
                        }
                    }
                }
            }
            .padding(.horizontal, 4)
        }
        .frame(height: 32)
    }
}

struct AttachmentPillView: View {
    let document: Document
    let onRemove: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 6) {
            // Document icon
            Image(systemName: "doc.text")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(DesignSystem.Colors.accent)
            
            // Document title
            Text(document.title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(DesignSystem.Colors.textPrimary)
                .lineLimit(1)
                .truncationMode(.middle)
            
            // Remove button
            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
            .buttonStyle(.plain)
            .frame(width: 14, height: 14)
            .contentShape(Circle())
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(DesignSystem.Colors.background)
                .stroke(DesignSystem.Colors.border.opacity(0.3), lineWidth: 1)
        )
        .scaleEffect(isHovered ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isHovered)
        .onHover { isHovered = $0 }
    }
}

#Preview {
    VStack {
        Spacer()
        
        ChatInputView(
            text: .constant(""),
            isLoading: false,
            attachedDocuments: [
                Document(title: "Sample Document.pdf", filePath: URL(fileURLWithPath: "/path/to/document.pdf")),
                Document(title: "Research Paper.pdf", filePath: URL(fileURLWithPath: "/path/to/research.pdf"))
            ]
        ) {
            print("Send message")
        } onRemoveDocument: { document in
            print("Remove document: \(document.title)")
        }
    }
    .frame(width: 600, height: 400)
    .background(Color(NSColor.windowBackgroundColor))
}

