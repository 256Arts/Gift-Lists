import SwiftUI
import LocalAuthentication

@MainActor @Observable
final class BiometricAuthentication {
    
    var isAuthenticated = false
    
    func authenticate() async {
        // A screenshot run shares the real defaults domain, so a machine with the lock turned on
        // would prompt for Touch ID on every launch and redact the very content being photographed.
        guard !ScreenshotMode.isActive else {
            isAuthenticated = true
            return
        }

        guard !isAuthenticated, UserDefaults.standard.bool(forKey: UserDefaults.Key.requireAuthenication) else {
            isAuthenticated = true
            return
        }
        
        let context = LAContext()
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            // no biometrics
            isAuthenticated = true
            return
        }
        
        let reason = "To unlock your private list."
        do {
            let success = try await context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason)
            if success {
                isAuthenticated = true
            }
        } catch {
            isAuthenticated = true
        }
    }
    
}

extension LABiometryType {
    
    var name: String? {
        switch self {
        case .touchID:
            "Touch ID"
        case .faceID:
            "Face ID"
        case .opticID:
            "Optic ID"
        default:
            nil
        }
    }
    
    var systemImageName: String? {
        switch self {
        case .touchID:
            "touchid"
        case .faceID:
            "faceid"
        case .opticID:
            "opticid"
        default:
            nil
        }
    }
    
}
