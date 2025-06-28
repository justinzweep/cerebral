//
//  DocumentReferenceResolver.swift
//  cerebral
//
//  Created by Assistant on 26/06/2025.
//

import Foundation
import SwiftUI

/// Service responsible for resolving document references in text
@MainActor
final class DocumentReferenceResolver: DocumentReferenceServiceProtocol {
    static let shared = DocumentReferenceResolver()
    private let documentService = DocumentService.shared
    
    private init() {}
    
    // MARK: - Shared Constants
    
    /// Unified regex pattern for document references
    static let documentReferencePattern = #"@([a-zA-Z0-9\s\-_\.]+\.pdf|[a-zA-Z0-9\s\-_\.]+)"#
    
    // MARK: - Document Reference Extraction
    
    func extractDocumentReferences(from text: String) -> [Document] {
        guard let regex = try? NSRegularExpression(pattern: Self.documentReferencePattern, options: [.caseInsensitive]) else {
            return []
        }
        
        let nsString = text as NSString
        let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))
        
        var documents: [Document] = []
        for match in matches {
            let matchText = nsString.substring(with: match.range)
            let documentName = DocumentReferenceResolver.extractDocumentName(from: matchText)
            
            if let document = documentService.findDocument(byName: documentName) {
                documents.append(document)
            }
        }
        
        return Array(Set(documents)) // Remove duplicates
    }
    
    /// Extract document name from @mention text
    static func extractDocumentName(from matchText: String) -> String {
        var documentName = String(matchText.dropFirst()) // Remove @ symbol
        
        // If it ends with .pdf, remove only the final .pdf extension
        if documentName.lowercased().hasSuffix(".pdf") {
            documentName = String(documentName.dropLast(4))
        }
        
        return documentName
    }
    
    /// Check if document exists for a given name
    static func documentExists(named documentName: String) -> Bool {
        return ServiceContainer.shared.documentService.findDocument(byName: documentName) != nil
    }
    
    /// Find all document references in text and return their validity
    static func validateDocumentReferences(in text: String) -> Bool {
        guard let regex = try? NSRegularExpression(pattern: documentReferencePattern, options: [.caseInsensitive]) else {
            return true // If regex fails, allow sending
        }
        
        let nsString = text as NSString
        let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))
        
        for match in matches {
            let fullMatch = nsString.substring(with: match.range)
            let documentName = extractDocumentName(from: fullMatch)
            
            if !documentExists(named: documentName) {
                return false // Invalid reference found
            }
        }
        
        return true // All references are valid
    }
    
    // MARK: - Legacy Implementation
    
    func getDocumentUUIDs(from documents: [Document]) -> [UUID] {
        return documents.map { $0.id }
    }
    
    func combineUniqueDocuments(_ documentArrays: [Document]...) -> [Document] {
        let allDocuments = documentArrays.flatMap { $0 }
        return Array(Set(allDocuments))
    }
} 
