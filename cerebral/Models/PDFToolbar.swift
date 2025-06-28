//
//  PDFToolbar.swift
//  cerebral
//
//  Created by Assistant on 26/06/2025.
//

import SwiftUI
import PDFKit
import Foundation

// MARK: - Highlight Colors

enum HighlightColor: String, CaseIterable, Identifiable {
    case yellow = "yellow"
    case green = "green" 
    case blue = "blue"
    case pink = "pink"
    
    var id: String { rawValue }
    
    var color: Color {
        switch self {
        case .yellow: return Color(red: 1.0, green: 0.922, blue: 0.231) // #FFEB3B
        case .green: return Color(red: 0.298, green: 0.686, blue: 0.314) // #4CAF50
        case .blue: return Color(red: 0.129, green: 0.588, blue: 0.953) // #2196F3
        case .pink: return Color(red: 0.914, green: 0.118, blue: 0.388) // #E91E63
        }
    }
    
    var nsColor: NSColor {
        switch self {
        case .yellow: return NSColor(red: 1.0, green: 0.922, blue: 0.231, alpha: 0.4)
        case .green: return NSColor(red: 0.298, green: 0.686, blue: 0.314, alpha: 0.4)
        case .blue: return NSColor(red: 0.129, green: 0.588, blue: 0.953, alpha: 0.4)
        case .pink: return NSColor(red: 0.914, green: 0.118, blue: 0.388, alpha: 0.4)
        }
    }
    
    var semanticMeaning: String {
        switch self {
        case .yellow: return "Default/most common highlighting"
        case .green: return "Important concepts, definitions"
        case .blue: return "References, citations, links"
        case .pink: return "Questions, unclear items, review needed"
        }
    }
    
    static func from(_ nsColor: NSColor?) -> HighlightColor {
        guard let nsColor = nsColor else { return .yellow }
        
        // Convert to components and match closest color
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        nsColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        // Match by dominant color component
        if green > red && green > blue {
            return .green
        } else if blue > red && blue > green {
            return .blue
        } else if red > 0.8 && green < 0.5 && blue < 0.5 {
            return .pink
        } else {
            return .yellow
        }
    }
}

// MARK: - Toolbar State

@Observable
class ToolbarState {
    var isVisible: Bool = false
    var position: CGPoint = .zero
    var selectedColor: HighlightColor?
    var currentSelection: PDFSelection?
    var animationState: ToolbarAnimationState = .hidden
    var existingHighlight: PDFHighlight?
    
    func reset() {
        isVisible = false
        position = .zero
        selectedColor = nil
        currentSelection = nil
        animationState = .hidden
        existingHighlight = nil
    }
}

enum ToolbarAnimationState {
    case hidden
    case appearing
    case visible
    case disappearing
}

// MARK: - PDF Highlight Model

struct PDFHighlight: Identifiable, Equatable {
    let id = UUID()
    let bounds: CGRect
    let color: HighlightColor
    let pageIndex: Int
    let text: String
    let createdAt: Date
    let documentURL: URL
    
    // PDFKit annotation reference
    var annotationID: String {
        return "cerebral_highlight_\(id.uuidString)"
    }
    
    static func == (lhs: PDFHighlight, rhs: PDFHighlight) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Toolbar Position Calculator

struct ToolbarPositionCalculator {
    static let toolbarSize = CGSize(width: 140, height: 50)
    static let margin: CGFloat = 16
    static let offsetFromSelection: CGFloat = 20
    
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

// MARK: - Toolbar Extensions

extension PDFSelection {
    var isEmpty: Bool {
        return string?.isEmpty ?? true
    }
    
    var isValidForHighlighting: Bool {
        guard let text = string,
              !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              text.count > 1 else {
            return false
        }
        return true
    }
} 