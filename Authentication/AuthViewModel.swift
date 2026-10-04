//
//  AuthViewModel.swift
//  35DDP257 - iOS + CarPlay DJ Application
//

import SwiftUI
import Combine

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var isUnlocked: Bool = false
    @Published var enteredPin: String = ""
    @Published var errorMessage: String? = nil
    @Published var isLockedOut: Bool = false
    @Published var lockoutCountdown: Int = 0
    @Published var isInitialSetup: Bool = false
    @Published var setupConfirmPin: String = ""
    @Published var isConfirmingSetup: Bool = false
    @Published var autoLockOnBackground: Bool = true
    
    private let maxAttempts = 5
    @Published private(set) var failedAttempts: Int = 0
    private var lockoutTimer: AnyCancellable?
    
    private let keychain = KeychainService.shared
    private let biometric = BiometricAuthService.shared
    
    init() {
        checkInitialStatus()
    }
    
    func checkInitialStatus() {
        if !keychain.isPinConfigured() {
            _ = keychain.savePin("35257")
        }
        isInitialSetup = false
        isUnlocked = false
    }
    
    func appendDigit(_ digit: String) {
        guard !isLockedOut else { return }
        guard enteredPin.count < 5 else { return }
        
        enteredPin.append(digit)
        errorMessage = nil
        
        if enteredPin.count == 5 {
            processPinSubmission()
        }
    }
    
    func deleteDigit() {
        guard !enteredPin.isEmpty else { return }
        enteredPin.removeLast()
        errorMessage = nil
    }
    
    func clearPin() {
        enteredPin = ""
        errorMessage = nil
    }
    
    private func processPinSubmission() {
        if isInitialSetup {
            if !isConfirmingSetup {
                // First entry of new PIN
                setupConfirmPin = enteredPin
                enteredPin = ""
                isConfirmingSetup = true
            } else {
                // Confirm entry
                if enteredPin == setupConfirmPin {
                    if keychain.savePin(enteredPin) {
                        isInitialSetup = false
                        isConfirmingSetup = false
                        isUnlocked = true
                        enteredPin = ""
                    } else {
                        errorMessage = "Şifre kaydedilemedi. Lütfen tekrar deneyin."
                        resetSetup()
                    }
                } else {
                    errorMessage = "Şifreler eşleşmedi. Baştan başlayın."
                    resetSetup()
                }
            }
        } else {
            // Normal Unlock Verification
            if keychain.verifyPin(enteredPin) {
                isUnlocked = true
                failedAttempts = 0
                enteredPin = ""
                errorMessage = nil
            } else {
                failedAttempts += 1
                enteredPin = ""
                let remaining = maxAttempts - failedAttempts
                if remaining > 0 {
                    errorMessage = "Hatalı Şifre! Kalan deneme: \(remaining)"
                } else {
                    startLockout(duration: 30)
                }
            }
        }
    }
    
    private func resetSetup() {
        enteredPin = ""
        setupConfirmPin = ""
        isConfirmingSetup = false
    }
    
    private func startLockout(duration: Int) {
        isLockedOut = true
        lockoutCountdown = duration
        errorMessage = "Çok fazla hatalı giriş. \(lockoutCountdown) sn bekleyin."
        
        lockoutTimer?.cancel()
        lockoutTimer = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                if self.lockoutCountdown > 1 {
                    self.lockoutCountdown -= 1
                    self.errorMessage = "Çok fazla hatalı giriş. \(self.lockoutCountdown) sn bekleyin."
                } else {
                    self.isLockedOut = false
                    self.failedAttempts = 0
                    self.errorMessage = nil
                    self.lockoutTimer?.cancel()
                }
            }
    }
    
    func triggerBiometricsIfAvailable() {
        // Face ID disabled per user preference
    }
    
    func lockApp() {
        isUnlocked = false
        enteredPin = ""
        errorMessage = nil
    }
    
    func handleAppMovedToBackground() {
        if autoLockOnBackground && !isInitialSetup {
            lockApp()
        }
    }
}
