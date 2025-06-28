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
        case .fullDocument: return DesignSystem.Colors.accent
        case .pageRange: return DesignSystem.Colors.secondaryAccent
        case .textSelection: return DesignSystem.Colors.success
        case .semanticChunk: return DesignSystem.Colors.warning
        }
    }
    
    private var contextTypeName: String {
        switch context.contextType {
        case .fullDocument: return "Full document"
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