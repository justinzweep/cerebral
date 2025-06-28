//
//  SettingsManager.swift
//  cerebral
//
//  Created by Justin Zweep on 26/06/2025.
//

import Foundation
import SwiftUI

@MainActor
@Observable
final class SettingsManager: SettingsServiceProtocol {
    static let shared = SettingsManager()
    
    var apiKey: String = ""
    var lastError: String?
    
    private let keychainService = KeychainService.shared
    
    private init() {
        loadAPIKey()
    }
    
    // UI Settings - using UserDefaults directly to avoid @AppStorage conflicts
    var selectedTheme: String {
        get { UserDefaults.standard.string(forKey: "selectedTheme") ?? "system" }
        set { UserDefaults.standard.set(newValue, forKey: "selectedTheme") }
    }
    
    var fontSize: Double {
        get { UserDefaults.standard.double(forKey: "fontSize") != 0 ? UserDefaults.standard.double(forKey: "fontSize") : 14.0 }
        set { UserDefaults.standard.set(newValue, forKey: "fontSize") }
    }
    
    var enableMarkdown: Bool {
        get { UserDefaults.standard.object(forKey: "enableMarkdown") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "enableMarkdown") }
    }
    
    // Context management settings
    var includeActiveDocumentByDefault: Bool {
        get { UserDefaults.standard.bool(forKey: "includeActiveDocumentByDefault") }
        set { UserDefaults.standard.set(newValue, forKey: "includeActiveDocumentByDefault") }
    }
    
    var contextTokenLimit: Int {
        get { 
            let value = UserDefaults.standard.integer(forKey: "contextTokenLimit")
            return value == 0 ? 50_000 : value
        }
        set { UserDefaults.standard.set(newValue, forKey: "contextTokenLimit") }
    }
    
    var showContextIndicators: Bool {
        get { UserDefaults.standard.object(forKey: "showContextIndicators") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "showContextIndicators") }
    }
    
    func loadAPIKey() {
        do {
            if let key = try keychainService.getAPIKey() {
                apiKey = key
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
    
    func validateAPIKey(_ key: String) -> Bool {
        // Claude API keys start with "sk-ant-" and are typically 90+ characters long
        return key.hasPrefix("sk-ant-") && key.count > 20
    }
} 

