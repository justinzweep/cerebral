//
//  DocumentSidebarPane.swift
//  cerebral
//
//  Created by Justin Zweep on 26/06/2025.
//

import SwiftUI
import SwiftData

struct DocumentSidebarPane: View {
    @Binding var selectedDocument: Document?
    @Environment(\.modelContext) private var modelContext
    
    // Optimized query with limit for better performance
    @Query(
        sort: \Document.dateAdded, 
        order: .reverse
    ) private var documents: [Document]
    
    @State private var showingImporter = false
    
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
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(DesignSystem.Colors.accent)
                }
                .buttonStyle(.plain)
                .frame(width: 32, height: 32)
                .background(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                        .fill(DesignSystem.Colors.hoverBackground.opacity(0))
                )
                .onHover { isHovered in
                    withAnimation(DesignSystem.Animation.microInteraction) {
                        // Hover effect handled by button style
                    }
                }
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
                                    selectedDocument = document
                                }
                                .background(
                                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                                        .fill(selectedDocument?.id == document.id ? 
                                              DesignSystem.Colors.selectedBackground : 
                                              Color.clear)
                                )
                                .animation(DesignSystem.Animation.microInteraction, value: selectedDocument?.id)
                                .id(document.id) // Stable ID for each document
                                .trackPerformance("document_row_\(index)")
                        }
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.md)
                .padding(.bottom, DesignSystem.Spacing.lg)
            }
            .scrollIndicators(.hidden) // Performance optimization
            .trackPerformance("document_list_scroll")
        }
        .fileImporter(
            isPresented: $showingImporter,
            allowedContentTypes: [.pdf],
            allowsMultipleSelection: true
        ) { result in
            Task { @MainActor in
                do {
                    try await ServiceContainer.shared.documentService.importDocuments(result, to: modelContext)
                } catch {
                    ServiceContainer.shared.errorManager.handle(error)
                }
            }
        }
        .trackPerformance("document_sidebar_pane")
    }
}

#Preview {
    DocumentSidebarPane(selectedDocument: .constant(nil))
        .modelContainer(for: [Document.self, ChatSession.self], inMemory: true)
        .frame(width: 280, height: 600)
} 