import SwiftUI
import Charts

// MARK: - System Monitor
struct SystemMonitorView: View {
    @EnvironmentObject var kernel: Kernel
    @State private var selectedTab = 0
    @State private var cpuHistory: [Double] = Array(repeating: 0, count: 60)
    @State private var memoryHistory: [Double] = Array(repeating: 0, count: 60)
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(spacing: 0) {
            // Tab bar
            Picker("", selection: $selectedTab) {
                Text("Overview").tag(0)
                Text("CPU").tag(1)
                Text("Memory").tag(2)
                Text("Processes").tag(3)
                Text("Optical").tag(4)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            
            // Content
            TabView(selection: $selectedTab) {
                OverviewTab()
                    .tag(0)
                
                CPUTab(cpuHistory: cpuHistory)
                    .tag(1)
                
                MemoryTab(memoryHistory: memoryHistory)
                    .tag(2)
                
                ProcessesTab()
                    .tag(3)
                
                OpticalTab()
                    .tag(4)
            }
            .tabViewStyle(.automatic)
        }
        .background(Color.black.opacity(0.2))
        .onReceive(timer) { _ in
            updateHistory()
        }
    }
    
    private func updateHistory() {
        cpuHistory.append(kernel.cpuUsage)
        if cpuHistory.count > 60 {
            cpuHistory.removeFirst()
        }
        
        memoryHistory.append(kernel.memoryUsage)
        if memoryHistory.count > 60 {
            memoryHistory.removeFirst()
        }
    }
}

struct OverviewTab: View {
    @EnvironmentObject var kernel: Kernel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // System Info
                GroupBox("System Information") {
                    VStack(alignment: .leading, spacing: 10) {
                        InfoRow(label: "Kernel Version", value: kernel.kernelVersion)
                        InfoRow(label: "Uptime", value: formatUptime(kernel.systemUptime))
                        InfoRow(label: "Optical Computing", value: kernel.opticalComputingEnabled ? "Enabled" : "Disabled")
                        InfoRow(label: "Processes", value: "\(kernel.processes.count)")
                    }
                    .padding(.vertical, 5)
                }
                
                // Performance Metrics
                GroupBox("Performance") {
                    VStack(spacing: 15) {
                        PerformanceGauge(
                            title: "CPU Usage",
                            value: kernel.cpuUsage,
                            color: .blue
                        )
                        
                        PerformanceGauge(
                            title: "Memory Usage",
                            value: kernel.memoryUsage,
                            color: .green
                        )
                        
                        if kernel.opticalComputingEnabled {
                            PerformanceGauge(
                                title: "Optical Processing",
                                value: kernel.performanceMetrics.opticalProcessingRate * 100,
                                color: .cyan
                            )
                        }
                    }
                }
            }
            .padding()
        }
    }
    
    private func formatUptime(_ uptime: TimeInterval) -> String {
        let hours = Int(uptime) / 3600
        let minutes = (Int(uptime) % 3600) / 60
        let seconds = Int(uptime) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}

struct CPUTab: View {
    @EnvironmentObject var kernel: Kernel
    let cpuHistory: [Double]
    
    var body: some View {
        VStack {
            // CPU Graph
            Chart(Array(cpuHistory.enumerated()), id: \.offset) { index, value in
                LineMark(
                    x: .value("Time", index),
                    y: .value("CPU %", value)
                )
                .foregroundStyle(.blue)
                
                AreaMark(
                    x: .value("Time", index),
                    y: .value("CPU %", value)
                )
                .foregroundStyle(.blue.opacity(0.2))
            }
            .frame(height: 200)
            .padding()
            
            // CPU Details
            GroupBox("CPU Details") {
                VStack(alignment: .leading, spacing: 10) {
                    InfoRow(label: "Instructions/sec", value: formatNumber(kernel.performanceMetrics.instructionsPerSecond))
                    InfoRow(label: "Cache Hit Rate", value: String(format: "%.1f%%", kernel.performanceMetrics.cacheHitRate * 100))
                    InfoRow(label: "Context Switches", value: "\(kernel.performanceMetrics.contextSwitches)")
                    
                    if kernel.opticalComputingEnabled {
                        Divider()
                        InfoRow(label: "Optical Cores", value: "8")
                        InfoRow(label: "Photonic Frequency", value: "3.0 THz")
                    }
                }
                .padding(.vertical, 5)
            }
            .padding()
            
            Spacer()
        }
    }
    
