import Foundation
import SwiftUI

// MARK: - System Monitor

public class SystemMonitor: ObservableObject {
    static let shared = SystemMonitor()
    
    // CPU & Memory
    @Published var cpuUsage: Double = 0
    @Published var memoryUsage: Double = 0
    @Published var diskUsage: Double = 0
    @Published var cpuHistory: [Double] = []
    @Published var memoryHistory: [Double] = []
    
    // Trends
    @Published var cpuTrend: Trend = .stable
    @Published var memoryTrend: Trend = .stable
    @Published var diskTrend: Trend = .stable
    
    // Network
    @Published var networkSpeed = "0 MB/s"
    @Published var downloadSpeed: Double = 0
    @Published var uploadSpeed: Double = 0
    
    // System Health
    @Published var cpuTemperature = 45
    @Published var fanSpeed = 2100
    @Published var uptime = "2d 14h 32m"
    @Published var loadAverage = "1.24"
    @Published var temperatureStatus: HealthStatus = .good
    @Published var loadStatus: HealthStatus = .good
    
    private var timer: Timer?
    private let maxHistoryPoints = 60
    
    private init() {
        startMonitoring()
    }
    
    private func startMonitoring() {
        // Initialize with some data
        for _ in 0..<maxHistoryPoints {
            cpuHistory.append(Double.random(in: 20...40))
            memoryHistory.append(Double.random(in: 30...50))
        }
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.updateMetrics()
        }
    }
    
    private func updateMetrics() {
        // Simulate CPU usage
        let newCpu = Double.random(in: 20...60)
        cpuUsage = newCpu
        cpuHistory.append(newCpu)
        if cpuHistory.count > maxHistoryPoints {
            cpuHistory.removeFirst()
        }
        
        // Simulate Memory usage
        let newMemory = Double.random(in: 40...70)
        memoryUsage = newMemory
        memoryHistory.append(newMemory)
        if memoryHistory.count > maxHistoryPoints {
            memoryHistory.removeFirst()
        }
        
        // Update trends
        updateTrends()
        
        // Simulate disk usage
        diskUsage = Double.random(in: 50...70)
        
        // Simulate network
        downloadSpeed = Double.random(in: 0...100)
        uploadSpeed = Double.random(in: 0...50)
        networkSpeed = String(format: "%.1f MB/s", (downloadSpeed + uploadSpeed) / 8)
        
        // Update health
        cpuTemperature = Int.random(in: 40...65)
        temperatureStatus = cpuTemperature > 60 ? .warning : .good
        
        let load = Double.random(in: 0.5...2.0)
        loadAverage = String(format: "%.2f", load)
        loadStatus = load > 1.5 ? .warning : .good
    }
    
    private func updateTrends() {
        // Calculate CPU trend
        if cpuHistory.count > 10 {
            let recent = cpuHistory.suffix(5).reduce(0, +) / 5
            let previous = cpuHistory.suffix(10).prefix(5).reduce(0, +) / 5
            
            if recent > previous + 10 {
                cpuTrend = .increasing
            } else if recent < previous - 10 {
                cpuTrend = .decreasing
            } else {
                cpuTrend = .stable
            }
        }
        
        // Similar for memory
        if memoryHistory.count > 10 {
            let recent = memoryHistory.suffix(5).reduce(0, +) / 5
            let previous = memoryHistory.suffix(10).prefix(5).reduce(0, +) / 5
            
            if recent > previous + 10 {
                memoryTrend = .increasing
            } else if recent < previous - 10 {
                memoryTrend = .decreasing
            } else {
                memoryTrend = .stable
            }
        }
    }
    
    func refresh() {
        updateMetrics()
    }
    
    func exportReport() {
        // Export system report
        print("Exporting system report...")
    }
    
    // MARK: - Types
    
    enum Trend {
        case increasing
        case decreasing
        case stable
        
        var icon: String {
            switch self {
            case .increasing: return "arrow.up.right"
            case .decreasing: return "arrow.down.right"
            case .stable: return "arrow.right"
            }
        }
        
        var color: Color {
            switch self {
            case .increasing: return .orange
            case .decreasing: return .green
            case .stable: return .blue
            }
        }
    }
    
    enum HealthStatus {
        case good
        case warning
        case critical
        
        var color: Color {
            switch self {
            case .good: return .green
            case .warning: return .orange
            case .critical: return .red
            }
        }
    }
}

