import SwiftUI
import Charts

/// System monitoring dashboard inspired by GNOME System Monitor and KDE System Guard
public struct SystemMonitorDashboard: View {
    @StateObject private var monitor = SystemMonitor.shared
    @State private var selectedTab = "Overview"
    
    let tabs = ["Overview", "Processes", "Resources", "Security", "Network", "Logs"]
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header
            DashboardHeader(selectedTab: $selectedTab, tabs: tabs)
            
            // Content
            ScrollView {
                switch selectedTab {
                case "Overview":
                    OverviewTab()
                case "Processes":
                    ProcessesTab()
                case "Resources":
                    ResourcesTab()
                case "Security":
                    SecurityTab()
                case "Network":
                    NetworkTab()
                case "Logs":
                    LogsTab()
                default:
                    EmptyView()
                }
            }
            .padding()
        }
        .frame(minWidth: 1000, minHeight: 700)
        .background(.regularMaterial)
    }
}

// MARK: - Dashboard Header

struct DashboardHeader: View {
    @Binding var selectedTab: String
    let tabs: [String]
    
    var body: some View {
        HStack {
            // Title
            Label("System Monitor", systemImage: "chart.line.uptrend.xyaxis")
                .font(.title2)
                .fontWeight(.semibold)
            
            Spacer()
            
            // Tab Selector
            HStack(spacing: 0) {
                ForEach(tabs, id: \.self) { tab in
                    TabButton(
                        title: tab,
                        isSelected: selectedTab == tab,
                        action: { selectedTab = tab }
                    )
                }
            }
            .background(Color.primary.opacity(0.05))
            .cornerRadius(8)
            
            Spacer()
            
            // Actions
            HStack(spacing: 12) {
                Button(action: { SystemMonitor.shared.exportReport() }) {
                    Image(systemName: "square.and.arrow.up")
                }
                
                Button(action: { SystemMonitor.shared.refresh() }) {
                    Image(systemName: "arrow.clockwise")
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
    }
}

struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.accentColor : Color.clear)
                .foregroundColor(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Overview Tab

struct OverviewTab: View {
    @StateObject private var monitor = SystemMonitor.shared
    
    var body: some View {
        VStack(spacing: 20) {
            // System Info Cards
            HStack(spacing: 16) {
                SystemInfoCard(
                    title: "CPU",
                    value: "\(Int(monitor.cpuUsage))%",
                    icon: "cpu",
                    color: .blue,
                    trend: monitor.cpuTrend
                )
                
                SystemInfoCard(
                    title: "Memory",
                    value: "\(Int(monitor.memoryUsage))%",
                    icon: "memorychip",
                    color: .green,
                    trend: monitor.memoryTrend
                )
                
                SystemInfoCard(
                    title: "Disk",
                    value: "\(Int(monitor.diskUsage))%",
                    icon: "internaldrive",
                    color: .orange,
                    trend: monitor.diskTrend
                )
                
                SystemInfoCard(
                    title: "Network",
                    value: monitor.networkSpeed,
                    icon: "network",
                    color: .purple,
                    trend: .stable
                )
            }
            
            // Performance Graphs
            HStack(spacing: 16) {
                PerformanceGraph(
                    title: "CPU History",
                    data: monitor.cpuHistory,
                    color: .blue
                )
                
                PerformanceGraph(
                    title: "Memory History",
                    data: monitor.memoryHistory,
                    color: .green
                )
            }
            
            // System Health
            SystemHealthCard()
            
            // Active Alerts
            ActiveAlertsCard()
        }
    }
}

struct SystemInfoCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let trend: SystemMonitor.Trend
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                TrendIndicator(trend: trend)
            }
            
            Text(value)
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(color)
            
            // Mini graph
            MiniGraph(color: color)
                .frame(height: 30)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.primary.opacity(0.05))
        .cornerRadius(12)
    }
}

struct TrendIndicator: View {
    let trend: SystemMonitor.Trend
    
