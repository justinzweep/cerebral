//
//  KeychainService.swift
//  cerebral
//
//  Created by Justin Zweep on 26/06/2025.
//

import Foundation
import Security

class KeychainService {
    static let shared = KeychainService()
    private let service = "com.blendrlabs.cerebral"
    
    private init() {}
    
    func saveAPIKey(_ key: String) throws {
        let data = key.data(using: .utf8)!
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: "claude_api_key",
            kSecValueData as String: data
        ]
        
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else { throw KeychainError.unableToSave }
    }
    
    func getAPIKey() throws -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: "claude_api_key",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess else {
            return status == errSecItemNotFound ? nil : nil
        }
        
        guard let data = result as? Data,
              let key = String(data: data, encoding: .utf8) else {
            throw KeychainError.invalidData
        }
        
        return key
    }
    
    func deleteAPIKey() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: "claude_api_key"
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unableToDelete
        }
    }
}

enum KeychainError: LocalizedError {
    case unableToSave
    case unableToRetrieve
    case unableToDelete
    case invalidData
    
    var errorDescription: String? {
        switch self {
        case .unableToSave: return "Unable to save API key to Keychain"
        case .unableToRetrieve: return "Unable to retrieve API key from Keychain"
        case .unableToDelete: return "Unable to delete API key from Keychain"
        case .invalidData: return "Invalid data retrieved from Keychain"
        }
    }
} 