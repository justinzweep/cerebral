//
//  APIKeySettingsView.swift
//  cerebral
//
//  Created by Justin Zweep on 26/06/2025.
//

import SwiftUI

struct APIKeySettingsView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @State private var tempAPIKey: String = ""
    @State private var isEditing: Bool = false
    @State private var showingConfirmation: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                Text("Claude API Configuration")
                    .font(DesignSystem.Typography.title2)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Text("Enter your Anthropic Claude API key to enable AI chat functionality.")
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                Text("API Key")
                    .font(DesignSystem.Typography.bodyMedium)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                HStack(spacing: DesignSystem.Spacing.sm) {
                    if isEditing {
                        SecureField("sk-ant-...", text: $tempAPIKey)
                            .textFieldStyle(CerebralTextFieldStyle(isError: !settingsManager.validateAPIKey(tempAPIKey) && !tempAPIKey.isEmpty))
                    } else {
                        HStack(spacing: DesignSystem.Spacing.sm) {
                            Text(settingsManager.apiKey.isEmpty ? "No API key set" : "••••••••••••••••••••")
                                .font(DesignSystem.Typography.monospace)
                                .foregroundColor(settingsManager.apiKey.isEmpty ? DesignSystem.Colors.textTertiary : DesignSystem.Colors.textPrimary)
                            
                            Spacer()
                            
                            if settingsManager.isAPIKeyValid {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(DesignSystem.Colors.successGreen)
                            }
                        }
                        .padding(.horizontal, DesignSystem.Spacing.sm)
                        .padding(.vertical, DesignSystem.Spacing.xs)
                        .background(DesignSystem.Colors.background)
                        .cornerRadius(DesignSystem.CornerRadius.sm)
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                                .stroke(DesignSystem.Colors.border, lineWidth: 1)
                        )
                    }
                    
                    VStack(spacing: DesignSystem.Spacing.xs) {
                        if isEditing {
                            Button("Save") {
                                if settingsManager.validateAPIKey(tempAPIKey) {
                                    settingsManager.saveAPIKey(tempAPIKey)
                                    isEditing = false
                                }
                            }
                            .buttonStyle(PrimaryButtonStyle())
                            .disabled(!settingsManager.validateAPIKey(tempAPIKey))
                            
                            Button("Cancel") {
                                tempAPIKey = settingsManager.apiKey
                                isEditing = false
                            }
                            .buttonStyle(SecondaryButtonStyle())
                        } else {
                            Button(settingsManager.apiKey.isEmpty ? "Add" : "Edit") {
                                tempAPIKey = settingsManager.apiKey
                                isEditing = true
                            }
                            .buttonStyle(SecondaryButtonStyle())
                            
                            if !settingsManager.apiKey.isEmpty {
                                Button("Remove") {
                                    showingConfirmation = true
                                }
                                .buttonStyle(DestructiveButtonStyle())
                            }
                        }
                    }
                }
            }
            
            // Error Messages
            if isEditing && !settingsManager.validateAPIKey(tempAPIKey) && !tempAPIKey.isEmpty {
                HStack(spacing: DesignSystem.Spacing.xs) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(DesignSystem.Colors.errorRed)
                    
                    Text("Invalid API key format. Claude API keys should start with 'sk-ant-'")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.errorRed)
                }
            }
            
            if let error = settingsManager.lastError {
                HStack(spacing: DesignSystem.Spacing.xs) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(DesignSystem.Colors.errorRed)
                    
                    Text(error)
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.errorRed)
                }
            }
            
            // Help Section
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                Text("How to get your API key:")
                    .font(DesignSystem.Typography.subheadline)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                    HelpStepView(step: "1", text: "Visit console.anthropic.com")
                    HelpStepView(step: "2", text: "Create an account or sign in")
                    HelpStepView(step: "3", text: "Go to API Keys section")
                    HelpStepView(step: "4", text: "Create a new API key")
                    HelpStepView(step: "5", text: "Copy and paste it above")
                }
            }
            .padding(DesignSystem.Spacing.md)
            .background(DesignSystem.Colors.background)
            .cornerRadius(DesignSystem.CornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                    .stroke(DesignSystem.Colors.border, lineWidth: 1)
            )
            
            Spacer()
        }
        .padding(DesignSystem.Spacing.lg)
        .onAppear {
            tempAPIKey = settingsManager.apiKey
        }
        .confirmationDialog("Remove API Key", isPresented: $showingConfirmation) {
            Button("Remove", role: .destructive) {
                settingsManager.deleteAPIKey()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to remove your Claude API key? This will disable AI chat functionality.")
        }
    }
}

// MARK: - Helper Components

struct HelpStepView: View {
    let step: String
    let text: String
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.xs) {
            Text(step)
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.accent)
                .fontWeight(.medium)
                .frame(minWidth: 12)
            
            Text(text)
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.textSecondary)
        }
    }
}

#Preview {
    APIKeySettingsView()
        .environmentObject(SettingsManager())
        .frame(width: 500, height: 400)
} 