    var body: some View {
        Image(systemName: trend.icon)
            .foregroundColor(trend.color)
            .font(.caption)
    }
}

struct MiniGraph: View {
    let color: Color
    @State private var animateGraph = false
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let width = geometry.size.width
                let height = geometry.size.height
                
                path.move(to: CGPoint(x: 0, y: height))
                
                for i in 0..<10 {
                    let x = width * CGFloat(i) / 9
                    let y = height * (1 - CGFloat.random(in: 0.3...0.8))
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }
            .stroke(color, lineWidth: 2)
            .opacity(animateGraph ? 1 : 0)
            .onAppear {
                withAnimation(.easeIn(duration: 0.5)) {
                    animateGraph = true
                }
            }
        }
    }
}

struct PerformanceGraph: View {
    let title: String
    let data: [Double]
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.headline)
            
            Chart {
                ForEach(Array(data.enumerated()), id: \.offset) { index, value in
                    LineMark(
                        x: .value("Time", index),
                        y: .value("Usage", value)
                    )
                    .foregroundStyle(color)
                    
                    AreaMark(
                        x: .value("Time", index),
                        y: .value("Usage", value)
                    )
                    .foregroundStyle(color.opacity(0.2))
                }
            }
            .frame(height: 150)
        }
        .padding()
        .background(Color.primary.opacity(0.05))
        .cornerRadius(12)
    }
}

struct SystemHealthCard: View {
    @StateObject private var monitor = SystemMonitor.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("System Health", systemImage: "heart.fill")
                .font(.headline)
            
            HStack {
                HealthIndicator(
                    label: "Temperature",
                    status: monitor.temperatureStatus,
                    value: "\(monitor.cpuTemperature)°C"
                )
                
                HealthIndicator(
                    label: "Fan Speed",
                    status: .good,
                    value: "\(monitor.fanSpeed) RPM"
                )
                
                HealthIndicator(
                    label: "Uptime",
                    status: .good,
                    value: monitor.uptime
                )
                
                HealthIndicator(
                    label: "Load Average",
                    status: monitor.loadStatus,
                    value: monitor.loadAverage
                )
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.primary.opacity(0.05))
        .cornerRadius(12)
    }
}

struct HealthIndicator: View {
    let label: String
    let status: SystemMonitor.HealthStatus
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Circle()
                    .fill(status.color)
                    .frame(width: 8, height: 8)
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Text(value)
                .font(.system(size: 16, weight: .medium))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Security Tab

struct SecurityTab: View {
    @StateObject private var securityMonitor = SecurityMonitor.shared
    
    var body: some View {
        VStack(spacing: 20) {
            // Security Status
            SecurityStatusCard()
            
            // Firewall Status
            FirewallStatusCard()
            
            // Recent Security Events
            SecurityEventsCard()
            
            // Active Threats
            ActiveThreatsCard()
        }
    }
}

struct SecurityStatusCard: View {
    @StateObject private var securityMonitor = SecurityMonitor.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Security Status", systemImage: "shield.fill")
                .font(.headline)
            
            HStack(spacing: 20) {
                SecurityMetric(
                    label: "Protection",
                    value: securityMonitor.protectionLevel,
                    icon: "shield.lefthalf.filled",
                    color: .green
                )
                
                SecurityMetric(
                    label: "Last Scan",
                    value: securityMonitor.lastScanTime,
                    icon: "magnifyingglass",
                    color: .blue
                )
                
                SecurityMetric(
                    label: "Threats Blocked",
                    value: "\(securityMonitor.threatsBlocked)",
                    icon: "xmark.shield.fill",
                    color: .red
                )
                
                SecurityMetric(
                    label: "Updates",
                    value: securityMonitor.updateStatus,
                    icon: "arrow.down.circle.fill",
                    color: .orange
                )
            }
            
