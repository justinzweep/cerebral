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

// MARK: - Alternative Implementation with Proper Inline Layout

struct FlowMessageText: View {
    let text: String
    let contexts: [DocumentContext]
    @State private var textParts: [TextPart] = []
    @State private var referencedDocuments: [Document] = []
    
    init(text: String, contexts: [DocumentContext] = []) {
        self.text = text
        self.contexts = contexts
    }
    
    var body: some View {
        Group {
            let hasMentions = textParts.contains { $0.isMention }
            
            if hasMentions {
                flowLayoutContent
            } else {
                simpleTextContent
            }
        }
        .onAppear {
            loadReferencedDocuments()
            parseTextParts()
        }
    }
    
    private var flowLayoutContent: some View {
        InlineFlowLayout(alignment: .leading, spacing: 4) {
            ForEach(Array(textParts.enumerated()), id: \.offset) { index, part in
                if part.isMention {
                    MentionPillButton(
                        text: part.text,
                        documentName: part.documentName,
                        document: findReferencedDocument(for: part.documentName),
                        context: findDocumentContext(for: part.documentName)
                    )
                } else {
                    Text(part.text)
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                }
            }
        }
    }
    
    private var simpleTextContent: some View {
        Text(text)
            .font(DesignSystem.Typography.body)
            .foregroundColor(DesignSystem.Colors.primaryText)
    }
    
    private func loadReferencedDocuments() {
        // Get documents from contexts instead of legacy documentReferences
        let contextDocumentIds = Array(Set(contexts.map { $0.documentId }))
        referencedDocuments = contextDocumentIds.compactMap { uuid in
            ServiceContainer.shared.documentService.findDocument(byId: uuid)
        }
        
        print("📚 Loaded \(referencedDocuments.count) referenced documents from contexts")
        for doc in referencedDocuments {
            print("  - '\(doc.title)' (ID: \(doc.id))")
        }
    }
    
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
        // Find context that matches the document name
        return contexts.first { context in
            let contextTitleWithoutPdf = context.documentTitle.hasSuffix(".pdf") ? 
                String(context.documentTitle.dropLast(4)) : context.documentTitle
            let searchNameWithoutPdf = documentName.hasSuffix(".pdf") ? 
                String(documentName.dropLast(4)) : documentName
            
            return contextTitleWithoutPdf.lowercased() == searchNameWithoutPdf.lowercased()
        }
    }
    
    private func parseTextParts() {
        textParts = []
        
        let pattern = #"@([a-zA-Z0-9\s\-_\.]+\.pdf|[a-zA-Z0-9\s\-_\.]+)"#
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            textParts = [TextPart(text: text, isMention: false, documentName: "")]
            return
        }
        
        let nsString = text as NSString
        let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))
        
        var lastLocation = 0
        
        for match in matches {
            if match.range.location > lastLocation {
                let beforeText = nsString.substring(with: NSRange(location: lastLocation, length: match.range.location - lastLocation))
                if !beforeText.isEmpty {
                    textParts.append(TextPart(text: beforeText, isMention: false, documentName: ""))
                }
            }
            
            let mentionText = nsString.substring(with: match.range)
            var documentName = String(mentionText.dropFirst())
            if documentName.hasSuffix(".pdf") {
                documentName = String(documentName.dropLast(4))
            }
            
            textParts.append(TextPart(text: mentionText, isMention: true, documentName: documentName))
            
            lastLocation = match.range.location + match.range.length
        }
        
        if lastLocation < nsString.length {
            let remainingText = nsString.substring(from: lastLocation)
            if !remainingText.isEmpty {
                textParts.append(TextPart(text: remainingText, isMention: false, documentName: ""))
            }
        }
    }
}

// MARK: - Mention Pill Button

struct MentionPillButton: View {
    let text: String
    let documentName: String
    let document: Document?
    let context: DocumentContext?
    @State private var isHovered = false
    
    var body: some View {
        Button(action: openDocument) {
            pillContent
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .help(document != nil ? "Click to open \(documentName).pdf" : "Document '\(documentName)' not found")
        .disabled(document == nil)
    }
    
    private var pillContent: some View {
        HStack(spacing: 4) {
            Image(systemName: contextIcon)
                .font(.system(size: 10, weight: .medium))
            
            Text(text)
                .font(.system(size: 13, weight: .medium))
        }
        .foregroundColor(DesignSystem.Colors.textOnAccent)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(pillBackground)
        .scaleEffect(isHovered ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isHovered)
    }
    
    private var pillBackground: some View {
        Capsule()
            .fill(document != nil ? pillColor : Color.gray.opacity(0.6))
            .overlay(
                Capsule()
                    .stroke(document != nil ? pillColor.opacity(0.8) : Color.gray.opacity(0.8), lineWidth: 1)
            )
    }
    
    private var contextIcon: String {
        guard let context = context else { return "doc.fill" }
        
        switch context.contextType {
        case .fullDocument: return "doc.fill"
        case .pageRange: return "doc.on.doc"
        case .textSelection: return "text.viewfinder"
        case .semanticChunk: return "brain"
        case .reference: return "at"
        }
    }
    
    private var pillColor: Color {
        guard let context = context else { return Color.blue.opacity(0.6) }
        
        switch context.contextType {
        case .fullDocument: return Color.blue.opacity(0.6)
        case .pageRange: return Color.purple.opacity(0.6)
        case .textSelection: return Color.orange.opacity(0.6)
        case .semanticChunk: return Color.green.opacity(0.6)
        case .reference: return Color.indigo.opacity(0.6)
        }
    }
    
    private func openDocument() {
        guard let document = document else {
            print("❌ No document available to open for: '\(documentName)'")
            return
        }
        
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

// MARK: - Inline Flow Layout for Text Elements

struct InlineFlowLayout: Layout {
    let alignment: Alignment
    let spacing: CGFloat
    
    init(alignment: Alignment = .center, spacing: CGFloat = 8) {
        self.alignment = alignment
        self.spacing = spacing
    }
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let availableWidth = proposal.width ?? .infinity
        var totalHeight: CGFloat = 0
        var lineHeight: CGFloat = 0
        var currentX: CGFloat = 0
        
        for subview in subviews {
            let subviewSize = subview.sizeThatFits(.unspecified)
            
            if currentX + subviewSize.width > availableWidth && currentX > 0 {
                totalHeight += lineHeight + spacing
                lineHeight = subviewSize.height
                currentX = subviewSize.width + spacing
            } else {
                lineHeight = max(lineHeight, subviewSize.height)
                currentX += subviewSize.width + spacing
            }
        }
        
        totalHeight += lineHeight
        return CGSize(width: availableWidth, height: totalHeight)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var currentX: CGFloat = bounds.minX
        var currentY: CGFloat = bounds.minY
        var lineHeight: CGFloat = 0
        
        for subview in subviews {
            let subviewSize = subview.sizeThatFits(.unspecified)
            
            if currentX + subviewSize.width > bounds.maxX && currentX > bounds.minX {
                currentY += lineHeight + spacing
                currentX = bounds.minX
                lineHeight = 0
            }
            
            let placement = CGPoint(x: currentX, y: currentY)
            let proposedSize = ProposedViewSize(subviewSize)
            subview.place(at: placement, proposal: proposedSize)
            
            currentX += subviewSize.width + spacing
            lineHeight = max(lineHeight, subviewSize.height)
        }
    }
}

// MARK: - Text Part Model

struct TextPart {
    let text: String
    let isMention: Bool
    let documentName: String
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
