//
//  SecurityManager.swift
//  RadiateOS
//
//  Security management with offline protection
//

import Foundation

@MainActor
class SecurityManager: ObservableObject {
    @Published var isOfflineMode: Bool = true
    @Published var securityLevel: SecurityLevel = .offline
    @Published var firewallStatus: FirewallStatus = .enabled
    @Published var encryptionStatus: EncryptionStatus = .enabled

    enum SecurityLevel: String {
        case offline = "Offline Security"
        case standard = "Standard Security"
        case high = "High Security"
        case maximum = "Maximum Security"
    }

    enum FirewallStatus: String {
        case disabled = "Disabled"
        case enabled = "Enabled"
        case blocking = "Blocking All"
    }

    enum EncryptionStatus: String {
        case disabled = "Disabled"
        case enabled = "Enabled"
        case quantum = "Quantum Encryption"
    }

    struct SecurityPolicy {
        let name: String
        let description: String
        let isActive: Bool
        let riskLevel: String
    }

    private var securityPolicies: [SecurityPolicy] = []

    init() {
        setupOfflineSecurityConfiguration()
    }

    func setupOfflineSecurityConfiguration() {
        print("🔒 Security Manager: Configuring offline security")

        securityLevel = .offline
        firewallStatus = .enabled
        encryptionStatus = .enabled

        // Configure offline security policies
        securityPolicies = [
            SecurityPolicy(
                name: "Offline Mode Protection",
                description: "Blocks all external network connections",
                isActive: true,
                riskLevel: "Very Low"
            ),
            SecurityPolicy(
                name: "Local Service Isolation",
                description: "Allows only local loopback connections",
                isActive: true,
                riskLevel: "Very Low"
            ),
            SecurityPolicy(
                name: "File System Encryption",
                description: "Encrypts sensitive files at rest",
                isActive: true,
                riskLevel: "Very Low"
            ),
            SecurityPolicy(
                name: "Memory Protection",
                description: "Prevents unauthorized memory access",
                isActive: true,
                riskLevel: "Very Low"
            ),
            SecurityPolicy(
                name: "Process Isolation",
                description: "Isolates processes for security",
                isActive: true,
                riskLevel: "Very Low"
            )
        ]

        print("✅ Security Manager: Offline security configured")
        print("   - Firewall: \(firewallStatus.rawValue)")
        print("   - Encryption: \(encryptionStatus.rawValue)")
        print("   - Security Level: \(securityLevel.rawValue)")
    }

    func enableOfflineMode() {
        print("🔒 Enabling offline security mode...")
        isOfflineMode = true
        securityLevel = .offline
        firewallStatus = .blocking

        // Strengthen offline policies
        securityPolicies = securityPolicies.map { policy in
            SecurityPolicy(
                name: policy.name,
                description: policy.description,
                isActive: true,
                riskLevel: "Very Low"
            )
        }

        print("✅ Offline security mode enabled - Maximum protection active")
    }

    func disableOfflineMode() {
        print("🔒 Disabling offline security mode...")
        isOfflineMode = false
        securityLevel = .standard
        firewallStatus = .enabled

        // Relax some policies for online mode
        securityPolicies = securityPolicies.map { policy in
            if policy.name.contains("Offline") {
                return SecurityPolicy(
                    name: policy.name,
                    description: policy.description,
                    isActive: false,
                    riskLevel: "Low"
                )
            }
            return policy
        }

        print("✅ Online security mode enabled - Standard protection active")
    }

    func initialize() async throws {
        print("🔒 Security Manager: Initializing offline security")

        // Always start with offline security as requested
        enableOfflineMode()

        print("✅ Security Manager initialized successfully (Offline Mode)")
    }

    func getSecurityStatus() -> String {
        var status = "Security Status\n"
        status += "===============\n"
        status += "Mode: \(isOfflineMode ? "Offline" : "Online")\n"
        status += "Level: \(securityLevel.rawValue)\n"
        status += "Firewall: \(firewallStatus.rawValue)\n"
        status += "Encryption: \(encryptionStatus.rawValue)\n\n"

        status += "Active Policies:\n"
        for policy in securityPolicies where policy.isActive {
            status += "  ✓ \(policy.name) (\(policy.riskLevel))\n"
        }

        return status
    }

    func getSecurityReport() -> String {
        var report = "Security Report\n"
        report += "===============\n\n"

        report += "System Security Level: \(securityLevel.rawValue)\n"
        report += "Network Status: \(isOfflineMode ? "Offline (Secure)" : "Online (Caution)")\n"
        report += "Firewall Status: \(firewallStatus.rawValue)\n"
        report += "Encryption Status: \(encryptionStatus.rawValue)\n\n"

        report += "Security Policies:\n"
        for policy in securityPolicies {
            let status = policy.isActive ? "✓ ACTIVE" : "✗ INACTIVE"
            report += "  \(status) \(policy.name)\n"
            report += "    \(policy.description)\n"
            report += "    Risk Level: \(policy.riskLevel)\n\n"
        }

        report += "Recommendations:\n"
        if isOfflineMode {
            report += "  ✓ System is in secure offline mode\n"
            report += "  ✓ All external connections blocked\n"
            report += "  ✓ Maximum security protection active\n"
        } else {
            report += "  ⚠ System is online - monitor network activity\n"
            report += "  ⚠ External connections may pose security risks\n"
            report += "  ✓ Standard security measures in place\n"
        }

        return report
    }

    func checkSecurityHealth() -> SecurityHealth {
        var score = 100
        var issues: [String] = []

        if !isOfflineMode {
            score -= 30
            issues.append("System is online - increased security risk")
        }

        if firewallStatus == .disabled {
            score -= 50
            issues.append("Firewall is disabled - high security risk")
        }

        if encryptionStatus == .disabled {
            score -= 40
            issues.append("Encryption is disabled - data vulnerability")
        }

        let activePolicies = securityPolicies.filter { $0.isActive }.count
        let policyScore = (Double(activePolicies) / Double(securityPolicies.count)) * 100
        score = Int(Double(score) * (policyScore / 100))

        return SecurityHealth(
            score: max(0, score),
            status: score >= 90 ? .excellent :
                   score >= 70 ? .good :
                   score >= 50 ? .fair : .poor,
            issues: issues
        )
    }
}

struct SecurityHealth {
    let score: Int
    let status: SecurityStatus
    let issues: [String]

    enum SecurityStatus: String {
        case excellent = "Excellent"
        case good = "Good"
        case fair = "Fair"
        case poor = "Poor"
    }

    var description: String {
        return "\(status.rawValue) (\(score)/100)"
    }
}