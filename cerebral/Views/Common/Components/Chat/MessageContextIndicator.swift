//
//  MessageContextIndicator.swift
//  cerebral
//
//  Created on 26/06/2025.
//

import SwiftUI

struct MessageContextIndicator: View {
    let contexts: [DocumentContext]
    @State private var isExpanded = false
    private let settingsManager = SettingsManager.shared
    
    var body: some View {
        if !contexts.isEmpty && settingsManager.showContextIndicators {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                // Clean summary header like @ mentions
                Button(action: toggleExpansion) {
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        // Context icon
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(DesignSystem.Colors.accent)
                        
                        // Context summary
                        Text(contextSummary)
                            .appleTextStyle(.caption2)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                        
                        Spacer()
                        
                        // Simple chevron
                        Image(systemName: "chevron.down")
                            .font(.system(size: 8, weight: .medium))
                            .foregroundColor(DesignSystem.Colors.tertiaryText)
                            .rotationEffect(.degrees(isExpanded ? 180 : 0))
                    }
                    .padding(.horizontal, DesignSystem.Spacing.sm)
                    .padding(.vertical, DesignSystem.Spacing.xs)
                }
                .buttonStyle(.plain)
                .background(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                        .fill(DesignSystem.Colors.tertiaryBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                                .strokeBorder(DesignSystem.Colors.borderSecondary, lineWidth: 0.5)
                        )
                )
                
                // Expanded details - simple fade in/out
                if isExpanded {
                    LazyVStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                        ForEach(contexts) { context in
                            ContextRow(context: context)
                        }
                    }
                    .padding(.top, DesignSystem.Spacing.xs)
                }
            }
        }
    }
    
    private func toggleExpansion() {
        withAnimation(DesignSystem.Animation.quick) {
            isExpanded.toggle()
        }
    }
    
    private var contextSummary: String {
        let docCount = Set(contexts.map { $0.documentId }).count
        let tokenCount = contexts.reduce(0) { $0 + $1.metadata.tokenCount }
        let formattedTokenCount = formatTokenCount(tokenCount)
        
        let docText = docCount == 1 ? "document" : "documents"
        return "\(docCount) \(docText) • \(formattedTokenCount) tokens"
    }
    
    private func formatTokenCount(_ count: Int) -> String {
        if count >= 1000000 {
            return String(format: "%.1fM", Double(count) / 1000000.0)
        } else if count >= 1000 {
            return String(format: "%.1fK", Double(count) / 1000.0)
        } else {
            return "\(count)"
        }
    }
}

struct ContextRow: View {
    let context: DocumentContext
    @State private var isHovered = false
    
