//
//  PDFThumbnailView.swift
//  cerebral
//
//  Created by Justin Zweep on 26/06/2025.
//

import SwiftUI
import AppKit

struct PDFThumbnailView: View {
    let document: Document
    let size: CGSize
    
    @State private var thumbnailImage: NSImage?
    @State private var isLoading = true
    
    init(document: Document, size: CGSize = CGSize(width: 36, height: 44)) {
        self.document = document
        self.size = size
    }
    
    var body: some View {
        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xs)
            .fill(DesignSystem.Colors.accent.opacity(0.1))
            .frame(width: size.width, height: size.height)
            .overlay(
                Group {
                    if let thumbnail = thumbnailImage {
                        Image(nsImage: thumbnail)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .clipped()
                    } else if isLoading {
                        ProgressView()
                            .scaleEffect(0.5)
                            .tint(DesignSystem.Colors.accent)
                    } else {
                        // Fallback icon
                        Image(systemName: "doc.text.fill")
                            .foregroundColor(DesignSystem.Colors.accent)
                            .font(.system(size: 16, weight: .medium))
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xs))
            .task {
                await loadThumbnail()
            }
    }
    
    @MainActor
    private func loadThumbnail() async {
        isLoading = true
        
        let thumbnail = await Task.detached {
            PDFThumbnailService.shared.generateThumbnail(for: document, size: size)
        }.value
        
        thumbnailImage = thumbnail
        isLoading = false
    }
} 