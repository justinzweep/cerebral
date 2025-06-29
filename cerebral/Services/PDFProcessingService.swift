//
//  PDFProcessingService.swift
//  cerebral
//
//  Created on 27/11/2024.
//

import Foundation

enum ProcessingError: Error {
    case invalidFilePath
    case serverError
    case networkError(Error)
    case decodingError(Error)
    case invalidResponse
}

@Observable
final class PDFProcessingService {
    private let baseURL = "http://localhost:8000"
    
    func processPDF(document: Document) async throws -> ProcessedDocumentResponse {
        guard let fileURL = document.filePath else {
            throw ProcessingError.invalidFilePath
        }
        
        let url = URL(string: "\(baseURL)/process-pdf")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // Set longer timeout for PDF processing (5 minutes)
        request.timeoutInterval = 300.0
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        let body = try createMultipartBody(
            fileURL: fileURL,
            documentUUID: document.id.uuidString,
            boundary: boundary
        )
        
        request.httpBody = body
        
        // Create custom URLSession with longer timeout
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = 300.0  // 5 minutes
        sessionConfig.timeoutIntervalForResource = 600.0  // 10 minutes
        let session = URLSession(configuration: sessionConfig)
        
        do {
            print("🔄 Starting PDF processing for '\(document.title)' - this may take several minutes...")
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw ProcessingError.invalidResponse
            }
            
            guard httpResponse.statusCode == 200 else {
                print("❌ Server returned status code: \(httpResponse.statusCode)")
                if let responseString = String(data: data, encoding: .utf8) {
                    print("❌ Server response: \(responseString)")
                }
                throw ProcessingError.serverError
            }
            
            // Debug: Print raw response
            if let responseString = String(data: data, encoding: .utf8) {
                print("📋 Raw API Response (first 500 chars): \(String(responseString.prefix(500)))")
            }
            
            // Try to decode the response
            let decoder = JSONDecoder()
            let result = try decoder.decode(ProcessedDocumentResponse.self, from: data)
            print("✅ Successfully processed PDF with \(result.totalChunks) chunks")
            return result
            
        } catch let decodingError as DecodingError {
            print("❌ JSON Decoding Error Details:")
            switch decodingError {
            case .dataCorrupted(let context):
                print("  - Data corrupted: \(context.debugDescription)")
                print("  - Context: \(context)")
            case .keyNotFound(let key, let context):
                print("  - Key '\(key.stringValue)' not found")
                print("  - Context: \(context.debugDescription)")
            case .typeMismatch(let type, let context):
                print("  - Type mismatch for type \(type)")
                print("  - Context: \(context.debugDescription)")
            case .valueNotFound(let type, let context):
                print("  - Value not found for type \(type)")
                print("  - Context: \(context.debugDescription)")
            @unknown default:
                print("  - Unknown decoding error: \(decodingError)")
            }
            throw ProcessingError.decodingError(decodingError)
        } catch let processingError as ProcessingError {
            throw processingError
        } catch {
            throw ProcessingError.networkError(error)
        }
    }
    
    private func createMultipartBody(fileURL: URL, documentUUID: String, boundary: String) throws -> Data {
        var body = Data()
        
        // Add document UUID field
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"document_uuid\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(documentUUID)\r\n".data(using: .utf8)!)
        
        // Add file field
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileURL.lastPathComponent)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: application/pdf\r\n\r\n".data(using: .utf8)!)
        
        // Add file data
        let fileData = try Data(contentsOf: fileURL)
        body.append(fileData)
        body.append("\r\n".data(using: .utf8)!)
        
        // Close boundary
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        return body
    }
    
    // Helper method to get query embedding for search using /embed-text endpoint
    func getQueryEmbedding(_ query: String) async throws -> [Float] {
        let url = URL(string: "\(baseURL)/embed-text")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Use the proper EmbeddingRequest structure with input_type="query"
        let embeddingRequest = EmbeddingRequest(text: query, inputType: "query")
        
        do {
            let encoder = JSONEncoder()
            request.httpBody = try encoder.encode(embeddingRequest)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                throw ProcessingError.serverError
            }
            
            let decoder = JSONDecoder()
            let embeddingResponse = try decoder.decode(EmbeddingResponse.self, from: data)
            
            guard embeddingResponse.success else {
                throw ProcessingError.serverError
            }
            
            print("🔍 Generated query embedding with \(embeddingResponse.embedding.count) dimensions using \(embeddingResponse.modelInfo.model)")
            
            return embeddingResponse.embedding
        } catch let processingError as ProcessingError {
            throw processingError
        } catch {
            throw ProcessingError.networkError(error)
        }
    }
    
    // Health check for processing server
    func checkServerHealth() async -> Bool {
        let url = URL(string: "\(baseURL)/health")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 5.0 // Quick health check
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse {
                return httpResponse.statusCode == 200
            }
            return false
        } catch {
            return false
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case embedding
    }
} 