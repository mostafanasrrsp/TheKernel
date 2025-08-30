import Foundation
import Network

/// UFW (Uncomplicated Firewall) inspired interface for RadiateOS
/// Provides simple yet powerful firewall management similar to Ubuntu's UFW
public class UFWFirewall {
    
    // MARK: - Singleton
    public static let shared = UFWFirewall()
    
    // MARK: - Properties
    private var isEnabled = false
    private var rules: [UFWRule] = []
    private var defaultIncoming: DefaultPolicy = .deny
    private var defaultOutgoing: DefaultPolicy = .allow
    private var defaultRouted: DefaultPolicy = .deny
    private var logging: LogLevel = .medium
    private var applicationProfiles: [String: ApplicationProfile] = [:]
    
    // Statistics
    private var statistics = FirewallStatistics()
    
    // MARK: - Initialization
    private init() {
        loadDefaultProfiles()
        loadIPTables()
    }
    
    // MARK: - UFW-style Commands
    
    /// Enable the firewall
    public func enable() -> CommandResult {
        isEnabled = true
        applyRules()
        return CommandResult(success: true, message: "Firewall is active and enabled on system startup")
    }
    
    /// Disable the firewall
    public func disable() -> CommandResult {
        isEnabled = false
        return CommandResult(success: true, message: "Firewall stopped and disabled on system startup")
    }
    
    /// Reload firewall rules
    public func reload() -> CommandResult {
        if !isEnabled {
            return CommandResult(success: false, message: "Firewall not enabled")
        }
        applyRules()
        return CommandResult(success: true, message: "Firewall reloaded")
    }
    
    /// Get firewall status
    public func status(verbose: Bool = false) -> FirewallStatus {
        var status = "Status: \(isEnabled ? "active" : "inactive")\n"
        
        if verbose {
            status += "\nDefault: \(defaultIncoming.rawValue) (incoming), \(defaultOutgoing.rawValue) (outgoing), \(defaultRouted.rawValue) (routed)\n"
            status += "New profiles: skip\n\n"
            
            if !rules.isEmpty {
                status += "To                         Action      From\n"
                status += "--                         ------      ----\n"
                
                for rule in rules {
                    status += rule.description + "\n"
                }
            }
        }
        
        return FirewallStatus(
            enabled: isEnabled,
            description: status,
            ruleCount: rules.count,
            defaultIncoming: defaultIncoming,
            defaultOutgoing: defaultOutgoing
        )
    }
    
    /// Allow a port or service
    public func allow(_ target: String, from source: String? = nil) -> CommandResult {
        let rule = createRule(action: .allow, target: target, source: source)
        rules.append(rule)
        
        if isEnabled {
            applyRule(rule)
        }
        
        return CommandResult(success: true, message: "Rule added")
    }
    
    /// Deny a port or service
    public func deny(_ target: String, from source: String? = nil) -> CommandResult {
        let rule = createRule(action: .deny, target: target, source: source)
        rules.append(rule)
        
        if isEnabled {
            applyRule(rule)
        }
        
        return CommandResult(success: true, message: "Rule added")
    }
    
    /// Reject a port or service (sends rejection packet)
    public func reject(_ target: String, from source: String? = nil) -> CommandResult {
        let rule = createRule(action: .reject, target: target, source: source)
        rules.append(rule)
        
        if isEnabled {
            applyRule(rule)
        }
        
        return CommandResult(success: true, message: "Rule added")
    }
    
    /// Limit connections (rate limiting)
    public func limit(_ target: String, from source: String? = nil) -> CommandResult {
        let rule = createRule(action: .limit, target: target, source: source)
        rule.rateLimit = RateLimit(connections: 6, period: 30) // 6 connections per 30 seconds
        rules.append(rule)
        
        if isEnabled {
            applyRule(rule)
        }
        
        return CommandResult(success: true, message: "Rule added")
    }
    
    /// Delete a rule
    public func delete(ruleNumber: Int) -> CommandResult {
        guard ruleNumber > 0 && ruleNumber <= rules.count else {
            return CommandResult(success: false, message: "Invalid rule number")
        }
        
        let rule = rules.remove(at: ruleNumber - 1)
        return CommandResult(success: true, message: "Rule deleted: \(rule.description)")
    }
    
