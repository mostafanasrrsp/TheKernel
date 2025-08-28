import Foundation

// MARK: - Network Utilities
class NetworkUtilities: ObservableObject {
    @Published var pingResults: [PingResult] = []
    @Published var tracerouteResults: [TracerouteHop] = []
    @Published var portScanResults: [PortScanResult] = []
    @Published var networkSpeed = NetworkSpeed()
    @Published var isScanning = false
    
    private let queue = DispatchQueue(label: "com.radiateos.netutils")
    
    // MARK: - Ping
    
    func ping(_ host: String, count: Int = 4, completion: @escaping (PingStatistics) -> Void) {
        pingResults.removeAll()
        var sentPackets = 0
        var receivedPackets = 0
        var totalTime: Double = 0
        var minTime: Double = Double.infinity
        var maxTime: Double = 0
        
        queue.async { [weak self] in
            for sequence in 1...count {
                let startTime = Date()
                
                // Simulate ping with random success and latency
                let success = Double.random(in: 0...1) > 0.1 // 90% success rate
                let latency = success ? Double.random(in: 5...150) : 0
                
                DispatchQueue.main.async {
                    let result = PingResult(
                        sequence: sequence,
                        host: host,
                        success: success,
                        latency: latency,
                        timestamp: Date()
                    )
                    
                    self?.pingResults.append(result)
                    
                    sentPackets += 1
                    if success {
                        receivedPackets += 1
                        totalTime += latency
                        minTime = min(minTime, latency)
                        maxTime = max(maxTime, latency)
                    }
                }
                
                // Wait between pings
                Thread.sleep(forTimeInterval: 1.0)
            }
            
            // Calculate statistics
            DispatchQueue.main.async {
                let stats = PingStatistics(
                    host: host,
                    packetsSent: sentPackets,
                    packetsReceived: receivedPackets,
                    packetsLost: sentPackets - receivedPackets,
                    minLatency: minTime == Double.infinity ? 0 : minTime,
                    maxLatency: maxTime,
                    avgLatency: receivedPackets > 0 ? totalTime / Double(receivedPackets) : 0,
                    packetLoss: Double(sentPackets - receivedPackets) / Double(sentPackets) * 100
                )
                completion(stats)
            }
        }
    }
    
    // MARK: - Traceroute
    
    func traceroute(_ destination: String, maxHops: Int = 30, completion: @escaping () -> Void) {
        tracerouteResults.removeAll()
        
        queue.async { [weak self] in
            // Simulate traceroute
            let totalHops = Int.random(in: 5...min(15, maxHops))
            
            for hop in 1...totalHops {
                // Simulate hop discovery
                Thread.sleep(forTimeInterval: 0.5)
                
                DispatchQueue.main.async {
                    let hopResult = TracerouteHop(
                        hopNumber: hop,
                        address: self?.generateHopAddress(hop: hop, total: totalHops) ?? "*",
                        hostname: self?.generateHopHostname(hop: hop, total: totalHops),
                        latencies: self?.generateHopLatencies() ?? [],
                        isDestination: hop == totalHops
                    )
                    
                    self?.tracerouteResults.append(hopResult)
                }
            }
            
            DispatchQueue.main.async {
                completion()
            }
        }
    }
    
    private func generateHopAddress(hop: Int, total: Int) -> String {
        if hop == 1 {
            return "192.168.1.1" // Local gateway
        } else if hop == total {
            return "93.184.216.34" // Example destination
        } else {
            // Generate intermediate hop addresses
            return "\(Int.random(in: 10...200)).\(Int.random(in: 0...255)).\(Int.random(in: 0...255)).\(Int.random(in: 1...254))"
        }
    }
    
    private func generateHopHostname(hop: Int, total: Int) -> String? {
        if hop == 1 {
            return "gateway.local"
        } else if hop == total {
            return "destination.example.com"
        } else if Double.random(in: 0...1) > 0.3 {
            return "router\(hop).isp.net"
        }
        return nil
    }
    
    private func generateHopLatencies() -> [Double] {
        // Generate 3 latency measurements
        return (0..<3).map { _ in
            if Double.random(in: 0...1) > 0.9 {
                return -1 // Timeout
            }
            return Double.random(in: 5...200)
        }
    }
    
    // MARK: - Port Scanning
    
    func scanPorts(_ host: String, startPort: Int = 1, endPort: Int = 1024, completion: @escaping () -> Void) {
        portScanResults.removeAll()
        isScanning = true
        
        queue.async { [weak self] in
            // Common open ports for simulation
            let commonOpenPorts: Set<Int> = [22, 80, 443, 3306, 5432, 8080, 8443]
            
            for port in startPort...endPort {
                // Quick scan simulation
                let isOpen = commonOpenPorts.contains(port) && Double.random(in: 0...1) > 0.3
                
                if isOpen || Double.random(in: 0...1) < 0.01 { // Show some results
                    DispatchQueue.main.async {
                        let result = PortScanResult(
                            port: port,
                            state: isOpen ? .open : .closed,
                            service: self?.getServiceName(port: port),
                            timestamp: Date()
                        )
                        self?.portScanResults.append(result)
                    }
                }
                
                // Simulate scan delay
                if port % 100 == 0 {
                    Thread.sleep(forTimeInterval: 0.1)
                }
            }
            
            DispatchQueue.main.async {
                self?.isScanning = false
                completion()
            }
        }
    }
    
