//
//  SettingsViews.swift
//  cerebral
//
//  Redesigned Settings Views with Professional Design
//

import SwiftUI

// MARK: - API Key Settings View

struct APIKeySettingsView: View {
    @Environment(SettingsManager.self) var settingsManager: SettingsManager
    @State private var tempAPIKey: String = ""
    @State private var isEditingAPIKey: Bool = false
    @State private var showingAPIKeyConfirmation: Bool = false
    @FocusState private var isAPIKeyFocused: Bool
    
    var body: some View {
        SettingsContentView(
            title: "API Key",
            subtitle: "Configure Claude API integration",
            icon: "key.fill"
        ) {
            VStack(spacing: DesignSystem.Spacing.xl) {
                // API Key Configuration Section
                SettingsSection(
                    title: "Claude API Key",
                    subtitle: "Your API key is stored securely in the system keychain"
                ) {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                        // API Key Input/Display
                        if isEditingAPIKey {
                            APIKeyInputField(
                                tempAPIKey: $tempAPIKey,
                                isValid: settingsManager.validateAPIKey(tempAPIKey),
                                onSave: saveAPIKey,
                                onCancel: cancelEditing
                            )
                            .focused($isAPIKeyFocused)
                        } else {
                            APIKeyDisplay(
                                hasKey: !settingsManager.apiKey.isEmpty,
                                onEdit: startEditing,
                                onRemove: { showingAPIKeyConfirmation = true }
                            )
                        }
                        
                        // Error Display
                        if let error = settingsManager.lastError {
                            ErrorMessage(error: error)
                        }
                    }
                }
            }
        }
        .onAppear {
            tempAPIKey = settingsManager.apiKey
        }
        .confirmationDialog(
            "Remove API Key",
            isPresented: $showingAPIKeyConfirmation,
            titleVisibility: .visible
        ) {
            Button("Remove", role: .destructive) {
                removeAPIKey()
            }
            Button("Cancel", role: .cancel) { }  
        } message: {
            Text("Are you sure you want to remove your Claude API key? This will disable AI chat functionality.")
        }
    }
    
    // MARK: - Actions
    
    private func startEditing() {
        tempAPIKey = settingsManager.apiKey
        isEditingAPIKey = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            isAPIKeyFocused = true
        }
    }
    
    private func cancelEditing() {
        tempAPIKey = settingsManager.apiKey
        isEditingAPIKey = false
        isAPIKeyFocused = false
    }
    
    private func saveAPIKey() {
        guard settingsManager.validateAPIKey(tempAPIKey) else { return }
        
        do {
            try settingsManager.saveAPIKey(tempAPIKey)
            isEditingAPIKey = false
            isAPIKeyFocused = false
        } catch {
            ServiceContainer.shared.errorManager.handle(error, context: "api_key_save")
        }
    }
    
    private func removeAPIKey() {
        do {
            try settingsManager.deleteAPIKey()
        } catch {
            ServiceContainer.shared.errorManager.handle(error, context: "api_key_delete")
        }
    }
}

// MARK: - API Key Input Field

struct APIKeyInputField: View {
    @Binding var tempAPIKey: String
    let isValid: Bool
    let onSave: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            // Input Field
            SecureField("sk-ant-...", text: $tempAPIKey)
                .font(.system(.body, design: .monospaced))
                .padding(.horizontal, DesignSystem.Spacing.md)
                .padding(.vertical, DesignSystem.Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.input)
                        .fill(DesignSystem.Colors.background)
                        .stroke(borderColor, lineWidth: 1)
                )
                .onSubmit {
                    if isValid {
                        onSave()
                    }
                }
            
            // Validation Message
            if !tempAPIKey.isEmpty && !isValid {
                HStack(spacing: DesignSystem.Spacing.xs) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.error)
                    
                    Text("Invalid API key format. Should start with 'sk-ant-'")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.error)
                }
            }
            
            // Action Buttons
            HStack(spacing: DesignSystem.Spacing.sm) {
                Button("Save", action: onSave)
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(!isValid)
                
                Button("Cancel", action: onCancel)
                    .buttonStyle(SecondaryButtonStyle())
                
                Spacer()
            }
        }
    }
    
    private var borderColor: Color {
        if !tempAPIKey.isEmpty && !isValid {
            return DesignSystem.Colors.borderError
        } else {
            return DesignSystem.Colors.border
        }
    }
}

// MARK: - API Key Display

struct APIKeyDisplay: View {
    let hasKey: Bool
    let onEdit: () -> Void
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            // Key Display
            VStack(alignment: .leading, spacing: 4) {
                Text(hasKey ? "API Key Configured" : "No API Key Set")
                    .font(DesignSystem.Typography.body)
                    .fontWeight(.medium)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                
                if hasKey {
                    Text("••••••••••••••••••••••••••••••••••••")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
            }
            
            Spacer()
            
            // Action Buttons
            HStack(spacing: DesignSystem.Spacing.xs) {
                Button(hasKey ? "Edit" : "Add") {
                    onEdit()
                }
                .buttonStyle(SecondaryButtonStyle())
                
                if hasKey {
                    Button("Remove") {
                        onRemove()
                    }
                    .buttonStyle(DestructiveButtonStyle())
                }
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.input)
                .fill(DesignSystem.Colors.secondaryBackground)
                .stroke(DesignSystem.Colors.border, lineWidth: 0.5)
        )
    }
}

// MARK: - Error Message Component

struct ErrorMessage: View {
    let error: String
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.xs) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.error)
            
            Text(error)
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.error)
        }
        .padding(DesignSystem.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                .fill(DesignSystem.Colors.error.opacity(0.1))
                .stroke(DesignSystem.Colors.error.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Previews

#Preview("API Key Settings") {
    APIKeySettingsView()
        .environment(SettingsManager.shared)
        .frame(width: 640, height: 480)
} 