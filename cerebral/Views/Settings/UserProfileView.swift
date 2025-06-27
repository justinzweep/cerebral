//
//  ProfileTabView.swift
//  cerebral
//
//  Created by Justin Zweep on 26/06/2025.
//

import SwiftUI

struct ProfileTabView: View {
    @Environment(SettingsManager.self) var settingsManager: SettingsManager
    @AppStorage("userName") private var userName: String = ""
    @State private var tempAPIKey: String = ""
    @State private var isEditingAPIKey: Bool = false
    @State private var showingAPIKeyConfirmation: Bool = false
    
    var body: some View {
        Form {            
                HStack {
                    VStack(alignment: .leading) {
                        Text("Claude API Key")
                        Text("Required for AI chat functionality")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    if settingsManager.isAPIKeyValid {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                }
                
                if isEditingAPIKey {
                    SecureField("sk-ant-...", text: $tempAPIKey)
                    
                    HStack {
                        Button("Save") {
                            if settingsManager.validateAPIKey(tempAPIKey) {
                                do {
                                    try settingsManager.saveAPIKey(tempAPIKey)
                                    isEditingAPIKey = false
                                } catch {
                                    // Error is already handled by SettingsManager and stored in lastError
                                    print("Failed to save API key: \(error)")
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
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                } else {
                    HStack {
                        Text(settingsManager.apiKey.isEmpty ? "No API key set" : "••••••••••••••••••••")
                            .font(.system(.body, design: .monospaced))
                            .foregroundStyle(settingsManager.apiKey.isEmpty ? .secondary : .primary)
                        
                        Spacer()
                        
                        Button(settingsManager.apiKey.isEmpty ? "Add" : "Edit") {
                            tempAPIKey = settingsManager.apiKey
                            isEditingAPIKey = true
                        }
                        
                        if !settingsManager.apiKey.isEmpty {
                            Button("Remove") {
                                showingAPIKeyConfirmation = true
                            }
                        }
                    }
                }
                
                if let error = settingsManager.lastError {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            
            

        }
        .formStyle(.grouped)
        .onAppear {
            tempAPIKey = settingsManager.apiKey
        }
        .confirmationDialog("Remove API Key", isPresented: $showingAPIKeyConfirmation) {
            Button("Remove", role: .destructive) {
                do {
                    try settingsManager.deleteAPIKey()
                } catch {
                    // Error is already handled by SettingsManager and stored in lastError
                    print("Failed to delete API key: \(error)")
                }
            }
        } message: {
            Text("Are you sure you want to remove your Claude API key?")
        }
    }
}

#Preview {
    ProfileTabView()
        .environment(SettingsManager())
        .frame(width: 500, height: 400)
} 