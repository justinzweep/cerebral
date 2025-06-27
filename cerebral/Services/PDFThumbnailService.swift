//
//  PDFThumbnailService.swift
//  cerebral
//
//  Created by Justin Zweep on 26/06/2025.
//

import Foundation
import PDFKit
import SwiftUI

class PDFThumbnailService {
    static let shared = PDFThumbnailService()
    
    private init() {}
    
    private let thumbnailCache = NSCache<NSString, NSImage>()
    
    func generateThumbnail(for document: Document, size: CGSize = CGSize(width: 120, height: 160)) -> NSImage? {
        let cacheKey = "\(document.id.uuidString)-\(size.width)x\(size.height)" as NSString
        
        // Check cache first
        if let cachedThumbnail = thumbnailCache.object(forKey: cacheKey) {
            return cachedThumbnail
        }
        
        // Generate new thumbnail
        guard let pdfDocument = PDFDocument(url: document.filePath),
              let firstPage = pdfDocument.page(at: 0) else {
            return nil
        }
        
        let pageBounds = firstPage.bounds(for: .mediaBox)
        let aspectRatio = pageBounds.width / pageBounds.height
        
        // Calculate thumbnail size maintaining aspect ratio
        var thumbnailSize = size
        if aspectRatio > 1 {
            // Landscape
            thumbnailSize.height = size.width / aspectRatio
        } else {
            // Portrait
            thumbnailSize.width = size.height * aspectRatio
        }
        
        // Create thumbnail image
        let thumbnail = firstPage.thumbnail(of: thumbnailSize, for: .mediaBox)
        
        // Cache the thumbnail
        thumbnailCache.setObject(thumbnail, forKey: cacheKey)
        
        return thumbnail
    }
    
    func clearCache() {
        thumbnailCache.removeAllObjects()
    }
} 