    /// Insert a rule at specific position
    public func insert(at position: Int, action: RuleAction, target: String, from source: String? = nil) -> CommandResult {
        guard position > 0 && position <= rules.count + 1 else {
            return CommandResult(success: false, message: "Invalid position")
        }
        
        let rule = createRule(action: action, target: target, source: source)
        rules.insert(rule, at: position - 1)
        
        if isEnabled {
            applyRules()
        }
        
        return CommandResult(success: true, message: "Rule inserted")
    }
    
    /// Reset firewall to defaults
    public func reset() -> CommandResult {
        rules.removeAll()
        defaultIncoming = .deny
        defaultOutgoing = .allow
        defaultRouted = .deny
        isEnabled = false
        
        return CommandResult(success: true, message: "Firewall reset to defaults")
    }
    
    /// Set default policy
    public func setDefault(_ chain: Chain, policy: DefaultPolicy) -> CommandResult {
        switch chain {
        case .incoming:
            defaultIncoming = policy
        case .outgoing:
            defaultOutgoing = policy
        case .routed:
            defaultRouted = policy
        }
        
        if isEnabled {
            applyRules()
        }
        
        return CommandResult(success: true, message: "Default \(chain.rawValue) policy changed to '\(policy.rawValue)'")
    }
    
    /// Set logging level
    public func setLogging(_ level: LogLevel) -> CommandResult {
        logging = level
        return CommandResult(success: true, message: "Logging level set to '\(level.rawValue)'")
    }
    
    // MARK: - Application Profiles
    
    /// List available application profiles
    public func listApplications() -> [ApplicationProfile] {
        return Array(applicationProfiles.values)
    }
    
    /// Allow an application
    public func allowApplication(_ appName: String) -> CommandResult {
        guard let profile = applicationProfiles[appName] else {
            return CommandResult(success: false, message: "Application profile not found: \(appName)")
        }
        
        for port in profile.ports {
            _ = allow("\(port)/\(profile.protocol.rawValue)")
        }
        
        return CommandResult(success: true, message: "Rules updated for profile: \(appName)")
    }
    
    // MARK: - Advanced Features
    
    /// Rate limiting check
    public func checkRateLimit(for connection: Connection) -> Bool {
        guard isEnabled else { return true }
        
        for rule in rules {
            if let rateLimit = rule.rateLimit, rule.matches(connection) {
                return rateLimit.allows(connection)
            }
        }
        
        return true
    }
    
    /// Log connection attempt
    public func logConnection(_ connection: Connection, allowed: Bool) {
        guard logging != .off else { return }
        
        let logMessage = "[UFW \(allowed ? "ALLOW" : "BLOCK")] IN=\(connection.interface ?? "") " +
                        "SRC=\(connection.source) DST=\(connection.destination) " +
                        "PROTO=\(connection.protocol) SPT=\(connection.sourcePort) DPT=\(connection.destinationPort)"
        
        switch logging {
        case .low:
            if !allowed {
                print(logMessage)
            }
        case .medium:
            if !allowed || connection.isNewConnection {
                print(logMessage)
            }
        case .high, .full:
            print(logMessage)
        default:
            break
        }
        
        // Update statistics
        if allowed {
            statistics.allowedConnections += 1
        } else {
            statistics.blockedConnections += 1
        }
    }
    
    // MARK: - Private Methods
    
    private func createRule(action: RuleAction, target: String, source: String?) -> UFWRule {
        let rule = UFWRule()
        rule.action = action
        
        // Parse target (can be port, port/protocol, or application name)
        if let appProfile = applicationProfiles[target] {
            rule.destinationPort = appProfile.ports.first
            rule.protocol = appProfile.protocol
        } else if target.contains("/") {
            let parts = target.split(separator: "/")
            rule.destinationPort = Int(String(parts[0]))
            rule.protocol = Protocol(rawValue: String(parts[1]).uppercased()) ?? .tcp
        } else if let port = Int(target) {
            rule.destinationPort = port
            rule.protocol = .tcp
        }
        
        // Parse source
        if let source = source {
            rule.source = source
        }
        
        return rule
    }
    
