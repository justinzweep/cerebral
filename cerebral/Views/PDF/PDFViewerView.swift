//
//  PDFViewerView.swift
//  cerebral
//
//  Created by Justin Zweep on 26/06/2025.
//

import SwiftUI
import PDFKit
import SwiftData

struct PDFViewerView: View {
    let document: Document?
    @State private var pdfDocument: PDFDocument?
    @State private var currentPage: Int = 0
    @State private var showingError: Bool = false
    @State private var errorMessage: String = ""
    @State private var pdfViewCoordinator: PDFViewCoordinator?
    
    // PDF selection state for escape key handling
    @State private var appState = ServiceContainer.shared.appState
    
    // Toolbar integration
    @State private var toolbarService = ServiceContainer.shared.toolbarService
    
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        Group {
            if let currentDocument = document {
                if let pdfDocument = pdfDocument {
                    // PDF Content with Toolbar Overlay
                    ZStack {
                        PDFViewerRepresentable(
                            document: pdfDocument,
                            currentPage: $currentPage,
                            coordinator: $pdfViewCoordinator
                        )
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        .clipped()
                        .background(DesignSystem.Colors.secondaryBackground)
                        .onTapGesture {
                            // Hide toolbar when clicking outside selection
                            appState.hideToolbar()
                        }
                        
                        // Toolbar Overlay
                        PDFToolbarContainer(
                            pdfDocument: pdfDocument,
                            documentURL: currentDocument.filePath
                        )
                    }
                } else {
                    // Enhanced Loading State
                    LoadingStateView(message: "Loading PDF...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            } else {
                // Enhanced Empty State
                EmptyPDFStateView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onChange(of: document) { oldDocument, newDocument in
            loadPDF()
        }
        .onAppear {
            loadPDF()
        }
        .alert("Error Loading PDF", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func loadPDF() {
        guard let document = document else {
            pdfDocument = nil
            return
        }
        
        // Update last opened date
        document.lastOpened = Date()
        
        // Load PDF document
        if FileManager.default.fileExists(atPath: document.filePath.path) {
            pdfDocument = PDFDocument(url: document.filePath)
            
            if let pdfDoc = pdfDocument {
                // Load existing highlights
                Task { @MainActor in
                    let existingHighlights = toolbarService.loadHighlights(from: pdfDoc)
                    for highlight in existingHighlights {
                        appState.addHighlight(highlight)
                    }
                }
            } else {
                errorMessage = "Failed to load PDF. The file may be corrupted or in an unsupported format."
                showingError = true
            }
        } else {
            errorMessage = "PDF file not found. It may have been moved or deleted."
            showingError = true
        }
    }
}

// MARK: - Loading State

struct LoadingStateView: View {
    let message: String
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: DesignSystem.Colors.accent))
                .scaleEffect(1.5)
            
            Text(message)
                .font(DesignSystem.Typography.title3)
                .foregroundColor(DesignSystem.Colors.secondaryText)
        }
        .background(DesignSystem.Colors.secondaryBackground)
    }
}

// MARK: - Empty State

struct EmptyPDFStateView: View {
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xl) {
            Image(systemName: "doc.text")
                .font(.system(size: 64))
                .foregroundColor(DesignSystem.Colors.tertiaryText)
            
            VStack(spacing: DesignSystem.Spacing.sm) {
                Text("No Document Selected")
                    .font(DesignSystem.Typography.title2)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                
                Text("Select a PDF from the sidebar to start reading")
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.tertiaryText)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(DesignSystem.Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignSystem.Colors.secondaryBackground)
    }
}

#Preview {
    PDFViewerView(document: nil)
} 
