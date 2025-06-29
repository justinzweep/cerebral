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
                    Image(systemName: "doc.badge.plus")
                        .font(DesignSystem.Typography.callout)
                        .foregroundColor(DesignSystem.Colors.accent)
                }
                .buttonStyle(.plain)
                .frame(width: DesignSystem.ComponentSizes.largeIconFrame.width, height: DesignSystem.ComponentSizes.largeIconFrame.height)
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
                        // Use ForEach directly over documents for safety
                        ForEach(documents) { document in
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

                PDFHighlightToolbar(
                    highlightingState: $appState.highlightingState,
                    onModeChanged: { mode in
                        appState.setHighlightingMode(mode)
                    },
                    onColorChanged: { color in
                        appState.highlightingState.setColor(color)
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
            document.processingStatus = .pending
            modelContext.insert(document)
            
            try modelContext.save()
            
            // Select the newly imported document
            await MainActor.run {
                withAnimation(DesignSystem.Animation.smooth) {
                    selectedDocument = document
                }
            }
            
            // Process the PDF for vector search
            await processPDFForVectorSearch(document)
            
        } catch {
            ServiceContainer.shared.errorManager.handle(error, context: "document_import_single")
        }
    }
    
    private func processPDFForVectorSearch(_ document: Document) async {
        do {
            // Initialize services
            let pdfProcessingService = PDFProcessingService()
            let vectorSearchService = VectorSearchService(modelContext: modelContext)
            
            // Check if processing server is available
            let isServerHealthy = await pdfProcessingService.checkServerHealth()
            if !isServerHealthy {
                print("⚠️ Processing server not available at localhost:8000")
                print("💡 To enable vector search, start the processing server:")
                print("   cd path/to/your/python/server && python app.py")
                print("   Or check VECTOR_SEARCH_README.md for setup instructions")
                document.processingStatus = .failed
                try modelContext.save()
                return
            }
            
            // Set processing status
            document.processingStatus = .processing
            try modelContext.save()
            
            print("🔄 Starting PDF processing for '\(document.title)' - this may take several minutes...")
            
            // Process PDF to get chunks
            let response = try await pdfProcessingService.processPDF(document: document)
            
            // Store chunks in vector database
            try vectorSearchService.storeChunks(response.chunks, for: document)
            
            // Update document status
            document.processingStatus = .completed
            document.documentTitle = response.documentTitle
            try modelContext.save()
            
            print("✅ Successfully processed PDF for vector search: '\(document.title)'")
            
        } catch {
            // Update status to failed
            document.processingStatus = .failed
            try? modelContext.save()
            
            // Provide more specific error messages
            let errorMessage = if let processingError = error as? ProcessingError {
                switch processingError {
                case .networkError(let networkError):
                    if let urlError = networkError as? URLError {
                        switch urlError.code {
                        case .timedOut:
                            "Processing timed out - PDF may be too large or server is busy"
                        case .cannotConnectToHost:
                            "Cannot connect to processing server - make sure it's running on localhost:8000"
                        default:
                            "Network error: \(urlError.localizedDescription)"
                        }
                    } else {
                        "Network error: \(networkError.localizedDescription)"
                    }
                case .serverError:
                    "Server error - check processing server logs"
                case .invalidFilePath:
                    "Invalid file path"
                case .decodingError(let decodingError):
                    "Response parsing error: \(decodingError.localizedDescription)"
                case .invalidResponse:
                    "Invalid server response"
                }
            } else {
                error.localizedDescription
            }
            
            print("❌ Failed to process PDF for vector search: '\(document.title)' - \(errorMessage)")
            ServiceContainer.shared.errorManager.handle(error, context: "pdf_processing")
        }
    }
}

#Preview {
    DocumentSidebarPane(
        selectedDocument: .constant(nil),
        showingImporter: .constant(false)
    )
    .modelContainer(for: [Document.self], inMemory: true)
            .frame(width: DesignSystem.ComponentSizes.panelMaxWidth, height: DesignSystem.ComponentSizes.demoWindowHeight)
} 
