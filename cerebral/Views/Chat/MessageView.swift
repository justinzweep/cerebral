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
    @State private var isHovered = false
    
    init(message: ChatMessage, shouldGroup: Bool = false) {
        self.message = message
        self.shouldGroup = shouldGroup
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: DesignSystem.Spacing.sm) {
            if message.isUser {
                Spacer(minLength: DesignSystem.Spacing.xxl)
                
                // User message with inline clickable @mentions
                FlowMessageText(text: message.text, documentReferences: message.documentReferences)
                    .padding(.horizontal, DesignSystem.Spacing.md)
                    .padding(.vertical, DesignSystem.Spacing.sm)
                    .animation(DesignSystem.Animation.microInteraction, value: isHovered)
                    .onHover { isHovered = $0 }
                    .contextMenu {
                        Button("Copy Message") {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(message.text, forType: .string)
                        }
                    }
            } else {
                // AI message - no background with white text
                Text(message.text)
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(.white)
                    .padding(.horizontal, DesignSystem.Spacing.md)
                    .padding(.vertical, DesignSystem.Spacing.sm)
                    .textSelection(.enabled)
                    .onHover { isHovered = $0 }
                    .contextMenu {
                        Button("Copy Message") {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(message.text, forType: .string)
                        }
                        
                        Divider()
                        
                        Button("Regenerate Response") {
                            // TODO: Implement regenerate functionality
                        }
                    }
                
                Spacer(minLength: DesignSystem.Spacing.xxl)
            }
        }
        .padding(.vertical, shouldGroup ? DesignSystem.Spacing.xxxs : DesignSystem.Spacing.xs)
    }
}

// MARK: - Inline Message Text with Clickable Pills

struct InlineMessageText: View {
    let text: String
    @State private var textParts: [TextPart] = []
    
    var body: some View {
        // Use Text with AttributedString to keep everything inline
        Text(buildClickableAttributedString())
            .font(DesignSystem.Typography.body)
            .foregroundColor(.white)
            .textSelection(.enabled)
            .onAppear {
                parseTextParts()
            }
    }
    
    private func buildClickableAttributedString() -> AttributedString {
        var result = AttributedString()
        
        for part in textParts {
            var partString = AttributedString(part.text)
            
            if part.isMention {
                // Style as clickable pill
                partString.backgroundColor = .blue.opacity(0.4)
                partString.foregroundColor = .white
                partString.font = .system(size: 14, weight: .medium)
                
                // Add click handler - this is where we'll handle the tap
                partString.link = URL(string: "mention://\(part.documentName)")
                
                // Add some padding-like effect with spaces
                partString = AttributedString(" ") + partString + AttributedString(" ")
            }
            
            result += partString
        }
        
        return result
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
            // Add text before mention
            if match.range.location > lastLocation {
                let beforeText = nsString.substring(with: NSRange(location: lastLocation, length: match.range.location - lastLocation))
                if !beforeText.isEmpty {
                    textParts.append(TextPart(text: beforeText, isMention: false, documentName: ""))
                }
            }
            
            // Add mention
            let mentionText = nsString.substring(with: match.range)
            var documentName = String(mentionText.dropFirst())
            if documentName.hasSuffix(".pdf") {
                documentName = String(documentName.dropLast(4))
            }
            
            textParts.append(TextPart(text: mentionText, isMention: true, documentName: documentName))
            
            lastLocation = match.range.location + match.range.length
        }
        
        // Add remaining text
        if lastLocation < nsString.length {
            let remainingText = nsString.substring(from: lastLocation)
            if !remainingText.isEmpty {
                textParts.append(TextPart(text: remainingText, isMention: false, documentName: ""))
            }
        }
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

// MARK: - Alternative Implementation with Proper Inline Layout

struct FlowMessageText: View {
    let text: String
    let documentReferences: [UUID]
    @State private var textParts: [TextPart] = []
    @State private var referencedDocuments: [Document] = []
    
    var body: some View {
                        InlineFlowLayout(alignment: .leading, spacing: 2) {
            ForEach(Array(textParts.enumerated()), id: \.offset) { index, part in
                if part.isMention {
                    MentionPillButton(
                        text: part.text,
                        documentName: part.documentName,
                        document: findReferencedDocument(for: part.documentName)
                    )
                } else {
                    // Split text by spaces and newlines for proper flow
                    ForEach(part.text.components(separatedBy: .whitespacesAndNewlines), id: \.self) { word in
                        if !word.isEmpty {
                            Text(word + " ")
                                .font(DesignSystem.Typography.body)
                                .foregroundColor(.white)
                        }
                    }
                }
            }
        }
        .onAppear {
            loadReferencedDocuments()
            parseTextParts()
        }
    }
    
