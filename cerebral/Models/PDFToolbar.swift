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
    
    /// Darker version of the color for better contrast in selection indicators
    var darkColor: Color {
        switch self {
        case .yellow: return Color(red: 0.8, green: 0.722, blue: 0.031)
        case .green: return Color(red: 0.098, green: 0.486, blue: 0.114)
        case .blue: return Color(red: 0.029, green: 0.388, blue: 0.753)
        case .pink: return Color(red: 0.714, green: 0.018, blue: 0.188)
        }
    }
    
    /// Light version of the color for subtle backgrounds
    var lightColor: Color {
        switch self {
        case .yellow: return Color(red: 1.0, green: 0.982, blue: 0.831)
        case .green: return Color(red: 0.798, green: 0.886, blue: 0.814)
        case .blue: return Color(red: 0.629, green: 0.788, blue: 0.953)
        case .pink: return Color(red: 0.984, green: 0.718, blue: 0.788)
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
    
    /// Display name for accessibility and UI
    var displayName: String {
        switch self {
        case .yellow: return "Yellow"
        case .green: return "Green"
        case .blue: return "Blue"
        case .pink: return "Pink"
        }
    }
    
    /// Icon that represents the semantic meaning
    var semanticIcon: String {
        switch self {
        case .yellow: return "highlighter"
        case .green: return "lightbulb"
        case .blue: return "link"
        case .pink: return "questionmark.circle"
        }
    }
    
    /// Whether this color provides good contrast with white text
    var hasGoodWhiteTextContrast: Bool {
        switch self {
        case .yellow: return false // Yellow is too light for white text
        case .green, .blue, .pink: return true
        }
    }
    
    /// Best text color to use over this highlight color
    var contrastingTextColor: Color {
        return hasGoodWhiteTextContrast ? .white : .black
    }
    
    static func from(_ nsColor: NSColor?) -> HighlightColor {
        guard let nsColor = nsColor else { return .yellow }
        
        // Convert to components and match closest color
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        nsColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        // Match by dominant color component with better accuracy
        let colors: [(HighlightColor, (r: CGFloat, g: CGFloat, b: CGFloat))] = [
            (.yellow, (1.0, 0.922, 0.231)),
            (.green, (0.298, 0.686, 0.314)),
            (.blue, (0.129, 0.588, 0.953)),
            (.pink, (0.914, 0.118, 0.388))
        ]
        
        // Find closest color by euclidean distance
        let closest = colors.min { lhs, rhs in
            let lhsDistance = sqrt(pow(red - lhs.1.r, 2) + pow(green - lhs.1.g, 2) + pow(blue - lhs.1.b, 2))
            let rhsDistance = sqrt(pow(red - rhs.1.r, 2) + pow(green - rhs.1.g, 2) + pow(blue - rhs.1.b, 2))
            return lhsDistance < rhsDistance
        }
        
        return closest?.0 ?? .yellow
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
    var isAnimatingColorChange: Bool = false
    
    func reset() {
        isVisible = false
        position = .zero
        selectedColor = nil
        currentSelection = nil
        animationState = .hidden
        existingHighlight = nil
        isAnimatingColorChange = false
    }
    
    func selectColor(_ color: HighlightColor) {
        isAnimatingColorChange = true
        selectedColor = color
        
        // Reset animation flag after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.isAnimatingColorChange = false
        }
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
    
    /// Formatted creation date for display
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: createdAt)
    }
    
    /// Short preview of the highlighted text
    var textPreview: String {
        let maxLength = 50
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.count > maxLength ? String(trimmed.prefix(maxLength)) + "..." : trimmed
    }
    
    static func == (lhs: PDFHighlight, rhs: PDFHighlight) -> Bool {
        return lhs.id == rhs.id
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
    
    /// Clean text suitable for display and storage
    var cleanText: String {
        return string?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }
} 