    private func formatNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }
}

struct MemoryTab: View {
    @EnvironmentObject var kernel: Kernel
    let memoryHistory: [Double]
    
    var body: some View {
        VStack {
            // Memory Graph
            Chart(Array(memoryHistory.enumerated()), id: \.offset) { index, value in
                LineMark(
                    x: .value("Time", index),
                    y: .value("Memory %", value)
                )
                .foregroundStyle(.green)
                
                AreaMark(
                    x: .value("Time", index),
                    y: .value("Memory %", value)
                )
                .foregroundStyle(.green.opacity(0.2))
            }
            .frame(height: 200)
            .padding()
            
            // Memory Details
            GroupBox("Memory Details") {
                VStack(alignment: .leading, spacing: 10) {
                    InfoRow(label: "Total Memory", value: "16 GB")
                    InfoRow(label: "Used Memory", value: String(format: "%.1f GB", kernel.memoryUsage * 16 / 100))
                    InfoRow(label: "Free Memory", value: String(format: "%.1f GB", (100 - kernel.memoryUsage) * 16 / 100))
                    InfoRow(label: "Page Faults", value: "\(kernel.performanceMetrics.pageFlaults)")
                }
                .padding(.vertical, 5)
            }
            .padding()
            
            Spacer()
        }
    }
}

struct ProcessesTab: View {
    @EnvironmentObject var kernel: Kernel
    
    var body: some View {
        VStack {
            // Process list header
            HStack {
                Text("PID")
                    .frame(width: 50, alignment: .leading)
                Text("Name")
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("State")
                    .frame(width: 80, alignment: .center)
                Text("Priority")
                    .frame(width: 80, alignment: .center)
                Text("CPU Time")
                    .frame(width: 100, alignment: .trailing)
            }
            .font(.caption)
            .foregroundColor(.white.opacity(0.6))
            .padding(.horizontal)
            .padding(.vertical, 5)
            .background(Color.white.opacity(0.05))
            
            // Process list
            ScrollView {
                VStack(spacing: 2) {
                    ForEach(kernel.processes) { process in
                        ProcessRow(process: process)
                    }
                }
            }
        }
    }
}

struct ProcessRow: View {
    @ObservedObject var process: Process
    
    var body: some View {
        HStack {
            Text("\(process.pid)")
                .frame(width: 50, alignment: .leading)
                .font(.system(.caption, design: .monospaced))
            
            Text(process.name)
                .frame(maxWidth: .infinity, alignment: .leading)
                .font(.caption)
            
            Text(stateString(process.state))
                .frame(width: 80, alignment: .center)
                .font(.caption)
                .foregroundColor(stateColor(process.state))
            
            Text(priorityString(process.priority))
                .frame(width: 80, alignment: .center)
                .font(.caption)
            
            Text(formatCPUTime(process.cpuTime))
                .frame(width: 100, alignment: .trailing)
                .font(.system(.caption, design: .monospaced))
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
        .background(Color.white.opacity(0.02))
    }
    
    private func stateString(_ state: ProcessState) -> String {
        switch state {
        case .ready: return "Ready"
        case .running: return "Running"
        case .waiting: return "Waiting"
        case .terminated: return "Terminated"
        }
    }
    
    private func stateColor(_ state: ProcessState) -> Color {
        switch state {
        case .ready: return .yellow
        case .running: return .green
        case .waiting: return .orange
        case .terminated: return .red
        }
    }
    
    private func priorityString(_ priority: ProcessPriority) -> String {
        switch priority {
        case .idle: return "Idle"
        case .low: return "Low"
        case .normal: return "Normal"
        case .high: return "High"
        case .realtime: return "Realtime"
        case .kernel: return "Kernel"
        }
    }
    
    private func formatCPUTime(_ time: TimeInterval) -> String {
        return String(format: "%.2fs", time)
    }
}

struct OpticalTab: View {
    @EnvironmentObject var kernel: Kernel
    
