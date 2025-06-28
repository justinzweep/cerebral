//
//  DocumentRowView.swift
//  cerebral
//
//  Created by Justin Zweep on 26/06/2025.
//

import SwiftUI

struct DocumentRowView: View {
    let document: Document
    @State private var isHovered = false
    @State private var showingEditTitle = false
    @State private var showingDeleteConfirmation = false
    @State private var editedTitle = ""
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            // PDF Thumbnail
            PDFThumbnailView(
                document: document,
                size: CGSize(width: 36, height: 44)
            )
            
            // Document info
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxxs) {
                Text(document.title)
                    .font(DesignSystem.Typography.body)
                    .fontWeight(.medium)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                    .lineLimit(2)
                    .truncationMode(.tail)
            }
            
            Spacer()
            
            // Add to Chat button - clean, always visible
            Button {
                ServiceContainer.shared.appState.addDocumentToChat(document)
            } label: {
                Image(systemName: "plus.message")
                    .font(DesignSystem.Typography.footnote)
                    .foregroundColor(DesignSystem.Colors.tertiaryText)
            }
            .buttonStyle(.plain)
            .frame(width: 24, height: 24)
            .background(
                Circle()
                    .fill(Color.clear)
            )
            .help("Add to Chat")
        
        }
        .padding(.horizontal, DesignSystem.Spacing.sm)
        .padding(.vertical, DesignSystem.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                .fill(isHovered ? DesignSystem.Colors.hoverBackground.opacity(0.5) : Color.clear)
        )
        .onHover { hovering in
            withAnimation(DesignSystem.Animation.microInteraction) {
                isHovered = hovering
            }
        }
        .contentShape(Rectangle())
        .contextMenu {
            Button {
                editedTitle = document.title
                showingEditTitle = true
            } label: {
                Label("Edit Title", systemImage: "pencil")
            }
            
            Divider()
            
            Button(role: .destructive) {
                showingDeleteConfirmation = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .alert("Edit Title", isPresented: $showingEditTitle) {
            TextField("Document Title", text: $editedTitle)
            Button("Cancel", role: .cancel) { }
            Button("Save") {
                saveTitle()
            }
            .disabled(editedTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        } message: {
            Text("Enter a new title for this document")
        }
        .alert("Delete Document", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteDocument()
            }
        } message: {
            Text("Are you sure you want to delete \"\(document.title)\"? This action cannot be undone.")
        }
    }
    
    private func saveTitle() {
        let trimmedTitle = editedTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }
        
        document.title = trimmedTitle
        
        do {
            try modelContext.save()
        } catch {
            ServiceContainer.shared.errorManager.handle(error, context: "document_title_update")
        }
    }
    
    private func deleteDocument() {
        // Delete the physical file first
        do {
            if FileManager.default.fileExists(atPath: document.filePath.path) {
                try FileManager.default.removeItem(at: document.filePath)
            }
        } catch {
            ServiceContainer.shared.errorManager.handle(error, context: "document_file_deletion")
        }
        
        // Delete from SwiftData
        modelContext.delete(document)
        
        do {
            try modelContext.save()
        } catch {
            ServiceContainer.shared.errorManager.handle(error, context: "document_model_deletion")
        }
    }
    
    private func relativeDateString(from date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        
        // Check if it's today
        if calendar.isDate(date, inSameDayAs: now) {
            return "Today"
        }
        
        // Check if it's yesterday
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: now),
           calendar.isDate(date, inSameDayAs: yesterday) {
            return "Yesterday"
        }
        
        // Check if it's in the same week
        if calendar.isDate(date, equalTo: now, toGranularity: .weekOfYear) {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            return formatter.string(from: date)
        }
        
        // Check if it's in the same year
        if calendar.isDate(date, equalTo: now, toGranularity: .year) {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: date)
        }
        
        // Different year
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
} 
