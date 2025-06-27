//
//  AppErrors.swift
//  cerebral
//
//  Created by Assistant on 26/06/2025.
//

import Foundation

// MARK: - Main App Error

enum AppError: LocalizedError {
    case apiKeyInvalid
    case networkFailure(String)
    case documentImportFailed(String)
    case chatServiceUnavailable
    case settingsError(SettingsError)
    case documentError(DocumentError)
    case chatError(ChatError)
    case pdfError(PDFError)
    
    var errorDescription: String? {
        switch self {
        case .apiKeyInvalid:
            return "Invalid API key. Please check your Claude API key in Settings."
        case .networkFailure(let message):
            return "Network error: \(message)"
        case .documentImportFailed(let message):
            return "Failed to import document: \(message)"
        case .chatServiceUnavailable:
            return "Chat service is currently unavailable. Please try again later."
        case .settingsError(let settingsError):
            return settingsError.errorDescription
        case .documentError(let documentError):
            return documentError.errorDescription
        case .chatError(let chatError):
            return chatError.errorDescription
        case .pdfError(let pdfError):
            return pdfError.errorDescription
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .apiKeyInvalid:
            return "Go to Settings and enter a valid Claude API key."
        case .networkFailure:
            return "Check your internet connection and try again."
        case .documentImportFailed:
            return "Ensure the file is a valid PDF and try importing again."
        case .chatServiceUnavailable:
            return "Wait a moment and try sending your message again."
        case .settingsError(let settingsError):
            return settingsError.recoverySuggestion
        case .documentError(let documentError):
            return documentError.recoverySuggestion
        case .chatError(let chatError):
            return chatError.recoverySuggestion
        case .pdfError(let pdfError):
            return pdfError.recoverySuggestion
        }
    }
    
    /// Error severity level for determining how to handle the error
    var severity: ErrorSeverity {
        switch self {
        case .apiKeyInvalid, .settingsError(.invalidAPIKey), .chatError(.noAPIKey):
            return .critical
        case .networkFailure, .chatServiceUnavailable, .chatError(.connectionFailed):
            return .high
        case .documentImportFailed, .documentError(.importFailed), .documentError(.invalidFormat):
            return .medium
        case .pdfError(.textExtractionFailed), .pdfError(.thumbnailGenerationFailed):
            return .low
        default:
            return .medium
        }
    }
    
    /// Whether this error can be automatically retried
    var isRetryable: Bool {
        switch self {
        case .networkFailure, .chatServiceUnavailable, .chatError(.connectionFailed), .chatError(.requestFailed), .chatError(.rateLimitExceeded):
            return true
        default:
            return false
        }
    }
    
    /// Whether this error requires user action to resolve
    var requiresUserAction: Bool {
        switch self {
        case .apiKeyInvalid, .settingsError(.invalidAPIKey), .chatError(.noAPIKey):
            return true
        default:
            return false
        }
    }
}

// MARK: - Error Severity

enum ErrorSeverity {
    case low        // Minor issues that don't prevent core functionality
    case medium     // Issues that affect some features
    case high       // Issues that affect major functionality
    case critical   // Issues that prevent core app functionality
    
    var displayPriority: Int {
        switch self {
        case .low: return 1
        case .medium: return 2
        case .high: return 3
        case .critical: return 4
        }
    }
}

// MARK: - Chat Errors

enum ChatError: LocalizedError {
    case noAPIKey
    case connectionFailed(String)
    case requestFailed(String)
    case invalidResponse(String)
    case streamingFailed(String)
    case messageProcessingFailed(String)
    case contextTooLarge
    case rateLimitExceeded
    
    var errorDescription: String? {
        switch self {
        case .noAPIKey:
            return "No API key configured. Please add your Claude API key in Settings."
        case .connectionFailed(let message):
            return "Connection failed: \(message)"
        case .requestFailed(let message):
            return "Request failed: \(message)"
        case .invalidResponse(let message):
            return "Invalid response from Claude API: \(message)"
        case .streamingFailed(let message):
            return "Streaming failed: \(message)"
        case .messageProcessingFailed(let message):
            return "Failed to process message: \(message)"
        case .contextTooLarge:
            return "The document context is too large. Try with fewer or smaller documents."
        case .rateLimitExceeded:
            return "API rate limit exceeded. Please wait a moment before trying again."
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .noAPIKey:
            return "Go to Settings → API Key and enter your Claude API key."
        case .connectionFailed:
            return "Check your internet connection and API key, then try again."
        case .requestFailed, .invalidResponse, .streamingFailed, .messageProcessingFailed:
            return "Please try again. If the problem persists, check your API key."
        case .contextTooLarge:
            return "Remove some documents from your selection or try with shorter documents."
        case .rateLimitExceeded:
            return "Wait a few seconds and try again."
        }
    }
}