            // Quick Actions
            HStack {
                Button("Run Security Scan") {
                    securityMonitor.runSecurityScan()
                }
                .buttonStyle(.borderedProminent)
                
                Button("Update Definitions") {
                    securityMonitor.updateDefinitions()
                }
                .buttonStyle(.bordered)
                
                Button("View Report") {
                    securityMonitor.generateReport()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .background(Color.primary.opacity(0.05))
        .cornerRadius(12)
    }
}

struct SecurityMetric: View {
    let label: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.headline)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct FirewallStatusCard: View {
    @StateObject private var firewall = FirewallManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Firewall", systemImage: "flame.fill")
                    .font(.headline)
                
                Spacer()
                
                Toggle("", isOn: .constant(true))
                    .toggleStyle(.switch)
            }
            
            HStack(spacing: 16) {
                StatisticView(
                    label: "Rules Active",
                    value: "\(firewall.listRules().count)"
                )
                
                StatisticView(
                    label: "Connections Blocked",
                    value: "\(firewall.status().blockedConnections)"
                )
                
                StatisticView(
                    label: "Connections Allowed",
                    value: "\(firewall.status().allowedConnections)"
                )
            }
            
            // Recent blocked IPs
            if !SecurityMonitor.shared.recentBlockedIPs.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Recently Blocked")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    ForEach(SecurityMonitor.shared.recentBlockedIPs, id: \.self) { ip in
                        HStack {
                            Image(systemName: "xmark.octagon.fill")
                                .foregroundColor(.red)
                                .font(.caption)
                            Text(ip)
                                .font(.system(.caption, design: .monospaced))
                            Spacer()
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.primary.opacity(0.05))
        .cornerRadius(12)
    }
}

struct SecurityEventsCard: View {
    @StateObject private var securityMonitor = SecurityMonitor.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Security Events", systemImage: "exclamationmark.triangle.fill")
                    .font(.headline)
                
                Spacer()
                
                Button("View All") {
                    securityMonitor.showAllEvents()
                }
                .buttonStyle(.plain)
                .foregroundColor(.accentColor)
            }
            
            ForEach(securityMonitor.recentEvents) { event in
                SecurityEventRow(event: event)
            }
        }
        .padding()
        .background(Color.primary.opacity(0.05))
        .cornerRadius(12)
    }
}

struct SecurityEventRow: View {
    let event: SecurityEvent
    
