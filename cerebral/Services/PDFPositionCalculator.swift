//
//  PDFPositionCalculator.swift
//  cerebral
//
//  Created by Assistant on 26/06/2025.
//

import Foundation
import PDFKit
import SwiftUI

// MARK: - Protocol

@MainActor
protocol PDFPositionCalculatorProtocol {
    func calculateToolbarPosition(for selection: PDFSelection, in view: PDFView) -> CGPoint
}

// MARK: - Implementation

@MainActor
final class PDFPositionCalculator: PDFPositionCalculatorProtocol {
    
    static let toolbarSize = CGSize(width: 140, height: 50)
    static let margin: CGFloat = 16
    static let offsetFromSelection: CGFloat = 20
    
    func calculateToolbarPosition(for selection: PDFSelection, in view: PDFView) -> CGPoint {
        return Self.calculatePosition(for: selection, in: view)
    }
    
    static func calculatePosition(
        for selection: PDFSelection,
        in pdfView: PDFView,
        toolbarSize: CGSize = toolbarSize
    ) -> CGPoint {
        guard let page = selection.pages.first else {
            return CGPoint(x: 100, y: 100) // Safe fallback
        }
        
        // Get the selection bounds on the PDF page
        let selectionBounds = selection.bounds(for: page)
        
        // Convert to PDFView coordinates
        let viewBounds = pdfView.convert(selectionBounds, from: page)
        
        // Use the center-top of the selection as reference point
        let referencePoint = CGPoint(
            x: viewBounds.midX,
            y: viewBounds.minY
        )
        
        print("📍 Selection bounds on page: \(selectionBounds)")
        print("📍 Converted to view bounds: \(viewBounds)")
        print("📍 Reference point: \(referencePoint)")
        
        return referencePoint
    }
} 