// MARK: - Document Errors

enum DocumentError: LocalizedError {
    case importFailed(String)
    case fileNotFound(String)
    case invalidFormat(String)
    case accessDenied(String)
    case duplicateDocument(String)
    case storageError(String)
    case searchFailed(String)
    case deletionFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .importFailed(let message):
            return "Failed to import document: \(message)"
        case .fileNotFound(let filename):
            return "File not found: \(filename)"
        case .invalidFormat(let filename):
            return "Invalid file format for: \(filename). Only PDF files are supported."
        case .accessDenied(let filename):
            return "Access denied to file: \(filename)"
        case .duplicateDocument(let filename):
            return "Document already exists: \(filename)"
        case .storageError(let message):
            return "Storage error: \(message)"
        case .searchFailed(let message):
            return "Search failed: \(message)"
        case .deletionFailed(let message):
            return "Failed to delete document: \(message)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .importFailed:
            return "Ensure the file is a valid PDF and try again."
        case .fileNotFound:
            return "Make sure the file exists and hasn't been moved or deleted."
        case .invalidFormat:
            return "Convert the file to PDF format before importing."
        case .accessDenied:
            return "Check file permissions and try again."
        case .duplicateDocument:
            return "The document is already in your library."
        case .storageError:
            return "Check available storage space and try again."
        case .searchFailed:
            return "Try a different search term or check your search syntax."
        case .deletionFailed:
            return "Make sure the document is not in use and try again."
        }
    }
}

// MARK: - PDF Errors

enum PDFError: LocalizedError {
    case failedToLoad(String)
    case textExtractionFailed(String)
    case thumbnailGenerationFailed(String)
    case invalidPageIndex(Int)
    case metadataExtractionFailed(String)
    case renderingFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .failedToLoad(let filename):
            return "Failed to load PDF: \(filename)"
        case .textExtractionFailed(let filename):
            return "Failed to extract text from: \(filename)"
        case .thumbnailGenerationFailed(let filename):
            return "Failed to generate thumbnail for: \(filename)"
        case .invalidPageIndex(let pageIndex):
            return "Invalid page index: \(pageIndex)"
        case .metadataExtractionFailed(let filename):
            return "Failed to extract metadata from: \(filename)"
        case .renderingFailed(let filename):
            return "Failed to render PDF: \(filename)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .failedToLoad:
            return "Ensure the PDF file is not corrupted and try again."
        case .textExtractionFailed:
            return "The PDF might be image-based or corrupted. Try with a different PDF."
        case .thumbnailGenerationFailed:
            return "The PDF might be corrupted. Try importing a different PDF."
        case .invalidPageIndex:
            return "Check that the page number is valid for this document."
        case .metadataExtractionFailed:
            return "The PDF metadata might be corrupted, but the document should still work."
        case .renderingFailed:
            return "Try closing and reopening the document."
        }
    }
}

// MARK: - Settings Errors

enum SettingsError: LocalizedError {
    case invalidAPIKey(String)
    case keychainAccessFailed(String)
    case validationFailed(String)
    case configurationError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidAPIKey(let message):
            return "Invalid API key: \(message)"
        case .keychainAccessFailed(let message):
            return "Keychain access failed: \(message)"
        case .validationFailed(let message):
            return "Settings validation failed: \(message)"
        case .configurationError(let message):
            return "Configuration error: \(message)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .invalidAPIKey:
            return "Enter a valid Claude API key that starts with 'sk-ant-'."
        case .keychainAccessFailed:
            return "Check your system keychain access and try again."
        case .validationFailed:
            return "Check your settings and try again."
        case .configurationError:
            return "Reset your settings and reconfigure the application."
        }
    }
} 