import Foundation

// MARK: - DNS Resolver
class DNSResolver: ObservableObject {
    @Published var cache: [String: DNSRecord] = [:]
    @Published var servers: [String] = []
    @Published var queryHistory: [DNSQuery] = []
    @Published var statistics = DNSStatistics()
    
    private let cacheTimeout: TimeInterval = 300 // 5 minutes
    private let queue = DispatchQueue(label: "com.radiateos.dns")
    
    init() {
        setupDefaultServers()
        preloadCommonRecords()
    }
    
    private func setupDefaultServers() {
        servers = [
            "8.8.8.8",      // Google DNS
            "8.8.4.4",      // Google DNS Secondary
            "1.1.1.1",      // Cloudflare DNS
            "1.0.0.1",      // Cloudflare DNS Secondary
            "208.67.222.222", // OpenDNS
            "208.67.220.220"  // OpenDNS Secondary
        ]
    }
    
    private func preloadCommonRecords() {
        // Preload some common DNS records for simulation
        cache["localhost"] = DNSRecord(
            hostname: "localhost",
            ipAddress: "127.0.0.1",
            type: .A,
            ttl: 86400,
            timestamp: Date()
        )
        
        cache["radiateos.local"] = DNSRecord(
            hostname: "radiateos.local",
            ipAddress: "192.168.1.100",
            type: .A,
            ttl: 3600,
            timestamp: Date()
        )
    }
    
    // MARK: - DNS Resolution
    
    func resolve(_ hostname: String, type: DNSRecordType = .A, completion: @escaping (Result<DNSRecord, DNSError>) -> Void) {
        // Check cache first
        if let cached = getCachedRecord(hostname) {
            statistics.cacheHits += 1
            completion(.success(cached))
            return
        }
        
        statistics.cacheMisses += 1
        
        // Log query
        let query = DNSQuery(
            hostname: hostname,
            type: type,
            server: servers.first ?? "",
            timestamp: Date()
        )
        queryHistory.insert(query, at: 0)
        if queryHistory.count > 100 {
            queryHistory.removeLast()
        }
        
        // Simulate DNS resolution
        queue.async { [weak self] in
            self?.performDNSLookup(hostname: hostname, type: type) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let record):
                        self?.cache[hostname] = record
                        self?.statistics.successfulQueries += 1
                        completion(.success(record))
                    case .failure(let error):
                        self?.statistics.failedQueries += 1
                        completion(.failure(error))
                    }
                }
            }
        }
    }
    
    private func getCachedRecord(_ hostname: String) -> DNSRecord? {
        guard let record = cache[hostname] else { return nil }
        
        // Check if cache entry is still valid
        let age = Date().timeIntervalSince(record.timestamp)
        if age < TimeInterval(record.ttl) {
            return record
        }
        
        // Remove expired entry
        cache.removeValue(forKey: hostname)
        return nil
    }
    
    private func performDNSLookup(hostname: String, type: DNSRecordType, completion: @escaping (Result<DNSRecord, DNSError>) -> Void) {
        // Simulate DNS lookup with delay
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
            // Simulate successful resolution for common domains
            let commonDomains = [
                "google.com": "142.250.80.46",
                "apple.com": "17.253.144.10",
                "github.com": "140.82.112.4",
                "microsoft.com": "20.70.246.20",
                "stackoverflow.com": "151.101.1.69"
            ]
            
            if let ip = commonDomains[hostname] {
                let record = DNSRecord(
                    hostname: hostname,
                    ipAddress: ip,
                    type: type,
                    ttl: 300,
                    timestamp: Date()
                )
                completion(.success(record))
            } else if hostname.hasSuffix(".local") {
                // Local domain
                let record = DNSRecord(
                    hostname: hostname,
                    ipAddress: "192.168.1.\(Int.random(in: 2...254))",
                    type: type,
                    ttl: 60,
                    timestamp: Date()
                )
                completion(.success(record))
            } else {
                // Generate random IP for unknown domains
                let record = DNSRecord(
                    hostname: hostname,
                    ipAddress: "\(Int.random(in: 1...223)).\(Int.random(in: 0...255)).\(Int.random(in: 0...255)).\(Int.random(in: 1...254))",
                    type: type,
                    ttl: 300,
                    timestamp: Date()
                )
                completion(.success(record))
            }
        }
    }
    
    // MARK: - Reverse DNS
    
    func reverseLookup(_ ipAddress: String, completion: @escaping (Result<String, DNSError>) -> Void) {
        queue.async {
            // Simulate reverse DNS lookup
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
                // Check if we have this IP in cache
                for (hostname, record) in self.cache {
                    if record.ipAddress == ipAddress {
                        completion(.success(hostname))
                        return
                    }
                }
                
                // Simulate reverse lookup for known IPs
                let knownIPs = [
                    "127.0.0.1": "localhost",
                    "8.8.8.8": "dns.google",
                    "1.1.1.1": "one.one.one.one"
                ]
                
                if let hostname = knownIPs[ipAddress] {
                    completion(.success(hostname))
                } else {
                    completion(.success("host-\(ipAddress.replacingOccurrences(of: ".", with: "-")).reverse-dns.local"))
                }
            }
        }
    }
    
    // MARK: - Cache Management
    
    func clearCache() {
        cache.removeAll()
        statistics.cacheClears += 1
    }
    
    func flushExpiredEntries() {
        let now = Date()
        cache = cache.filter { _, record in
            let age = now.timeIntervalSince(record.timestamp)
            return age < TimeInterval(record.ttl)
        }
    }
    
    // MARK: - Server Management
    
    func addServer(_ server: String) {
        if !servers.contains(server) {
            servers.append(server)
        }
    }
    
    func removeServer(_ server: String) {
        servers.removeAll { $0 == server }
    }
    
    func setPrimaryServer(_ server: String) {
        if let index = servers.firstIndex(of: server) {
            servers.remove(at: index)
            servers.insert(server, at: 0)
        }
    }
}

