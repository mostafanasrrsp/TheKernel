import Foundation
import CryptoKit
import LocalAuthentication

/// Core security framework inspired by Pop!_OS and Ubuntu's security features
public class SecurityCore {
    
    // MARK: - Singleton Instance
    public static let shared = SecurityCore()
    
    // MARK: - Properties
    private var encryptionKeys: [String: SymmetricKey] = [:]
    private var sessionTokens: Set<String> = []
    private var failedAuthAttempts: [String: Int] = [:]
    private let maxAuthAttempts = 5
    private var isSystemLocked = false
    
    // MARK: - Security Policies
    public struct SecurityPolicy {
        var requireEncryption: Bool = true
        var enforcePasswordComplexity: Bool = true
        var enableTwoFactorAuth: Bool = false
        var sessionTimeout: TimeInterval = 900 // 15 minutes
        var autoLockOnSuspend: Bool = true
        var secureBootEnabled: Bool = true
    }
    
    private var currentPolicy = SecurityPolicy()
    
    // MARK: - Initialization
    private init() {
        setupSecurityEnvironment()
    }
    
    private func setupSecurityEnvironment() {
        // Initialize security subsystems
        initializeEncryption()
        setupAuditLogging()
        loadSecurityPolicies()
    }
    
    // MARK: - Encryption (inspired by Pop!_OS full-disk encryption)
    
    private func initializeEncryption() {
        // Generate master encryption key
        let masterKey = SymmetricKey(size: .bits256)
        encryptionKeys["master"] = masterKey
    }
    
    public func encryptData(_ data: Data, withKey keyIdentifier: String = "master") -> Data? {
        guard let key = encryptionKeys[keyIdentifier] else { return nil }
        
        do {
            let sealedBox = try AES.GCM.seal(data, using: key)
            return sealedBox.combined
        } catch {
            logSecurityEvent("Encryption failed: \(error.localizedDescription)", severity: .error)
            return nil
        }
    }
    
    public func decryptData(_ encryptedData: Data, withKey keyIdentifier: String = "master") -> Data? {
        guard let key = encryptionKeys[keyIdentifier] else { return nil }
        
        do {
            let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
            let decryptedData = try AES.GCM.open(sealedBox, using: key)
            return decryptedData
        } catch {
            logSecurityEvent("Decryption failed: \(error.localizedDescription)", severity: .error)
            return nil
        }
    }
    
    // MARK: - Authentication System
    
    public func authenticateUser(username: String, password: String) -> AuthenticationResult {
        // Check if account is locked
        if let attempts = failedAuthAttempts[username], attempts >= maxAuthAttempts {
            return .accountLocked
        }
        
        // Hash password using SHA256
        let passwordData = Data(password.utf8)
        let hashedPassword = SHA256.hash(data: passwordData)
        let hashString = hashedPassword.compactMap { String(format: "%02x", $0) }.joined()
        
        // Verify against stored hash (simplified for demo)
        if verifyCredentials(username: username, passwordHash: hashString) {
            // Generate session token
            let sessionToken = generateSessionToken()
            sessionTokens.insert(sessionToken)
            
            // Reset failed attempts
            failedAuthAttempts[username] = 0
            
            logSecurityEvent("Successful authentication for user: \(username)", severity: .info)
            return .success(token: sessionToken)
        } else {
            // Increment failed attempts
            failedAuthAttempts[username, default: 0] += 1
            
            logSecurityEvent("Failed authentication attempt for user: \(username)", severity: .warning)
            return .failure
        }
    }
    
    private func verifyCredentials(username: String, passwordHash: String) -> Bool {
        // In production, this would check against secure storage
        // For demo, using a simple validation
        return username.count > 3 && passwordHash.count == 64
    }
    
