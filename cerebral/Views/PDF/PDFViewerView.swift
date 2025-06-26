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
    let annotationManager: AnnotationManager?
    @State private var pdfDocument: PDFDocument?
    @State private var currentPage: Int = 0
    @State private var selectedText: String?
    @State private var showingError: Bool = false
    @State private var errorMessage: String = ""
    @Environment(\.modelContext) private var modelContext
    
    // Default annotation manager for when none is provided
    @StateObject private var defaultAnnotationManager = AnnotationManager()
    
    private var activeAnnotationManager: AnnotationManager {
        annotationManager ?? defaultAnnotationManager
    }
    
    var body: some View {
        VStack {
            if let document = document {
                if let pdfDocument = pdfDocument {
                    VStack(spacing: 0) {
                        // PDF Toolbar
                        HStack {
                            Text(document.title)
                                .font(.headline)
                                .lineLimit(1)
                            
                            Spacer()
                            
                            if let pageCount = pdfDocument.pageCount as Int?, pageCount > 0 {
                                Text("Page \(currentPage + 1) of \(pageCount)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .background(Color(NSColor.controlBackgroundColor))
                        
                        // Annotation Toolbar
                        AnnotationToolbar(annotationManager: activeAnnotationManager)
                            .padding(.horizontal)
                            .padding(.bottom, 8)
                        
                        Divider()
                        
                        // PDF Content with annotation overlay
                        ZStack {
                            PDFViewerRepresentable(
                                document: pdfDocument,
                                currentPage: $currentPage,
                                selectedText: $selectedText,
                                annotationManager: activeAnnotationManager
                            )
                            .background(Color(NSColor.controlBackgroundColor))
                        }
                    }
                } else {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                        
                        Text("Loading PDF...")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                }
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 64))
                        .foregroundColor(.secondary)
                    
                    Text("No Document Selected")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    
                    Text("Select a PDF from the sidebar to start reading")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
            }
        }
        .onChange(of: document) { oldDocument, newDocument in
            loadPDF()
            setupAnnotationManager()
        }
        .onAppear {
            loadPDF()
            setupAnnotationManager()
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
    
    private func setupAnnotationManager() {
        activeAnnotationManager.setContext(modelContext)
        activeAnnotationManager.setCurrentDocument(document)
    }
}

#Preview {
    PDFViewerView(document: nil, annotationManager: nil)
} 