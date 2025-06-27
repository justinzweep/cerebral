//
//  FileImportService.swift
//  cerebral
//
//  Created by Justin Zweep on 26/06/2025.
//

import Foundation
import SwiftData

@MainActor
final class FileImportService {
    static let shared = FileImportService()
    
    private init() {}
    
    // MARK: - Public Methods
    
    func importDocuments(_ result: Result<[URL], Error>, to modelContext: ModelContext) {
        switch result {
        case .success(let urls):
            for url in urls {
                importDocument(from: url, to: modelContext)
            }
        case .failure(let error):
            print("Error importing documents: \(error)")
        }
    }
    
    // MARK: - Private Methods
    
    private func importDocument(from url: URL, to modelContext: ModelContext) {
        guard url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }
        
        // Create documents directory if it doesn't exist
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let cerebralDocsPath = documentsPath.appendingPathComponent("Cerebral Documents")
        try? FileManager.default.createDirectory(at: cerebralDocsPath, withIntermediateDirectories: true)
        
        // Copy file to app's documents directory
        let fileName = url.lastPathComponent
        let destinationURL = cerebralDocsPath.appendingPathComponent(fileName)
        
        // Handle duplicates by appending a number
        var finalURL = destinationURL
        var counter = 1
        while FileManager.default.fileExists(atPath: finalURL.path) {
            let nameWithoutExt = (fileName as NSString).deletingPathExtension
            let ext = (fileName as NSString).pathExtension
            finalURL = cerebralDocsPath.appendingPathComponent("\(nameWithoutExt) \(counter).\(ext)")
            counter += 1
        }
        
        do {
            try FileManager.default.copyItem(at: url, to: finalURL)
            
            // Create document model
            let title = finalURL.deletingPathExtension().lastPathComponent
            let document = Document(title: title, filePath: finalURL)
            modelContext.insert(document)
            
            try modelContext.save()
        } catch {
            print("Error importing document: \(error)")
        }
    }
} 