import Foundation

// MARK: - Firewall Manager
class FirewallManager: ObservableObject {
    @Published var isEnabled = true
    @Published var rules: [FirewallRule] = []
    @Published var blockedConnections: [BlockedConnection] = []
    @Published var statistics = FirewallStatistics()
    @Published var securityLevel: SecurityLevel = .medium
    
    enum SecurityLevel: String, CaseIterable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
        case paranoid = "Paranoid"
        
        var description: String {
            switch self {
            case .low: return "Allow most connections"
            case .medium: return "Balanced security"
            case .high: return "Block suspicious connections"
            case .paranoid: return "Block all except whitelisted"
            }
        }
    }
    
    init() {
        setupDefaultRules()
    }
    
    private func setupDefaultRules() {
        // Allow loopback
        rules.append(FirewallRule(
            name: "Allow Loopback",
            action: .allow,
            direction: .both,
            protocol: nil,
            sourceIP: "127.0.0.1",
            destinationIP: "127.0.0.1",
            port: nil,
            isEnabled: true,
            priority: 1000
        ))
        
        // Allow established connections
        rules.append(FirewallRule(
            name: "Allow Established",
            action: .allow,
            direction: .inbound,
            protocol: nil,
            sourceIP: nil,
            destinationIP: nil,
            port: nil,
            isEnabled: true,
            priority: 900,
            isStateful: true
        ))
        
        // Allow DNS
        rules.append(FirewallRule(
            name: "Allow DNS",
            action: .allow,
            direction: .outbound,
            protocol: .udp,
            sourceIP: nil,
            destinationIP: nil,
            port: 53,
            isEnabled: true,
            priority: 800
        ))
        
        // Allow HTTP/HTTPS
        rules.append(FirewallRule(
            name: "Allow Web Traffic",
            action: .allow,
            direction: .outbound,
            protocol: .tcp,
            sourceIP: nil,
            destinationIP: nil,
            port: nil,
            ports: [80, 443],
            isEnabled: true,
            priority: 700
        ))
        
        // Block common attack ports
        rules.append(FirewallRule(
            name: "Block Telnet",
            action: .block,
            direction: .inbound,
            protocol: .tcp,
            sourceIP: nil,
            destinationIP: nil,
            port: 23,
            isEnabled: true,
            priority: 600
        ))
        
        // Default deny rule (lowest priority)
        rules.append(FirewallRule(
            name: "Default Deny",
            action: .block,
            direction: .inbound,
            protocol: nil,
            sourceIP: nil,
            destinationIP: nil,
            port: nil,
            isEnabled: securityLevel == .paranoid,
            priority: 0
        ))
    }
    
    // MARK: - Packet Filtering
    
    func shouldAllowPacket(_ packet: NetworkPacket) -> Bool {
        guard isEnabled else { return true }
        
        statistics.packetsInspected += 1
        
        // Sort rules by priority (higher priority first)
        let sortedRules = rules
            .filter { $0.isEnabled }
            .sorted { $0.priority > $1.priority }
        
        for rule in sortedRules {
            if rule.matches(packet) {
                if rule.action == .allow {
                    statistics.packetsAllowed += 1
                    return true
                } else {
                    statistics.packetsBlocked += 1
                    logBlockedConnection(packet, rule: rule)
                    return false
                }
            }
        }
        
        // Default action based on security level
        let defaultAllow = securityLevel == .low
        if defaultAllow {
            statistics.packetsAllowed += 1
        } else {
            statistics.packetsBlocked += 1
            logBlockedConnection(packet, rule: nil)
        }
        return defaultAllow
    }
    
    func shouldAllowConnection(_ connection: NetworkConnection) -> Bool {
        guard isEnabled else { return true }
        
        // Create a virtual packet to test against rules
        let testPacket = NetworkPacket(
            source: connection.interface.ipAddress,
            destination: connection.endpoint,
            protocol: connection.protocol,
            data: Data()
        )
        
        return shouldAllowPacket(testPacket)
    }
    
    // MARK: - Rule Management
    
    func addRule(_ rule: FirewallRule) {
        rules.append(rule)
        rules.sort { $0.priority > $1.priority }
    }
    
    func removeRule(_ rule: FirewallRule) {
        rules.removeAll { $0.id == rule.id }
    }
    
    func updateRule(_ rule: FirewallRule) {
        if let index = rules.firstIndex(where: { $0.id == rule.id }) {
            rules[index] = rule
            rules.sort { $0.priority > $1.priority }
        }
    }
    
    func toggleRule(_ rule: FirewallRule) {
        if let index = rules.firstIndex(where: { $0.id == rule.id }) {
            rules[index].isEnabled.toggle()
        }
    }
    
    // MARK: - Security Level Management
    
    func setSecurityLevel(_ level: SecurityLevel) {
        securityLevel = level
        updateRulesForSecurityLevel()
    }
    
    private func updateRulesForSecurityLevel() {
        switch securityLevel {
        case .low:
            // Disable most blocking rules
            if let defaultDeny = rules.first(where: { $0.name == "Default Deny" }) {
                defaultDeny.isEnabled = false
            }
            
        case .medium:
            // Balanced approach
            if let defaultDeny = rules.first(where: { $0.name == "Default Deny" }) {
                defaultDeny.isEnabled = false
            }
            
        case .high:
            // Enable more restrictive rules
            if let defaultDeny = rules.first(where: { $0.name == "Default Deny" }) {
                defaultDeny.isEnabled = true
            }
            
        case .paranoid:
            // Only allow whitelisted connections
            if let defaultDeny = rules.first(where: { $0.name == "Default Deny" }) {
                defaultDeny.isEnabled = true
            }
            // Add more restrictive rules
            addParanoidRules()
        }
    }
    
    private func addParanoidRules() {
        // Block all inbound except established
        if !rules.contains(where: { $0.name == "Paranoid Block Inbound" }) {
            rules.append(FirewallRule(
                name: "Paranoid Block Inbound",
                action: .block,
                direction: .inbound,
                protocol: nil,
                sourceIP: nil,
                destinationIP: nil,
                port: nil,
                isEnabled: true,
                priority: 100
            ))
        }
    }
    
    // MARK: - Logging
    
    private func logBlockedConnection(_ packet: NetworkPacket, rule: FirewallRule?) {
        let blocked = BlockedConnection(
            timestamp: Date(),
            source: packet.source,
            destination: packet.destination,
            protocol: packet.protocol,
            rule: rule?.name ?? "Default Policy"
        )
        
        blockedConnections.insert(blocked, at: 0)
        
        // Keep only last 100 blocked connections
        if blockedConnections.count > 100 {
            blockedConnections.removeLast()
        }
    }
    
    func clearBlockedConnections() {
        blockedConnections.removeAll()
    }
    
    // MARK: - Statistics
    
    func resetStatistics() {
        statistics = FirewallStatistics()
    }
}

