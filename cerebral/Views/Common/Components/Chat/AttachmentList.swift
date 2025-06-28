//
//  AttachmentList.swift
//  cerebral
//
//  Reusable Attachment List Component
//

import SwiftUI

struct AttachmentList: View {
    let documents: [Document]
    let textChunks: [TextSelectionChunk]
    let onRemoveDocument: (Document) -> Void
    let onRemoveTextChunk: (TextSelectionChunk) -> Void
    
    var hasAttachments: Bool {
        !documents.isEmpty || !textChunks.isEmpty
    }
    
    var body: some View {
        if hasAttachments {
            VStack(spacing: DesignSystem.Spacing.sm) {
                // Document attachments
                if !documents.isEmpty {
                    AttachmentPreviewView(
                        documents: documents,
                        onRemove: onRemoveDocument
                    )
                }
                
                // Text selection chunks
                if !textChunks.isEmpty {
                    TextChunkPreviewView(
                        chunks: textChunks,
                        onRemove: onRemoveTextChunk
                    )
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
            .transition(.modernSlide)
        }
    }
}

// MARK: - Attachment Preview

struct AttachmentPreviewView: View {
    let documents: [Document]
    let onRemove: (Document) -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DesignSystem.Spacing.sm) {
                ForEach(documents, id: \.id) { document in
                    AttachmentPill(document: document) {
                        withAnimation(DesignSystem.Animation.quick) {
                            onRemove(document)
                        }
                    }
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.xs)
        }
        .frame(height: DesignSystem.Layout.minimumTouchTarget)
    }
}

struct AttachmentPill: View {
    let document: Document
    let onRemove: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.xs) {
            // Document icon
            Image(systemName: "doc.text")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(DesignSystem.Colors.accent)
            
            // Document title
            Text(document.title)
                .font(DesignSystem.Typography.caption)
                .fontWeight(.medium)
                .foregroundColor(DesignSystem.Colors.primaryText)
                .lineLimit(1)
                .truncationMode(.middle)
            
            // Remove button
            IconButton(
                icon: "xmark",
                style: .tertiary,
                size: .small
            ) {
                onRemove()
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.sm)
        .padding(.vertical, DesignSystem.Spacing.xs)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                .fill(DesignSystem.Materials.cardSurface)
                .stroke(DesignSystem.Colors.border.opacity(0.2), lineWidth: 1)
        )
        .scaleEffect(isHovered ? DesignSystem.Scale.active : 1.0)
        .animation(DesignSystem.Animation.micro, value: isHovered)
        .onHover { isHovered = $0 }
    }
}

// MARK: - Text Chunk Preview

struct TextChunkPreviewView: View {
    let chunks: [TextSelectionChunk]
    let onRemove: (TextSelectionChunk) -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DesignSystem.Spacing.sm) {
                ForEach(chunks, id: \.id) { chunk in
                    TextChunkPill(chunk: chunk) {
                        withAnimation(DesignSystem.Animation.quick) {
                            onRemove(chunk)
                        }
                    }
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.xs)
        }
        .frame(height: DesignSystem.Layout.minimumTouchTarget)
    }
}

struct TextChunkPill: View {
    let chunk: TextSelectionChunk
    let onRemove: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.xs) {
            // Text selection icon
            Image(systemName: "quote.bubble")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(DesignSystem.Colors.accent)
            
            // Preview text with source
            VStack(alignment: .leading, spacing: 1) {
                Text(chunk.previewText)
                    .font(DesignSystem.Typography.caption)
                    .fontWeight(.medium)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                    .lineLimit(1)
                
                Text("from \(chunk.source)")
                    .font(DesignSystem.Typography.caption2)
                    .foregroundColor(DesignSystem.Colors.tertiaryText)
                    .lineLimit(1)
            }
            
            // Remove button
            IconButton(
                icon: "xmark",
                style: .tertiary,
                size: .small
            ) {
                onRemove()
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.sm)
        .padding(.vertical, DesignSystem.Spacing.xs)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                .fill(DesignSystem.Materials.cardSurface)
                .stroke(DesignSystem.Colors.accent.opacity(0.2), lineWidth: 1)
        )
        .scaleEffect(isHovered ? DesignSystem.Scale.active : 1.0)
        .animation(DesignSystem.Animation.micro, value: isHovered)
        .onHover { isHovered = $0 }
    }
}

#Preview {
    AttachmentList(
        documents: [
            Document(title: "Sample Document.pdf", filePath: URL(fileURLWithPath: "/path/to/document.pdf")),
            Document(title: "Research Paper.pdf", filePath: URL(fileURLWithPath: "/path/to/research.pdf"))
        ],
        textChunks: [
            TextSelectionChunk(text: "This is a sample text selection from a PDF document.", source: "Sample Document"),
            TextSelectionChunk(text: "Another text selection example that demonstrates the feature.", source: "Research Paper")
        ]
    ) { document in
        print("Remove document: \(document.title)")
    } onRemoveTextChunk: { chunk in
        print("Remove text chunk: \(chunk.previewText)")
    }
    .padding()
} 