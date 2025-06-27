//
//  DocumentReferenceResolver.swift
//  cerebral
//
//  Created by Assistant on 26/06/2025.
//

import Foundation

/// Service responsible for resolving @mention document references
final class DocumentReferenceResolver: DocumentReferenceServiceProtocol {
    static let shared = DocumentReferenceResolver()
    
    private init() {}
    
    /// Extract document references from @mentions in text
    @MainActor
    func extractDocumentReferences(from text: String) -> [Document] {
        let pattern = #"@([a-zA-Z0-9\s\-_\.]+\.pdf|[a-zA-Z0-9\s\-_]+)"#
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return []
        }
        
        let nsString = text as NSString
        let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))
        
        var referencedDocuments: [Document] = []
        
        for match in matches {
            let fullMatch = nsString.substring(with: match.range)
            
            // Extract document name (remove @ and potentially .pdf)
            var documentName = String(fullMatch.dropFirst()) // Remove @
            if documentName.hasSuffix(".pdf") {
                documentName = String(documentName.dropLast(4)) // Remove .pdf
            }
            
            // Try to find the document
            if let document = ServiceContainer.shared.documentService.findDocument(byName: documentName) {
                referencedDocuments.append(document)
                print("✅ Found referenced document: '\(document.title)' for mention: '\(fullMatch)'")
            } else {
                print("❌ Document not found for mention: '\(fullMatch)' (looking for: '\(documentName)')")
                // Show all available documents for debugging
                let allDocs = ServiceContainer.shared.documentService.getAllDocuments()
                print("📚 Available documents:")
                for doc in allDocs.prefix(5) { // Show first 5 for brevity
                    print("  - '\(doc.title)'")
                }
            }
        }
        
        return referencedDocuments
    }
    
    /// Get UUIDs from a list of documents
    func getDocumentUUIDs(from documents: [Document]) -> [UUID] {
        return documents.map { $0.id }
    }
    
    /// Combine multiple document arrays and remove duplicates
    func combineUniqueDocuments(_ documentArrays: [Document]...) -> [Document] {
        let allDocuments = documentArrays.flatMap { $0 }
        var uniqueDocuments: [Document] = []
        var seenUUIDs: Set<UUID> = []
        
        for document in allDocuments {
            if !seenUUIDs.contains(document.id) {
                uniqueDocuments.append(document)
                seenUUIDs.insert(document.id)
            }
        }
        
        return uniqueDocuments
    }
} 