    var body: some View {
        Button(action: openDocument) {
            HStack(spacing: DesignSystem.Spacing.sm) {
                // Context type dot
                Circle()
                    .fill(contextColor)
                    .frame(width: 6, height: 6)
                
                VStack(alignment: .leading, spacing: 2) {
                    // Document name and type
                    HStack(spacing: DesignSystem.Spacing.xs) {
                        Text(context.documentTitle)
                            .appleTextStyle(.caption2)
                            .foregroundColor(DesignSystem.Colors.primaryText)
                            .fontWeight(.medium)
                            .lineLimit(1)
                        
                        Text("•")
                            .appleTextStyle(.caption2)
                            .foregroundColor(DesignSystem.Colors.tertiaryText)
                        
                        Text(contextTypeName)
                            .appleTextStyle(.caption2)
                            .foregroundColor(DesignSystem.Colors.tertiaryText)
                        
                        if let pageNumbers = context.metadata.pageNumbers, !pageNumbers.isEmpty {
                            Text("•")
                                .appleTextStyle(.caption2)
                                .foregroundColor(DesignSystem.Colors.tertiaryText)
                            
                            Text(pageDescription(pageNumbers))
                                .appleTextStyle(.caption2)
                                .foregroundColor(DesignSystem.Colors.tertiaryText)
                        }
                        
                        Spacer()
                        
                        // Token count
                        Text("\(context.metadata.tokenCount)")
                            .appleTextStyle(.caption2)
                            .foregroundColor(DesignSystem.Colors.tertiaryText)
                            .padding(.horizontal, DesignSystem.Spacing.xs)
                            .padding(.vertical, 1)
                            .background(
                                Capsule()
                                    .fill(DesignSystem.Colors.tertiaryBackground)
                            )
                    }
                    
                    // Text preview for selections
                    if context.contextType == .textSelection && !context.content.isEmpty {
                        Text("\"\(context.content.prefix(80))...\"")
                            .appleTextStyle(.caption2)
                            .foregroundColor(DesignSystem.Colors.tertiaryText)
                            .italic()
                            .lineLimit(2)
                    }
                }
                
                Spacer()
            }
        }
        .buttonStyle(.plain)
        .padding(.horizontal, DesignSystem.Spacing.sm)
        .padding(.vertical, DesignSystem.Spacing.xs)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xs)
                .fill(isHovered ? DesignSystem.Colors.hoverBackground : Color.clear)
        )
        .onHover { hovering in
            withAnimation(DesignSystem.Animation.micro) {
                isHovered = hovering
            }
        }
        .help("Open \(context.documentTitle)")
    }
    
    private func openDocument() {
        guard let document = ServiceContainer.shared.documentService.findDocument(byId: context.documentId) else {
            return
        }
        
        ServiceContainer.shared.appState.selectDocument(document)
        
        // Navigate to context location
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            if let pageNumbers = context.metadata.pageNumbers, let firstPage = pageNumbers.first {
                ServiceContainer.shared.appState.navigateToPDFPage(firstPage)
                
                if context.contextType == .textSelection,
                   let selectionBounds = context.metadata.selectionBounds,
                   !selectionBounds.isEmpty {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        ServiceContainer.shared.appState.navigateToSelectionBounds(
                            bounds: selectionBounds,
                            onPage: firstPage
                        )
                    }
                }
            }
        }
    }
    
    private var contextColor: Color {
        switch context.contextType {
        case .fullDocument: return DesignSystem.Colors.tertiaryText // Grayed out for deprecated
        case .pageRange: return DesignSystem.Colors.secondaryAccent
        case .textSelection: return DesignSystem.Colors.success
        case .semanticChunk: return DesignSystem.Colors.warning
        }
    }
    
    private var contextTypeName: String {
        switch context.contextType {
        case .fullDocument: return "Full document (deprecated)"
        case .pageRange: return "Page range"
        case .textSelection: return "Text selection"
        case .semanticChunk: return "Section"
        }
    }
    
    private func pageDescription(_ pages: [Int]) -> String {
        if pages.count == 1 {
            return "Page \(pages[0])"
        } else if pages.count <= 3 {
            return "Pages \(pages.map(String.init).joined(separator: ", "))"
        } else {
            return "Pages \(pages.first!)-\(pages.last!)"
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        // Single document context
        MessageContextIndicator(contexts: [
            DocumentContext(
                documentId: UUID(),
                documentTitle: "Machine Learning Research.pdf",
                contextType: .fullDocument,
                content: "Sample content from the document about machine learning algorithms...",
                metadata: ContextMetadata(
                    pageNumbers: [1, 2, 3],
                    selectionBounds: [],
                    characterRange: nil,
                    extractionMethod: "full",
                    tokenCount: 1500,
                    checksum: "abc123"
                )
            )
        ])
        
        // Multiple documents context
        MessageContextIndicator(contexts: [
            DocumentContext(
                documentId: UUID(),
                documentTitle: "Neural Networks.pdf",
                contextType: .textSelection,
                content: "Selected text from neural networks document discussing backpropagation algorithms",
                metadata: ContextMetadata(
                    pageNumbers: [5],
                    selectionBounds: [],
                    characterRange: NSRange(location: 100, length: 50),
                    extractionMethod: "user_selection",
                    tokenCount: 250,
                    checksum: "def456"
                )
            ),
            DocumentContext(
                documentId: UUID(),
                documentTitle: "Conference Proceedings.pdf",
                contextType: .pageRange,
                content: "Content from pages covering recent advances",
                metadata: ContextMetadata(
                    pageNumbers: [2, 3, 4],
                    selectionBounds: [],
                    characterRange: nil,
                    extractionMethod: "page_range",
                    tokenCount: 800,
                    checksum: "ghi789"
                )
            )
        ])
        
        Spacer()
    }
    .padding()
    .frame(width: 500)
    .background(DesignSystem.Colors.background)
}