    private func loadReferencedDocuments() {
        // Convert UUIDs to actual Document objects using the improved lookup service
        referencedDocuments = documentReferences.compactMap { uuid in
            DocumentLookupService.shared.findDocument(byId: uuid)
        }
        
        print("📚 Loaded \(referencedDocuments.count) referenced documents for message")
        for doc in referencedDocuments {
            print("  - '\(doc.title)' (ID: \(doc.id))")
        }
        
        // Debug: Print all document references and available documents
        if documentReferences.count != referencedDocuments.count {
            print("⚠️ Missing documents - looking for \(documentReferences.count) but found \(referencedDocuments.count)")
            let allDocs = DocumentLookupService.shared.getAllDocuments()
            print("📋 Available documents (\(allDocs.count)):")
            for doc in allDocs.prefix(5) {
                print("  - '\(doc.title)' (ID: \(doc.id))")
            }
        }
    }
    
    private func findReferencedDocument(for documentName: String) -> Document? {
        // First try to find in the referenced documents list
        let foundInReferences = referencedDocuments.first { document in
            // Try exact match first
            if document.title.lowercased() == documentName.lowercased() {
                return true
            }
            // Try without .pdf extension
            let titleWithoutPdf = document.title.hasSuffix(".pdf") ? 
                String(document.title.dropLast(4)) : document.title
            return titleWithoutPdf.lowercased() == documentName.lowercased()
        }
        
        if let found = foundInReferences {
            return found
        }
        
        // Fallback: try to find in all available documents
        return DocumentLookupService.shared.findDocument(byName: documentName)
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
            // Add text before mention
            if match.range.location > lastLocation {
                let beforeText = nsString.substring(with: NSRange(location: lastLocation, length: match.range.location - lastLocation))
                if !beforeText.isEmpty {
                    textParts.append(TextPart(text: beforeText, isMention: false, documentName: ""))
                }
            }
            
            // Add mention
            let mentionText = nsString.substring(with: match.range)
            var documentName = String(mentionText.dropFirst())
            if documentName.hasSuffix(".pdf") {
                documentName = String(documentName.dropLast(4))
            }
            
            textParts.append(TextPart(text: mentionText, isMention: true, documentName: documentName))
            
            lastLocation = match.range.location + match.range.length
        }
        
        // Add remaining text
        if lastLocation < nsString.length {
            let remainingText = nsString.substring(from: lastLocation)
            if !remainingText.isEmpty {
                textParts.append(TextPart(text: remainingText, isMention: false, documentName: ""))
            }
        }
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

// MARK: - Mention Pill Button

struct MentionPillButton: View {
    let text: String
    let documentName: String
    let document: Document?
    @State private var isHovered = false
    
    var body: some View {
        Button(action: {
            openDocument()
        }) {
            HStack(spacing: 4) {
                Image(systemName: "doc.fill")
                    .font(.system(size: 10, weight: .medium))
                
                Text(text)
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(document != nil ? Color.blue.opacity(0.6) : Color.gray.opacity(0.6))
                    .overlay(
                        Capsule()
                            .stroke(document != nil ? Color.blue.opacity(0.8) : Color.gray.opacity(0.8), lineWidth: 1)
                    )
            )
            .scaleEffect(isHovered ? 1.05 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isHovered)
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .help(document != nil ? "Click to open \(documentName).pdf" : "Document '\(documentName)' not found")
        .disabled(document == nil)
    }
    
    private func openDocument() {
        guard let document = document else {
            print("❌ No document available to open for: '\(documentName)'")
            return
        }
        
        print("🔍 Opening document: '\(document.title)' (ID: \(document.id))")
        NotificationCenter.default.post(
            name: .documentSelected,
            object: document
        )
        print("📤 Posted .documentSelected notification")
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
        let width = proposal.width ?? .infinity
        var height: CGFloat = 0
        var lineHeight: CGFloat = 0
        var currentX: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            
            if currentX + size.width > width {
                height += lineHeight + spacing
                lineHeight = size.height
                currentX = size.width + spacing
            } else {
                lineHeight = max(lineHeight, size.height)
                currentX += size.width + spacing
            }
        }
        
        height += lineHeight
        return CGSize(width: width, height: height)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var currentX: CGFloat = bounds.minX
        var currentY: CGFloat = bounds.minY
        var lineHeight: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            
            if currentX + size.width > bounds.maxX && currentX > bounds.minX {
                currentY += lineHeight + spacing
                currentX = bounds.minX
                lineHeight = 0
            }
            
            subview.place(at: CGPoint(x: currentX, y: currentY), proposal: ProposedViewSize(size))
            
            currentX += size.width + spacing
            lineHeight = max(lineHeight, size.height)
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
        
        // Grouped messages example
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
    .background(.black) // Dark background to see white text
} 