// MARK: - DNS Record Types
enum DNSRecordType: String, CaseIterable {
    case A = "A"           // IPv4 address
    case AAAA = "AAAA"     // IPv6 address
    case CNAME = "CNAME"   // Canonical name
    case MX = "MX"         // Mail exchange
    case NS = "NS"         // Name server
    case PTR = "PTR"       // Pointer (reverse DNS)
    case SOA = "SOA"       // Start of authority
    case TXT = "TXT"       // Text record
    case SRV = "SRV"       // Service record
}

// MARK: - DNS Record
struct DNSRecord: Identifiable {
    let id = UUID()
    let hostname: String
    let ipAddress: String
    let type: DNSRecordType
    let ttl: Int // Time to live in seconds
    let timestamp: Date
    
    var isExpired: Bool {
        let age = Date().timeIntervalSince(timestamp)
        return age >= TimeInterval(ttl)
    }
    
    var remainingTTL: Int {
        let age = Date().timeIntervalSince(timestamp)
        let remaining = TimeInterval(ttl) - age
        return max(0, Int(remaining))
    }
}

// MARK: - DNS Query
struct DNSQuery: Identifiable {
    let id = UUID()
    let hostname: String
    let type: DNSRecordType
    let server: String
    let timestamp: Date
}

// MARK: - DNS Error
enum DNSError: Error, LocalizedError {
    case serverUnreachable
    case timeout
    case noRecordFound
    case invalidHostname
    case serverError
    
    var errorDescription: String? {
        switch self {
        case .serverUnreachable:
            return "DNS server is unreachable"
        case .timeout:
            return "DNS query timed out"
        case .noRecordFound:
            return "No DNS record found"
        case .invalidHostname:
            return "Invalid hostname format"
        case .serverError:
            return "DNS server error"
        }
    }
}

// MARK: - DNS Statistics
struct DNSStatistics {
    var successfulQueries: Int = 0
    var failedQueries: Int = 0
    var cacheHits: Int = 0
    var cacheMisses: Int = 0
    var cacheClears: Int = 0
    
    var cacheHitRate: Double {
        let total = cacheHits + cacheMisses
        guard total > 0 else { return 0 }
        return Double(cacheHits) / Double(total) * 100
    }
    
    var successRate: Double {
        let total = successfulQueries + failedQueries
        guard total > 0 else { return 0 }
        return Double(successfulQueries) / Double(total) * 100
    }
}