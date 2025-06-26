//
//  PDFTextExtractionService.swift
//  cerebral
//
//  Created by Justin Zweep on 26/06/2025.
//

import Foundation
import PDFKit

class PDFTextExtractionService {
    static let shared = PDFTextExtractionService()
    
    private init() {}
    
    func extractText(from document: Document, maxLength: Int = 4000) -> String? {
        guard let pdfDocument = PDFDocument(url: document.filePath) else {
            return nil
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
    }
    
    func extractTextFromPage(document: Document, pageIndex: Int) -> String? {
        guard let pdfDocument = PDFDocument(url: document.filePath),
              pageIndex >= 0,
              pageIndex < pdfDocument.pageCount,
              let page = pdfDocument.page(at: pageIndex) else {
            return nil
        }
        
        return page.string
    }
    
    func getDocumentMetadata(from document: Document) -> [String: Any]? {
        guard let pdfDocument = PDFDocument(url: document.filePath) else {
            return nil
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
    }
} 