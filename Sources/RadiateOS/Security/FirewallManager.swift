import Foundation

/// Advanced firewall system inspired by Ubuntu's UFW and iptables
public class FirewallManager {
    
    // MARK: - Singleton
    public static let shared = FirewallManager()
    
    // MARK: - Properties
    private var rules: [FirewallRule] = []
    private var isEnabled = false
    private var defaultPolicy: FirewallPolicy = .deny
    private var connectionTable: [ConnectionEntry] = []
    private var blockedIPs: Set<String> = []
    private var trustedZones: Set<String> = []
    
    // MARK: - Statistics
    private var statistics = FirewallStatistics()
    
    // MARK: - Initialization
    private init() {
        setupDefaultRules()
        loadConfiguration()
    }
    
    // MARK: - Firewall Control
    
    public func enable() {
        isEnabled = true
        SecurityCore.shared.logSecurityEvent("Firewall enabled", severity: .info)
        applyRules()
    }
    
    public func disable() {
        isEnabled = false
        SecurityCore.shared.logSecurityEvent("Firewall disabled", severity: .warning)
    }
    
    public func status() -> FirewallStatus {
        return FirewallStatus(
            enabled: isEnabled,
            defaultPolicy: defaultPolicy,
            activeRules: rules.count,
            blockedConnections: statistics.blockedConnections,
            allowedConnections: statistics.allowedConnections
        )
    }
    
    // MARK: - Rule Management
    
    public func addRule(_ rule: FirewallRule) {
        rules.append(rule)
        rules.sort { $0.priority < $1.priority }
        
        SecurityCore.shared.logSecurityEvent(
            "Firewall rule added: \(rule.description)",
            severity: .info
        )
        
        if isEnabled {
            applyRules()
        }
    }
    
    public func removeRule(id: UUID) {
        rules.removeAll { $0.id == id }
        
        SecurityCore.shared.logSecurityEvent(
            "Firewall rule removed: \(id)",
            severity: .info
        )
        
        if isEnabled {
            applyRules()
        }
    }
    
    public func listRules() -> [FirewallRule] {
        return rules
    }
    
    // MARK: - Connection Filtering
    
    public func shouldAllowConnection(_ connection: NetworkConnection) -> Bool {
        guard isEnabled else { return true }
        
        // Check if IP is blocked
        if blockedIPs.contains(connection.sourceIP) {
            statistics.blockedConnections += 1
            logConnection(connection, allowed: false, reason: "Blocked IP")
            return false
        }
        
        // Check trusted zones
        if trustedZones.contains(connection.sourceIP) {
            statistics.allowedConnections += 1
            logConnection(connection, allowed: true, reason: "Trusted zone")
            return true
        }
        
        // Check rules in priority order
        for rule in rules {
            if rule.matches(connection) {
                let allowed = rule.action == .allow
                
                if allowed {
                    statistics.allowedConnections += 1
                } else {
                    statistics.blockedConnections += 1
                }
                
                logConnection(connection, allowed: allowed, reason: "Rule: \(rule.name)")
                return allowed
            }
        }
        
        // Apply default policy
        let allowed = defaultPolicy == .allow
        
        if allowed {
            statistics.allowedConnections += 1
        } else {
            statistics.blockedConnections += 1
        }
        
        logConnection(connection, allowed: allowed, reason: "Default policy")
        return allowed
    }
    
    // MARK: - IP Management
    
    public func blockIP(_ ip: String) {
        blockedIPs.insert(ip)
        SecurityCore.shared.logSecurityEvent("IP blocked: \(ip)", severity: .warning)
    }
    
    public func unblockIP(_ ip: String) {
        blockedIPs.remove(ip)
        SecurityCore.shared.logSecurityEvent("IP unblocked: \(ip)", severity: .info)
    }
    
    public func addTrustedZone(_ zone: String) {
        trustedZones.insert(zone)
        SecurityCore.shared.logSecurityEvent("Trusted zone added: \(zone)", severity: .info)
    }
    
    // MARK: - DDoS Protection
    
    public func detectDDoS() -> Bool {
        let recentConnections = connectionTable.filter { 
            Date().timeIntervalSince($0.timestamp) < 60 // Last minute
        }
        
        // Group by source IP
        var connectionCounts: [String: Int] = [:]
        for entry in recentConnections {
            connectionCounts[entry.sourceIP, default: 0] += 1
        }
        
        // Check for suspicious activity
        for (ip, count) in connectionCounts {
            if count > 100 { // More than 100 connections per minute
                blockIP(ip)
                SecurityCore.shared.logSecurityEvent(
                    "Potential DDoS detected from \(ip): \(count) connections",
                    severity: .critical
                )
                return true
            }
        }
        
        return false
    }
    
    // MARK: - Private Methods
    