// MARK: - Unified Context Indicator

struct UnifiedContextIndicator: View {
    let contexts: [DocumentContext]
    let chunkIds: [UUID]
    @State private var chunks: [DocumentChunk] = []
    @State private var selectedChunkId: String? = nil // Track which chunk is currently selected/showing bounding boxes
    private let settingsManager = SettingsManager.shared
    
    var body: some View {
        Group {
            if hasAnyContext && settingsManager.showContextIndicators {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    // Minimal header
                    HStack(spacing: DesignSystem.Spacing.xs) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(DesignSystem.Colors.tertiaryText)
                        
                        Text(contextSummary)
                            .appleTextStyle(.caption2)
                            .foregroundColor(DesignSystem.Colors.tertiaryText)
                            .fontWeight(.medium)
                    }
                    
                    // Unified horizontal scroll view
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: DesignSystem.Spacing.xs) {
                            // Text selections first
                            ForEach(contexts, id: \.id) { context in
                                ContextCapsule(
                                    context: context,
                                    onTap: { handleContextTap(context) }
                                )
                            }
                            
                            // Then chunks
                            ForEach(chunks, id: \.id) { chunk in
                                ChunkCapsule(
                                    chunk: chunk,
                                    isSelected: selectedChunkId == chunk.chunkId,
                                    onTap: { handleChunkTap(chunk) }
                                )
                            }
                        }
                        .padding(.horizontal, DesignSystem.Spacing.sm)
                        .padding(.vertical, DesignSystem.Spacing.xs)
                    }
                    .frame(height: 48) // Compact height for minimal capsules
                }
            }
        }
        .onAppear {
            resolveChunks()
        }
        .onChange(of: chunkIds) { _, _ in
            resolveChunks()
        }
    }
    
    // MARK: - Computed Properties
    
    private var hasAnyContext: Bool {
        return !contexts.isEmpty || !chunkIds.isEmpty
    }
    
    private var contextSummary: String {
        let contextCount = contexts.count
        let chunkCount = chunks.count
        let totalCount = contextCount + chunkCount
        
        if totalCount == 0 { return "No context" }
        if totalCount == 1 { return "1 reference" }
        
        return "\(totalCount) references"
    }
    
    // MARK: - Methods
    
    private func resolveChunks() {
        print("🔍 UnifiedContextIndicator: Starting to resolve \(chunkIds.count) chunk IDs")
        
        Task {
            var resolvedChunks: [DocumentChunk] = []
            
            // Get vector search service from context management service
            if let vectorService = ServiceContainer.shared.contextService.currentVectorSearchService {
                print("✅ UnifiedContextIndicator: Vector service available")
                do {
                    // Use batch method for efficiency
                    resolvedChunks = try vectorService.getChunks(byIds: chunkIds)
                    print("✅ UnifiedContextIndicator: Successfully resolved \(resolvedChunks.count) chunks")
                } catch {
                    print("❌ UnifiedContextIndicator: Failed to resolve chunks: \(error)")
                }
            } else {
                print("❌ UnifiedContextIndicator: No vector service available")
            }
            
            await MainActor.run {
                print("🔄 UnifiedContextIndicator: Setting chunks array to \(resolvedChunks.count) items")
                self.chunks = resolvedChunks
            }
        }
    }
    
    private func handleContextTap(_ context: DocumentContext) {
        guard let document = ServiceContainer.shared.documentService.findDocument(byId: context.documentId) else {
            return
        }
        
        print("📝 Context tapped: \(context.contextType) in document: \(context.documentTitle)")
        
        // Select the document
        ServiceContainer.shared.appState.selectDocument(document)
        
        // Navigate to context location
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            if let pageNumbers = context.metadata.pageNumbers, let firstPage = pageNumbers.first {
                ServiceContainer.shared.appState.navigateToPDFPage(firstPage)
                
                if context.contextType == .textSelection,
                   let selectionBounds = context.metadata.selectionBounds,
                   !selectionBounds.isEmpty {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        ServiceContainer.shared.appState.navigateToSelectionBounds(
                            bounds: selectionBounds,
                            onPage: firstPage
                        )
                    }
                }
            }
        }
    }
    
    private func handleChunkTap(_ chunk: DocumentChunk) {
        guard let document = chunk.document else { return }
        
        print("📦 Chunk tapped: \(chunk.chunkId) in document: \(document.title ?? "Untitled")")
        
        // If this chunk is already selected, deselect it and clear bounding boxes
        if selectedChunkId == chunk.chunkId {
            selectedChunkId = nil
            NotificationCenter.default.post(
                name: NSNotification.Name("ClearChunkBoundingBoxes"),
                object: nil
            )
            print("🧹 Cleared bounding boxes for deselected chunk")
            return
        }
        
        // Select this chunk and show its bounding boxes
        selectedChunkId = chunk.chunkId
        
        // Select the document first
        ServiceContainer.shared.appState.selectDocument(document)
        
        // Navigate to chunk location and show bounding boxes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            if let primaryPage = chunk.primaryPageNumber {
                // Navigate to the page
                ServiceContainer.shared.appState.navigateToPDFPage(primaryPage)
                
                // Show bounding boxes for this specific chunk only
                NotificationCenter.default.post(
                    name: NSNotification.Name("ShowChunkBoundingBoxes"),
                    object: nil,
                    userInfo: ["chunks": [chunk]]
                )
                
                print("📍 Navigated to page \(primaryPage) and showing bounding boxes for selected chunk")
            }
        }
    }
}

