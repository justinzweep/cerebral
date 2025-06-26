//
//  PDFViewerRepresentable.swift
//  cerebral
//
//  Created by Justin Zweep on 26/06/2025.
//

import SwiftUI
import PDFKit

struct PDFViewerRepresentable: NSViewRepresentable {
    let document: PDFDocument?
    @Binding var currentPage: Int
    @Binding var selectedText: String?
    @ObservedObject var annotationManager: AnnotationManager
    
    func makeNSView(context: Context) -> PDFView {
        let pdfView = PDFView()
        
        // Configure PDF view
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displaysPageBreaks = true
        pdfView.displayBox = .mediaBox
        pdfView.interpolationQuality = .high
        
        // Set up notifications
        NotificationCenter.default.addObserver(
            forName: .PDFViewPageChanged,
            object: pdfView,
            queue: .main
        ) { _ in
            if let page = pdfView.currentPage,
               let pageIndex = pdfView.document?.index(for: page) {
                currentPage = pageIndex
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: .PDFViewSelectionChanged,
            object: pdfView,
            queue: .main
        ) { _ in
            selectedText = pdfView.currentSelection?.string
            
            // Handle highlight creation when text is selected in annotation mode
            Task { @MainActor in
                if annotationManager.isAnnotationMode && 
                   annotationManager.selectedAnnotationTool == .highlight,
                   let selection = pdfView.currentSelection,
                   let page = pdfView.currentPage {
                    let bounds = selection.bounds(for: page)
                    let pageIndex = pdfView.document?.index(for: page) ?? 0
                    annotationManager.createHighlightAnnotation(
                        at: bounds,
                        on: pageIndex,
                        selectedText: selection.string
                    )
                    pdfView.clearSelection()
                }
            }
        }
        
        return pdfView
    }
    
    func updateNSView(_ nsView: PDFView, context: Context) {
        if nsView.document !== document {
            nsView.document = document
            
            // Reset to first page when loading new document
            if let document = document, document.pageCount > 0 {
                nsView.go(to: document.page(at: 0)!)
                currentPage = 0
            }
        }
    }
    
    static func dismantleNSView(_ nsView: PDFView, coordinator: ()) {
        NotificationCenter.default.removeObserver(nsView)
    }
}

#Preview {
    PDFViewerRepresentable(
        document: nil,
        currentPage: .constant(0),
        selectedText: .constant(nil),
        annotationManager: AnnotationManager()
    )
} 