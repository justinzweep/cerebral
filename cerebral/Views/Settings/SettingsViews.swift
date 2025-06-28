//
//  SettingsViews.swift
//  cerebral
//
//  Consolidated Settings Views
//

import SwiftUI

// MARK: - API Key Settings View

struct APIKeySettingsView: View {
    @Environment(SettingsManager.self) var settingsManager: SettingsManager
    @State private var tempAPIKey: String = ""
    @State private var isEditingAPIKey: Bool = false
    @State private var showingAPIKeyConfirmation: Bool = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                // Header
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    Text("API Key Configuration")
                        .font(DesignSystem.Typography.headline)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                    
                    Text("Configure your Claude API key for AI chat functionality.")
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
                
                // API Key Configuration
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Claude API Key")
                                .font(DesignSystem.Typography.body)
                                .foregroundColor(DesignSystem.Colors.primaryText)
                            
                            Text("Required for AI chat functionality")
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                        }
                        
                        Spacer()
                        
                        if settingsManager.isAPIKeyValid {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(DesignSystem.Colors.success)
                        }
                    }
                    
                    if isEditingAPIKey {
                        SecureField("sk-ant-...", text: $tempAPIKey)
                            .textFieldStyle(.roundedBorder)
                        
                        HStack {
                            Button("Save") {
                                if settingsManager.validateAPIKey(tempAPIKey) {
                                    do {
                                        try settingsManager.saveAPIKey(tempAPIKey)
                                        isEditingAPIKey = false
                                    } catch {
                                        ServiceContainer.shared.errorManager.handle(error, context: "api_key_save")
                                    }
                                }
                            }
                            .disabled(!settingsManager.validateAPIKey(tempAPIKey))
                            
                            Button("Cancel") {
                                tempAPIKey = settingsManager.apiKey
                                isEditingAPIKey = false
                            }
                        }
                        
                        if !settingsManager.validateAPIKey(tempAPIKey) && !tempAPIKey.isEmpty {
                            Text("Invalid API key format")
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(DesignSystem.Colors.error)
                        }
                    } else {
                        HStack {
                            Text(settingsManager.apiKey.isEmpty ? "No API key set" : "••••••••••••••••••••")
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(settingsManager.apiKey.isEmpty ? DesignSystem.Colors.secondaryText : DesignSystem.Colors.primaryText)
                            
                            Spacer()
                            
                            Button(settingsManager.apiKey.isEmpty ? "Add" : "Edit") {
                                tempAPIKey = settingsManager.apiKey
                                isEditingAPIKey = true
                            }
                            
                            if !settingsManager.apiKey.isEmpty {
                                Button("Remove") {
                                    showingAPIKeyConfirmation = true
                                }
                                .foregroundColor(DesignSystem.Colors.error)
                            }
                        }
                    }
                    
                    if let error = settingsManager.lastError {
                        Text(error)
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.error)
                    }
                }
                .padding(DesignSystem.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                        .fill(DesignSystem.Colors.secondaryBackground)
                )
                
                Spacer()
            }
            .padding(DesignSystem.Spacing.lg)
        }
        .onAppear {
            tempAPIKey = settingsManager.apiKey
        }
        .onReceive(NotificationCenter.default.publisher(for: .escapeKeyPressed)) { notification in
            if let context = notification.userInfo?["context"] as? String, 
               context == "apikey",
               isEditingAPIKey {
                // Cancel editing mode
                tempAPIKey = settingsManager.apiKey
                isEditingAPIKey = false
            }
        }

        .confirmationDialog("Remove API Key", isPresented: $showingAPIKeyConfirmation) {
            Button("Remove", role: .destructive) {
                do {
                    try settingsManager.deleteAPIKey()
                                    } catch {
                        ServiceContainer.shared.errorManager.handle(error, context: "api_key_delete")
                    }
            }
        } message: {
            Text("Are you sure you want to remove your Claude API key?")
        }
    }
}

// MARK: - General Settings View

struct GeneralSettingsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
            // Header
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                Text("General Settings")
                    .font(DesignSystem.Typography.headline)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                
                Text("Configure general application preferences.")
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
            }
            
            // Placeholder for future general settings
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                Text("Coming Soon")
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                
                Text("General application settings will be available in a future update.")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.tertiaryText)
            }
            .padding(DesignSystem.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                    .fill(DesignSystem.Colors.secondaryBackground)
            )
            
            Spacer()
        }
        .padding(DesignSystem.Spacing.lg)
    }
}

// MARK: - User Profile View

struct UserProfileView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
            // Header
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                Text("User Profile")
                    .font(DesignSystem.Typography.headline)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                
                Text("Manage your user profile and preferences.")
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
            }
            
            // Placeholder for future user profile settings
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                Text("Coming Soon")
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                
                Text("User profile management will be available in a future update.")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.tertiaryText)
            }
            .padding(DesignSystem.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                    .fill(DesignSystem.Colors.secondaryBackground)
            )
            
            Spacer()
        }
        .padding(DesignSystem.Spacing.lg)
    }
}

// MARK: - Previews

#Preview("API Key Settings") {
    APIKeySettingsView()
        .environment(SettingsManager.shared)
}

#Preview("General Settings") {
    GeneralSettingsView()
        .environment(SettingsManager.shared)
}

#Preview("User Profile") {
    UserProfileView()
        .environment(SettingsManager.shared)
} 