// MARK: - Context Capsule (for text selections)

struct ContextCapsule: View {
    let context: DocumentContext
    let onTap: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: DesignSystem.Spacing.xs) {
                // Context type indicator dot
                Circle()
                    .fill(contextColor)
                    .frame(width: 6, height: 6)
                
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxxs) {
                    // Document name (truncated)
                    Text(documentDisplayName)
                        .appleTextStyle(.caption2)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                        .fontWeight(.regular)
                        .lineLimit(1)
                    
                    // Page number or context type
                    Text(contextDescription)
                        .appleTextStyle(.caption2)
                        .foregroundColor(DesignSystem.Colors.tertiaryText)
                }
                
                Spacer(minLength: 0)
            }
            .padding(.horizontal, DesignSystem.Spacing.sm)
            .padding(.vertical, DesignSystem.Spacing.xs)
        }
        .buttonStyle(.plain)
        .frame(height: 32) // Same height as chunk capsules
        .frame(minWidth: 80, maxWidth: 120) // Same constraints as chunk capsules
        .background(
            Capsule()
                .fill(backgroundColor)
                .overlay(
                    Capsule()
                        .strokeBorder(borderColor, lineWidth: 0.5)
                )
        )
        .scaleEffect(isHovered ? DesignSystem.Scale.hover : 1.0)
        .animation(DesignSystem.Animation.micro, value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
        .help(helpText)
    }
    
    // MARK: - Computed Properties
    
    private var documentDisplayName: String {
        let title = context.documentTitle
        
        // Remove common file extensions and truncate
        let cleanTitle = title
            .replacingOccurrences(of: ".pdf", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: ".PDF", with: "")
        
        // Truncate long names intelligently
        if cleanTitle.count > 12 {
            return String(cleanTitle.prefix(12)) + "…"
        }
        return cleanTitle
    }
    
    private var contextDescription: String {
        if let pageNumbers = context.metadata.pageNumbers, !pageNumbers.isEmpty {
            if pageNumbers.count == 1 {
                return "Page \(pageNumbers[0])"
            } else {
                return "Pages \(pageNumbers.first!)-\(pageNumbers.last!)"
            }
        } else {
            return contextTypeName
        }
    }
    
    private var contextTypeName: String {
        switch context.contextType {
        case .fullDocument: return "Full doc"
        case .pageRange: return "Pages"
        case .textSelection: return "Selection"
        case .semanticChunk: return "Section"
        }
    }
    
    private var contextColor: Color {
        switch context.contextType {
        case .fullDocument: return DesignSystem.Colors.tertiaryText
        case .pageRange: return DesignSystem.Colors.secondaryAccent
        case .textSelection: return DesignSystem.Colors.success
        case .semanticChunk: return DesignSystem.Colors.warning
        }
    }
    
    private var backgroundColor: Color {
        if isHovered {
            return DesignSystem.Colors.hoverBackground
        } else {
            return DesignSystem.Colors.tertiaryBackground
        }
    }
    
    private var borderColor: Color {
        if isHovered {
            return DesignSystem.Colors.borderSecondary.opacity(0.8)
        } else {
            return DesignSystem.Colors.borderSecondary.opacity(0.3)
        }
    }
    
    private var helpText: String {
        return "Tap to navigate to \(contextTypeName.lowercased()) in \(context.documentTitle)"
    }
}