// MARK: - Security Monitor

public class SecurityMonitor: ObservableObject {
    static let shared = SecurityMonitor()
    
    @Published var protectionLevel = "High"
    @Published var lastScanTime = "2 hours ago"
    @Published var threatsBlocked = 142
    @Published var updateStatus = "Up to date"
    
    @Published var recentEvents: [SecurityEvent] = []
    @Published var activeThreats: [SecurityThreat] = []
    @Published var recentBlockedIPs: [String] = []
    
    private init() {
        loadSampleData()
        setupMonitoring()
    }
    
    private func loadSampleData() {
        recentEvents = [
            SecurityEvent(
                title: "Suspicious network activity blocked",
                description: "Blocked connection attempt from 192.168.1.100",
                severity: .warning,
                timestamp: Date().addingTimeInterval(-300)
            ),
            SecurityEvent(
                title: "Firewall rule updated",
                description: "Added rule to block port 8080",
                severity: .info,
                timestamp: Date().addingTimeInterval(-1800)
            ),
            SecurityEvent(
                title: "Security scan completed",
                description: "No threats detected in system scan",
                severity: .success,
                timestamp: Date().addingTimeInterval(-3600)
            ),
        ]
        
        recentBlockedIPs = [
            "192.168.1.100",
            "10.0.0.45",
            "172.16.0.23"
        ]
    }
    
    private func setupMonitoring() {
        // Setup security monitoring
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSecurityAlert),
            name: Notification.Name("SecurityAlert"),
            object: nil
        )
    }
    
    @objc private func handleSecurityAlert(_ notification: Notification) {
        if let userInfo = notification.userInfo,
           let event = userInfo["event"] as? String,
           let severity = userInfo["severity"] as? String {
            
            let securityEvent = SecurityEvent(
                title: "Security Alert",
                description: event,
                severity: SecurityEventSeverity(rawValue: severity) ?? .info,
                timestamp: Date()
            )
            
            DispatchQueue.main.async {
                self.recentEvents.insert(securityEvent, at: 0)
                if self.recentEvents.count > 10 {
                    self.recentEvents.removeLast()
                }
            }
        }
    }
    
    func runSecurityScan() {
        lastScanTime = "Just now"
        // Implement security scan
    }
    
    func updateDefinitions() {
        updateStatus = "Updating..."
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.updateStatus = "Up to date"
        }
    }
    
    func generateReport() {
        // Generate security report
    }
    
    func showAllEvents() {
        // Show all security events
    }
    
    func quarantine(_ threat: SecurityThreat) {
        activeThreats.removeAll { $0.id == threat.id }
    }
}

// MARK: - Process Monitor

public class ProcessMonitor: ObservableObject {
    static let shared = ProcessMonitor()
    
    @Published var processes: [ProcessInfo] = []
    @Published var selectedProcess: ProcessInfo?
    
    private var timer: Timer?
    
    private init() {
        loadProcesses()
        startMonitoring()
    }
    
    private func loadProcesses() {
        processes = [
            ProcessInfo(
                pid: 1,
                name: "systemd",
                cpuUsage: 0.1,
                memoryMB: 12,
                status: .running,
                user: "root",
                isSystem: true
            ),
            ProcessInfo(
                pid: 1234,
                name: "RadiateOS",
                cpuUsage: 5.2,
                memoryMB: 256,
                status: .running,
                user: "user",
                isSystem: false
            ),
            ProcessInfo(
                pid: 2345,
                name: "Terminal",
                cpuUsage: 0.5,
                memoryMB: 48,
                status: .running,
                user: "user",
                isSystem: false
            ),
            ProcessInfo(
                pid: 3456,
                name: "Browser",
                cpuUsage: 12.3,
                memoryMB: 512,
                status: .running,
                user: "user",
                isSystem: false
            ),
            ProcessInfo(
                pid: 4567,
                name: "kernel_task",
                cpuUsage: 2.1,
                memoryMB: 128,
                status: .running,
                user: "root",
                isSystem: true
            ),
        ]
    }
    
