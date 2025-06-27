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
    
    func makeNSView(context: Context) -> PDFView {
        let pdfView = PDFView()
        
        // Configure PDF view with enhanced settings
        pdfView.autoScales = true // Auto-scale to fit width
        pdfView.displayMode = .singlePageContinuous
        pdfView.displaysPageBreaks = true
        pdfView.displayBox = .mediaBox
        pdfView.interpolationQuality = .high
        
        // Enhanced appearance
        pdfView.backgroundColor = NSColor.controlBackgroundColor
        
        // Set document view background using layer approach
        if let documentView = pdfView.documentView {
            documentView.wantsLayer = true
            documentView.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        }
        
        // Set up notifications with better handling
        NotificationCenter.default.addObserver(
            forName: .PDFViewPageChanged,
            object: pdfView,
            queue: .main
        ) { [weak pdfView] _ in
            guard let pdfView = pdfView,
                  let page = pdfView.currentPage,
                  let pageIndex = pdfView.document?.index(for: page) else { return }
            currentPage = pageIndex
        }
        

        
        return pdfView
    }
    
    func updateNSView(_ nsView: PDFView, context: Context) {
        // Update document if changed
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
        // Clean up all notifications for this specific PDFView instance
        NotificationCenter.default.removeObserver(nsView, name: .PDFViewPageChanged, object: nil)
        NotificationCenter.default.removeObserver(nsView, name: .PDFViewScaleChanged, object: nil)
    }
}

#Preview {
    PDFViewerRepresentable(
        document: nil,
        currentPage: .constant(0)
    )
} 