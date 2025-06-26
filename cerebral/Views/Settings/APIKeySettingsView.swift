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
        VStack(alignment: .leading, spacing: 20) {
            Text("Claude API Configuration")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Enter your Anthropic Claude API key to enable AI chat functionality.")
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("API Key")
                    .fontWeight(.medium)
                
                HStack {
                    if isEditing {
                        SecureField("sk-ant-...", text: $tempAPIKey)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(.body, design: .monospaced))
                    } else {
                        HStack {
                            Text(settingsManager.apiKey.isEmpty ? "No API key set" : "••••••••••••••••••••")
                                .foregroundColor(settingsManager.apiKey.isEmpty ? .secondary : .primary)
                                .font(.system(.body, design: .monospaced))
                            Spacer()
                            if settingsManager.isAPIKeyValid {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(6)
                    }
                    
                    if isEditing {
                        Button("Save") {
                            if settingsManager.validateAPIKey(tempAPIKey) {
                                settingsManager.saveAPIKey(tempAPIKey)
                                isEditing = false
                            }
                        }
                        .disabled(!settingsManager.validateAPIKey(tempAPIKey))
                        
                        Button("Cancel") {
                            tempAPIKey = settingsManager.apiKey
                            isEditing = false
                        }
                    } else {
                        Button(settingsManager.apiKey.isEmpty ? "Add" : "Edit") {
                            tempAPIKey = settingsManager.apiKey
                            isEditing = true
                        }
                        
                        if !settingsManager.apiKey.isEmpty {
                            Button("Remove") {
                                showingConfirmation = true
                            }
                            .foregroundColor(.red)
                        }
                    }
                }
            }
            
            if isEditing && !settingsManager.validateAPIKey(tempAPIKey) && !tempAPIKey.isEmpty {
                Label("Invalid API key format. Claude API keys should start with 'sk-ant-'", 
                      systemImage: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
                    .font(.caption)
            }
            
            if let error = settingsManager.lastError {
                Label(error, systemImage: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
                    .font(.caption)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("How to get your API key:")
                    .fontWeight(.medium)
                    .font(.subheadline)
                
                Text("1. Visit console.anthropic.com")
                Text("2. Create an account or sign in")
                Text("3. Go to API Keys section")
                Text("4. Create a new API key")
                Text("5. Copy and paste it above")
            }
            .font(.caption)
            .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding(20)
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

#Preview {
    APIKeySettingsView()
        .environmentObject(SettingsManager())
        .frame(width: 500, height: 400)
} 