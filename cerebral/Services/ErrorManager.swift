//
//  ErrorManager.swift
//  cerebral
//
//  Created by Assistant on 26/06/2025.
//

import Foundation
import SwiftUI

// MARK: - Error Manager

@Observable
final class ErrorManager {
    var currentError: cerebral.AppError?
    var showingError: Bool = false
    private var errorHistory: [ErrorLogEntry] = []
    private var retryAttempts: [String: Int] = [:]
    
    func handle(_ error: Error, context: String = "") {
        DispatchQueue.main.async { [weak self] in
            let appError = self?.convertToAppError(error)
            
            // Log error for debugging and analytics
            let logEntry = ErrorLogEntry(
                error: appError ?? cerebral.AppError.networkFailure("Unknown error"),
                context: context,
                timestamp: Date()
            )
            self?.errorHistory.append(logEntry)
            
            // Only show error if it's severe enough or requires user action
            if let appError = appError {
                switch appError.severity {
                case .critical, .high:
                    self?.showError(appError)
                case .medium:
                    // Show medium errors unless they've been retried too many times
                    let errorKey = self?.errorKey(for: appError) ?? ""
                    let attempts = self?.retryAttempts[errorKey] ?? 0
                    if attempts > 2 {
                        self?.showError(appError)
                    } else {
                        self?.logError(appError, context: context)
                    }
                case .low:
                    // Just log low-severity errors
                    self?.logError(appError, context: context)
                }
            }
        }
    }
    
    func clearError() {
        currentError = nil
        showingError = false
    }
    
    func attemptRetry(for error: cerebral.AppError) {
        let errorKey = errorKey(for: error)
        let currentAttempts = retryAttempts[errorKey] ?? 0
        retryAttempts[errorKey] = currentAttempts + 1
        
        // Clear the current error since we're retrying
        clearError()
    }
    
    // MARK: - Private Methods
    
    private func convertToAppError(_ error: Error) -> cerebral.AppError? {
        if let appError = error as? cerebral.AppError {
            return appError
        } else if let documentError = error as? DocumentError {
            return cerebral.AppError.documentError(documentError)
        } else if let chatError = error as? ChatError {
            return cerebral.AppError.chatError(chatError)
        } else if let pdfError = error as? PDFError {
            return cerebral.AppError.pdfError(pdfError)
        } else if let settingsError = error as? SettingsError {
            return cerebral.AppError.settingsError(settingsError)
        } else {
            // For unknown errors, wrap in a network failure
            return cerebral.AppError.networkFailure(error.localizedDescription)
        }
    }
    
    private func showError(_ error: cerebral.AppError) {
        currentError = error
        showingError = true
    }
    
    private func logError(_ error: cerebral.AppError, context: String) {
        let severity = error.severity
        let prefix = severityPrefix(for: severity)
        print("\(prefix) Error [\(context.isEmpty ? "Unknown" : context)]: \(error.localizedDescription)")
    }
    
    private func errorKey(for error: cerebral.AppError) -> String {
        switch error {
        case .apiKeyInvalid:
            return "api_key_invalid"
        case .networkFailure:
            return "network_failure"
        case .documentImportFailed:
            return "document_import_failed"
        case .chatServiceUnavailable:
            return "chat_service_unavailable"
        case .settingsError(let settingsError):
            return "settings_\(settingsError)"
        case .documentError(let documentError):
            return "document_\(documentError)"
        case .chatError(let chatError):
            return "chat_\(chatError)"
        case .pdfError(let pdfError):
            return "pdf_\(pdfError)"
        }
    }
    
    private func severityPrefix(for severity: ErrorSeverity) -> String {
        switch severity {
        case .low: return "ℹ️"
        case .medium: return "⚠️"
        case .high: return "❌"
        case .critical: return "🚨"
        }
    }
}

// MARK: - Error Log Entry

private struct ErrorLogEntry {
    let error: cerebral.AppError
    let context: String
    let timestamp: Date
} 