    private func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            self.updateProcesses()
        }
    }
    
    private func updateProcesses() {
        // Update process information
        for i in processes.indices {
            processes[i].cpuUsage = Double.random(in: 0...20)
            processes[i].memoryMB = Int.random(in: 10...600)
        }
    }
    
    func endSelectedProcess() {
        guard let selected = selectedProcess else { return }
        processes.removeAll { $0.id == selected.id }
        selectedProcess = nil
    }
}

// MARK: - Alert Manager

public class AlertManager: ObservableObject {
    static let shared = AlertManager()
    
    @Published var alerts: [SystemAlert] = []
    
    private init() {
        loadSampleAlerts()
    }
    
    private func loadSampleAlerts() {
        alerts = [
            SystemAlert(
                title: "High CPU Usage",
                message: "CPU usage has exceeded 80% for more than 5 minutes",
                severity: .warning
            ),
            SystemAlert(
                title: "Low Disk Space",
                message: "Less than 10GB of free space remaining",
                severity: .critical
            ),
        ]
    }
    
    func dismiss(_ alert: SystemAlert) {
        alerts.removeAll { $0.id == alert.id }
    }
    
    func addAlert(_ alert: SystemAlert) {
        alerts.insert(alert, at: 0)
    }
}

// MARK: - Models

public struct SecurityEvent: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let severity: SecurityEventSeverity
    let timestamp: Date
    
    var timeAgo: String {
        let interval = Date().timeIntervalSince(timestamp)
        if interval < 60 {
            return "Just now"
        } else if interval < 3600 {
            return "\(Int(interval / 60))m ago"
        } else if interval < 86400 {
            return "\(Int(interval / 3600))h ago"
        } else {
            return "\(Int(interval / 86400))d ago"
        }
    }
}

public enum SecurityEventSeverity {
    case info
    case success
    case warning
    case error
    case critical
    
    var icon: String {
        switch self {
        case .info: return "info.circle.fill"
        case .success: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .error: return "xmark.circle.fill"
        case .critical: return "exclamationmark.octagon.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .info: return .blue
        case .success: return .green
        case .warning: return .orange
        case .error: return .red
        case .critical: return .purple
        }
    }
}

public struct SecurityThreat: Identifiable {
    let id = UUID()
    let name: String
    let type: String
    let severity: SecurityEventSeverity
    let location: String
}

public struct ProcessInfo: Identifiable {
    let id = UUID()
    let pid: Int
    let name: String
    var cpuUsage: Double
    var memoryMB: Int
    var status: ProcessStatus
    let user: String
    let isSystem: Bool
    
    var icon: String {
        isSystem ? "gear" : "app.fill"
    }
    
    var memoryFormatted: String {
        if memoryMB < 1024 {
            return "\(memoryMB) MB"
        } else {
            return String(format: "%.1f GB", Double(memoryMB) / 1024)
        }
    }
}

public enum ProcessStatus: String {
    case running = "Running"
    case sleeping = "Sleeping"
    case stopped = "Stopped"
    case zombie = "Zombie"
    
    var color: Color {
        switch self {
        case .running: return .green
        case .sleeping: return .blue
        case .stopped: return .orange
        case .zombie: return .red
        }
    }
}

public struct SystemAlert: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let severity: AlertSeverity
    let timestamp = Date()
}

public enum AlertSeverity {
    case info
    case warning
    case critical
    
    var icon: String {
        switch self {
        case .info: return "info.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .critical: return "exclamationmark.octagon.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .info: return .blue
        case .warning: return .orange
        case .critical: return .red
        }
    }
}