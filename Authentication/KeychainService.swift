//
//  KeychainService.swift
//  35DDP257 - iOS + CarPlay DJ Application
//

import Foundation
import Security
import CryptoKit

final class KeychainService {
    static let shared = KeychainService()
    
    private let serviceName = "com.antigravity.dj.35DDP257"
    private let pinAccount = "dj_access_pin_hash"
    private let saltAccount = "dj_access_pin_salt"
    
    private init() {}
    
    // MARK: - Salt & Hash Helpers
    private func generateSalt() -> Data {
        var bytes = [UInt8](repeating: 0, count: 16)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return Data(bytes)
    }
    
    private func hashPin(pin: String, salt: Data) -> String {
        guard let pinData = pin.data(using: .utf8) else { return "" }
        var combined = salt
        combined.append(pinData)
        let digest = SHA256.hash(data: combined)
        return digest.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    // MARK: - Public API
    func isPinConfigured() -> Bool {
        return getStoredString(for: pinAccount) != nil
    }
    
    func savePin(_ pin: String) -> Bool {
        let salt = generateSalt()
        let hashedPin = hashPin(pin: pin, salt: salt)
        
        let saltSaved = save(data: salt, for: saltAccount)
        let pinSaved = save(data: hashedPin.data(using: .utf8) ?? Data(), for: pinAccount)
        
        return saltSaved && pinSaved
    }
    
    func verifyPin(_ pin: String) -> Bool {
        guard let storedHash = getStoredString(for: pinAccount),
              let saltData = getStoredData(for: saltAccount) else {
            return false
        }
        let inputHash = hashPin(pin: pin, salt: saltData)
        return inputHash == storedHash
    }
    
    func resetPin() {
        delete(account: pinAccount)
        delete(account: saltAccount)
    }
    
    // MARK: - Low-Level Keychain Operations
    private func save(data: Data, for account: String) -> Bool {
        delete(account: account)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    private func getStoredData(for account: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        if status == errSecSuccess, let data = dataTypeRef as? Data {
            return data
        }
        return nil
    }
    
    private func getStoredString(for account: String) -> String? {
        guard let data = getStoredData(for: account) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    private func delete(account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
    }
}
