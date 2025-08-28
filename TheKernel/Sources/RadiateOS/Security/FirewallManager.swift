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
    
    // UFW-like features
    private var logLevel: FirewallLogLevel = .low
    private var activeProfiles: Set<String> = []
    private let rateLimiter = RateLimiter()
    
    // Temporary (fail2ban-style) blocks
    private var temporaryBlocks: [String: Date] = [:] // IP -> expiry
    
    // MARK: - Statistics
    private var statistics = FirewallStatistics()
    
    // MARK: - Initialization
    private init() {
        setupDefaultRules()
        setupPredefinedProfiles()
        // Default: enable OpenSSH and WWW Full profiles (common baseline)
        _ = enableProfile("OpenSSH")
        _ = enableProfile("WWW Full")
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
            allowedConnections: statistics.allowedConnections,
            logLevel: logLevel,
            activeProfiles: Array(activeProfiles).sorted()
        )
    }
    
    // MARK: - Configuration
    
    public func setDefaultPolicy(_ policy: FirewallPolicy) {
        defaultPolicy = policy
        if isEnabled { applyRules() }
        SecurityCore.shared.logSecurityEvent("Firewall default policy set to \(policy.rawValue)", severity: .info)
    }
    
    public func setLogLevel(_ level: FirewallLogLevel) {
        logLevel = level
        SecurityCore.shared.logSecurityEvent("Firewall log level set to \(level.rawValue)", severity: .info)
    }
    
    // MARK: - Rule Management
    
    @discardableResult
    public func addRule(_ rule: FirewallRule) -> UUID {
        rules.append(rule)
        rules.sort { $0.priority < $1.priority }
        SecurityCore.shared.logSecurityEvent(
            "Firewall rule added: \(rule.description)",
            severity: .info
        )
        if isEnabled { applyRules() }
        return rule.id
    }
    
    public func removeRule(id: UUID) {
        rules.removeAll { $0.id == id }
        SecurityCore.shared.logSecurityEvent(
            "Firewall rule removed: \(id)",
            severity: .info
        )
        if isEnabled { applyRules() }
    }
    
    public func listRules() -> [FirewallRule] { rules }
    
    // MARK: - Profile Management (UFW-like)
    
    private var predefinedProfiles: [String: UFWProfile] = [:]
    
    public func listProfiles() -> [UFWProfile] {
        Array(predefinedProfiles.values).sorted { $0.name < $1.name }
    }
    
    @discardableResult
    public func enableProfile(_ name: String) -> Bool {
        guard let profile = predefinedProfiles[name] else { return false }
        guard !activeProfiles.contains(name) else { return true }
        for r in profile.rules { _ = addRule(r) }
        activeProfiles.insert(name)
        SecurityCore.shared.logSecurityEvent("Profile enabled: \(name)", severity: .info)
        return true
    }
    
    @discardableResult
    public func disableProfile(_ name: String) -> Bool {
        guard activeProfiles.contains(name), let profile = predefinedProfiles[name] else { return false }
        let removedIds = Set(profile.rules.map { $0.id })
        rules.removeAll { removedIds.contains($0.id) }
        activeProfiles.remove(name)
        SecurityCore.shared.logSecurityEvent("Profile disabled: \(name)", severity: .warning)
        if isEnabled { applyRules() }
        return true
    }
    
    // MARK: - Connection Filtering
    
    public func shouldAllowConnection(_ connection: NetworkConnection) -> Bool {
        guard isEnabled else { return true }
        
        cleanupExpiredTemporaryBlocks()
        
        // Check temporary bans
        if let expiry = temporaryBlocks[connection.sourceIP], expiry > Date() {
            statistics.blockedConnections += 1
            logDecision(connection, allowed: false, reason: "Temporary block active")
            return false
        }
        
        // Check if IP is blocked
        if blockedIPs.contains(connection.sourceIP) {
            statistics.blockedConnections += 1
            logDecision(connection, allowed: false, reason: "Blocked IP")
            return false
        }
        
        // Check trusted zones
        if trustedZones.contains(connection.sourceIP) {
            statistics.allowedConnections += 1
            logDecision(connection, allowed: true, reason: "Trusted zone")
            return true
        }
        
        // Rate limiting (SSH stricter by default)
        if rateLimiter.isRateLimited(ip: connection.sourceIP, port: connection.port) {
            statistics.blockedConnections += 1
            logDecision(connection, allowed: false, reason: "Rate limited")
            return false
        }
        
        // Check rules in priority order
        for rule in rules {
            if rule.matches(connection) {
                let allowed = rule.action == .allow
                if allowed { statistics.allowedConnections += 1 } else { statistics.blockedConnections += 1 }
                logDecision(connection, allowed: allowed, reason: "Rule: \(rule.name)")
                return allowed
            }
        }
        
        // Apply default policy
        let allowed = defaultPolicy == .allow
        if allowed { statistics.allowedConnections += 1 } else { statistics.blockedConnections += 1 }
        logDecision(connection, allowed: allowed, reason: "Default policy")
        return allowed
    }
    
    // MARK: - IP Management
    
    public func blockIP(_ ip: String) {
        blockedIPs.insert(ip)
        SecurityCore.shared.logSecurityEvent("IP blocked: \(ip)", severity: .warning)
    }
    
    public func unblockIP(_ ip: String) {
        blockedIPs.remove(ip)
        temporaryBlocks.removeValue(forKey: ip)
        SecurityCore.shared.logSecurityEvent("IP unblocked: \(ip)", severity: .info)
    }
    
    public func tempBlockIP(_ ip: String, duration: TimeInterval) {
        temporaryBlocks[ip] = Date().addingTimeInterval(duration)
        SecurityCore.shared.logSecurityEvent("IP temporarily blocked: \(ip) for \(Int(duration))s", severity: .warning)
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
        _ = addRule(FirewallRule(
            name: "Allow Localhost",
            priority: 0,
            action: .allow,
            protocol: .any,
            sourceIP: "127.0.0.1",
            destinationPort: nil
        ))
        
        // Allow established connections (modeled as any for now)
        _ = addRule(FirewallRule(
            name: "Allow Established",
            priority: 1,
            action: .allow,
            protocol: .any,
            sourceIP: nil,
            destinationPort: nil,
            isEstablished: true
        ))
    }
    
    private func setupPredefinedProfiles() {
        func tcpRule(name: String, priority: Int, port: Int) -> FirewallRule {
            FirewallRule(
                name: name,
                priority: priority,
                action: .allow,
                protocol: .tcp,
                sourceIP: nil,
                destinationPort: port
            )
        }
        
        let openSSH = UFWProfile(
            name: "OpenSSH",
            description: "Secure shell access on port 22",
            rules: [tcpRule(name: "Allow SSH", priority: 10, port: 22)]
        )
        
        let wwwFull = UFWProfile(
            name: "WWW Full",
            description: "Web server (HTTP 80, HTTPS 443)",
            rules: [
                tcpRule(name: "Allow HTTP", priority: 20, port: 80),
                tcpRule(name: "Allow HTTPS", priority: 21, port: 443)
            ]
        )
        
        let dns = UFWProfile(
            name: "DNS",
            description: "Domain Name System (TCP/UDP 53)",
            rules: [
                FirewallRule(name: "Allow DNS TCP", priority: 30, action: .allow, protocol: .tcp, sourceIP: nil, destinationPort: 53),
                FirewallRule(name: "Allow DNS UDP", priority: 31, action: .allow, protocol: .udp, sourceIP: nil, destinationPort: 53)
            ]
        )
        
        let ntp = UFWProfile(
            name: "NTP",
            description: "Network Time Protocol (UDP 123)",
            rules: [
                FirewallRule(name: "Allow NTP", priority: 40, action: .allow, protocol: .udp, sourceIP: nil, destinationPort: 123)
            ]
        )
        
        predefinedProfiles[openSSH.name] = openSSH
        predefinedProfiles[wwwFull.name] = wwwFull
        predefinedProfiles[dns.name] = dns
        predefinedProfiles[ntp.name] = ntp
        
        // Rate limits (defaults + overrides)
        rateLimiter.setDefaultLimit(RateLimit(maxRequests: 60, perSeconds: 60))
        rateLimiter.setOverride(forPort: 22, limit: RateLimit(maxRequests: 6, perSeconds: 60)) // SSH typical
        rateLimiter.setOverride(forPort: 80, limit: RateLimit(maxRequests: 600, perSeconds: 60)) // HTTP
        rateLimiter.setOverride(forPort: 443, limit: RateLimit(maxRequests: 600, perSeconds: 60)) // HTTPS
    }
    
    private func loadConfiguration() {
        // Load saved configuration (placeholder)
    }
    
    private func applyRules() {
        // Apply firewall rules to system (placeholder)
    }
    
    private func cleanupExpiredTemporaryBlocks() {
        let now = Date()
        temporaryBlocks = temporaryBlocks.filter { $0.value > now }
    }
    
    private func logDecision(_ connection: NetworkConnection, allowed: Bool, reason: String) {
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
        if connectionTable.count > 1000 { connectionTable.removeFirst() }
        
        guard logLevel != .off else { return }
        let base = "\(allowed ? "ALLOW" : "DENY") \(connection.protocol.rawValue) \(connection.sourceIP) -> \(connection.destinationIP):\(connection.port)"
        switch logLevel {
        case .off:
            break
        case .low:
            SecurityCore.shared.logSecurityEvent("[FW] \(base)", severity: allowed ? .info : .warning)
        case .medium:
            SecurityCore.shared.logSecurityEvent("[FW] \(base) reason=\(reason)", severity: allowed ? .info : .warning)
        case .high:
            SecurityCore.shared.logSecurityEvent("[FW] \(base) reason=\(reason) policy=\(defaultPolicy.rawValue) profiles=\(activeProfiles.sorted().joined(separator: ","))", severity: allowed ? .info : .warning)
        }
    }
    
    // MARK: - Types
    
    public struct FirewallRule {
        let id = UUID()
        let name: String
        let priority: Int
        let action: FirewallAction
        let `protocol`: NetworkProtocol
        let sourceIP: String?
        let destinationPort: Int?
        var isEstablished: Bool = false
        
        var description: String {
            var desc = "\(name): \(action.rawValue) \(`protocol`.rawValue)"
            if let ip = sourceIP { desc += " from \(ip)" }
            if let port = destinationPort { desc += " to port \(port)" }
            return desc
        }
        
        func matches(_ connection: NetworkConnection) -> Bool {
            // Check protocol
            if `protocol` != .any && `protocol` != connection.protocol { return false }
            // Check source IP
            if let ruleIP = sourceIP, ruleIP != connection.sourceIP { return false }
            // Check destination port
            if let rulePort = destinationPort, rulePort != connection.port { return false }
            return true
        }
    }
    
    public enum FirewallAction: String { case allow = "ALLOW"; case deny = "DENY"; case reject = "REJECT" }
    public enum FirewallPolicy: String { case allow = "ALLOW"; case deny = "DENY" }
    public enum FirewallLogLevel: String { case off = "OFF"; case low = "LOW"; case medium = "MEDIUM"; case high = "HIGH" }
    
    public enum NetworkProtocol: String { case tcp = "TCP"; case udp = "UDP"; case icmp = "ICMP"; case any = "ANY" }
    
    public struct NetworkConnection {
        let sourceIP: String
        let destinationIP: String
        let port: Int
        let `protocol`: NetworkProtocol
    }
    
    public struct FirewallStatus {
        let enabled: Bool
        let defaultPolicy: FirewallPolicy
        let activeRules: Int
        let blockedConnections: Int
        let allowedConnections: Int
        let logLevel: FirewallLogLevel
        let activeProfiles: [String]
    }
    
    private struct FirewallStatistics { var blockedConnections = 0; var allowedConnections = 0; var detectedThreats = 0 }
    
    private struct ConnectionEntry {
        let sourceIP: String
        let destinationIP: String
        let port: Int
        let `protocol`: NetworkProtocol
        let allowed: Bool
        let reason: String
        let timestamp: Date
    }
    
    public struct UFWProfile: Equatable {
        public let name: String
        public let description: String
        public let rules: [FirewallRule]
    }
}