// MARK: - Chunk Capsule (for vector search results)

struct ChunkCapsule: View {
    let chunk: DocumentChunk
    let isSelected: Bool
    let onTap: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: DesignSystem.Spacing.xs) {
                // Chunk indicator dot
                Circle()
                    .fill(dotColor)
                    .frame(width: 6, height: 6)
                
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxxs) {
                    // Document name (truncated)
                    Text(documentDisplayName)
                        .appleTextStyle(.caption2)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                        .fontWeight(isSelected ? .medium : .regular)
                        .lineLimit(1)
                    
                    // Page number
                    if let primaryPage = chunk.primaryPageNumber {
                        Text("Page \(primaryPage)")
                            .appleTextStyle(.caption2)
                            .foregroundColor(DesignSystem.Colors.tertiaryText)
                    }
                }
                
                Spacer(minLength: 0)
            }
            .padding(.horizontal, DesignSystem.Spacing.sm)
            .padding(.vertical, DesignSystem.Spacing.xs)
        }
        .buttonStyle(.plain)
        .frame(height: 32) // Compact height
        .frame(minWidth: 80, maxWidth: 120) // Flexible but constrained width
        .background(
            Capsule()
                .fill(backgroundColor)
                .overlay(
                    Capsule()
                        .strokeBorder(borderColor, lineWidth: isSelected ? 1.0 : 0.5)
                )
        )
        .scaleEffect(isHovered ? DesignSystem.Scale.hover : 1.0)
        .animation(DesignSystem.Animation.micro, value: isHovered)
        .animation(DesignSystem.Animation.micro, value: isSelected)
        .onHover { hovering in
            isHovered = hovering
        }
        .help(helpText)
    }
    
    // MARK: - Computed Properties
    
    private var documentDisplayName: String {
        guard let title = chunk.document?.title else { return "Unknown" }
        
        // Remove common file extensions and truncate
        let cleanTitle = title
            .replacingOccurrences(of: ".pdf", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: ".PDF", with: "")
        
        // Truncate long names intelligently
        if cleanTitle.count > 12 {
            return String(cleanTitle.prefix(12)) + "…"
        }
        return cleanTitle
    }
    
    private var dotColor: Color {
        if isSelected {
            return DesignSystem.Colors.accent
        } else {
            return DesignSystem.Colors.tertiaryText
        }
    }
    
    private var backgroundColor: Color {
        if isSelected {
            return DesignSystem.Colors.accentSecondary
        } else if isHovered {
            return DesignSystem.Colors.hoverBackground
        } else {
            return DesignSystem.Colors.tertiaryBackground
        }
    }
    
    private var borderColor: Color {
        if isSelected {
            return DesignSystem.Colors.accent
        } else if isHovered {
            return DesignSystem.Colors.borderSecondary.opacity(0.8)
        } else {
            return DesignSystem.Colors.borderSecondary.opacity(0.3)
        }
    }
    
    private var helpText: String {
        if isSelected {
            return "Tap to hide bounding boxes"
        } else {
            return "Tap to show bounding boxes for \(chunk.document?.title ?? "document")"
        }
    }
}