    private func applyRule(_ rule: UFWRule) {
        // Apply rule to network filter
        // This would interface with the kernel in a real implementation
    }
    
    private func applyRules() {
        // Apply all rules
        for rule in rules {
            applyRule(rule)
        }
    }
    
    private func loadDefaultProfiles() {
        // Load application profiles (similar to /etc/ufw/applications.d/)
        
        applicationProfiles["SSH"] = ApplicationProfile(
            name: "SSH",
            title: "Secure Shell Server",
            description: "SSH server for secure remote access",
            ports: [22],
            protocol: .tcp
        )
        
        applicationProfiles["HTTP"] = ApplicationProfile(
            name: "HTTP",
            title: "Web Server",
            description: "HTTP web server",
            ports: [80],
            protocol: .tcp
        )
        
        applicationProfiles["HTTPS"] = ApplicationProfile(
            name: "HTTPS",
            title: "Secure Web Server",
            description: "HTTPS web server",
            ports: [443],
            protocol: .tcp
        )
        
        applicationProfiles["DNS"] = ApplicationProfile(
            name: "DNS",
            title: "Domain Name Server",
            description: "DNS server",
            ports: [53],
            protocol: .udp
        )
        
        applicationProfiles["Mail"] = ApplicationProfile(
            name: "Mail",
            title: "Mail Server",
            description: "SMTP/IMAP/POP3 mail server",
            ports: [25, 143, 993, 110, 995],
            protocol: .tcp
        )
    }
    
    private func loadIPTables() {
        // Load existing iptables rules if any
        // This would interface with system iptables in a real implementation
    }
}

// MARK: - Supporting Types

public class UFWRule {
    var action: RuleAction = .allow
    var direction: Direction = .in
    var protocol: Protocol = .any
    var source: String?
    var sourcePort: Int?
    var destination: String?
    var destinationPort: Int?
    var interface: String?
    var rateLimit: RateLimit?
    
    var description: String {
        var desc = ""
        
        // Format: "22/tcp                     ALLOW       Anywhere"
        if let port = destinationPort {
            desc += String(format: "%-26s", "\(port)/\(protocol.rawValue.lowercased())")
        } else {
            desc += String(format: "%-26s", "Anywhere")
        }
        
        desc += String(format: " %-11s", action.rawValue.uppercased())
        desc += source ?? "Anywhere"
        
        if rateLimit != nil {
            desc += " (limit)"
        }
        
        return desc
    }
    
    func matches(_ connection: Connection) -> Bool {
        if let src = source, src != connection.source && src != "Anywhere" {
            return false
        }
        
        if let dstPort = destinationPort, dstPort != connection.destinationPort {
            return false
        }
        
        if protocol != .any && protocol.rawValue != connection.protocol {
            return false
        }
        
        return true
    }
}

public enum RuleAction {
    case allow
    case deny
    case reject
    case limit
}

public enum Direction {
    case `in`
    case out
    case forward
}

public enum Protocol: String {
    case tcp = "TCP"
    case udp = "UDP"
    case icmp = "ICMP"
    case ah = "AH"
    case esp = "ESP"
    case gre = "GRE"
    case any = "ANY"
}

public enum DefaultPolicy: String {
    case allow = "allow"
    case deny = "deny"
    case reject = "reject"
}

public enum Chain: String {
    case incoming = "incoming"
    case outgoing = "outgoing"
    case routed = "routed"
}

public enum LogLevel: String {
    case off = "off"
    case low = "low"
    case medium = "medium"
    case high = "high"
    case full = "full"
}

public struct CommandResult {
    let success: Bool
    let message: String
}

public struct FirewallStatus {
    let enabled: Bool
    let description: String
    let ruleCount: Int
    let defaultIncoming: DefaultPolicy
    let defaultOutgoing: DefaultPolicy
}