    var body: some View {
        HStack {
            Image(systemName: event.severity.icon)
                .foregroundColor(event.severity.color)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(event.title)
                    .font(.system(size: 13, weight: .medium))
                
                Text(event.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(event.timeAgo)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Processes Tab

struct ProcessesTab: View {
    @StateObject private var processMonitor = ProcessMonitor.shared
    @State private var searchText = ""
    @State private var sortBy = "CPU"
    
    var filteredProcesses: [ProcessInfo] {
        let processes = processMonitor.processes
        
        if searchText.isEmpty {
            return processes
        } else {
            return processes.filter { 
                $0.name.localizedCaseInsensitiveContains(searchText) 
            }
        }
    }
    
    var body: some View {
        VStack {
            // Search and controls
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search processes...", text: $searchText)
                    .textFieldStyle(.plain)
                
                Spacer()
                
                Picker("Sort by", selection: $sortBy) {
                    Text("CPU").tag("CPU")
                    Text("Memory").tag("Memory")
                    Text("Name").tag("Name")
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
                
                Button("End Process") {
                    processMonitor.endSelectedProcess()
                }
                .buttonStyle(.borderedProminent)
                .disabled(processMonitor.selectedProcess == nil)
            }
            .padding()
            .background(Color.primary.opacity(0.05))
            .cornerRadius(8)
            
            // Process list
            ProcessListView(processes: filteredProcesses)
        }
    }
}

struct ProcessListView: View {
    let processes: [ProcessInfo]
    @StateObject private var processMonitor = ProcessMonitor.shared
    
    var body: some View {
        Table(processes) {
            TableColumn("PID") { process in
                Text("\(process.pid)")
                    .font(.system(.body, design: .monospaced))
            }
            .width(60)
            
            TableColumn("Name") { process in
                HStack {
                    Image(systemName: process.icon)
                        .foregroundColor(process.isSystem ? .secondary : .primary)
                    Text(process.name)
                }
            }
            
            TableColumn("CPU %") { process in
                HStack {
                    ProgressView(value: process.cpuUsage / 100)
                        .frame(width: 50)
                    Text(String(format: "%.1f", process.cpuUsage))
                }
            }
            .width(100)
            
            TableColumn("Memory") { process in
                Text(process.memoryFormatted)
            }
            .width(100)
            
            TableColumn("Status") { process in
                HStack {
                    Circle()
                        .fill(process.status.color)
                        .frame(width: 8, height: 8)
                    Text(process.status.rawValue)
                }
            }
            .width(100)
            
            TableColumn("User") { process in
                Text(process.user)
                    .foregroundColor(.secondary)
            }
            .width(100)
        }
        .tableStyle(.inset)
    }
}

// MARK: - Supporting Views

struct ActiveAlertsCard: View {
    @StateObject private var alertManager = AlertManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Active Alerts", systemImage: "bell.fill")
                    .font(.headline)
                
                Spacer()
                
                if !alertManager.alerts.isEmpty {
                    Text("\(alertManager.alerts.count)")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            
            if alertManager.alerts.isEmpty {
                Text("No active alerts")
                    .foregroundColor(.secondary)
                    .padding(.vertical)
            } else {
                ForEach(alertManager.alerts) { alert in
                    AlertRow(alert: alert)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.primary.opacity(0.05))
        .cornerRadius(12)
    }
}

struct AlertRow: View {
    let alert: SystemAlert
    
    var body: some View {
        HStack {
            Image(systemName: alert.severity.icon)
                .foregroundColor(alert.severity.color)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(alert.title)
                    .font(.system(size: 13, weight: .medium))
                
                Text(alert.message)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            Button(action: { AlertManager.shared.dismiss(alert) }) {
                Image(systemName: "xmark")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(8)
        .background(alert.severity.color.opacity(0.1))
        .cornerRadius(6)
    }
}

struct ActiveThreatsCard: View {
    @StateObject private var securityMonitor = SecurityMonitor.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Active Threats", systemImage: "exclamationmark.shield.fill")
                .font(.headline)
            
            if securityMonitor.activeThreats.isEmpty {
                HStack {
                    Image(systemName: "checkmark.shield.fill")
                        .foregroundColor(.green)
                        .font(.largeTitle)
                    
                    VStack(alignment: .leading) {
                        Text("No Active Threats")
                            .font(.headline)
                        Text("Your system is secure")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
            } else {
                ForEach(securityMonitor.activeThreats) { threat in
                    ThreatRow(threat: threat)
                }
            }
        }
        .padding()
        .background(Color.primary.opacity(0.05))
        .cornerRadius(12)
    }
}

struct ThreatRow: View {
    let threat: SecurityThreat
    
    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
            
            VStack(alignment: .leading) {
                Text(threat.name)
                    .font(.system(size: 13, weight: .medium))
                Text(threat.type)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button("Quarantine") {
                SecurityMonitor.shared.quarantine(threat)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding(8)
        .background(Color.red.opacity(0.1))
        .cornerRadius(6)
    }
}

// MARK: - Other Tabs (Simplified)

struct ResourcesTab: View {
    var body: some View {
        Text("Resources monitoring coming soon...")
            .foregroundColor(.secondary)
            .padding()
    }
}

struct NetworkTab: View {
    var body: some View {
        Text("Network monitoring coming soon...")
            .foregroundColor(.secondary)
            .padding()
    }
}

struct LogsTab: View {
    var body: some View {
        Text("System logs coming soon...")
            .foregroundColor(.secondary)
            .padding()
    }
}

struct StatisticView: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}