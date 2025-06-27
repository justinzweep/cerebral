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
                        .font(.system(size: 16, weight: .medium))
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
                        }
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.md)
                .padding(.bottom, DesignSystem.Spacing.lg)
            }
            .scrollIndicators(.hidden) // Performance optimization
        }
    }
}

#Preview {
    DocumentSidebarPane(
        selectedDocument: .constant(nil),
        showingImporter: .constant(false)
    )
    .modelContainer(for: [Document.self, ChatSession.self], inMemory: true)
    .frame(width: 280, height: 600)
} 