import Foundation

/// Intrusion detection that can feed Fail2BanManager and FirewallManager
public final class IntrusionDetectionManager {
    public static let shared = IntrusionDetectionManager()
    
    private let suspiciousPatterns: [String] = [
        "../../", "<script>", "DROP TABLE", "rm -rf", "/etc/passwd"
    ]
    
    private init() {}
    
    public enum ThreatLevel { case none, low, medium, high, critical }
    
    public func scan(data: String) -> ThreatLevel {
        for pattern in suspiciousPatterns {
            if data.lowercased().contains(pattern.lowercased()) {
                SecurityCore.shared.logSecurityEvent("IDS: \(pattern) detected", severity: .critical)
                return .high
            }
        }
        if detectPortScan(in: data) { return .medium }
        return .none
    }
    
    public func recordAuthFailure(service: String, ip: String) {
        Fail2BanManager.shared.recordFailure(service: service, ip: ip)
    }
    
    private func detectPortScan(in data: String) -> Bool {
        let portPattern = #":\d{1,5}"#
        let regex = try? NSRegularExpression(pattern: portPattern)
        let matches = regex?.matches(in: data, range: NSRange(data.startIndex..., in: data))
        return (matches?.count ?? 0) > 10
    }
}

