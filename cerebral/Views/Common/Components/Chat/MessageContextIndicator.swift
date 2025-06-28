//
//  MessageContextIndicator.swift
//  cerebral
//
//  Created on 26/06/2025.
//

import SwiftUI

struct MessageContextIndicator: View {
    let contexts: [DocumentContext]
    @State private var isExpanded = false
    private let settingsManager = SettingsManager.shared
    
    var body: some View {
        if !contexts.isEmpty && settingsManager.showContextIndicators {
            VStack(alignment: .leading, spacing: 4) {
                // Summary view
                HStack(spacing: 6) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(contextSummary)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button(action: { withAnimation(.easeInOut(duration: 0.2)) { isExpanded.toggle() } }) {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(NSColor.controlBackgroundColor))
                )
                
                // Expanded details
                if isExpanded {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(groupedContexts.sorted(by: { $0.key < $1.key }), id: \.key) { documentTitle, docContexts in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(documentTitle)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                
                                ForEach(docContexts) { context in
                                    ContextDetailRow(context: context)
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color(NSColor.controlBackgroundColor).opacity(0.5))
                            )
                        }
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
    }
    
    private var contextSummary: String {
        let docCount = Set(contexts.map { $0.documentId }).count
        let tokenCount = contexts.reduce(0) { $0 + $1.metadata.tokenCount }
        let formattedTokenCount = tokenCount > 1000 ? "\(tokenCount / 1000)k" : "\(tokenCount)"
        
        if docCount == 1 {
            return "\(docCount) document, ~\(formattedTokenCount) tokens"
        } else {
            return "\(docCount) documents, ~\(formattedTokenCount) tokens"
        }
    }
    
    private var groupedContexts: [String: [DocumentContext]] {
        Dictionary(grouping: contexts, by: { $0.documentTitle })
    }
}

struct ContextDetailRow: View {
    let context: DocumentContext
    @State private var isHovered = false
    
    var body: some View {
        Button(action: openDocument) {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: contextTypeIcon)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .frame(width: 16)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(context.contextType.displayName)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    if let pageNumbers = context.metadata.pageNumbers, !pageNumbers.isEmpty {
                        Text(pageDescription(pageNumbers))
                            .font(.caption2)
                            .foregroundColor(.secondary.opacity(0.7))
                    }
                    
                    // Show text preview for text selections
                    if context.contextType == .textSelection && !context.content.isEmpty {
                        Text("\"\(context.content.prefix(60))...\"")
                            .font(.caption2)
                            .foregroundColor(.secondary.opacity(0.8))
                            .italic()
                            .lineLimit(2)
                    }
                    
                    Text("\(context.metadata.tokenCount) tokens")
                        .font(.caption2)
                        .foregroundColor(.secondary.opacity(0.7))
                }
                
                Spacer()
            }
        }
        .buttonStyle(.plain)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(isHovered ? Color.secondary.opacity(0.1) : Color.clear)
        )
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
        .help(context.contextType == .textSelection ? 
              "Click to navigate to the selected text in \(context.documentTitle)" : 
              "Click to open \(context.documentTitle)")
    }
    
    private func openDocument() {
        // Find the document by ID
        guard let document = ServiceContainer.shared.documentService.findDocument(byId: context.documentId) else {
            print("❌ Document not found for context: \(context.documentTitle)")
            return
        }
        
        print("🔍 Opening document from context detail: '\(document.title)' (ID: \(document.id))")
        
        // Open the document in the PDF viewer
        ServiceContainer.shared.appState.selectDocument(document)
        
        // Navigate to the specific context location
        navigateToContext(context: context)
        
        print("📤 Updated AppState with selected document from context detail")
    }
    
    private func navigateToContext(context: DocumentContext) {
        print("🎯 Navigating to context: \(context.contextType.displayName)")
        
        // Schedule navigation after PDF loads
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if let pageNumbers = context.metadata.pageNumbers, let firstPage = pageNumbers.first {
                print("📄 Navigating to page \(firstPage) from context detail")
                ServiceContainer.shared.appState.navigateToPDFPage(firstPage)
                
                // For text selections, try to navigate to the exact bounds within the page
                if context.contextType == .textSelection,
                   let selectionBounds = context.metadata.selectionBounds,
                   !selectionBounds.isEmpty {
                    
                    // Wait a bit more for page navigation to complete, then scroll to selection bounds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        ServiceContainer.shared.appState.navigateToSelectionBounds(
                            bounds: selectionBounds,
                            onPage: firstPage
                        )
                    }
                }
            }
        }
    }
    
    private var contextTypeIcon: String {
        switch context.contextType {
        case .fullDocument: return "doc.fill"
        case .pageRange: return "doc.on.doc"
        case .textSelection: return "text.viewfinder"
        case .semanticChunk: return "brain"
        }
    }
    
    private func pageDescription(_ pages: [Int]) -> String {
        if pages.count == 1 {
            return "Page \(pages[0])"
        } else if pages.count <= 3 {
            return "Pages \(pages.map(String.init).joined(separator: ", "))"
        } else {
            return "Pages \(pages.first!)-\(pages.last!)"
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        MessageContextIndicator(contexts: [
            DocumentContext(
                documentId: UUID(),
                documentTitle: "Research Paper.pdf",
                contextType: .fullDocument,
                content: "Sample content",
                metadata: ContextMetadata(
                    pageNumbers: [1, 2, 3, 4, 5],
                    extractionMethod: "PDFKit",
                    tokenCount: 5432,
                    checksum: "abc123"
                )
            ),
            DocumentContext(
                documentId: UUID(),
                documentTitle: "Meeting Notes.pdf",
                contextType: .textSelection,
                content: "Selected text",
                metadata: ContextMetadata(
                    pageNumbers: [2],
                    extractionMethod: "PDFKit",
                    tokenCount: 234,
                    checksum: "def456"
                )
            )
        ])
        .frame(width: 400)
        .padding()
    }
} 