//
//  MessageView.swift
//  cerebral
//
//  Created by Justin Zweep on 26/06/2025.
//

import SwiftUI

struct MessageView: View {
    let message: ChatMessage
    let shouldGroup: Bool
    
    init(message: ChatMessage, shouldGroup: Bool = false) {
        self.message = message
        self.shouldGroup = shouldGroup
    }
    
    var body: some View {
        if message.isUser {
            UserMessage(message: message, shouldGroup: shouldGroup)
        } else {
            AIMessage(message: message, shouldGroup: shouldGroup)
        }
    }
}

// MARK: - Highlighted Message Text

struct HighlightedMessageText: View {
    let text: String
    let contexts: [DocumentContext]
    @State private var referencedDocuments: [Document] = []
    
    init(text: String, contexts: [DocumentContext] = []) {
        self.text = text
        self.contexts = contexts
    }
    
    var body: some View {
        Text(buildHighlightedAttributedString())
            .font(DesignSystem.Typography.body)
            .textSelection(.enabled)
            .onTapGesture { location in
                handleTap(at: location)
            }
            .onAppear {
                loadReferencedDocuments()
            }
    }
    
    private func loadReferencedDocuments() {
        // Get documents from contexts
        let contextDocumentIds = Array(Set(contexts.map { $0.documentId }))
        referencedDocuments = contextDocumentIds.compactMap { uuid in
            ServiceContainer.shared.documentService.findDocument(byId: uuid)
        }
    }
    
    private func buildHighlightedAttributedString() -> AttributedString {
        var result = AttributedString(text)
        
        // Apply default text color
        result.foregroundColor = DesignSystem.Colors.primaryText
        
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
            
            // Find document and context
            let document = findReferencedDocument(for: documentName)
            let context = findDocumentContext(for: documentName)
            
            // Convert NSRange to AttributedString range
            let utf16Range = match.range
            let utf16Start = String.Index(utf16Offset: utf16Range.location, in: text)
            let utf16End = String.Index(utf16Offset: utf16Range.location + utf16Range.length, in: text)
            
            if let attrStart = AttributedString.Index(utf16Start, within: result),
               let attrEnd = AttributedString.Index(utf16End, within: result) {
                let attributedRange = attrStart..<attrEnd
                
                if document != nil {
                    // Valid reference - highlight with blue color (same as ChatInputView)
                    result[attributedRange].backgroundColor = DesignSystem.Colors.accent.opacity(0.2)
                    result[attributedRange].foregroundColor = DesignSystem.Colors.accent
                    result[attributedRange].font = .system(size: DesignSystem.Typography.FontSize.body, weight: .medium)
                } else {
                    // Invalid reference - red highlight
                    result[attributedRange].backgroundColor = Color.red.opacity(0.2)
                    result[attributedRange].foregroundColor = Color.red
                }
            }
        }
        
        return result
    }
    
    // private func getContextColor(for context: DocumentContext?) -> Color {
    //     guard let context = context else { return Color.blue }
        
    //     switch context.contextType {
    //     case .fullDocument: return Color.blue
    //     case .pageRange: return Color.purple
    //     case .textSelection: return Color.orange
    //     case .semanticChunk: return Color.green
    //     }
    // }
    
    private func findReferencedDocument(for documentName: String) -> Document? {
        let foundInReferences = referencedDocuments.first { document in
            if document.title.lowercased() == documentName.lowercased() {
                return true
            }
            let titleWithoutPdf = document.title.hasSuffix(".pdf") ? 
                String(document.title.dropLast(4)) : document.title
            return titleWithoutPdf.lowercased() == documentName.lowercased()
        }
        
        if let found = foundInReferences {
            return found
        }
        
        return ServiceContainer.shared.documentService.findDocument(byName: documentName)
    }
    
    private func findDocumentContext(for documentName: String) -> DocumentContext? {
        return contexts.first { context in
            let contextTitleWithoutPdf = context.documentTitle.hasSuffix(".pdf") ? 
                String(context.documentTitle.dropLast(4)) : context.documentTitle
            let searchNameWithoutPdf = documentName.hasSuffix(".pdf") ? 
                String(documentName.dropLast(4)) : documentName
            
            return contextTitleWithoutPdf.lowercased() == searchNameWithoutPdf.lowercased()
        }
    }
    

    
    private func handleTap(at location: CGPoint) {
        // Find which @mention was tapped (simplified approach)
        // For now, we'll handle any tap on the text as opening the first found document
        let pattern = DocumentReferenceResolver.documentReferencePattern
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return
        }
        
        let nsString = text as NSString
        let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))
        
        // For simplicity, open the first valid document found
        for match in matches {
            let matchText = nsString.substring(with: match.range)
            let documentName = DocumentReferenceResolver.extractDocumentName(from: matchText)
            
            if let document = findReferencedDocument(for: documentName) {
                openDocument(document, context: findDocumentContext(for: documentName))
                break
            }
        }
    }
    
    private func openDocument(_ document: Document, context: DocumentContext?) {
        print("🔍 Opening document: '\(document.title)' (ID: \(document.id))")
        
        // Open the document in the PDF viewer
        ServiceContainer.shared.appState.selectDocument(document)
        
        // If we have context with specific page/location info, navigate there
        if let context = context {
            navigateToContext(in: document, context: context)
        }
        
        print("📤 Updated AppState with selected document")
    }
    
    private func navigateToContext(in document: Document, context: DocumentContext) {
        print("🎯 Navigating to context in document: \(context.contextType.displayName)")
        
        // Schedule navigation after PDF loads
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if let pageNumbers = context.metadata.pageNumbers, let firstPage = pageNumbers.first {
                print("📄 Navigating to page \(firstPage)")
                ServiceContainer.shared.appState.navigateToPDFPage(firstPage)
            }
        }
    }
}

#Preview {
    VStack(spacing: DesignSystem.Spacing.md) {
        MessageView(message: ChatMessage(
            text: "Hello, how can I help you with your documents today? I can analyze PDFs, answer questions about their content, and help you understand complex information.",
            isUser: false
        ))
        
        MessageView(message: ChatMessage(
            text: "Can you help me understand @document.pdf and also reference @research_paper.pdf in this longer message?",
            isUser: true
        ))
        
        MessageView(message: ChatMessage(
            text: "This is a streaming message that's being typed...",
            isUser: false,
            isStreaming: true
        ))
        
        MessageView(message: ChatMessage(
            text: "Sure! I can definitely help you with that.",
            isUser: false
        ), shouldGroup: false)
        
        MessageView(message: ChatMessage(
            text: "What specific aspects would you like me to explain?",
            isUser: false
        ), shouldGroup: true)
    }
    .padding()
    .frame(width: 400)
    .background(DesignSystem.Colors.background)
} 