    private func setupDefaultRules() {
        // Allow localhost
        addRule(FirewallRule(
            name: "Allow Localhost",
            priority: 0,
            action: .allow,
            protocol: .any,
            sourceIP: "127.0.0.1",
            destinationPort: nil
        ))
        
        // Allow established connections
        addRule(FirewallRule(
            name: "Allow Established",
            priority: 1,
            action: .allow,
            protocol: .any,
            sourceIP: nil,
            destinationPort: nil,
            isEstablished: true
        ))
        
        // Allow SSH (port 22)
        addRule(FirewallRule(
            name: "Allow SSH",
            priority: 10,
            action: .allow,
            protocol: .tcp,
            sourceIP: nil,
            destinationPort: 22
        ))
        
        // Allow HTTP (port 80)
        addRule(FirewallRule(
            name: "Allow HTTP",
            priority: 20,
            action: .allow,
            protocol: .tcp,
            sourceIP: nil,
            destinationPort: 80
        ))
        
        // Allow HTTPS (port 443)
        addRule(FirewallRule(
            name: "Allow HTTPS",
            priority: 21,
            action: .allow,
            protocol: .tcp,
            sourceIP: nil,
            destinationPort: 443
        ))
    }
    
    private func loadConfiguration() {
        // Load saved configuration
        // For demo, using defaults
    }
    
    private func applyRules() {
        // Apply firewall rules to system
        // This would interface with system-level firewall
    }
    
    private func logConnection(_ connection: NetworkConnection, allowed: Bool, reason: String) {
        let entry = ConnectionEntry(
            sourceIP: connection.sourceIP,
            destinationIP: connection.destinationIP,
            port: connection.port,
            protocol: connection.protocol,
            allowed: allowed,
            reason: reason,
            timestamp: Date()
        )
        
        connectionTable.append(entry)
        
        // Keep only recent entries (last 1000)
        if connectionTable.count > 1000 {
            connectionTable.removeFirst()
        }
    }
    
    // MARK: - Types
    
    public struct FirewallRule {
        let id = UUID()
        let name: String
        let priority: Int
        let action: FirewallAction
        let protocol: NetworkProtocol
        let sourceIP: String?
        let destinationPort: Int?
        var isEstablished: Bool = false
        
        var description: String {
            var desc = "\(name): \(action.rawValue) \(protocol.rawValue)"
            if let ip = sourceIP {
                desc += " from \(ip)"
            }
            if let port = destinationPort {
                desc += " to port \(port)"
            }
            return desc
        }
        
        func matches(_ connection: NetworkConnection) -> Bool {
            // Check protocol
            if protocol != .any && protocol != connection.protocol {
                return false
            }
            
            // Check source IP
            if let ruleIP = sourceIP, ruleIP != connection.sourceIP {
                return false
            }
            
            // Check destination port
            if let rulePort = destinationPort, rulePort != connection.port {
                return false
            }
            
            return true
        }
    }
    
    public enum FirewallAction: String {
        case allow = "ALLOW"
        case deny = "DENY"
        case reject = "REJECT"
    }
    
    public enum FirewallPolicy: String {
        case allow = "ALLOW"
        case deny = "DENY"
    }
    
    public enum NetworkProtocol: String {
        case tcp = "TCP"
        case udp = "UDP"
        case icmp = "ICMP"
        case any = "ANY"
    }
    
    public struct NetworkConnection {
        let sourceIP: String
        let destinationIP: String
        let port: Int
        let protocol: NetworkProtocol
    }
    
    public struct FirewallStatus {
        let enabled: Bool
        let defaultPolicy: FirewallPolicy
        let activeRules: Int
        let blockedConnections: Int
        let allowedConnections: Int
    }
    
    private struct FirewallStatistics {
        var blockedConnections = 0
        var allowedConnections = 0
        var detectedThreats = 0
    }
    
    private struct ConnectionEntry {
        let sourceIP: String
        let destinationIP: String
        let port: Int
        let protocol: NetworkProtocol
        let allowed: Bool
        let reason: String
        let timestamp: Date
    }
}

// MARK: - Intrusion Detection System

public class IntrusionDetectionSystem {
    
    private var suspiciousPatterns: [String] = [
        "../../", // Directory traversal
        "<script>", // XSS attempt
        "DROP TABLE", // SQL injection
        "rm -rf", // Dangerous command
        "/etc/passwd", // System file access
    ]
    
    public func scanForThreats(_ data: String) -> ThreatLevel {
        for pattern in suspiciousPatterns {
            if data.lowercased().contains(pattern.lowercased()) {
                SecurityCore.shared.logSecurityEvent(
                    "Potential threat detected: \(pattern)",
                    severity: .critical
                )
                return .high
            }
        }
        
        // Check for port scanning
        if detectPortScan(in: data) {
            return .medium
        }
        
        return .none
    }
    
    private func detectPortScan(in data: String) -> Bool {
        // Simplified port scan detection
        let portPattern = #":\d{1,5}"#
        let regex = try? NSRegularExpression(pattern: portPattern)
        let matches = regex?.matches(in: data, range: NSRange(data.startIndex..., in: data))
        return (matches?.count ?? 0) > 10
    }
    
    public enum ThreatLevel {
        case none
        case low
        case medium
        case high
        case critical
    }
}