    private func generateSessionToken() -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<32).map { _ in letters.randomElement()! })
    }
    
    // MARK: - Session Management
    
    public func validateSession(token: String) -> Bool {
        return sessionTokens.contains(token)
    }
    
    public func invalidateSession(token: String) {
        sessionTokens.remove(token)
        logSecurityEvent("Session invalidated", severity: .info)
    }
    
    // MARK: - Biometric Authentication (inspired by Elementary OS)
    
    public func authenticateWithBiometrics(completion: @escaping (Bool) -> Void) {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Authenticate to access RadiateOS"
            
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authError in
                DispatchQueue.main.async {
                    if success {
                        self.logSecurityEvent("Biometric authentication successful", severity: .info)
                    } else {
                        self.logSecurityEvent("Biometric authentication failed: \(authError?.localizedDescription ?? "Unknown")", severity: .warning)
                    }
                    completion(success)
                }
            }
        } else {
            completion(false)
        }
    }
    
    // MARK: - Security Policies
    
    public func updateSecurityPolicy(_ policy: SecurityPolicy) {
        currentPolicy = policy
        applySecurityPolicies()
    }
    
    private func loadSecurityPolicies() {
        // Load policies from secure storage
        // For demo, using defaults
        applySecurityPolicies()
    }
    
    private func applySecurityPolicies() {
        // Apply current security policies
        if currentPolicy.secureBootEnabled {
            enableSecureBoot()
        }
        
        if currentPolicy.autoLockOnSuspend {
            setupAutoLock()
        }
    }
    
    private func enableSecureBoot() {
        logSecurityEvent("Secure boot enabled", severity: .info)
        // Implement secure boot verification
    }
    
    private func setupAutoLock() {
        // Setup auto-lock timer
        Timer.scheduledTimer(withTimeInterval: currentPolicy.sessionTimeout, repeats: false) { _ in
            self.lockSystem()
        }
    }
    
    public func lockSystem() {
        isSystemLocked = true
        sessionTokens.removeAll()
        logSecurityEvent("System locked", severity: .info)
    }
    
    // MARK: - Audit Logging
    
    private func setupAuditLogging() {
        // Initialize audit log
        logSecurityEvent("Security audit system initialized", severity: .info)
    }
    
    public func logSecurityEvent(_ event: String, severity: SecurityEventSeverity) {
        let timestamp = Date()
        let logEntry = "[\(timestamp)] [\(severity.rawValue)] \(event)"
        
        // In production, write to secure audit log
        print("SECURITY: \(logEntry)")
        
        // Send critical events to monitoring system
        if severity == .critical || severity == .error {
            notifySecurityMonitor(event: event, severity: severity)
        }
    }
    
    private func notifySecurityMonitor(event: String, severity: SecurityEventSeverity) {
        // Send to security monitoring dashboard
        NotificationCenter.default.post(
            name: Notification.Name("SecurityAlert"),
            object: nil,
            userInfo: ["event": event, "severity": severity.rawValue]
        )
    }
    
    // MARK: - Types
    
    public enum AuthenticationResult {
        case success(token: String)
        case failure
        case accountLocked
    }
    
    public enum SecurityEventSeverity: String {
        case info = "INFO"
        case warning = "WARNING"
        case error = "ERROR"
        case critical = "CRITICAL"
    }
}

// MARK: - Password Validator

public class PasswordValidator {
    
    public static func validate(_ password: String) -> ValidationResult {
        var errors: [String] = []
        
        if password.count < 8 {
            errors.append("Password must be at least 8 characters")
        }
        
        if !password.contains(where: { $0.isUppercase }) {
            errors.append("Password must contain at least one uppercase letter")
        }
        
        if !password.contains(where: { $0.isLowercase }) {
            errors.append("Password must contain at least one lowercase letter")
        }
        
        if !password.contains(where: { $0.isNumber }) {
            errors.append("Password must contain at least one number")
        }
        
        let specialCharacters = "!@#$%^&*()_+-=[]{}|;:,.<>?"
        if !password.contains(where: { specialCharacters.contains($0) }) {
            errors.append("Password must contain at least one special character")
        }
        
        return errors.isEmpty ? .valid : .invalid(errors: errors)
    }
    
    public enum ValidationResult {
        case valid
        case invalid(errors: [String])
    }
}
