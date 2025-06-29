//
//  VectorSearchService.swift
//  cerebral
//
//  Created on 27/11/2024.
//

import Foundation
import SwiftData

enum VectorSearchError: Error {
    case noEmbeddingService
    case vectorDimensionMismatch
    case noQueryEmbedding
    case databaseError(Error)
    case serviceNotInitialized(String)
    case invalidResponse
}

@Observable
final class VectorSearchService {
    private let modelContext: ModelContext
    private let pdfProcessingService: PDFProcessingService
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.pdfProcessingService = PDFProcessingService()
    }
    
    func storeChunks(_ chunks: [DocumentChunkResponse], for document: Document) throws {
        // Convert API response to local models and store
        var documentChunks: [DocumentChunk] = []
        
        for chunkResponse in chunks {
            let chunk = DocumentChunk(from: chunkResponse, document: document)
            documentChunks.append(chunk)
            
            // Store in SwiftData
            modelContext.insert(chunk)
        }
        
        // Update document with chunks
        document.chunks = documentChunks
        document.totalChunks = chunks.count
        
        // Save SwiftData context
        try modelContext.save()
    }
    
    func searchSimilar(to query: String, limit: Int = 5) async throws -> [DocumentChunk] {
        // First, get query embedding from API
        let queryEmbedding = try await pdfProcessingService.getQueryEmbedding(query)
        
        // Perform vector search
        return try await performVectorSearch(embedding: queryEmbedding, limit: limit)
    }
    
    func searchSimilarInDocuments(_ documentIds: [UUID], query: String, limit: Int = 10) async throws -> [DocumentChunk] {
        let queryEmbedding = try await pdfProcessingService.getQueryEmbedding(query)
        let allResults = try await performVectorSearch(embedding: queryEmbedding, limit: limit * 2)
        
        // Filter results to only include chunks from specified documents
        return allResults.filter { chunk in
            guard let document = chunk.document else { return false }
            return documentIds.contains(document.id)
        }.prefix(limit).map { $0 }
    }
    
    func getChunksForDocument(_ documentId: UUID) throws -> [DocumentChunk] {
        // Query SwiftData for chunks belonging to this document
        let descriptor = FetchDescriptor<DocumentChunk>(
            predicate: #Predicate { chunk in
                chunk.document?.id == documentId
            },
            sortBy: [SortDescriptor(\.chunkId)]
        )
        
        return try modelContext.fetch(descriptor)
    }
    
    func getChunk(byId chunkId: UUID) throws -> DocumentChunk? {
        // Query SwiftData for a specific chunk by ID
        let descriptor = FetchDescriptor<DocumentChunk>(
            predicate: #Predicate { chunk in
                chunk.id == chunkId
            }
        )
        
        return try modelContext.fetch(descriptor).first
    }
    
    func getChunks(byIds chunkIds: [UUID]) throws -> [DocumentChunk] {
        // Query SwiftData for multiple chunks by their IDs
        let descriptor = FetchDescriptor<DocumentChunk>(
            predicate: #Predicate { chunk in
                chunkIds.contains(chunk.id)
            }
        )
        
        return try modelContext.fetch(descriptor)
    }
    
    private func performVectorSearch(embedding: [Float], limit: Int) async throws -> [DocumentChunk] {
        // Fetch all chunks (in a production app, you'd want to optimize this)
        let descriptor = FetchDescriptor<DocumentChunk>()
        let allChunks = try modelContext.fetch(descriptor)
        
        // Calculate cosine similarity for each chunk
        var similarities: [(chunk: DocumentChunk, similarity: Float)] = []
        
        for chunk in allChunks {
            let similarity = cosineSimilarity(embedding, chunk.embedding)
            similarities.append((chunk: chunk, similarity: similarity))
        }
        
        // Sort by similarity (descending) and return top results
        return similarities
            .sorted { $0.similarity > $1.similarity }
            .prefix(limit)
            .map { $0.chunk }
    }
    
    private func cosineSimilarity(_ a: [Float], _ b: [Float]) -> Float {
        guard a.count == b.count else { return 0 }
        
        let dotProduct = zip(a, b).map { $0 * $1 }.reduce(0, +)
        let magnitudeA = sqrt(a.map { $0 * $0 }.reduce(0, +))
        let magnitudeB = sqrt(b.map { $0 * $0 }.reduce(0, +))
        
        guard magnitudeA > 0 && magnitudeB > 0 else { return 0 }
        
        return dotProduct / (magnitudeA * magnitudeB)
    }
    
    // Helper method to clear all chunks for a document (useful for reprocessing)
    func clearChunksForDocument(_ documentId: UUID) throws {
        let chunks = try getChunksForDocument(documentId)
        
        print("🗑️ Clearing \(chunks.count) chunks from vector database for document ID: \(documentId)")
        
        for chunk in chunks {
            // Remove from SwiftData
            modelContext.delete(chunk)
        }
        
        try modelContext.save()
        
        if !chunks.isEmpty {
            print("✅ Successfully cleared \(chunks.count) chunks from vector database")
        } else {
            print("ℹ️ No chunks found to clear for document ID: \(documentId)")
        }
    }
    
    // Method specifically for cleaning up chunks when a document is being deleted
    func deleteChunksForDocument(_ documentId: UUID) throws -> Int {
        let chunks = try getChunksForDocument(documentId)
        let chunkCount = chunks.count
        
        if chunkCount > 0 {
            print("🗑️ Deleting \(chunkCount) vector chunks for document deletion")
            
            for chunk in chunks {
                modelContext.delete(chunk)
            }
            
            try modelContext.save()
            print("✅ Successfully deleted \(chunkCount) vector chunks")
        } else {
            print("ℹ️ No vector chunks found to delete for document ID: \(documentId)")
        }
        
        return chunkCount
    }
    
    // Batch processing for multiple documents
    func processDocumentBatch(_ documents: [Document]) async throws {
        for document in documents {
            do {
                document.processingStatus = .processing
                let response = try await pdfProcessingService.processPDF(document: document)
                try storeChunks(response.chunks, for: document)
                document.processingStatus = .completed
                document.documentTitle = response.documentTitle
            } catch {
                document.processingStatus = .failed
                print("Failed to process document \(document.title): \(error)")
            }
        }
        
        try modelContext.save()
    }
    
    // Get processing statistics
    func getProcessingStats() throws -> (total: Int, processed: Int, pending: Int, failed: Int) {
        let descriptor = FetchDescriptor<Document>()
        let documents = try modelContext.fetch(descriptor)
        
        let total = documents.count
        let processed = documents.filter { $0.processingStatus == .completed }.count
        let pending = documents.filter { $0.processingStatus == .pending }.count
        let failed = documents.filter { $0.processingStatus == .failed }.count
        
        return (total: total, processed: processed, pending: pending, failed: failed)
    }
} 