// MARK: - Legacy Chunk Context Indicator (for backward compatibility)

struct ChunkContextIndicator: View {
    let chunkIds: [UUID]
    @State private var chunks: [DocumentChunk] = []
    @State private var selectedChunkId: String? = nil // Track which chunk is currently selected/showing bounding boxes
    private let settingsManager = SettingsManager.shared
    
    var body: some View {
        Group {
            if !chunks.isEmpty && settingsManager.showContextIndicators {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    // Minimal header
                    HStack(spacing: DesignSystem.Spacing.xs) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(DesignSystem.Colors.tertiaryText)
                        
                        Text(chunkSummary)
                            .appleTextStyle(.caption2)
                            .foregroundColor(DesignSystem.Colors.tertiaryText)
                            .fontWeight(.medium)
                    }
                    
                    // Horizontal scroll view of chunks
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: DesignSystem.Spacing.xs) {
                            ForEach(chunks, id: \.id) { chunk in
                                ChunkCard(
                                    chunk: chunk,
                                    isSelected: selectedChunkId == chunk.chunkId,
                                    onTap: { handleChunkTap(chunk) }
                                )
                            }
                        }
                        .padding(.horizontal, DesignSystem.Spacing.sm)
                        .padding(.vertical, DesignSystem.Spacing.xs)
                    }
                    .frame(height: 48) // Compact height for minimal cards
                }
            }
        }
        .onAppear {
            resolveChunks()
        }
        .onChange(of: chunkIds) { _, _ in
            resolveChunks()
        }
    }
    
    private func resolveChunks() {
        print("🔍 ChunkContextIndicator: Starting to resolve \(chunkIds.count) chunk IDs")
        
        Task {
            var resolvedChunks: [DocumentChunk] = []
            
            // Get vector search service from context management service
            if let vectorService = ServiceContainer.shared.contextService.currentVectorSearchService {
                print("✅ ChunkContextIndicator: Vector service available")
                do {
                    // Use batch method for efficiency
                    resolvedChunks = try vectorService.getChunks(byIds: chunkIds)
                    print("✅ ChunkContextIndicator: Successfully resolved \(resolvedChunks.count) chunks")
                } catch {
                    print("❌ ChunkContextIndicator: Failed to resolve chunks: \(error)")
                }
            } else {
                print("❌ ChunkContextIndicator: No vector service available")
            }
            
            await MainActor.run {
                print("🔄 ChunkContextIndicator: Setting chunks array to \(resolvedChunks.count) items")
                self.chunks = resolvedChunks
            }
        }
    }
    
    private func handleChunkTap(_ chunk: DocumentChunk) {
        guard let document = chunk.document else { return }
        
        print("📦 Chunk tapped: \(chunk.chunkId) in document: \(document.title ?? "Untitled")")
        
        // If this chunk is already selected, deselect it and clear bounding boxes
        if selectedChunkId == chunk.chunkId {
            selectedChunkId = nil
            NotificationCenter.default.post(
                name: NSNotification.Name("ClearChunkBoundingBoxes"),
                object: nil
            )
            print("🧹 Cleared bounding boxes for deselected chunk")
            return
        }
        
        // Select this chunk and show its bounding boxes
        selectedChunkId = chunk.chunkId
        
        // Select the document first
        ServiceContainer.shared.appState.selectDocument(document)
        
        // Navigate to chunk location and show bounding boxes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            if let primaryPage = chunk.primaryPageNumber {
                // Navigate to the page
                ServiceContainer.shared.appState.navigateToPDFPage(primaryPage)
                
                // Show bounding boxes for this specific chunk only
                NotificationCenter.default.post(
                    name: NSNotification.Name("ShowChunkBoundingBoxes"),
                    object: nil,
                    userInfo: ["chunks": [chunk]]
                )
                
                print("📍 Navigated to page \(primaryPage) and showing bounding boxes for selected chunk")
            }
        }
    }
    
    private var chunkSummary: String {
        let docCount = Set(chunks.compactMap { $0.document?.id }).count
        let chunkCount = chunks.count
        
        let docText = docCount == 1 ? "document" : "documents"
        let chunkText = chunkCount == 1 ? "chunk" : "chunks"
        return "\(chunkCount) \(chunkText) from \(docCount) \(docText)"
    }
}

