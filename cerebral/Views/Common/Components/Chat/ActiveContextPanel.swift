//
//  ActiveContextPanel.swift
//  cerebral
//
//  Created on 26/06/2025.
//

import SwiftUI

struct ActiveContextPanel: View {
    @Binding var contextBundle: ChatContextBundle
    let onRemoveContext: (DocumentContext) -> Void
    let onAddContext: () -> Void
    
    var body: some View {
        if !contextBundle.contexts.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Active Context")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("~\(formattedTokenCount) tokens")
                        .font(.caption2)
                        .foregroundColor(.secondary.opacity(0.7))
                }
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(contextBundle.contexts) { context in
                            ContextChip(
                                context: context,
                                onRemove: { onRemoveContext(context) }
                            )
                        }
                        
                        // Add context button
                        Button(action: onAddContext) {
                            HStack(spacing: 4) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.caption)
                                Text("Add")
                                    .font(.caption)
                            }
                            .foregroundColor(.accentColor)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .strokeBorder(Color.accentColor.opacity(0.3), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(NSColor.controlBackgroundColor).opacity(0.8))
            )
        }
    }
    
    private var formattedTokenCount: String {
        let tokenCount = contextBundle.tokenCount()
        if tokenCount > 1000 {
            return "\(tokenCount / 1000)k"
        } else {
            return "\(tokenCount)"
        }
    }
}

struct ContextChip: View {
    let context: DocumentContext
    let onRemove: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 6) {
            Button(action: openDocument) {
                HStack(spacing: 6) {
                    Image(systemName: contextIcon)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    VStack(alignment: .leading, spacing: 0) {
                        Text(context.documentTitle)
                            .font(.caption)
                            .lineLimit(1)
                            .truncationMode(.middle)
                        
                        Text(contextDescription)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .buttonStyle(.plain)
            .help(context.contextType == .textSelection ? 
                  "Click to navigate to the selected text in \(context.documentTitle)" : 
                  "Click to open \(context.documentTitle)")
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .opacity(isHovered ? 1 : 0.6)
            }
            .buttonStyle(.plain)
            .help("Remove from context")
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(NSColor.controlBackgroundColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(Color.secondary.opacity(0.2), lineWidth: 1)
                )
        )
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }
    
    private func openDocument() {
        // Find the document by ID
        guard let document = ServiceContainer.shared.documentService.findDocument(byId: context.documentId) else {
            print("❌ Document not found for context: \(context.documentTitle)")
            return
        }
        
        print("🔍 Opening document from context chip: '\(document.title)' (ID: \(document.id))")
        
        // Open the document in the PDF viewer
        ServiceContainer.shared.appState.selectDocument(document)
        
        // Navigate to the specific context location
        navigateToContext(context: context)
        
        print("📤 Updated AppState with selected document from context")
    }
    
    private func navigateToContext(context: DocumentContext) {
        print("🎯 Navigating to context: \(context.contextType.displayName)")
        
        // Schedule navigation after PDF loads
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if let pageNumbers = context.metadata.pageNumbers, let firstPage = pageNumbers.first {
                print("📄 Navigating to page \(firstPage) from context chip")
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
    
    private var contextIcon: String {
        switch context.contextType {
        case .fullDocument: return "doc.fill"
        case .pageRange: return "doc.on.doc"
        case .textSelection: return "text.viewfinder"
        case .semanticChunk: return "brain"
        }
    }
    
    private var contextDescription: String {
        switch context.contextType {
        case .fullDocument:
            return "Full document"
        case .pageRange:
            if let pages = context.metadata.pageNumbers {
                return pages.count == 1 ? "Page \(pages[0])" : "\(pages.count) pages"
            }
            return "Pages"
        case .textSelection:
            // Show a preview of the selected text
            if !context.content.isEmpty {
                let preview = context.content.prefix(40)
                return "\"\(preview)...\""
            }
            return "Selection"
        case .semanticChunk:
            return "Relevant section"
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        ActiveContextPanel(
            contextBundle: .constant(ChatContextBundle(
                contexts: [
                    DocumentContext(
                        documentId: UUID(),
                        documentTitle: "Research Paper.pdf",
                        contextType: .fullDocument,
                        content: "Content",
                        metadata: ContextMetadata(
                            extractionMethod: "PDFKit",
                            tokenCount: 5432,
                            checksum: "abc123"
                        )
                    ),
                    DocumentContext(
                        documentId: UUID(),
                        documentTitle: "Meeting Notes with a very long title.pdf",
                        contextType: .pageRange,
                        content: "Content",
                        metadata: ContextMetadata(
                            pageNumbers: [1, 2, 3],
                            extractionMethod: "PDFKit",
                            tokenCount: 1234,
                            checksum: "def456"
                        )
                    )
                ]
            )),
            onRemoveContext: { _ in print("Remove context") },
            onAddContext: { print("Add context") }
        )
        .frame(width: 600)
        .padding()
    }
} 