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
    
    // Highlighting state
    @State private var selectedText: PDFSelection?
    @State private var showHighlightPopup: Bool = false
    @State private var highlightPopupPosition: CGPoint = .zero
    @State private var pdfViewCoordinator: PDFViewCoordinator?
    
    // PDF selection state for escape key handling
    @State private var appState = ServiceContainer.shared.appState
    
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        Group {
            if let currentDocument = document {
                if let pdfDocument = pdfDocument {
                    // PDF Content with highlighting overlay
                    ZStack {
                        PDFViewerRepresentable(
                            document: pdfDocument,
                            currentPage: $currentPage,
                            selectedText: $selectedText,
                            showHighlightPopup: $showHighlightPopup,
                            highlightPopupPosition: $highlightPopupPosition,
                            coordinator: $pdfViewCoordinator
                        )
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        .clipped()
                        .background(DesignSystem.Colors.secondaryBackground)
                        .onTapGesture {
                            // Dismiss highlight popup when tapping outside
                            if showHighlightPopup {
                                showHighlightPopup = false
                                selectedText = nil
                            }
                        }
                        
                        // Highlight color picker overlay
                        if showHighlightPopup {
                            HighlightColorPicker(
                                position: highlightPopupPosition,
                                onColorSelected: { color in
                                    handleHighlightSelection(color: color)
                                },
                                onDismiss: {
                                    showHighlightPopup = false
                                    selectedText = nil
                                }
                            )
                            .zIndex(1000) // Ensure it appears above everything
                        }
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
        // NEW: Clear selections on Escape key
        .onKeyPress(KeyEquivalent.escape) {
            if !appState.pdfSelections.isEmpty {
                pdfViewCoordinator?.clearMultipleSelections()
                return .handled
            }
            return .ignored
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
            
            if pdfDocument == nil {
                errorMessage = "Failed to load PDF. The file may be corrupted or in an unsupported format."
                showingError = true
            }
        } else {
            errorMessage = "PDF file not found. It may have been moved or deleted."
            showingError = true
        }
    }
    
    private func handleHighlightSelection(color: NSColor) {
        print("🎯 === HANDLE HIGHLIGHT SELECTION ===")
        print("🎨 Color: \(color)")
        
        // Capture the selection and coordinator immediately
        let currentSelection = selectedText
        let currentCoordinator = pdfViewCoordinator ?? PDFViewCoordinator.sharedCoordinator
        
        print("📄 Current selection exists: \(currentSelection != nil)")
        print("🔗 Current coordinator exists: \(currentCoordinator != nil)")
        print("🔗 Shared coordinator exists: \(PDFViewCoordinator.sharedCoordinator != nil)")
        
        guard let selection = currentSelection else { 
            print("❌ Missing selection")
            showHighlightPopup = false
            selectedText = nil
            return 
        }
        
        guard let coordinator = currentCoordinator else {
            print("❌ Missing coordinator - trying to highlight anyway")
            showHighlightPopup = false
            selectedText = nil
            return
        }
        
        print("✅ Selection text: '\(selection.string?.prefix(50) ?? "nil")...'")
        print("✅ Selection pages count: \(selection.pages.count)")
        
        // Hide popup immediately
        showHighlightPopup = false
        
        // Use the coordinator to add the highlight
        coordinator.addHighlight(to: selection, color: color)
        
        // Clear selection after highlighting
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.selectedText = nil
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
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .background(DesignSystem.Colors.secondaryBackground.opacity(0.5))
    }
}

#Preview {
    PDFViewerView(document: nil)
} 
