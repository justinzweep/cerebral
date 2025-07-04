//
//  ChatView.swift
//  cerebral
//
//  Created by Justin Zweep on 26/06/2025.
//

import SwiftUI
import PDFKit

struct ChatView: View {
    let selectedDocument: Document?
    @State private var chatManager = ChatManager()
    private let settingsManager = SettingsManager.shared
    @State private var inputText = ""
    @State private var attachedDocuments: [Document] = []
    @State private var appState = ServiceContainer.shared.appState
    
    init(selectedDocument: Document? = nil) {
        self.selectedDocument = selectedDocument
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Chat Header with session info and actions
            ChatHeaderView(
                hasMessages: !chatManager.messages.isEmpty,
                onNewSession: {
                    startNewSession()
                }
            )
            
            if !settingsManager.apiKey.isEmpty && settingsManager.validateAPIKey(settingsManager.apiKey) {
                // Chat Messages Area with floating input
                ZStack(alignment: .bottom) {
                    // Messages area that extends full height
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 0) {
                                if chatManager.messages.isEmpty {
                                    EmptyStateView(hasAttachedDocuments: !attachedDocuments.isEmpty)
                                        .padding(.top, DesignSystem.Spacing.huge)
                                        .id("empty-state") // Stable ID for animations
                                } else {
                                    // Use stable IDs and minimize re-renders
                                    ForEach(Array(chatManager.messages.enumerated()), id: \.element.id) { index, message in
                                        let shouldGroup = chatManager.shouldGroupMessage(at: index)
                                        
                                        MessageView(
                                            message: message,
                                            shouldGroup: shouldGroup
                                        )
                                        .id(message.id) // Stable ID for each message
                                        .padding(.horizontal, DesignSystem.Spacing.md)
                                        .padding(.vertical, shouldGroup ? DesignSystem.Spacing.xxxs : DesignSystem.Spacing.xs)
                                    }
                                }
                            }
                            .padding(.bottom, DesignSystem.ComponentSizes.chatInputBottomPadding) // Add bottom padding so messages don't hide behind input
                        }
                        .scrollIndicators(.hidden) // Performance optimization
                        .onChange(of: chatManager.messages.count) { _, newCount in
                            // Optimize scroll-to-bottom with debouncing
                            if let lastMessage = chatManager.messages.last {
                                withAnimation(DesignSystem.Animation.smooth) {
                                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
                                }
                            }
                        }
                        .onChange(of: chatManager.isStreaming) { _, isStreaming in
                            // Auto-scroll when streaming starts
                            if isStreaming, let lastMessage = chatManager.messages.last {
                                withAnimation(DesignSystem.Animation.smooth) {
                                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
                                }
                            }
                        }
                        .onChange(of: chatManager.messages.last?.text) { _, _ in
                            // Auto-scroll during streaming text updates
                            if chatManager.isStreaming, let lastMessage = chatManager.messages.last {
                                // Use a faster animation for streaming updates to feel more responsive
                                withAnimation(DesignSystem.Animation.quick) {
                                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
                                }
                            }
                        }
                    }
                    
