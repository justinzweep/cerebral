//
//  AttachmentList.swift
//  cerebral
//
//  Reusable Attachment List Component
//

import SwiftUI

struct AttachmentList: View {
    let attachedDocuments: [Document]
    let onRemoveDocument: (Document) -> Void
    
    var hasAttachments: Bool {
        !attachedDocuments.isEmpty
    }
    
    var body: some View {
        if hasAttachments {
            AttachmentPreviewView(
                documents: attachedDocuments,
                onRemove: onRemoveDocument
            )
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

#Preview {
    AttachmentList(
        attachedDocuments: [
            Document(title: "Sample Document.pdf", filePath: URL(fileURLWithPath: "/path/to/document.pdf")),
            Document(title: "Research Paper.pdf", filePath: URL(fileURLWithPath: "/path/to/research.pdf"))
        ]
    ) { document in
        print("Remove document: \(document.title)")
    }
    .padding()
} 