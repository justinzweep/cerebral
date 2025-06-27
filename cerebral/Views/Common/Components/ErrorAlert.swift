//
//  ErrorAlert.swift
//  cerebral
//
//  Centralized Error Alert Component
//

import SwiftUI

/// Reusable error alert component with recovery suggestions and actions
struct ErrorAlert: View {
    let error: AppError
    let onDismiss: () -> Void
    let onRetry: (() -> Void)?
    let onOpenSettings: (() -> Void)?
    
    init(
        error: AppError,
        onDismiss: @escaping () -> Void,
        onRetry: (() -> Void)? = nil,
        onOpenSettings: (() -> Void)? = nil
    ) {
        self.error = error
        self.onDismiss = onDismiss
        self.onRetry = onRetry
        self.onOpenSettings = onOpenSettings
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            // Error Title and Icon
            HStack(spacing: DesignSystem.Spacing.sm) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(DesignSystem.Colors.error)
                    .font(.system(size: 20, weight: .medium))
                
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text("Error")
                        .font(DesignSystem.Typography.headline)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                    
                    if let description = error.errorDescription {
                        Text(description)
                            .font(DesignSystem.Typography.body)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                
                Spacer()
            }
            
            // Recovery Suggestion
            if let suggestion = error.recoverySuggestion {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text("How to fix:")
                        .font(DesignSystem.Typography.caption)
                        .fontWeight(.medium)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                    
                    Text(suggestion)
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(DesignSystem.Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button)
                        .fill(DesignSystem.Colors.tertiaryBackground)
                )
            }
            
            // Action Buttons
            HStack(spacing: DesignSystem.Spacing.sm) {
                Spacer()
                
                // Settings Button (for API key and configuration errors)
                if needsSettingsAction && onOpenSettings != nil {
                    Button("Open Settings") {
                        onOpenSettings?()
                        onDismiss()
                    }
                    .buttonStyle(.borderedProminent)
                }
                
                // Retry Button (for network and recoverable errors)
                if needsRetryAction && onRetry != nil {
                    Button("Retry") {
                        onRetry?()
                        onDismiss()
                    }
                    .buttonStyle(.bordered)
                }
                
                // Dismiss Button
                Button("Dismiss") {
                    onDismiss()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(DesignSystem.Spacing.lg)
        .frame(maxWidth: 400)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                .fill(DesignSystem.Colors.background)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
    }
    
    // MARK: - Helper Properties
    
    private var needsSettingsAction: Bool {
        switch error {
        case .apiKeyInvalid, .settingsError(.invalidAPIKey), .settingsError(.keychainAccessFailed), .chatError(.noAPIKey):
            return true
        default:
            return false
        }
    }
    
    private var needsRetryAction: Bool {
        switch error {
        case .networkFailure, .chatServiceUnavailable, .chatError(.connectionFailed), .chatError(.requestFailed), .chatError(.rateLimitExceeded):
            return true
        default:
            return false
        }
    }
}

// MARK: - Alert Modifier

extension View {
    func errorAlert(
        isPresented: Binding<Bool>,
        error: AppError?,
        onRetry: (() -> Void)? = nil,
        onOpenSettings: (() -> Void)? = nil
    ) -> some View {
        self.alert(
            "Error",
            isPresented: isPresented,
            presenting: error
        ) { error in
            // Settings Button
            if needsSettingsAction(for: error) && onOpenSettings != nil {
                Button("Open Settings") {
                    onOpenSettings?()
                }
            }
            
            // Retry Button
            if needsRetryAction(for: error) && onRetry != nil {
                Button("Retry") {
                    onRetry?()
                }
            }
            
            // Dismiss Button
            Button("OK") { }
        } message: { error in
            VStack(alignment: .leading, spacing: 8) {
                if let description = error.errorDescription {
                    Text(description)
                }
                
                if let suggestion = error.recoverySuggestion {
                    Text("How to fix: \(suggestion)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private func needsSettingsAction(for error: AppError) -> Bool {
        switch error {
        case .apiKeyInvalid, .settingsError(.invalidAPIKey), .settingsError(.keychainAccessFailed), .chatError(.noAPIKey):
            return true
        default:
            return false
        }
    }
    
    private func needsRetryAction(for error: AppError) -> Bool {
        switch error {
        case .networkFailure, .chatServiceUnavailable, .chatError(.connectionFailed), .chatError(.requestFailed), .chatError(.rateLimitExceeded):
            return true
        default:
            return false
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        ErrorAlert(
            error: .chatError(.noAPIKey),
            onDismiss: {},
            onOpenSettings: {}
        )
        
        ErrorAlert(
            error: .networkFailure("Connection timeout"),
            onDismiss: {},
            onRetry: {}
        )
        
        ErrorAlert(
            error: .documentError(.importFailed("Invalid PDF format")),
            onDismiss: {}
        )
    }
    .padding()
    .background(DesignSystem.Colors.secondaryBackground)
} 