// MARK: - Rate Limiter

public struct RateLimit {
    public let maxRequests: Int
    public let perSeconds: TimeInterval
}

fileprivate final class RateLimiter {
    private var defaultLimit = RateLimit(maxRequests: 60, perSeconds: 60)
    private var overrides: [Int: RateLimit] = [:] // port -> limit
    private var buckets: [String: [Date]] = [:] // key(ip:port) -> timestamps
    private let queue = DispatchQueue(label: "fw.ratelimiter.queue")
    
    func setDefaultLimit(_ limit: RateLimit) { defaultLimit = limit }
    func setOverride(forPort port: Int, limit: RateLimit) { overrides[port] = limit }
    
    func isRateLimited(ip: String, port: Int) -> Bool {
        let key = "\(ip):\(port)"
        let limit = overrides[port] ?? defaultLimit
        let now = Date()
        let cutoff = now.addingTimeInterval(-limit.perSeconds)
        
        return queue.sync {
            var times = buckets[key] ?? []
            times = times.filter { $0 > cutoff }
            if times.count >= limit.maxRequests {
                buckets[key] = times
                return true
            }
            times.append(now)
            buckets[key] = times
            return false
        }
    }
}

// MARK: - SecurityCore stub (if not linked in target, replace with your concrete implementation)

public class SecurityCore {
    public static let shared = SecurityCore()
    public enum Severity { case info, warning, critical }
    public func logSecurityEvent(_ message: String, severity: Severity) { /* Hook into your logging */ }
}

