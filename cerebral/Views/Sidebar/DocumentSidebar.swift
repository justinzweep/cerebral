//
//  DocumentSidebar.swift
//  cerebral
//
//  Created by Justin Zweep on 26/06/2025.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

// Legacy wrapper - keeping for compatibility
struct DocumentSidebar: View {
    @Binding var selectedDocument: Document?
    
    var body: some View {
        DocumentSidebarContent(selectedDocument: $selectedDocument)
    }
}

struct DocumentSidebarContent: View {
    @Binding var selectedDocument: Document?
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Document.dateAdded, order: .reverse) private var documents: [Document]
    
    @State private var showingImporter = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Clean header
            HStack {
                Text("Documents")
                    .font(DesignSystem.Typography.title3)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                
                Spacer()
                
                Button {
                    showingImporter = true
                } label: {
                    Image(systemName: "doc.badge.plus")
                        .font(DesignSystem.Typography.callout)
                        .foregroundColor(DesignSystem.Colors.accent)
                }
                .buttonStyle(.plain)
                .frame(width: 32, height: 32)
                .contentShape(Rectangle())
            }
            .padding(DesignSystem.Spacing.md)
            
            // Document list
            ScrollView {
                LazyVStack(spacing: DesignSystem.Spacing.xs) {
                    if documents.isEmpty {
                        EmptyDocumentListView(showingImporter: $showingImporter)
                    } else {
                        ForEach(documents) { document in
                            DocumentRowView(document: document)
                                .onTapGesture {
                                    selectedDocument = document
                                }
                                .background(
                                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                                        .fill(selectedDocument?.id == document.id ? 
                                              DesignSystem.Colors.selectedBackground : 
                                              Color.clear)
                                )
                                .animation(DesignSystem.Animation.microInteraction, value: selectedDocument?.id)
                        }
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.md)
                .padding(.bottom, DesignSystem.Spacing.lg)
            }
            .scrollIndicators(.never)
        }
        .onChange(of: documents) {
            // Clear selection if the selected document no longer exists
            if let currentSelection = selectedDocument,
               !documents.contains(where: { $0.id == currentSelection.id }) {
                selectedDocument = nil
            }
        }
        .fileImporter(
            isPresented: $showingImporter,
            allowedContentTypes: [UTType.pdf],
            allowsMultipleSelection: true
        ) { result in
            importDocuments(result)
        }
    }
    
    private func importDocuments(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            for url in urls {
                importDocument(from: url)
            }
        case .failure(let error):
            ServiceContainer.shared.errorManager.handle(error, context: "document_import_bulk")
        }
    }
    
    private func importDocument(from url: URL) {
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
        } catch {
            ServiceContainer.shared.errorManager.handle(error, context: "document_import_single")
        }
    }
}

// MARK: - Supporting Views

struct EmptyDocumentListView: View {
    @Binding var showingImporter: Bool
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            // Image(systemName: "doc.text")
            //     .font(DesignSystem.Typography.largeTitle)
            //     .foregroundColor(DesignSystem.Colors.tertiaryText)
            
            // VStack(spacing: DesignSystem.Spacing.sm) {
            //     Text("No Documents")
            //         .font(DesignSystem.Typography.headline)
            //         .foregroundColor(DesignSystem.Colors.primaryText)
                
            //     Text("Import your first PDF to get started")
            //         .font(DesignSystem.Typography.body)
            //         .foregroundColor(DesignSystem.Colors.secondaryText)
            //         .multilineTextAlignment(.center)
            // }
            
            // Button("Import PDF") {
            //     showingImporter = true
            // }
            // .buttonStyle(PrimaryButtonStyle())
        }
        .padding(DesignSystem.Spacing.xl)
        .frame(maxWidth: .infinity)
    }
}



#Preview {
    DocumentSidebar(selectedDocument: .constant(nil))
        .modelContainer(for: [Document.self], inMemory: true)
}
