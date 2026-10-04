//
//  BiometricAuthService.swift
//  35DDP257 - iOS + CarPlay DJ Application
//

import Foundation
import LocalAuthentication

final class BiometricAuthService {
    static let shared = BiometricAuthService()
    
    private init() {}
    
    var isBiometricsAvailable: Bool {
        let context = LAContext()
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }
    
    var biometryType: LABiometryType {
        let context = LAContext()
        _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        return context.biometryType
    }
    
    var biometryTypeString: String {
        switch biometryType {
        case .faceID: return "Face ID"
        case .touchID: return "Touch ID"
        case .opticID: return "Optic ID"
        default: return "Biometrics"
        }
    }
    
    func authenticate(reason: String = "DJ Konsolu Erişimi İçin Kimlik Doğrulayın", completion: @escaping (Bool, String?) -> Void) {
        let context = LAContext()
        context.localizedCancelTitle = "İptal"
        
        var authError: NSError?
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &authError) {
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, evaluateError in
                DispatchQueue.main.async {
                    if success {
                        completion(true, nil)
                    } else {
                        completion(false, evaluateError?.localizedDescription ?? "Doğrulama başarısız")
                    }
                }
            }
        } else {
            DispatchQueue.main.async {
                completion(false, authError?.localizedDescription ?? "Biyometrik doğrulama kullanılamıyor")
            }
        }
    }
}