    var body: some View {
        VStack {
            if kernel.opticalComputingEnabled {
                ScrollView {
                    VStack(spacing: 20) {
                        // Optical CPU Status
                        GroupBox("Optical CPU Status") {
                            VStack(alignment: .leading, spacing: 10) {
                                InfoRow(label: "Photonic Cores", value: "8 cores")
                                InfoRow(label: "Frequency", value: "3.0 THz")
                                InfoRow(label: "Wavelength Channels", value: "64")
                                InfoRow(label: "Quantum Features", value: "Disabled")
                                InfoRow(label: "Processing Rate", value: String(format: "%.1f%%", kernel.performanceMetrics.opticalProcessingRate * 100))
                            }
                            .padding(.vertical, 5)
                        }
                        
                        // Optical Performance
                        GroupBox("Performance Comparison") {
                            VStack(spacing: 15) {
                                ComparisonBar(
                                    label: "Speed",
                                    traditional: 1.0,
                                    optical: 3.0,
                                    unit: "x"
                                )
                                
                                ComparisonBar(
                                    label: "Power Efficiency",
                                    traditional: 1.0,
                                    optical: 0.3,
                                    unit: "x",
                                    lowerIsBetter: true
                                )
                                
                                ComparisonBar(
                                    label: "Parallel Processing",
                                    traditional: 1.0,
                                    optical: 5.0,
                                    unit: "x"
                                )
                            }
                        }
                    }
                    .padding()
                }
            } else {
                VStack {
                    Image(systemName: "cpu")
                        .font(.system(size: 60))
                        .foregroundColor(.white.opacity(0.3))
                    
                    Text("Optical Computing Disabled")
                        .font(.title2)
                        .foregroundColor(.white.opacity(0.6))
                    
                    Text("Enable optical computing for enhanced performance")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.4))
                        .padding(.top, 5)
                }
            }
        }
    }
}

// MARK: - Settings View
struct SettingsView: View {
    @State private var selectedCategory = "General"
    
    let categories = ["General", "Display", "Network", "Security", "Advanced"]
    
    var body: some View {
        HStack(spacing: 0) {
            // Sidebar
            VStack(alignment: .leading, spacing: 2) {
                ForEach(categories, id: \.self) { category in
                    SettingsCategoryRow(
                        title: category,
                        isSelected: selectedCategory == category,
                        action: { selectedCategory = category }
                    )
                }
                Spacer()
            }
            .frame(width: 200)
            .background(Color.white.opacity(0.05))
            
            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(selectedCategory)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .padding(.bottom, 10)
                    
                    switch selectedCategory {
                    case "General":
                        GeneralSettings()
                    case "Display":
                        DisplaySettings()
                    case "Network":
                        NetworkSettings()
                    case "Security":
                        SecuritySettings()
                    case "Advanced":
                        AdvancedSettings()
                    default:
                        EmptyView()
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .background(Color.black.opacity(0.2))
    }
}

struct SettingsCategoryRow: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: iconForCategory(title))
                    .frame(width: 20)
                Text(title)
                Spacer()
            }
            .padding(.horizontal, 15)
            .padding(.vertical, 8)
            .background(isSelected ? Color.blue.opacity(0.3) : Color.clear)
            .foregroundColor(isSelected ? .white : .white.opacity(0.8))
        }
        .buttonStyle(.plain)
    }
    
    private func iconForCategory(_ category: String) -> String {
        switch category {
        case "General": return "gearshape"
        case "Display": return "display"
        case "Network": return "network"
        case "Security": return "lock.shield"
        case "Advanced": return "wrench.and.screwdriver"
        default: return "questionmark.circle"
        }
    }
}

struct GeneralSettings: View {
    @AppStorage("userName") var userName: String = ""
    @AppStorage("systemName") var systemName: String = "RadiateOS"
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            GroupBox("System") {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("System Name:")
                        TextField("System Name", text: $systemName)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 200)
                    }
                    
                    HStack {
                        Text("User Name:")
                        TextField("User Name", text: $userName)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 200)
                    }
                }
                .padding(.vertical, 5)
            }
        }
    }
}

