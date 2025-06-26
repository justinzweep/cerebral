//
//  SettingsManager.swift
//  cerebral
//
//  Created by Justin Zweep on 26/06/2025.
//

import Foundation

@MainActor
class SettingsManager: ObservableObject {
    @Published var apiKey: String = ""
    @Published var isAPIKeyValid: Bool = false
    @Published var lastError: String?
    
    private let keychainService = KeychainService.shared
    
    init() {
        loadAPIKey()
    }
    
    func loadAPIKey() {
        do {
            if let key = try keychainService.getAPIKey() {
                apiKey = key
                isAPIKeyValid = validateAPIKey(key)
            }
        } catch {
            print("Error loading API key: \(error)")
            lastError = error.localizedDescription
        }
    }
    
    func saveAPIKey(_ key: String) {
        do {
            try keychainService.saveAPIKey(key)
            apiKey = key
            isAPIKeyValid = validateAPIKey(key)
            lastError = nil
        } catch {
            print("Error saving API key: \(error)")
            lastError = error.localizedDescription
        }
    }
    
    func deleteAPIKey() {
        do {
            try keychainService.deleteAPIKey()
            apiKey = ""
            isAPIKeyValid = false
            lastError = nil
        } catch {
            print("Error deleting API key: \(error)")
            lastError = error.localizedDescription
        }
    }
    
    func validateAPIKey(_ key: String) -> Bool {
        // Claude API keys start with "sk-ant-" and are typically 90+ characters long
        return key.hasPrefix("sk-ant-") && key.count > 20
    }
} 