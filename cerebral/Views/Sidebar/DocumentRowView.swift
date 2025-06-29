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
                
                // Processing status indicator
                if document.processingStatus != .completed {
                    HStack(spacing: DesignSystem.Spacing.xxs) {
                        processingStatusIcon
                        Text(processingStatusText)
                            .font(DesignSystem.Typography.caption2)
                            .foregroundColor(processingStatusColor)
                    }
                }
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
            
            // Retry processing if failed
            if document.processingStatus == .failed {
                Button {
                    retryProcessing()
                } label: {
                    Label("Retry Processing", systemImage: "arrow.clockwise")
                }
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
        do {
            // Use the proper DocumentService to handle complete deletion including vector chunks
            try DocumentService.shared.deleteDocument(document, from: modelContext)
        } catch {
            ServiceContainer.shared.errorManager.handle(error, context: "document_deletion")
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
    
    // MARK: - Processing Status UI
    
    private var processingStatusIcon: some View {
        Group {
            switch document.processingStatus {
            case .pending:
                Image(systemName: "clock")
            case .processing:
                Image(systemName: "gear")
                    .rotationEffect(.degrees(document.processingStatus == .processing ? 360 : 0))
                    .animation(
                        document.processingStatus == .processing ? 
                        Animation.linear(duration: 2).repeatForever(autoreverses: false) : 
                        .default,
                        value: document.processingStatus
                    )
            case .failed:
                Image(systemName: "exclamationmark.triangle")
            case .completed:
                EmptyView()
            }
        }
        .font(DesignSystem.Typography.caption2)
        .foregroundColor(processingStatusColor)
    }
    
    private var processingStatusText: String {
        switch document.processingStatus {
        case .pending:
            return "Queued for processing"
        case .processing:
            return "Processing for search..."
        case .failed:
            return "Processing failed"
        case .completed:
            return ""
        }
    }
    
    private var processingStatusColor: Color {
        switch document.processingStatus {
        case .pending:
            return DesignSystem.Colors.tertiaryText
        case .processing:
            return DesignSystem.Colors.accent
        case .failed:
            return .red
        case .completed:
            return DesignSystem.Colors.secondaryText
        }
    }
    
    private func retryProcessing() {
        Task {
            await processPDFForVectorSearch(document)
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
