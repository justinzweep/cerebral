//
//  DocumentLookupService.swift
//  cerebral
//
//  Created by Justin Zweep on 26/06/2025.
//

import Foundation
import SwiftData

@MainActor
class DocumentLookupService {
    static let shared = DocumentLookupService()
    
    private var modelContext: ModelContext?
    
    private init() {}
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }
    
    func findDocument(byName name: String) -> Document? {
        guard let modelContext = modelContext else { return nil }
        
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Get all documents and filter in memory since SwiftData predicates don't support all string methods
        let fetch = FetchDescriptor<Document>()
        
        guard let allDocuments = try? modelContext.fetch(fetch) else { return nil }
        
        // Try exact match first
        if let exactMatch = allDocuments.first(where: { $0.title == cleanName }) {
            return exactMatch
        }
        
        // Try case-insensitive partial match
        let lowercaseName = cleanName.lowercased()
        return allDocuments.first { document in
            document.title.lowercased().contains(lowercaseName)
        }
    }
    
    func findDocuments(matching pattern: String) -> [Document] {
        guard let modelContext = modelContext else { return [] }
        
        let cleanPattern = pattern
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        
        // Get all documents and filter in memory
        let fetch = FetchDescriptor<Document>()
        
        guard let allDocuments = try? modelContext.fetch(fetch) else { return [] }
        
        return allDocuments.filter { document in
            document.title.lowercased().contains(cleanPattern)
        }
    }
    
    func getAllDocuments() -> [Document] {
        guard let modelContext = modelContext else { return [] }
        
        let fetch = FetchDescriptor<Document>(
            sortBy: [SortDescriptor(\.dateAdded, order: .reverse)]
        )
        
        return (try? modelContext.fetch(fetch)) ?? []
    }
} 