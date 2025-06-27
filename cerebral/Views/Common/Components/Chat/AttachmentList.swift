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
            VStack(spacing: 8) {
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
            .padding(.horizontal, 16)
            .transition(.move(edge: .top).combined(with: .opacity))
        }
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
                    AttachmentPill(document: document) {
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

struct AttachmentPill: View {
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

// MARK: - Text Chunk Preview

struct TextChunkPreviewView: View {
    let chunks: [TextSelectionChunk]
    let onRemove: (TextSelectionChunk) -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(chunks, id: \.id) { chunk in
                    TextChunkPill(chunk: chunk) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            onRemove(chunk)
                        }
                    }
                }
            }
            .padding(.horizontal, 4)
        }
        .frame(height: 32)
    }
}

struct TextChunkPill: View {
    let chunk: TextSelectionChunk
    let onRemove: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 6) {
            // Text selection icon
            Image(systemName: "quote.bubble")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(DesignSystem.Colors.accent)
            
            // Preview text with source
            VStack(alignment: .leading, spacing: 1) {
                Text(chunk.previewText)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(DesignSystem.Colors.primaryText)
                    .lineLimit(1)
                
                Text("from \(chunk.source)")
                    .font(.system(size: 9, weight: .regular))
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
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(DesignSystem.Colors.accent.opacity(0.1))
                .stroke(DesignSystem.Colors.accent.opacity(0.3), lineWidth: 1)
        )
        .scaleEffect(isHovered ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isHovered)
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