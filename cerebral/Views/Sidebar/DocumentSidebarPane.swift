//
//  DocumentSidebarPane.swift
//  cerebral
//
//  Created by Justin Zweep on 26/06/2025.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct DocumentSidebarPane: View {
    @Binding var selectedDocument: Document?
    @Binding var showingImporter: Bool
    @Environment(\.modelContext) private var modelContext
    @State private var appState = ServiceContainer.shared.appState
    
    // Optimized query with limit for better performance
    @Query(
        sort: \Document.dateAdded, 
        order: .reverse
    ) private var documents: [Document]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with add button
            HStack {
                Text("Documents")
                    .font(DesignSystem.Typography.title3)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                
                Spacer()
                
                Button {
                    showingImporter = true
                } label: {
                    Image(systemName: "plus")
                        .font(DesignSystem.Typography.callout)
                        .foregroundColor(DesignSystem.Colors.accent)
                }
                .buttonStyle(.plain)
                .frame(width: 32, height: 32)
                .contentShape(Rectangle())
            }
            .padding(DesignSystem.Spacing.md)
            
            // Document list with performance optimizations
            ScrollView {
                LazyVStack(spacing: DesignSystem.Spacing.xs) {
                    if documents.isEmpty {
                        EmptyDocumentsView(showingImporter: $showingImporter)
                            .id("empty-documents") // Stable ID
                    } else {
                        // Use optimized ForEach with proper identifiers
                        ForEach(documents.indices, id: \.self) { index in
                            let document = documents[index]
                            
                            DocumentRowView(document: document)
                                .onTapGesture {
                                    withAnimation(DesignSystem.Animation.smooth) {
                                        selectedDocument = document
                                    }
                                }
                                .background(
                                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                                        .fill(selectedDocument?.id == document.id ? 
                                              DesignSystem.Colors.selectedBackground : 
                                              Color.clear)
                                )
                                .animation(DesignSystem.Animation.microInteraction, value: selectedDocument?.id)
                                .id(document.id) // Stable ID based on document
                        }
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.md)
                .padding(.bottom, DesignSystem.Spacing.lg)
            }
            .scrollIndicators(.never)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Simple highlighting toolbar always at the bottom
            VStack(spacing: 0) {
                Divider()
                    .foregroundColor(DesignSystem.Colors.border.opacity(0.3))
                
                PDFHighlightToolbar(
                    highlightingState: $appState.highlightingState,
                    onModeChanged: { mode in
                        appState.setHighlightingMode(mode)
                    },
                    onColorChanged: { color in
                        appState.setHighlightingColor(color)
                    }
                )
                .padding(DesignSystem.Spacing.md)
            }
        }
        .fileImporter(
            isPresented: $showingImporter,
            allowedContentTypes: [.pdf],
            allowsMultipleSelection: true
        ) { result in
            Task { @MainActor in
                await handleDocumentImport(result)
            }
        }
    }
    
    // MARK: - Document Import
    
    private func handleDocumentImport(_ result: Result<[URL], Error>) async {
        switch result {
        case .success(let urls):
            for url in urls {
                await importDocument(from: url)
            }
        case .failure(let error):
            ServiceContainer.shared.errorManager.handle(error, context: "document_import_bulk")
        }
    }
    
    private func importDocument(from url: URL) async {
        guard url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }
        
        // Create documents directory if it doesn't exist
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let cerebralDocsPath = documentsPath.appendingPathComponent("Cerebral Documents")
        try? FileManager.default.createDirectory(at: cerebralDocsPath, withIntermediateDirectories: true)
        
        // Copy file to app's documents directory
        let fileName = url.lastPathComponent
        let destinationURL = cerebralDocsPath.appendingPathComponent(fileName)
        
        // Handle duplicates by appending a number
        var finalURL = destinationURL
        var counter = 1
        while FileManager.default.fileExists(atPath: finalURL.path) {
            let nameWithoutExt = (fileName as NSString).deletingPathExtension
            let ext = (fileName as NSString).pathExtension
            finalURL = cerebralDocsPath.appendingPathComponent("\(nameWithoutExt) \(counter).\(ext)")
            counter += 1
        }
        
        do {
            try FileManager.default.copyItem(at: url, to: finalURL)
            
            // Create document model
            let title = finalURL.deletingPathExtension().lastPathComponent
            let document = Document(title: title, filePath: finalURL)
            modelContext.insert(document)
            
            try modelContext.save()
            
            // Select the newly imported document
            await MainActor.run {
                withAnimation(DesignSystem.Animation.smooth) {
                    selectedDocument = document
                }
            }
        } catch {
            ServiceContainer.shared.errorManager.handle(error, context: "document_import_single")
        }
    }
}

#Preview {
    DocumentSidebarPane(
        selectedDocument: .constant(nil),
        showingImporter: .constant(false)
    )
    .modelContainer(for: [Document.self], inMemory: true)
    .frame(width: 280, height: 600)
} 