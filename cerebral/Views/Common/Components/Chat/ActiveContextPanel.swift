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
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                // Clean header like @ mentions
                HStack(spacing: DesignSystem.Spacing.sm) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(DesignSystem.Colors.accent)
                    
                    Text("Active Context")
                        .appleTextStyle(.caption)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    // Simple token badge
                    Text("\(formattedTokenCount) tokens")
                        .appleTextStyle(.caption2)
                        .foregroundColor(DesignSystem.Colors.tertiaryText)
                        .padding(.horizontal, DesignSystem.Spacing.xs)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(DesignSystem.Colors.tertiaryBackground)
                        )
                }
                
                // Context chips with horizontal scroll
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: DesignSystem.Spacing.xs) {
                        ForEach(contextBundle.contexts) { context in
                            ContextChip(
                                context: context,
                                onRemove: { onRemoveContext(context) }
                            )
                        }
                        
                        // Add button like @ mentions
                        AddContextButton(action: onAddContext)
                    }
                    .padding(.horizontal, 1) // Prevent clipping
                }
            }
            .padding(DesignSystem.Spacing.md)
            .card(elevation: .low)
        }
    }
    
    private var formattedTokenCount: String {
        let tokenCount = contextBundle.tokenCount()
        if tokenCount >= 1000000 {
            return String(format: "%.1fM", Double(tokenCount) / 1000000.0)
        } else if tokenCount >= 1000 {
            return String(format: "%.1fK", Double(tokenCount) / 1000.0)
        } else {
            return "\(tokenCount)"
        }
    }
}

struct AddContextButton: View {
    let action: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignSystem.Spacing.xs) {
                Image(systemName: "plus")
                    .font(.system(size: 10, weight: .semibold))
                
                Text("Add")
                    .appleTextStyle(.caption2)
                    .fontWeight(.medium)
            }
            .foregroundColor(DesignSystem.Colors.accent)
            .padding(.horizontal, DesignSystem.Spacing.sm)
            .padding(.vertical, DesignSystem.Spacing.xs)
            .background(
                Capsule()
                    .strokeBorder(DesignSystem.Colors.accent.opacity(0.3), lineWidth: 1)
                    .background(
                        Capsule()
                            .fill(isHovered ? DesignSystem.Colors.accentSecondary : Color.clear)
                    )
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(DesignSystem.Animation.micro) {
                isHovered = hovering
            }
        }
        .help("Add context to conversation")
    }
}

struct ContextChip: View {
    let context: DocumentContext
    let onRemove: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.xs) {
            // Context type dot indicator
            Circle()
                .fill(contextColor)
                .frame(width: 6, height: 6)
            
            // Document name (clickable)
            Button(action: openDocument) {
                Text(context.documentTitle)
                    .appleTextStyle(.caption2)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                    .fontWeight(.medium)
                    .lineLimit(1)
            }
            .buttonStyle(.plain)
            .help("Open \(context.documentTitle)")
            
            // Context type badge
            Text(contextTypeName)
                .appleTextStyle(.caption2)
                .foregroundColor(DesignSystem.Colors.tertiaryText)
                .padding(.horizontal, DesignSystem.Spacing.xs)
                .padding(.vertical, 1)
                .background(
                    Capsule()
                        .fill(DesignSystem.Colors.tertiaryBackground)
                )
            
            // Remove button
            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(DesignSystem.Colors.tertiaryText)
            }
            .buttonStyle(.plain)
            .opacity(isHovered ? 1.0 : 0.6)
            .help("Remove from context")
        }
        .padding(.horizontal, DesignSystem.Spacing.sm)
        .padding(.vertical, DesignSystem.Spacing.xs)
        .background(
            Capsule()
                .fill(DesignSystem.Colors.secondaryBackground)
                .overlay(
                    Capsule()
                        .strokeBorder(DesignSystem.Colors.borderSecondary, lineWidth: 0.5)
                )
        )
        .onHover { hovering in
            withAnimation(DesignSystem.Animation.micro) {
                isHovered = hovering
            }
        }
    }
    
    private func openDocument() {
        guard let document = ServiceContainer.shared.documentService.findDocument(byId: context.documentId) else {
            return
        }
        
        ServiceContainer.shared.appState.selectDocument(document)
        
        // Navigate to context location
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            if let pageNumbers = context.metadata.pageNumbers, let firstPage = pageNumbers.first {
                ServiceContainer.shared.appState.navigateToPDFPage(firstPage)
                
                if context.contextType == .textSelection,
                   let selectionBounds = context.metadata.selectionBounds,
                   !selectionBounds.isEmpty {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        ServiceContainer.shared.appState.navigateToSelectionBounds(
                            bounds: selectionBounds,
                            onPage: firstPage
                        )
                    }
                }
            }
        }
    }
    
    private var contextColor: Color {
        switch context.contextType {
        case .fullDocument: return DesignSystem.Colors.accent
        case .pageRange: return DesignSystem.Colors.secondaryAccent
        case .textSelection: return DesignSystem.Colors.success
        case .semanticChunk: return DesignSystem.Colors.warning
        }
    }
    
    private var contextTypeName: String {
        switch context.contextType {
        case .fullDocument: return "Full"
        case .pageRange:
            if let pages = context.metadata.pageNumbers {
                return pages.count == 1 ? "Page" : "\(pages.count)p"
            }
            return "Pages"
        case .textSelection: return "Text"
        case .semanticChunk: return "Section"
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
                        documentTitle: "Machine Learning Research.pdf",
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
                        documentTitle: "Neural Networks.pdf",
                        contextType: .textSelection,
                        content: "Selected text",
                        metadata: ContextMetadata(
                            pageNumbers: [42],
                            extractionMethod: "UserSelection",
                            tokenCount: 256,
                            checksum: "def456"
                        )
                    ),
                    DocumentContext(
                        documentId: UUID(),
                        documentTitle: "Conference Proceedings.pdf",
                        contextType: .pageRange,
                        content: "Content",
                        metadata: ContextMetadata(
                            pageNumbers: [1, 2, 3],
                            extractionMethod: "PDFKit",
                            tokenCount: 1234,
                            checksum: "ghi789"
                        )
                    )
                ]
            )),
            onRemoveContext: { _ in },
            onAddContext: { }
        )
        .frame(width: 600)
        .padding()
    }
    .background(DesignSystem.Colors.background)
} 