import Foundation

/// Minimal fail2ban-style manager: tracks repeated failures per IP and issues temporary firewall blocks
public final class Fail2BanManager {
    public static let shared = Fail2BanManager()
    
    private struct Counter { var count: Int; var firstSeen: Date }
    private var serviceThresholds: [String: (threshold: Int, window: TimeInterval, banSeconds: TimeInterval)] = [
        // Service name -> (failures within window) -> ban duration
        "sshd": (threshold: 5, window: 10 * 60, banSeconds: 15 * 60), // 5 fails/10m -> 15m ban
        "http-auth": (threshold: 20, window: 10 * 60, banSeconds: 10 * 60)
    ]
    private var ipToServiceFail: [String: [String: Counter]] = [:] // ip -> service -> counter
    private let queue = DispatchQueue(label: "fw.fail2ban.queue")
    
    private init() {}
    
    /// Record an authentication failure for service from a given IP
    public func recordFailure(service: String, ip: String) {
        queue.sync {
            let now = Date()
            var serviceMap = ipToServiceFail[ip] ?? [:]
            var ctr = serviceMap[service] ?? Counter(count: 0, firstSeen: now)
            let policy = serviceThresholds[service] ?? (threshold: 5, window: 10 * 60, banSeconds: 10 * 60)
            
            // Reset window if expired
            if now.timeIntervalSince(ctr.firstSeen) > policy.window {
                ctr = Counter(count: 0, firstSeen: now)
            }
            ctr.count += 1
            serviceMap[service] = ctr
            ipToServiceFail[ip] = serviceMap
            
            if ctr.count >= policy.threshold {
                FirewallManager.shared.tempBlockIP(ip, duration: policy.banSeconds)
                SecurityCore.shared.logSecurityEvent("Fail2Ban: banning \(ip) for service=\(service)", severity: .warning)
                // Reset after ban to avoid immediate re-ban
                ipToServiceFail[ip]?[service] = Counter(count: 0, firstSeen: now)
            }
        }
    }
    
    public func configure(service: String, threshold: Int, window: TimeInterval, banSeconds: TimeInterval) {
        serviceThresholds[service] = (threshold: threshold, window: window, banSeconds: banSeconds)
    }
}