// MARK: - Firewall Rule
class FirewallRule: ObservableObject, Identifiable {
    let id = UUID()
    let name: String
    let action: Action
    let direction: Direction
    let `protocol`: NetworkProtocol?
    let sourceIP: String?
    let destinationIP: String?
    let port: Int?
    let ports: [Int]?
    @Published var isEnabled: Bool
    let priority: Int
    let isStateful: Bool
    
    enum Action {
        case allow, block
    }
    
    enum Direction {
        case inbound, outbound, both
    }
    
    init(name: String,
         action: Action,
         direction: Direction,
         protocol: NetworkProtocol? = nil,
         sourceIP: String? = nil,
         destinationIP: String? = nil,
         port: Int? = nil,
         ports: [Int]? = nil,
         isEnabled: Bool = true,
         priority: Int = 500,
         isStateful: Bool = false) {
        self.name = name
        self.action = action
        self.direction = direction
        self.protocol = `protocol`
        self.sourceIP = sourceIP
        self.destinationIP = destinationIP
        self.port = port
        self.ports = ports
        self.isEnabled = isEnabled
        self.priority = priority
        self.isStateful = isStateful
    }
    
    func matches(_ packet: NetworkPacket) -> Bool {
        // Check protocol
        if let ruleProtocol = protocol, packet.protocol != ruleProtocol {
            return false
        }
        
        // Check source IP
        if let ruleSource = sourceIP, !matchesIP(packet.source, pattern: ruleSource) {
            return false
        }
        
        // Check destination IP
        if let ruleDest = destinationIP, !matchesIP(packet.destination, pattern: ruleDest) {
            return false
        }
        
        // Check port (simplified - would need packet inspection in reality)
        // This is a placeholder for port matching logic
        
        return true
    }
    
    private func matchesIP(_ ip: String, pattern: String) -> Bool {
        // Simple IP matching - could be enhanced with CIDR support
        if pattern == "*" || pattern == "0.0.0.0/0" {
            return true
        }
        
        if pattern.contains("/") {
            // CIDR notation - simplified implementation
            return ip.hasPrefix(pattern.components(separatedBy: "/")[0])
        }
        
        return ip == pattern
    }
}

// MARK: - Supporting Types
struct BlockedConnection: Identifiable {
    let id = UUID()
    let timestamp: Date
    let source: String
    let destination: String
    let `protocol`: NetworkProtocol
    let rule: String
}

struct FirewallStatistics {
    var packetsInspected: UInt64 = 0
    var packetsAllowed: UInt64 = 0
    var packetsBlocked: UInt64 = 0
    var rulesEvaluated: UInt64 = 0
    
    var blockRate: Double {
        guard packetsInspected > 0 else { return 0 }
        return Double(packetsBlocked) / Double(packetsInspected) * 100
    }
}