                    // Floating Chat Input at the bottom
                    VStack(spacing: 0) {
                        // Chat Input with background
                        ChatInputView(
                            text: $inputText,
                            isLoading: chatManager.isLoading,
                            isStreaming: chatManager.isStreaming,
                            attachedDocuments: attachedDocuments,
                            onSend: {
                                sendMessage()
                            },
                            onRemoveDocument: { document in
                                withAnimation(DesignSystem.Animation.smooth) {
                                    attachedDocuments.removeAll { $0.id == document.id }
                                }
                            }
                        )
                        .disabled(!(!settingsManager.apiKey.isEmpty && settingsManager.validateAPIKey(settingsManager.apiKey)))
                    }
                }
                
            } else {
                // API Key Required State
                APIKeyRequiredView()
            }
        }
        .onChange(of: appState.documentToAddToChat) { _, newDocument in
            if let document = newDocument {
                withAnimation(DesignSystem.Animation.smooth) {
                    // Add to attached documents instead of replacing
                    if !attachedDocuments.contains(where: { $0.id == document.id }) {
                        attachedDocuments.append(document)
                    }
                }
                // Clear the trigger
                appState.documentToAddToChat = nil
            }
        }
        .onAppear {
            if !settingsManager.apiKey.isEmpty && settingsManager.validateAPIKey(settingsManager.apiKey) {
                // API key is configured and valid format, ready to use
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func sendMessage() {
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let messageText = inputText
        var documentsToSend: [Document] = []
        var explicitContexts: [DocumentContext] = []
        
        // Handle PDF text selections - create proper DocumentContext instead of sending full documents
        if !appState.pdfSelections.isEmpty {
            print("🎯 Processing \(appState.pdfSelections.count) PDF text selections")
            
            // Create DocumentContext for each text selection with precise location data
            for selectionInfo in appState.pdfSelections {
                // Get the document from the PDF selection itself, not from sidebar selection
                guard let pdfDocument = selectionInfo.selection.pages.first?.document else {
                    print("❌ No PDF document found in selection")
                    continue
                }
                
                // Find the corresponding Document model by matching the PDF document
                guard let documentModel = findDocumentModel(for: pdfDocument) else {
                    print("❌ No Document model found for PDF selection")
                    continue
                }
                
                // Extract location data from the original PDFSelection
                let pageNumbers = extractPageNumbers(from: selectionInfo.selection)
                let selectionBounds = extractSelectionBounds(from: selectionInfo.selection)
                let characterRange = extractCharacterRange(from: selectionInfo.selection)
                
                // Create a textSelection context with precise location metadata
                let selectionContext = DocumentContext(
                    documentId: documentModel.id,
                    documentTitle: documentModel.title,
                    contextType: .textSelection,
                    content: selectionInfo.text,
                    metadata: ContextMetadata(
                        pageNumbers: pageNumbers,
                        selectionBounds: selectionBounds,
                        characterRange: characterRange,
                        extractionMethod: "PDFKit.userSelection",
                        tokenCount: ServiceContainer.shared.tokenizerService.estimateTokenCount(for: selectionInfo.text),
                        checksum: ServiceContainer.shared.tokenizerService.calculateChecksum(for: selectionInfo.text)
                    )
                )
                explicitContexts.append(selectionContext)
                print("📝 Created text selection context for '\(documentModel.title)' with location: pages \(pageNumbers), bounds: \(selectionBounds.count) rects")
            }
        } else {
            // No text selections - handle attached documents normally
            documentsToSend = attachedDocuments
            
            // Add the currently selected document if there is one and no text selections
            if let selectedDoc = selectedDocument {
                if !documentsToSend.contains(where: { $0.id == selectedDoc.id }) {
                    documentsToSend.append(selectedDoc)
                }
            }
        }
        
        // Clear input, attachments, and PDF selections immediately
        inputText = ""
        withAnimation(DesignSystem.Animation.smooth) {
            attachedDocuments.removeAll()
        }
        appState.clearAllPDFSelections() // Clear PDF selections
        
        Task {
            // Use the unified sendMessage method with explicit contexts for text selections
            await chatManager.sendMessage(
                messageText,
                settingsManager: settingsManager,
                documentContext: documentsToSend,
                explicitContexts: explicitContexts
            )
            
            // Clear context bundle after message is sent
            chatManager.clearContext()
        }
    }
    
    private func startNewSession() {
        // Clear messages immediately to prevent index out of range
        chatManager.startNewSession()
        
        withAnimation(DesignSystem.Animation.smooth) {
            attachedDocuments.removeAll()
            inputText = ""
        }
    }
    
    // MARK: - PDF Selection Location Helpers
    
    private func findDocumentModel(for pdfDocument: PDFDocument) -> Document? {
        // Get the PDF document's URL
        guard let documentURL = pdfDocument.documentURL else {
            print("❌ PDF document has no URL")
            return nil
        }
        
        // Find the Document model that matches this URL
        let allDocuments = ServiceContainer.shared.documentService.getAllDocuments()
        
        // First try exact URL match
        if let exactMatch = allDocuments.first(where: { $0.filePath == documentURL }) {
            return exactMatch
        }
        
        // If no exact match, try matching by resolved paths (in case of symbolic links, etc.)
        let targetPath = documentURL.resolvingSymlinksInPath().path
        if let pathMatch = allDocuments.first(where: { document in
            guard let filePath = document.filePath else { return false }
            return filePath.resolvingSymlinksInPath().path == targetPath 
        }) {
            return pathMatch
        }
        
        print("❌ No Document model found for PDF at: \(documentURL.path)")
        return nil
    }
    
    private func extractPageNumbers(from selection: PDFSelection) -> [Int] {
        var pageNumbers: Set<Int> = []
        
        for page in selection.pages {
            if let document = page.document {
                let pageIndex = document.index(for: page)
                pageNumbers.insert(pageIndex + 1) // Convert to 1-based indexing
            }
        }
        
        return Array(pageNumbers).sorted()
    }
    
    private func extractSelectionBounds(from selection: PDFSelection) -> [CGRect] {
        var bounds: [CGRect] = []
        
        for page in selection.pages {
            let selectionBounds = selection.bounds(for: page)
            bounds.append(selectionBounds)
        }
        
        return bounds
    }
    
    private func extractCharacterRange(from selection: PDFSelection) -> NSRange? {
        // Try to get the character range from the first page
        guard let firstPage = selection.pages.first,
              let pageString = firstPage.string,
              let selectionString = selection.string else {
            return nil
        }
        
        // Find the range of the selection in the page text
        let nsPageString = pageString as NSString
        let range = nsPageString.range(of: selectionString)
        
        return range.location != NSNotFound ? range : nil
    }
}

// MARK: - Chat Header

struct ChatHeaderView: View {
    let hasMessages: Bool
    let onNewSession: () -> Void
    
    var body: some View {
        HStack {
            
            Text("Chat")
                .font(DesignSystem.Typography.title3)
                .foregroundColor(DesignSystem.Colors.primaryText)
            
            
            Spacer()
            
            HStack(spacing: DesignSystem.Spacing.xs) {
                // New session button
                Button(action: onNewSession) {
                    Image(systemName: "plus.circle.fill")
                        .font(DesignSystem.Typography.callout)
                        .foregroundColor(DesignSystem.Colors.accent)
                }
                .buttonStyle(.plain)
                .frame(width: DesignSystem.ComponentSizes.largeIconFrame.width, height: DesignSystem.ComponentSizes.largeIconFrame.height)
                .contentShape(Rectangle())
                .foregroundColor(DesignSystem.Colors.secondaryText)
            }
            .padding(DesignSystem.Spacing.md)

        }
        .padding(.horizontal, DesignSystem.Spacing.md)
        .padding(.bottom, DesignSystem.Spacing.lg)
    }
}


// MARK: - Empty State Components

struct EmptyStateView: View {
    let hasAttachedDocuments: Bool
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {                  
        }
        .frame(maxWidth: 400)  // Increased from 320
    }
}

struct APIKeyRequiredView: View {
    @Environment(\.openSettings) private var openSettings
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            // Icon
            Image(systemName: "key.slash")
                .font(DesignSystem.Typography.largeTitle)
                .foregroundColor(DesignSystem.Colors.error)
            
            VStack(spacing: DesignSystem.Spacing.sm) {
                // Title
                Text("API Key Required")
                    .font(DesignSystem.Typography.title3)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                
                // Description
                Text("Configure your Claude API key in Settings to use AI chat functionality.")
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            VStack(spacing: DesignSystem.Spacing.xs) {
                Button("Open Settings") {
                    openSettings()
                }
                .buttonStyle(PrimaryButtonStyle())

                
                Text("Or press ⌘, to open settings")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.tertiaryText)
            }
        }
        .frame(maxWidth: 400)  // Increased from 330
        .padding(DesignSystem.Spacing.xs)
//        .frame(maxHeight: .infinity)
    }
}

// accessibleHeading is already defined in DesignSystem.swift

#Preview {
    ChatView(selectedDocument: nil)
        .frame(width: DesignSystem.ComponentSizes.chatPanelWidth, height: DesignSystem.ComponentSizes.demoWindowHeight)  // Increased from 400 to match new chat width
}
