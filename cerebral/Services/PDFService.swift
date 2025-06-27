//
//  PDFService.swift
//  cerebral
//
//  Created by Assistant on 26/06/2025.
//

import Foundation
import PDFKit
import SwiftUI

/// Consolidated PDF service that handles text extraction, thumbnail generation, and metadata
final class PDFService: PDFServiceProtocol {
    static let shared = PDFService()
    
    private init() {}
    
    private let thumbnailCache = NSCache<NSString, NSImage>()
    
    // MARK: - Text Extraction
    
    func extractText(from document: Document, maxLength: Int = 4000) -> String? {
        do {
            guard let pdfDocument = PDFDocument(url: document.filePath) else {
                throw PDFError.failedToLoad(document.title)
            }
            
            var extractedText = ""
            let pageCount = pdfDocument.pageCount
            
            // Extract text from first few pages to stay within token limits
            let maxPages = min(pageCount, 5)
            
            for pageIndex in 0..<maxPages {
                if let page = pdfDocument.page(at: pageIndex) {
                    if let pageText = page.string {
                        extractedText += pageText + "\n\n"
                    }
                }
                
                // Break if we've extracted enough text
                if extractedText.count > maxLength {
                    break
                }
            }
            
            // Truncate if too long
            if extractedText.count > maxLength {
                extractedText = String(extractedText.prefix(maxLength)) + "...\n\n[Content truncated for length]"
            }
            
            return extractedText.isEmpty ? nil : extractedText
            
        } catch {
            print("❌ Failed to extract text from \(document.title): \(error)")
            return nil
        }
    }
    
    func extractTextFromPage(document: Document, pageIndex: Int) -> String? {
        do {
            guard let pdfDocument = PDFDocument(url: document.filePath) else {
                throw PDFError.failedToLoad(document.title)
            }
            
            guard pageIndex >= 0 && pageIndex < pdfDocument.pageCount else {
                throw PDFError.invalidPageIndex(pageIndex)
            }
            
            guard let page = pdfDocument.page(at: pageIndex) else {
                throw PDFError.invalidPageIndex(pageIndex)
            }
            
            return page.string
            
        } catch {
            print("❌ Failed to extract text from page \(pageIndex) of \(document.title): \(error)")
            return nil
        }
    }
    
    // MARK: - Metadata Extraction
    
    func getDocumentMetadata(from document: Document) -> [String: Any]? {
        do {
            guard let pdfDocument = PDFDocument(url: document.filePath) else {
                throw PDFError.failedToLoad(document.title)
            }
            
            var metadata: [String: Any] = [:]
            
            metadata["pageCount"] = pdfDocument.pageCount
            metadata["title"] = document.title
            metadata["dateAdded"] = document.dateAdded
            
            if let documentAttributes = pdfDocument.documentAttributes {
                metadata["pdfTitle"] = documentAttributes[PDFDocumentAttribute.titleAttribute]
                metadata["author"] = documentAttributes[PDFDocumentAttribute.authorAttribute]
                metadata["subject"] = documentAttributes[PDFDocumentAttribute.subjectAttribute]
                metadata["creator"] = documentAttributes[PDFDocumentAttribute.creatorAttribute]
                metadata["creationDate"] = documentAttributes[PDFDocumentAttribute.creationDateAttribute]
            }
            
            return metadata
            
        } catch {
            print("❌ Failed to extract metadata from \(document.title): \(error)")
            return nil
        }
    }
    
    // MARK: - Thumbnail Generation
    
    func generateThumbnail(for document: Document, size: CGSize = CGSize(width: 120, height: 160)) -> NSImage? {
        let cacheKey = "\(document.id.uuidString)-\(size.width)x\(size.height)" as NSString
        
        // Check cache first
        if let cachedThumbnail = thumbnailCache.object(forKey: cacheKey) {
            return cachedThumbnail
        }
        
        do {
            // Generate new thumbnail
            guard let pdfDocument = PDFDocument(url: document.filePath) else {
                throw PDFError.failedToLoad(document.title)
            }
            
            guard let firstPage = pdfDocument.page(at: 0) else {
                throw PDFError.thumbnailGenerationFailed(document.title)
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
            
        } catch {
            print("❌ Failed to generate thumbnail for \(document.title): \(error)")
            return nil
        }
    }
    
    func clearThumbnailCache() {
        thumbnailCache.removeAllObjects()
    }
    
    // MARK: - Helper Methods
    
    /// Validates that a PDF document can be loaded
    func validatePDF(at url: URL) throws {
        guard let _ = PDFDocument(url: url) else {
            throw PDFError.failedToLoad(url.lastPathComponent)
        }
    }
    
    /// Gets the page count for a PDF document
    func getPageCount(for document: Document) -> Int? {
        guard let pdfDocument = PDFDocument(url: document.filePath) else {
            return nil
        }
        return pdfDocument.pageCount
    }
    
    /// Estimates the text content size for a document
    func estimateContentSize(for document: Document) -> Int {
        guard let text = extractText(from: document, maxLength: Int.max) else {
            return 0
        }
        return text.count
    }
} 