struct DisplaySettings: View {
    @AppStorage("darkMode") var darkMode: Bool = true
    @AppStorage("resolution") var resolution: String = "1920x1080"
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            GroupBox("Appearance") {
                Toggle("Dark Mode", isOn: $darkMode)
                    .padding(.vertical, 5)
            }
            
            GroupBox("Resolution") {
                Picker("Display Resolution", selection: $resolution) {
                    Text("1920x1080").tag("1920x1080")
                    Text("2560x1440").tag("2560x1440")
                    Text("3840x2160").tag("3840x2160")
                }
                .pickerStyle(.menu)
                .padding(.vertical, 5)
            }
        }
    }
}

struct NetworkSettings: View {
    @State private var wifiEnabled = true
    @State private var ipAddress = "192.168.1.100"
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            GroupBox("Wi-Fi") {
                Toggle("Wi-Fi Enabled", isOn: $wifiEnabled)
                    .padding(.vertical, 5)
                
                if wifiEnabled {
                    HStack {
                        Text("IP Address:")
                        Text(ipAddress)
                            .font(.system(.body, design: .monospaced))
                    }
                }
            }
        }
    }
}

struct SecuritySettings: View {
    @State private var firewallEnabled = true
    @State private var encryptionEnabled = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            GroupBox("Security") {
                VStack(alignment: .leading, spacing: 10) {
                    Toggle("Firewall", isOn: $firewallEnabled)
                    Toggle("Disk Encryption", isOn: $encryptionEnabled)
                }
                .padding(.vertical, 5)
            }
        }
    }
}

struct AdvancedSettings: View {
    @EnvironmentObject var kernel: Kernel
    @State private var opticalEnabled = true
    @State private var quantumEnabled = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            GroupBox("Optical Computing") {
                VStack(alignment: .leading, spacing: 10) {
                    Toggle("Enable Optical CPU", isOn: $opticalEnabled)
                        .onChange(of: opticalEnabled) { value in
                            kernel.opticalComputingEnabled = value
                        }
                    
                    Toggle("Quantum Features", isOn: $quantumEnabled)
                        .disabled(!opticalEnabled)
                }
                .padding(.vertical, 5)
            }
        }
    }
}

// MARK: - Supporting Views
struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label + ":")
                .foregroundColor(.white.opacity(0.6))
            Spacer()
            Text(value)
                .foregroundColor(.white)
        }
        .font(.caption)
    }
}

struct PerformanceGauge: View {
    let title: String
    let value: Double
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(title)
                    .font(.caption)
                Spacer()
                Text(String(format: "%.1f%%", value))
                    .font(.caption)
                    .foregroundColor(color)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.1))
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geometry.size.width * value / 100)
                }
            }
            .frame(height: 8)
        }
    }
}

struct ComparisonBar: View {
    let label: String
    let traditional: Double
    let optical: Double
    let unit: String
    let lowerIsBetter: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label)
                .font(.caption)
            
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Traditional")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.6))
                    
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.white.opacity(0.1))
                            .frame(height: 20)
                        
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.gray)
                            .frame(width: 100 * (traditional / max(traditional, optical)), height: 20)
                    }
                    .frame(width: 100)
                    
                    Text("\(String(format: "%.1f", traditional))\(unit)")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Optical")
                        .font(.caption2)
                        .foregroundColor(.cyan.opacity(0.8))
                    
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.white.opacity(0.1))
                            .frame(height: 20)
                        
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.cyan)
                            .frame(width: 100 * (optical / max(traditional, optical)), height: 20)
                    }
                    .frame(width: 100)
                    
                    Text("\(String(format: "%.1f", optical))\(unit)")
                        .font(.caption2)
                        .foregroundColor(.cyan)
                }
                
                Spacer()
                
                // Better indicator
                if (lowerIsBetter && optical < traditional) || (!lowerIsBetter && optical > traditional) {
                    Label("Better", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
        }
    }
}