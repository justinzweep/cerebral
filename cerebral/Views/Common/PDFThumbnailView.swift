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
    @State private var loadingTask: Task<Void, Never>?
    
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
            .onAppear {
                loadThumbnail()
            }
            .onDisappear {
                // Cancel loading task to prevent memory leaks
                loadingTask?.cancel()
                loadingTask = nil
            }
    }
    
    private func loadThumbnail() {
        // Cancel any existing loading task
        loadingTask?.cancel()
        
        loadingTask = Task { @MainActor in
            isLoading = true
            
            // Perform thumbnail generation on background queue
            let thumbnail = await Task.detached { [document, size] in
                PDFService.shared.generateThumbnail(for: document, size: size)
            }.value
            
            // Check if task was cancelled
            guard !Task.isCancelled else { return }
            
            thumbnailImage = thumbnail
            isLoading = false
            loadingTask = nil
        }
    }
} 