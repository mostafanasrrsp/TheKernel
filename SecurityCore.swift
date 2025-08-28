import Foundation
import CryptoKit
import os.log

/// Core security module inspired by Ubuntu's security architecture
/// Combines features from AppArmor, SELinux, and modern security frameworks
public class SecurityCore {
    
    // MARK: - Singleton
    public static let shared = SecurityCore()
    
    // MARK: - Properties
    private let logger = Logger(subsystem: "com.radiateos.security", category: "SecurityCore")
    private var securityPolicies: [SecurityPolicy] = []
    private var auditLog: [SecurityEvent] = []
    private let encryptionKey: SymmetricKey
    private var integrityChecksums: [String: String] = [:]
    
    // Security levels inspired by Ubuntu's AppArmor profiles
    public enum SecurityLevel: String, CaseIterable {
        case enforce = "enforce"      // Full security enforcement
        case complain = "complain"    // Log violations but don't block
        case audit = "audit"          // Enhanced logging mode
        case disabled = "disabled"    // Security disabled (not recommended)
    }
    
    private var currentSecurityLevel: SecurityLevel = .enforce
    
    // MARK: - Initialization
    private init() {
        // Generate or load encryption key
        self.encryptionKey = SymmetricKey(size: .bits256)
        setupDefaultPolicies()
        initializeIntegrityChecking()
    }
    
    // MARK: - Security Event Logging
    
    public func logSecurityEvent(_ message: String, severity: SecuritySeverity) {
        let event = SecurityEvent(
            timestamp: Date(),
            message: message,
            severity: severity,
            processID: ProcessInfo.processInfo.processIdentifier,
            userID: getuid()
        )
        
        auditLog.append(event)
        
        // Log to system
        switch severity {
        case .info:
            logger.info("\(message)")
        case .warning:
            logger.warning("\(message)")
        case .error:
            logger.error("\(message)")
        case .critical:
            logger.critical("\(message)")
        }
        
        // Trim audit log if too large
        if auditLog.count > 10000 {
            auditLog.removeFirst(1000)
        }
    }
    
    // MARK: - AppArmor-inspired Application Sandboxing
    
    public func createSandbox(for application: String) -> ApplicationSandbox {
        let sandbox = ApplicationSandbox(
            applicationName: application,
            allowedPaths: determineAllowedPaths(for: application),
            capabilities: determineCapabilities(for: application),
            networkAccess: determineNetworkAccess(for: application)
        )
        
        logSecurityEvent("Sandbox created for \(application)", severity: .info)
        return sandbox
    }
    
    public func enforcePolicy(_ policy: SecurityPolicy, for process: Process) -> Bool {
        guard currentSecurityLevel != .disabled else { return true }
        
        let allowed = policy.evaluate(process: process)
        
        if !allowed {
            let message = "Security policy violation: \(policy.name) for process \(process.processIdentifier)"
            
            switch currentSecurityLevel {
            case .enforce:
                logSecurityEvent(message, severity: .error)
                return false
            case .complain, .audit:
                logSecurityEvent(message, severity: .warning)
                return true
            case .disabled:
                return true
            }
        }
        
        return allowed
    }
    
    // MARK: - Integrity Checking (inspired by AIDE/Tripwire)
    
    public func verifySystemIntegrity() -> IntegrityReport {
        var violations: [String] = []
        var checksumMismatches = 0
        
        for (file, expectedChecksum) in integrityChecksums {
            if let currentChecksum = calculateChecksum(for: file) {
                if currentChecksum != expectedChecksum {
                    violations.append("Checksum mismatch for \(file)")
                    checksumMismatches += 1
                    logSecurityEvent("Integrity violation detected: \(file)", severity: .critical)
                }
            }
        }
        
        return IntegrityReport(
            timestamp: Date(),
            filesChecked: integrityChecksums.count,
            violations: violations,
            checksumMismatches: checksumMismatches,
            status: violations.isEmpty ? .passed : .failed
        )
    }
    