struct ChunkCard: View {
    let chunk: DocumentChunk
    let isSelected: Bool
    let onTap: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: DesignSystem.Spacing.xs) {
                // Minimal indicator dot
                Circle()
                    .fill(dotColor)
                    .frame(width: 6, height: 6)
                
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxxs) {
                    // Document name (truncated)
                    Text(documentDisplayName)
                        .appleTextStyle(.caption2)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                        .fontWeight(isSelected ? .medium : .regular)
                        .lineLimit(1)
                    
                    // Page number
                    if let primaryPage = chunk.primaryPageNumber {
                        Text("Page \(primaryPage)")
                            .appleTextStyle(.caption2)
                            .foregroundColor(DesignSystem.Colors.tertiaryText)
                    }
                }
                
                Spacer(minLength: 0)
            }
            .padding(.horizontal, DesignSystem.Spacing.sm)
            .padding(.vertical, DesignSystem.Spacing.xs)
        }
        .buttonStyle(.plain)
        .frame(height: 32) // Compact height
        .frame(minWidth: 80, maxWidth: 120) // Flexible but constrained width
        .background(
            Capsule()
                .fill(backgroundColor)
                .overlay(
                    Capsule()
                        .strokeBorder(borderColor, lineWidth: isSelected ? 1.0 : 0.5)
                )
        )
        .scaleEffect(isHovered ? DesignSystem.Scale.hover : 1.0)
        .animation(DesignSystem.Animation.micro, value: isHovered)
        .animation(DesignSystem.Animation.micro, value: isSelected)
        .onHover { hovering in
            isHovered = hovering
        }
        .help(helpText)
    }
    
    // MARK: - Computed Properties
    
    private var documentDisplayName: String {
        guard let title = chunk.document?.title else { return "Unknown" }
        
        // Remove common file extensions and truncate
        let cleanTitle = title
            .replacingOccurrences(of: ".pdf", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: ".PDF", with: "")
        
        // Truncate long names intelligently
        if cleanTitle.count > 12 {
            return String(cleanTitle.prefix(12)) + "…"
        }
        return cleanTitle
    }
    
    private var dotColor: Color {
        if isSelected {
            return DesignSystem.Colors.accent
        } else {
            return DesignSystem.Colors.tertiaryText
        }
    }
    
    private var backgroundColor: Color {
        if isSelected {
            return DesignSystem.Colors.accentSecondary
        } else if isHovered {
            return DesignSystem.Colors.hoverBackground
        } else {
            return DesignSystem.Colors.tertiaryBackground
        }
    }
    
    private var borderColor: Color {
        if isSelected {
            return DesignSystem.Colors.accent
        } else if isHovered {
            return DesignSystem.Colors.borderSecondary.opacity(0.8)
        } else {
            return DesignSystem.Colors.borderSecondary.opacity(0.3)
        }
    }
    
    private var helpText: String {
        if isSelected {
            return "Tap to hide bounding boxes"
        } else {
            return "Tap to show bounding boxes for \(chunk.document?.title ?? "document")"
        }
    }
}

