//
//  AttachmentList.swift
//  cerebral
//
//  Reusable Attachment List Component
//

import SwiftUI
import PDFKit

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
                .font(DesignSystem.Typography.caption)
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

// MARK: - PDF Selection List

struct PDFSelectionList: View {
    let pdfSelections: [PDFSelectionInfo]
    let onRemoveSelection: (UUID) -> Void
    
    var hasSelections: Bool {
        !pdfSelections.isEmpty
    }
    
    var body: some View {
        if hasSelections {
            PDFSelectionPreviewView(
                selections: pdfSelections,
                onRemove: onRemoveSelection
            )
            .padding(.horizontal, DesignSystem.Spacing.md)
            .transition(.modernSlide)
        }
    }
}

// MARK: - PDF Selection Preview

struct PDFSelectionPreviewView: View {
    let selections: [PDFSelectionInfo]
    let onRemove: (UUID) -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DesignSystem.Spacing.sm) {
                ForEach(selections) { selection in
                    PDFSelectionPill(selection: selection) {
                        withAnimation(DesignSystem.Animation.quick) {
                            onRemove(selection.id)
                        }
                    }
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.xs)
        }
        .frame(height: DesignSystem.Layout.minimumTouchTarget)
    }
}

struct PDFSelectionPill: View {
    let selection: PDFSelectionInfo
    let onRemove: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.xs) {
            // Context icon
            Image(systemName: "text.badge.checkmark")
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.accent)
            
            // Selected text preview
            Text("\"\(selection.text.prefix(40))...\"")
                .font(DesignSystem.Typography.caption)
                .fontWeight(.medium)
                .foregroundColor(DesignSystem.Colors.primaryText)
                .lineLimit(1)
                .truncationMode(.tail)
            
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
                .fill(DesignSystem.Colors.accent.opacity(0.1))
                .stroke(DesignSystem.Colors.accent.opacity(0.3), lineWidth: 1)
        )
        .scaleEffect(isHovered ? DesignSystem.Scale.active : 1.0)
        .animation(DesignSystem.Animation.micro, value: isHovered)
        .onHover { isHovered = $0 }
    }
}

#Preview("PDF Selection List") {
    PDFSelectionList(
        pdfSelections: [
            PDFSelectionInfo(
                id: UUID(),
                selection: PDFSelection(), // Mock selection
                text: "Machine learning algorithms require large datasets to train effectively",
                timestamp: Date()
            ),
            PDFSelectionInfo(
                id: UUID(),
                selection: PDFSelection(), // Mock selection
                text: "Neural networks excel at pattern recognition tasks",
                timestamp: Date().addingTimeInterval(10)
            )
        ]
    ) { id in
        print("Remove selection: \(id)")
    }
    .padding()
} 
