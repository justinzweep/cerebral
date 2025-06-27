//
//  Typography.swift
//  cerebral
//
//  Typography System for Cerebral macOS App
//  Following SF Pro Guidelines and Apple Human Interface Guidelines
//

import SwiftUI

// MARK: - Typography System

extension DesignSystem {
    struct Typography {
        // MARK: - Display Text (Headers)
        static let largeTitle = Font.custom("SF Pro Display", size: 34).weight(.bold)      // 34pt - Page headers
        static let title = Font.custom("SF Pro Display", size: 28).weight(.semibold)       // 28pt - Section headers
        static let title2 = Font.custom("SF Pro Display", size: 22).weight(.semibold)      // 22pt - Subsection headers
        static let title3 = Font.custom("SF Pro Display", size: 20).weight(.medium)        // 20pt - Card headers
        
        // MARK: - Body Text (Content)
        static let headline = Font.custom("SF Pro Text", size: 17).weight(.semibold)       // 17pt - Emphasized body
        static let body = Font.custom("SF Pro Text", size: 17).weight(.regular)            // 17pt - Primary body
        static let bodyMedium = Font.custom("SF Pro Text", size: 17).weight(.medium)       // 17pt - Medium body
        static let callout = Font.custom("SF Pro Text", size: 16).weight(.regular)         // 16pt - Secondary text
        
        // MARK: - Supporting Text
        static let subheadline = Font.custom("SF Pro Text", size: 15).weight(.regular)     // 15pt - Metadata
        static let footnote = Font.custom("SF Pro Text", size: 13).weight(.regular)        // 13pt - Fine print
        static let caption = Font.custom("SF Pro Text", size: 12).weight(.medium)          // 12pt - Labels
        static let caption2 = Font.custom("SF Pro Text", size: 11).weight(.regular)        // 11pt - Tiny text
        
        // MARK: - Special Purpose
        static let monospace = Font.system(.body, design: .monospaced)
        static let code = Font.system(.caption, design: .monospaced).weight(.medium)
        static let button = Font.custom("SF Pro Text", size: 15).weight(.medium)
        static let tabBar = Font.custom("SF Pro Text", size: 13).weight(.medium)
        
        // MARK: - Fallback Fonts (when custom fonts fail)
        static let systemLargeTitle = Font.largeTitle.weight(.bold)
        static let systemTitle = Font.title.weight(.semibold)
        static let systemTitle2 = Font.title2.weight(.semibold)
        static let systemTitle3 = Font.title3.weight(.medium)
        static let systemHeadline = Font.headline.weight(.semibold)
        static let systemBody = Font.body
        static let systemCallout = Font.callout
        static let systemSubheadline = Font.subheadline
        static let systemFootnote = Font.footnote
        static let systemCaption = Font.caption.weight(.medium)
    }
} 