// MARK: - Legacy ChunkRow (keeping for compatibility if needed elsewhere)

struct ChunkRow: View {
    let chunk: DocumentChunk
    @State private var isHovered = false
    
    var body: some View {
        Button(action: openChunk) {
            HStack(spacing: DesignSystem.Spacing.sm) {
                // Chunk type dot
                Circle()
                    .fill(DesignSystem.Colors.accent)
                    .frame(width: 6, height: 6)
                
                VStack(alignment: .leading, spacing: 2) {
                    // Document name and page info
                    HStack(spacing: DesignSystem.Spacing.xs) {
                        Text(chunk.document?.title ?? "Unknown Document")
                            .appleTextStyle(.caption2)
                            .foregroundColor(DesignSystem.Colors.primaryText)
                            .fontWeight(.medium)
                            .lineLimit(1)
                        
                        if let primaryPage = chunk.primaryPageNumber {
                            Text("•")
                                .appleTextStyle(.caption2)
                                .foregroundColor(DesignSystem.Colors.tertiaryText)
                            
                            Text("Page \(primaryPage)")
                                .appleTextStyle(.caption2)
                                .foregroundColor(DesignSystem.Colors.tertiaryText)
                        }
                        
                        Spacer()
                        
                        // Chunk indicator
                        Text("Chunk")
                            .appleTextStyle(.caption2)
                            .foregroundColor(DesignSystem.Colors.tertiaryText)
                            .padding(.horizontal, DesignSystem.Spacing.xs)
                            .padding(.vertical, 1)
                            .background(
                                Capsule()
                                    .fill(DesignSystem.Colors.tertiaryBackground)
                            )
                    }
                    
                    // Text preview for chunks
                    Text("\"\(chunk.text.prefix(80))...\"")
                        .appleTextStyle(.caption2)
                        .foregroundColor(DesignSystem.Colors.tertiaryText)
                        .italic()
                        .lineLimit(2)
                }
                
                Spacer()
            }
        }
        .buttonStyle(.plain)
        .padding(.horizontal, DesignSystem.Spacing.sm)
        .padding(.vertical, DesignSystem.Spacing.xs)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xs)
                .fill(isHovered ? DesignSystem.Colors.hoverBackground : Color.clear)
        )
        .onHover { hovering in
            withAnimation(DesignSystem.Animation.micro) {
                isHovered = hovering
            }
            // Note: Removed automatic bounding box highlighting on hover per user requirements
            // Bounding boxes now only show on click via ChunkCard
        }
        .help("Open \(chunk.document?.title ?? "document")")
    }
    
    private func openChunk() {
        guard let document = chunk.document else { return }
        
        print("📦 Opening chunk: \(chunk.chunkId) in document: \(document.title ?? "Untitled")")
        
        // Select the document
        ServiceContainer.shared.appState.selectDocument(document)
        
        // Navigate to chunk location and show bounding boxes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            if let primaryPage = chunk.primaryPageNumber {
                // Navigate to the page
                ServiceContainer.shared.appState.navigateToPDFPage(primaryPage)
                
                // Show bounding boxes for this specific chunk
                NotificationCenter.default.post(
                    name: NSNotification.Name("ShowChunkBoundingBoxes"),
                    object: nil,
                    userInfo: ["chunks": [chunk]]
                )
                
                print("📍 Navigated to page \(primaryPage) and requested bounding boxes for chunk")
            }
        }
    }
} 