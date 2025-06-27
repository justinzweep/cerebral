//
//  SettingsManager.swift
//  cerebral
//
//  Created by Justin Zweep on 26/06/2025.
//

import Foundation

@MainActor
class SettingsManager: ObservableObject, SettingsServiceProtocol {
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
        } catch let error as KeychainError {
            print("Error loading API key: \(error)")
            lastError = SettingsError.keychainAccessFailed(error.localizedDescription).localizedDescription
        } catch {
            print("Error loading API key: \(error)")
            lastError = SettingsError.configurationError(error.localizedDescription).localizedDescription
        }
    }
    
    func saveAPIKey(_ key: String) throws {
        guard validateAPIKey(key) else {
            throw SettingsError.invalidAPIKey("API key must start with 'sk-ant-' and be at least 20 characters long")
        }
        
        do {
            try keychainService.saveAPIKey(key)
            apiKey = key
            isAPIKeyValid = true
            lastError = nil
        } catch let error as KeychainError {
            let settingsError = SettingsError.keychainAccessFailed(error.localizedDescription)
            lastError = settingsError.localizedDescription
            throw settingsError
        } catch {
            let settingsError = SettingsError.configurationError(error.localizedDescription)
            lastError = settingsError.localizedDescription
            throw settingsError
        }
    }
    
    func deleteAPIKey() throws {
        do {
            try keychainService.deleteAPIKey()
            apiKey = ""
            isAPIKeyValid = false
            lastError = nil
        } catch let error as KeychainError {
            let settingsError = SettingsError.keychainAccessFailed(error.localizedDescription)
            lastError = settingsError.localizedDescription
            throw settingsError
        } catch {
            let settingsError = SettingsError.configurationError(error.localizedDescription)
            lastError = settingsError.localizedDescription
            throw settingsError
        }
    }
    
    func validateSettings() async -> Bool {
        guard isAPIKeyValid else { return false }
        
        // Could add additional validation here like testing API connection
        return true
    }
    
    private func validateAPIKey(_ key: String) -> Bool {
        // Claude API keys start with "sk-ant-" and are typically 90+ characters long
        return key.hasPrefix("sk-ant-") && key.count > 20
    }
} 