public struct ApplicationProfile {
    let name: String
    let title: String
    let description: String
    let ports: [Int]
    let protocol: Protocol
}

public struct Connection {
    let source: String
    let sourcePort: Int
    let destination: String
    let destinationPort: Int
    let protocol: String
    let interface: String?
    let isNewConnection: Bool
}

public class RateLimit {
    private var connections: Int
    private var period: TimeInterval // in seconds
    private var connectionLog: [Date] = []
    
    init(connections: Int, period: TimeInterval) {
        self.connections = connections
        self.period = period
    }
    
    func allows(_ connection: Connection) -> Bool {
        let now = Date()
        
        // Remove old entries
        connectionLog.removeAll { entry in
            now.timeIntervalSince(entry) > period
        }
        
        // Check if limit exceeded
        if connectionLog.count >= connections {
            return false
        }
        
        // Log this connection
        connectionLog.append(now)
        return true
    }
}

private struct FirewallStatistics {
    var allowedConnections = 0
    var blockedConnections = 0
    var rateLimitedConnections = 0
}

// MARK: - UFW Command Line Interface

public class UFWCommandInterface {
    
    private let firewall = UFWFirewall.shared
    
    /// Parse and execute UFW-style commands
    public func execute(command: String) -> String {
        let parts = command.split(separator: " ").map(String.init)
        guard !parts.isEmpty else { return "No command provided" }
        
        guard parts[0] == "ufw" else { return "Command must start with 'ufw'" }
        guard parts.count > 1 else { return "Usage: ufw [--dry-run] COMMAND" }
        
        let subcommand = parts[1]
        
        switch subcommand {
        case "enable":
            return firewall.enable().message
            
        case "disable":
            return firewall.disable().message
            
        case "reload":
            return firewall.reload().message
            
        case "status":
            let verbose = parts.contains("verbose")
            return firewall.status(verbose: verbose).description
            
        case "allow":
            guard parts.count > 2 else { return "Usage: ufw allow <port/service>" }
            let from = extractFrom(parts)
            return firewall.allow(parts[2], from: from).message
            
        case "deny":
            guard parts.count > 2 else { return "Usage: ufw deny <port/service>" }
            let from = extractFrom(parts)
            return firewall.deny(parts[2], from: from).message
            
        case "reject":
            guard parts.count > 2 else { return "Usage: ufw reject <port/service>" }
            let from = extractFrom(parts)
            return firewall.reject(parts[2], from: from).message
            
        case "limit":
            guard parts.count > 2 else { return "Usage: ufw limit <port/service>" }
            let from = extractFrom(parts)
            return firewall.limit(parts[2], from: from).message
            
        case "delete":
            guard parts.count > 2, let ruleNum = Int(parts[2]) else {
                return "Usage: ufw delete <rule_number>"
            }
            return firewall.delete(ruleNumber: ruleNum).message
            
        case "reset":
            return firewall.reset().message
            
        case "default":
            guard parts.count > 3 else {
                return "Usage: ufw default <allow|deny|reject> <incoming|outgoing|routed>"
            }
            guard let policy = DefaultPolicy(rawValue: parts[2]),
                  let chain = Chain(rawValue: parts[3]) else {
                return "Invalid policy or chain"
            }
            return firewall.setDefault(chain, policy: policy).message
            
        case "logging":
            guard parts.count > 2, let level = LogLevel(rawValue: parts[2]) else {
                return "Usage: ufw logging <off|low|medium|high|full>"
            }
            return firewall.setLogging(level).message
            
        case "app":
            if parts.count > 2 && parts[2] == "list" {
                let apps = firewall.listApplications()
                return "Available applications:\n" + apps.map { "  \($0.name) - \($0.title)" }.joined(separator: "\n")
            }
            return "Usage: ufw app list"
            
        default:
            return "Unknown command: \(subcommand)"
        }
    }
    
    private func extractFrom(_ parts: [String]) -> String? {
        if let fromIndex = parts.firstIndex(of: "from"), fromIndex + 1 < parts.count {
            return parts[fromIndex + 1]
        }
        return nil
    }
}