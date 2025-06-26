//
//  DocumentRowView.swift
//  cerebral
//
//  Created by Justin Zweep on 26/06/2025.
//

import SwiftUI

struct DocumentRowView: View {
    let document: Document
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            // PDF Icon
            Image(systemName: "doc.fill")
                .foregroundColor(DesignSystem.Colors.pdfRed)
                .font(DesignSystem.Typography.title3)
                .frame(width: 24, height: 24)
                .accessibilityHidden(true)
            
            // Document Info
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxxs) {
                Text(document.title)
                    .font(DesignSystem.Typography.headline)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                
                HStack(spacing: DesignSystem.Spacing.xs) {
                    Text(document.dateAdded, style: .relative)
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.textTertiary)
                    
                    if let lastOpened = document.lastOpened {
                        Text("•")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.textTertiary)
                        
                        Text("Opened \(lastOpened, style: .relative)")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.textTertiary)
                    }
                }
            }
            
            Spacer()
        }
        .padding(.vertical, DesignSystem.Spacing.xs)
        .padding(.horizontal, DesignSystem.Spacing.sm)
        .background(Color.clear)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("PDF document: \(document.title)")
        .accessibilityHint("Added \(document.dateAdded, style: .relative). Double-click to open.")
        .accessibilityAddTraits(.isButton)
        .contextMenu {
            Button {
                NotificationCenter.default.post(name: .documentSelected, object: document)
            } label: {
                Label("Chat about this document", systemImage: "message")
            }
            .accessibleButton(
                label: "Start chat about \(document.title)",
                hint: "Opens the chat panel with this document's context"
            )
            
            Divider()
            
            Button {
                NSWorkspace.shared.activateFileViewerSelecting([document.filePath])
            } label: {
                Label("Reveal in Finder", systemImage: "folder")
            }
            .accessibleButton(
                label: "Show \(document.title) in Finder",
                hint: "Opens Finder and highlights this document"
            )
            
            Divider()
            
            Button(role: .destructive) {
                // This will be handled by the parent view
            } label: {
                Label("Delete", systemImage: "trash")
            }
            .accessibleButton(
                label: "Delete \(document.title)",
                hint: "Removes this document from your library"
            )
        }
    }
}

#Preview {
    let sampleDocument = Document(
        title: "Sample Document",
        filePath: URL(fileURLWithPath: "/path/to/sample.pdf")
    )
    
    return DocumentRowView(document: sampleDocument)
        .padding()
} 