    private func calculateChecksum(for file: String) -> String? {
        guard let data = FileManager.default.contents(atPath: file) else { return nil }
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    // MARK: - Mandatory Access Control (MAC) inspired by SELinux
    
    public func checkAccess(subject: SecuritySubject, object: SecurityObject, action: SecurityAction) -> Bool {
        // Check mandatory access control rules
        let context = SecurityContext(subject: subject, object: object, action: action)
        
        for policy in securityPolicies {
            if !policy.allows(context: context) {
                logSecurityEvent(
                    "Access denied: \(subject.identifier) -> \(action.rawValue) -> \(object.identifier)",
                    severity: .warning
                )
                return false
            }
        }
        
        logSecurityEvent(
            "Access granted: \(subject.identifier) -> \(action.rawValue) -> \(object.identifier)",
            severity: .info
        )
        return true
    }
    
    // MARK: - Encryption Services
    
    public func encryptData(_ data: Data) throws -> Data {
        let sealedBox = try AES.GCM.seal(data, using: encryptionKey)
        return sealedBox.combined ?? Data()
    }
    
    public func decryptData(_ encryptedData: Data) throws -> Data {
        let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
        return try AES.GCM.open(sealedBox, using: encryptionKey)
    }
    
    // MARK: - Private Methods
    
    private func setupDefaultPolicies() {
        // Add default security policies inspired by Ubuntu's defaults
        securityPolicies.append(
            SecurityPolicy(
                name: "System Files Protection",
                description: "Prevent unauthorized modification of system files",
                rules: [
                    PolicyRule(path: "/System", permissions: .readOnly),
                    PolicyRule(path: "/usr/bin", permissions: .readOnly),
                    PolicyRule(path: "/etc", permissions: .restricted)
                ]
            )
        )
        
        securityPolicies.append(
            SecurityPolicy(
                name: "User Data Protection",
                description: "Protect user data from unauthorized access",
                rules: [
                    PolicyRule(path: "~/Documents", permissions: .userOnly),
                    PolicyRule(path: "~/Downloads", permissions: .userOnly)
                ]
            )
        )
    }
    
    private func initializeIntegrityChecking() {
        // Initialize checksums for critical system files
        let criticalFiles = [
            "/usr/bin/sudo",
            "/etc/passwd",
            "/etc/shadow",
            "/boot/kernel"
        ]
        
        for file in criticalFiles {
            if let checksum = calculateChecksum(for: file) {
                integrityChecksums[file] = checksum
            }
        }
    }
    
    private func determineAllowedPaths(for application: String) -> [String] {
        // Return allowed paths based on application type
        return [
            "~/Library/\(application)",
            "/tmp/\(application)",
            "~/Documents/\(application)"
        ]
    }
    
    private func determineCapabilities(for application: String) -> Set<Capability> {
        // Return capabilities based on application requirements
        return [.fileRead, .fileWrite, .networkAccess]
    }
    
    private func determineNetworkAccess(for application: String) -> NetworkAccessLevel {
        // Determine network access level
        return .restricted
    }
}

// MARK: - Supporting Types

public struct SecurityEvent {
    let timestamp: Date
    let message: String
    let severity: SecuritySeverity
    let processID: Int32
    let userID: uid_t
}

public enum SecuritySeverity {
    case info
    case warning
    case error
    case critical
}

public struct ApplicationSandbox {
    let applicationName: String
    let allowedPaths: [String]
    let capabilities: Set<Capability>
    let networkAccess: NetworkAccessLevel
    
    public func isPathAllowed(_ path: String) -> Bool {
        return allowedPaths.contains { allowedPath in
            path.hasPrefix(allowedPath)
        }
    }
}

public enum Capability {
    case fileRead
    case fileWrite
    case networkAccess
    case processSpawn
    case systemCall
    case deviceAccess
}

public enum NetworkAccessLevel {
    case none
    case localhost
    case restricted
    case full
}

public struct SecurityPolicy {
    let name: String
    let description: String
    let rules: [PolicyRule]
    
    func evaluate(process: Process) -> Bool {
        // Evaluate all rules
        for rule in rules {
            if !rule.allows(process: process) {
                return false
            }
        }
        return true
    }
    
    func allows(context: SecurityContext) -> Bool {
        // Check if context is allowed by policy rules
        for rule in rules {
            if rule.path == context.object.path {
                return rule.permissions.allows(action: context.action)
            }
        }
        return true
    }
}

public struct PolicyRule {
    let path: String
    let permissions: Permission
    
    func allows(process: Process) -> Bool {
        // Check if process is allowed based on rule
        return true // Simplified for demo
    }
}

public enum Permission {
    case readOnly
    case writeOnly
    case readWrite
    case execute
    case restricted
    case userOnly
    
    func allows(action: SecurityAction) -> Bool {
        switch (self, action) {
        case (.readOnly, .read), (.readWrite, .read), (.readWrite, .write):
            return true
        case (.writeOnly, .write), (.readWrite, .write):
            return true
        case (.execute, .execute):
            return true
        case (.userOnly, _):
            return ProcessInfo.processInfo.userID == getuid()
        default:
            return false
        }
    }
}

public struct SecurityContext {
    let subject: SecuritySubject
    let object: SecurityObject
    let action: SecurityAction
}

public struct SecuritySubject {
    let identifier: String
    let processID: Int32
    let userID: uid_t
    let groupID: gid_t
}

public struct SecurityObject {
    let identifier: String
    let path: String
    let owner: uid_t
    let permissions: Permission
}

public enum SecurityAction: String {
    case read = "READ"
    case write = "WRITE"
    case execute = "EXECUTE"
    case delete = "DELETE"
    case create = "CREATE"
}

public struct IntegrityReport {
    let timestamp: Date
    let filesChecked: Int
    let violations: [String]
    let checksumMismatches: Int
    let status: IntegrityStatus
}

public enum IntegrityStatus {
    case passed
    case failed
    case partial
}

// MARK: - Process Extension

extension Process {
    var userID: uid_t {
        return getuid()
    }
}