    private func getServiceName(port: Int) -> String? {
        let services: [Int: String] = [
            20: "FTP-DATA",
            21: "FTP",
            22: "SSH",
            23: "Telnet",
            25: "SMTP",
            53: "DNS",
            80: "HTTP",
            110: "POP3",
            143: "IMAP",
            443: "HTTPS",
            445: "SMB",
            3306: "MySQL",
            3389: "RDP",
            5432: "PostgreSQL",
            5900: "VNC",
            8080: "HTTP-Proxy",
            8443: "HTTPS-Alt"
        ]
        return services[port]
    }
    
    // MARK: - Network Speed Test
    
    func testNetworkSpeed(completion: @escaping (NetworkSpeed) -> Void) {
        queue.async { [weak self] in
            // Simulate download speed test
            let downloadSpeed = Double.random(in: 10...1000) // Mbps
            
            // Simulate upload speed test
            Thread.sleep(forTimeInterval: 1.0)
            let uploadSpeed = Double.random(in: 5...500) // Mbps
            
            // Simulate ping test
            Thread.sleep(forTimeInterval: 0.5)
            let ping = Double.random(in: 5...50) // ms
            
            let speed = NetworkSpeed(
                downloadSpeed: downloadSpeed,
                uploadSpeed: uploadSpeed,
                ping: ping,
                jitter: Double.random(in: 0...10),
                packetLoss: Double.random(in: 0...2)
            )
            
            DispatchQueue.main.async {
                self?.networkSpeed = speed
                completion(speed)
            }
        }
    }
    
    // MARK: - Network Discovery
    
    func discoverLocalDevices(completion: @escaping ([NetworkDevice]) -> Void) {
        queue.async {
            // Simulate local network discovery
            var devices: [NetworkDevice] = []
            
            // Add router
            devices.append(NetworkDevice(
                name: "Router",
                ipAddress: "192.168.1.1",
                macAddress: "00:11:22:33:44:55",
                type: .router,
                isOnline: true
            ))
            
            // Add some random devices
            let deviceTypes: [NetworkDevice.DeviceType] = [.computer, .phone, .tablet, .printer, .smartTV, .iot]
            let deviceCount = Int.random(in: 3...8)
            
            for i in 2...deviceCount {
                devices.append(NetworkDevice(
                    name: "Device-\(i)",
                    ipAddress: "192.168.1.\(i)",
                    macAddress: self.generateMAC(),
                    type: deviceTypes.randomElement()!,
                    isOnline: Double.random(in: 0...1) > 0.2
                ))
            }
            
            DispatchQueue.main.async {
                completion(devices)
            }
        }
    }
    
    private func generateMAC() -> String {
        let bytes = (0..<6).map { _ in String(format: "%02X", Int.random(in: 0...255)) }
        return bytes.joined(separator: ":")
    }
}

// MARK: - Supporting Types

struct PingResult: Identifiable {
    let id = UUID()
    let sequence: Int
    let host: String
    let success: Bool
    let latency: Double // milliseconds
    let timestamp: Date
    
    var description: String {
        if success {
            return "Reply from \(host): time=\(String(format: "%.1f", latency))ms"
        } else {
            return "Request timeout for \(host)"
        }
    }
}

struct PingStatistics {
    let host: String
    let packetsSent: Int
    let packetsReceived: Int
    let packetsLost: Int
    let minLatency: Double
    let maxLatency: Double
    let avgLatency: Double
    let packetLoss: Double // percentage
}

struct TracerouteHop: Identifiable {
    let id = UUID()
    let hopNumber: Int
    let address: String
    let hostname: String?
    let latencies: [Double] // Multiple measurements, -1 for timeout
    let isDestination: Bool
    
    var avgLatency: Double {
        let validLatencies = latencies.filter { $0 > 0 }
        guard !validLatencies.isEmpty else { return -1 }
        return validLatencies.reduce(0, +) / Double(validLatencies.count)
    }
    
    var description: String {
        let latencyStrings = latencies.map { latency in
            latency > 0 ? String(format: "%.1f ms", latency) : "*"
        }
        
        if let hostname = hostname {
            return "\(hopNumber). \(hostname) (\(address)) \(latencyStrings.joined(separator: " "))"
        } else {
            return "\(hopNumber). \(address) \(latencyStrings.joined(separator: " "))"
        }
    }
}

struct PortScanResult: Identifiable {
    let id = UUID()
    let port: Int
    let state: PortState
    let service: String?
    let timestamp: Date
    
    enum PortState {
        case open, closed, filtered
        
        var description: String {
            switch self {
            case .open: return "Open"
            case .closed: return "Closed"
            case .filtered: return "Filtered"
            }
        }
    }
}

struct NetworkSpeed {
    var downloadSpeed: Double = 0 // Mbps
    var uploadSpeed: Double = 0   // Mbps
    var ping: Double = 0          // ms
    var jitter: Double = 0        // ms
    var packetLoss: Double = 0    // percentage
    
    var downloadSpeedFormatted: String {
        return String(format: "%.1f Mbps", downloadSpeed)
    }
    
    var uploadSpeedFormatted: String {
        return String(format: "%.1f Mbps", uploadSpeed)
    }
    
    var pingFormatted: String {
        return String(format: "%.0f ms", ping)
    }
}

struct NetworkDevice: Identifiable {
    let id = UUID()
    let name: String
    let ipAddress: String
    let macAddress: String
    let type: DeviceType
    let isOnline: Bool
    
    enum DeviceType {
        case router, computer, phone, tablet, printer, smartTV, iot, unknown
        
        var icon: String {
            switch self {
            case .router: return "wifi.router"
            case .computer: return "desktopcomputer"
            case .phone: return "iphone"
            case .tablet: return "ipad"
            case .printer: return "printer"
            case .smartTV: return "tv"
            case .iot: return "sensor.tag.radiowaves.forward"
            case .unknown: return "questionmark.circle"
            }
        }
    }
}
