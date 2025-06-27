//
//  DocumentService.swift
//  cerebral
//
//  Created by Assistant on 26/06/2025.
//

import Foundation
import SwiftData

/// Enhanced document service that handles import, lookup, and management operations
@MainActor
final class DocumentService: DocumentServiceProtocol {
    static let shared = DocumentService()
    
    private var modelContext: ModelContext?
    private let pdfService: PDFServiceProtocol
    
    private init(pdfService: PDFServiceProtocol = PDFService.shared) {
        self.pdfService = pdfService
    }
    
    // MARK: - Setup
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }
    
    // MARK: - Document Import
    
    func importDocument(from url: URL, to modelContext: ModelContext) async throws -> Document {
        guard url.startAccessingSecurityScopedResource() else {
            throw DocumentError.accessDenied(url.lastPathComponent)
        }
        defer { url.stopAccessingSecurityScopedResource() }
        
        // Validate the PDF first
        do {
            try pdfService.validatePDF(at: url)
        } catch {
            throw DocumentError.invalidFormat(url.lastPathComponent)
        }
        
        // Create documents directory if it doesn't exist
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let cerebralDocsPath = documentsPath.appendingPathComponent("Cerebral Documents")
        
        do {
            try FileManager.default.createDirectory(at: cerebralDocsPath, withIntermediateDirectories: true)
        } catch {
            throw DocumentError.storageError("Failed to create documents directory: \(error.localizedDescription)")
        }
        
        // Handle file naming and duplicates
        let fileName = url.lastPathComponent
        let finalURL = try generateUniqueFileURL(fileName: fileName, in: cerebralDocsPath)
        
        // Copy file to app's documents directory
        do {
            try FileManager.default.copyItem(at: url, to: finalURL)
        } catch {
            throw DocumentError.importFailed("Failed to copy file: \(error.localizedDescription)")
        }
        
        // Create document model
        let title = finalURL.deletingPathExtension().lastPathComponent
        let document = Document(title: title, filePath: finalURL)
        
        // Check for duplicates in the database
        if let existingDocument = findDocument(byName: title) {
            // Remove the copied file since it's a duplicate
            try? FileManager.default.removeItem(at: finalURL)
            throw DocumentError.duplicateDocument(title)
        }
        
        modelContext.insert(document)
        
        do {
            try modelContext.save()
        } catch {
            // Clean up the file if database save fails
            try? FileManager.default.removeItem(at: finalURL)
            throw DocumentError.storageError("Failed to save document to database: \(error.localizedDescription)")
        }
        
        print("✅ Successfully imported document: '\(title)'")
        return document
    }
    
    func importDocuments(_ result: Result<[URL], Error>, to modelContext: ModelContext) async throws {
        switch result {
        case .success(let urls):
            var importedCount = 0
            var failedCount = 0
            var errors: [Error] = []
            
            for url in urls {
                do {
                    _ = try await importDocument(from: url, to: modelContext)
                    importedCount += 1
                } catch {
                    failedCount += 1
                    errors.append(error)
                    print("❌ Failed to import \(url.lastPathComponent): \(error)")
                }
            }
            
            print("📊 Import summary: \(importedCount) succeeded, \(failedCount) failed")
            
            if failedCount > 0 && importedCount == 0 {
                // All imports failed
                throw DocumentError.importFailed("Failed to import all \(failedCount) documents")
            }
            
        case .failure(let error):
            throw DocumentError.importFailed("File selection failed: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Document Lookup
    
    func findDocument(byName name: String) -> Document? {
        guard let modelContext = modelContext else { return nil }
        
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        do {
            // Try exact match first
            let exactPredicate = #Predicate<Document> { document in
                document.title == cleanName
            }
            let exactFetch = FetchDescriptor<Document>(predicate: exactPredicate)
            
            if let exactMatch = try modelContext.fetch(exactFetch).first {
                return exactMatch
            }
            
            // Try exact match without .pdf extension using post-fetch filtering
            let nameWithoutPdf = cleanName.hasSuffix(".pdf") ? String(cleanName.dropLast(4)) : cleanName
            
            // Fetch all documents and filter in memory for complex string operations
            let allFetch = FetchDescriptor<Document>()
            let allDocuments = try modelContext.fetch(allFetch)
            
            // Check for exact match without .pdf extension
            for document in allDocuments {
                if document.title == nameWithoutPdf {
                    return document
                }
                // Check if document title without .pdf matches our search
                if document.title.hasSuffix(".pdf") {
                    let docTitleWithoutPdf = String(document.title.dropLast(4))
                    if docTitleWithoutPdf == nameWithoutPdf {
                        return document
                    }
                }
            }
            
            // Try case-insensitive partial match
            for document in allDocuments {
                if document.title.localizedStandardContains(cleanName) {
                    return document
                }
            }
            
            return nil
            
        } catch {
            print("❌ Failed to search for document '\(cleanName)': \(error)")
            return nil
        }
    }
    
    func findDocument(byId id: UUID) -> Document? {
        guard let modelContext = modelContext else { return nil }
        
        do {
            // Optimized: Use predicate to filter by ID at database level
            let predicate = #Predicate<Document> { document in
                document.id == id
            }
            var fetch = FetchDescriptor<Document>(predicate: predicate)
            fetch.fetchLimit = 1 // Only need one result
            
            return try modelContext.fetch(fetch).first
        } catch {
            print("❌ Failed to find document by ID \(id): \(error)")
            return nil
        }
    }
    
    func findDocuments(matching pattern: String) -> [Document] {
        guard let modelContext = modelContext else { return [] }
        
        let cleanPattern = pattern
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        
        guard !cleanPattern.isEmpty else { return [] }
        
        do {
            // Fetch documents and filter in memory since localizedStandardContains is not supported in predicates
            let fetch = FetchDescriptor<Document>(
                sortBy: [SortDescriptor(\.dateAdded, order: .reverse)]
            )
            
            let allDocuments = try modelContext.fetch(fetch)
            
            // Filter in memory using Swift string operations
            let matchingDocuments = allDocuments.filter { document in
                document.title.localizedStandardContains(cleanPattern)
            }
            
            // Return first 20 results for performance
            return Array(matchingDocuments.prefix(20))
            
        } catch {
            print("❌ Failed to search documents with pattern '\(pattern)': \(error)")
            return []
        }
    }
    
    func getAllDocuments() -> [Document] {
        guard let modelContext = modelContext else { return [] }
        
        do {
            // Optimized: Add fetch limit and proper sorting
            var fetch = FetchDescriptor<Document>(
                sortBy: [SortDescriptor(\.dateAdded, order: .reverse)]
            )
            fetch.fetchLimit = 100 // Reasonable limit for UI performance
            
            return try modelContext.fetch(fetch)
        } catch {
            print("❌ Failed to fetch all documents: \(error)")
            return []
        }
    }
    
    // MARK: - Optimized Queries for Performance
    
    /// Get recent documents with limit for better performance
    func getRecentDocuments(limit: Int = 10) -> [Document] {
        guard let modelContext = modelContext else { return [] }
        
        do {
            var fetch = FetchDescriptor<Document>(
                sortBy: [SortDescriptor(\.lastOpened, order: .reverse)]
            )
            fetch.fetchLimit = limit
            
            return try modelContext.fetch(fetch)
        } catch {
            print("❌ Failed to fetch recent documents: \(error)")
            return []
        }
    }
    
    /// Search documents with pagination support
    func searchDocuments(
        query: String, 
        offset: Int = 0, 
        limit: Int = 20
    ) -> [Document] {
        guard let modelContext = modelContext else { return [] }
        
        let cleanQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanQuery.isEmpty else { return [] }
        
        do {
            // Fetch all documents and filter in memory since localizedStandardContains is not supported in predicates
            let fetch = FetchDescriptor<Document>(
                sortBy: [SortDescriptor(\.dateAdded, order: .reverse)]
            )
            
            let allDocuments = try modelContext.fetch(fetch)
            
            // Filter in memory using Swift string operations
            let matchingDocuments = allDocuments.filter { document in
                document.title.localizedStandardContains(cleanQuery)
            }
            
            // Apply pagination manually
            let startIndex = min(offset, matchingDocuments.count)
            let endIndex = min(offset + limit, matchingDocuments.count)
            
            guard startIndex < endIndex else { return [] }
            
            return Array(matchingDocuments[startIndex..<endIndex])
            
        } catch {
            print("❌ Failed to search documents: \(error)")
            return []
        }
    }
    
    // MARK: - Document Management
    
    func deleteDocument(_ document: Document, from modelContext: ModelContext) throws {
        do {
            // Remove the physical file
            if FileManager.default.fileExists(atPath: document.filePath.path) {
                try FileManager.default.removeItem(at: document.filePath)
            }
            
            // Remove from database
            modelContext.delete(document)
            try modelContext.save()
            
            print("✅ Successfully deleted document: '\(document.title)'")
            
        } catch {
            throw DocumentError.deletionFailed("Failed to delete '\(document.title)': \(error.localizedDescription)")
        }
    }
    
    func updateDocumentLastOpened(_ document: Document) {
        guard let modelContext = modelContext else { return }
        
        document.lastOpened = Date()
        
        do {
            try modelContext.save()
        } catch {
            print("❌ Failed to update last opened date for '\(document.title)': \(error)")
        }
    }
    
    // MARK: - Helper Methods
    
    private func generateUniqueFileURL(fileName: String, in directory: URL) throws -> URL {
        var finalURL = directory.appendingPathComponent(fileName)
        var counter = 1
        
        while FileManager.default.fileExists(atPath: finalURL.path) {
            let nameWithoutExt = (fileName as NSString).deletingPathExtension
            let ext = (fileName as NSString).pathExtension
            finalURL = directory.appendingPathComponent("\(nameWithoutExt) \(counter).\(ext)")
            counter += 1
            
            // Prevent infinite loops
            if counter > 1000 {
                throw DocumentError.storageError("Too many duplicate files with name '\(fileName)'")
            }
        }
        
        return finalURL
    }
    
    /// Gets storage statistics for documents
    func getStorageInfo() -> (documentCount: Int, totalSize: Int64) {
        let documents = getAllDocuments()
        var totalSize: Int64 = 0
        
        for document in documents {
            if let attributes = try? FileManager.default.attributesOfItem(atPath: document.filePath.path),
               let fileSize = attributes[.size] as? Int64 {
                totalSize += fileSize
            }
        }
        
        return (documentCount: documents.count, totalSize: totalSize)
    }
    
    /// Validates the integrity of all documents
    func validateDocumentIntegrity() -> [(Document, Error)] {
        let documents = getAllDocuments()
        var errors: [(Document, Error)] = []
        
        for document in documents {
            if !FileManager.default.fileExists(atPath: document.filePath.path) {
                errors.append((document, DocumentError.fileNotFound(document.title)))
            } else {
                do {
                    try pdfService.validatePDF(at: document.filePath)
                } catch {
                    errors.append((document, error))
                }
            }
        }
        
        return errors
    }
} 