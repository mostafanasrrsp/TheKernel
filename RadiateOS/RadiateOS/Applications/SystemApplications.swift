//
//  SystemApplications.swift
//  RadiateOS
//
//  Collection of system applications
//

import SwiftUI

// MARK: - System Preferences
struct SystemPreferencesView: View {
    @State private var selectedCategory: PreferenceCategory = .general
    
    enum PreferenceCategory: String, CaseIterable {
        case general = "General"
        case display = "Display"
        case sound = "Sound"
        case network = "Network"
        case security = "Security"
        case kernel = "Kernel"
        case optical = "Optical CPU"
        case memory = "Memory"
        
        var icon: String {
            switch self {
            case .general: return "gearshape"
            case .display: return "display"
            case .sound: return "speaker.wave.2"
            case .network: return "network"
            case .security: return "lock.shield"
            case .kernel: return "cpu"
            case .optical: return "sparkles"
            case .memory: return "memorychip"
            }
        }
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // Sidebar
            VStack(alignment: .leading, spacing: 8) {
                ForEach(PreferenceCategory.allCases, id: \.self) { category in
                    Button(action: { selectedCategory = category }) {
                        HStack {
                            Image(systemName: category.icon)
                                .frame(width: 20)
                            Text(category.rawValue)
                            Spacer()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(selectedCategory == category ? Color.accentColor.opacity(0.2) : Color.clear)
                        .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .foregroundColor(selectedCategory == category ? .accentColor : .primary)
                }
                Spacer()
            }
            .frame(width: 200)
            .padding()
            .background(Color.primary.opacity(0.05))
            
            Divider()
            
            // Content
            VStack {
                switch selectedCategory {
                case .general:
                    GeneralPreferencesView()
                case .display:
                    DisplayPreferencesView()
                case .sound:
                    SoundPreferencesView()
                case .network:
                    NetworkPreferencesView()
                case .security:
                    SecurityPreferencesView()
                case .kernel:
                    KernelPreferencesView()
                case .optical:
                    OpticalCPUPreferencesView()
                case .memory:
                    MemoryPreferencesView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
        }
    }
}

struct GeneralPreferencesView: View {
    @State private var computerName = "RadiateOS Computer"
    @State private var autoLogin = false
    @State private var darkMode = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("General")
                .font(.largeTitle)
                .bold()
            
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Computer Name")
                        .font(.headline)
                    TextField("Computer Name", text: $computerName)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: 300)
                }
                
                Toggle("Auto-login", isOn: $autoLogin)
                Toggle("Dark Mode", isOn: $darkMode)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("System Information")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Version: RadiateOS 1.0")
                        Text("Kernel: Optical 1.0.0")
                        Text("Architecture: x147-optical")
                        Text("Memory: 8 GB Optical RAM")
                    }
                    .font(.system(.body, design: .monospaced))
                    .padding()
                    .background(Color.primary.opacity(0.05))
                    .cornerRadius(8)
                }
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct OpticalCPUPreferencesView: View {
    @State private var cpuFrequency: Double = 2.5
    @State private var coreCount = 4
    @State private var wavelength: Double = 1550
    @State private var powerEfficiency = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Optical CPU")
                .font(.largeTitle)
                .bold()
            
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Frequency: \(cpuFrequency, specifier: "%.1f") THz")
                        .font(.headline)
                    Slider(value: $cpuFrequency, in: 1.0...5.0, step: 0.1)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Active Cores: \(coreCount)")
                        .font(.headline)
                    Slider(value: Binding(
                        get: { Double(coreCount) },
                        set: { coreCount = Int($0) }
                    ), in: 1...8, step: 1)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Wavelength: \(wavelength, specifier: "%.0f") nm")
                        .font(.headline)
                    Slider(value: $wavelength, in: 1300...1600, step: 10)
                }
                
                Toggle("Power Efficiency Mode", isOn: $powerEfficiency)
                
                GroupBox("Current Status") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Temperature:")
                            Spacer()
                            Text("25°C")
                                .foregroundColor(.green)
                        }
                        HStack {
                            Text("Power Draw:")
                            Spacer()
                            Text("15W")
                                .foregroundColor(.green)
                        }
                        HStack {
                            Text("Efficiency:")
                            Spacer()
                            Text("98.7%")
                                .foregroundColor(.green)
                        }
                        HStack {
                            Text("Coherence:")
                            Spacer()
                            Text("Stable")
                                .foregroundColor(.green)
                        }
                    }
                    .font(.system(.body, design: .monospaced))
                }
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Activity Monitor
struct ActivityMonitorView: View {
    @State private var processes: [SystemProcess] = []
    @State private var selectedTab = 0
    @State private var cpuUsage: Double = 0.0
    @State private var memoryUsage: Double = 0.0
    @State private var updateTimer: Timer?
    
    var body: some View {
        VStack(spacing: 0) {
            // Tab bar
            Picker("View", selection: $selectedTab) {
                Text("CPU").tag(0)
                Text("Memory").tag(1)
                Text("Energy").tag(2)
                Text("Disk").tag(3)
                Text("Network").tag(4)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            
            Divider()
            
            // Content
            switch selectedTab {
            case 0:
                CPUMonitorView(processes: processes, cpuUsage: cpuUsage)
            case 1:
                MemoryMonitorView(processes: processes, memoryUsage: memoryUsage)
            case 2:
                EnergyMonitorView()
            case 3:
                DiskMonitorView()
            case 4:
                NetworkMonitorView()
            default:
                EmptyView()
            }
        }
        .onAppear {
            startMonitoring()
        }
        .onDisappear {
            stopMonitoring()
        }
    }
    
    private func startMonitoring() {
        generateProcesses()
        updateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            Task { @MainActor in
                updateSystemStats()
            }
        }
    }
    
    private func stopMonitoring() {
        updateTimer?.invalidate()
        updateTimer = nil
    }
    
    private func generateProcesses() {
        processes = [
            SystemProcess(name: "kernel", pid: 1, cpuUsage: 2.1, memoryUsage: 128),
            SystemProcess(name: "optical_cpu", pid: 2, cpuUsage: 15.3, memoryUsage: 64),
            SystemProcess(name: "memory_mgr", pid: 3, cpuUsage: 1.2, memoryUsage: 32),
            SystemProcess(name: "rom_manager", pid: 4, cpuUsage: 0.8, memoryUsage: 16),
            SystemProcess(name: "translation", pid: 5, cpuUsage: 5.5, memoryUsage: 256),
            SystemProcess(name: "desktop", pid: 100, cpuUsage: 8.2, memoryUsage: 512),
            SystemProcess(name: "filemanager", pid: 101, cpuUsage: 2.3, memoryUsage: 128),
            SystemProcess(name: "terminal", pid: 102, cpuUsage: 1.1, memoryUsage: 64)
        ]
    }
    
    private func updateSystemStats() {
        withAnimation(.easeInOut(duration: 0.5)) {
            cpuUsage = Double.random(in: 10...30)
            memoryUsage = Double.random(in: 20...40)
            
            // Update process stats
            for i in processes.indices {
                processes[i].cpuUsage = max(0, processes[i].cpuUsage + Double.random(in: -2...2))
                processes[i].memoryUsage = max(0, processes[i].memoryUsage + Double.random(in: -10...10))
            }
        }
    }
}

struct SystemProcess: Identifiable {
    let id = UUID()
    let name: String
    let pid: Int
    var cpuUsage: Double
    var memoryUsage: Double
}

struct CPUMonitorView: View {
    let processes: [SystemProcess]
    let cpuUsage: Double
    
    var body: some View {
        VStack {
            // CPU Usage chart
            VStack(alignment: .leading) {
                Text("CPU Usage: \(cpuUsage, specifier: "%.1f")%")
                    .font(.headline)
                
                ProgressView(value: cpuUsage / 100)
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    .frame(height: 8)
            }
            .padding()
            
            // Process list
            List(processes.sorted { $0.cpuUsage > $1.cpuUsage }) { process in
                HStack {
                    Text(process.name)
                        .frame(width: 120, alignment: .leading)
                    
                    Text("\(process.pid)")
                        .frame(width: 60, alignment: .trailing)
                        .font(.system(.body, design: .monospaced))
                    
                    Text("\(process.cpuUsage, specifier: "%.1f")%")
                        .frame(width: 80, alignment: .trailing)
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(process.cpuUsage > 10 ? .red : .primary)
                    
                    Spacer()
                }
                .padding(.vertical, 2)
            }
            .listStyle(PlainListStyle())
        }
    }
}

// MARK: - Text Editor
struct TextEditorView: View {
    @State private var text = "Welcome to RadiateOS Text Editor!\n\nThis is a simple text editor for the optical computing platform."
    @State private var fileName = "Untitled.txt"
    @State private var isModified = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack {
                Button("New") { newDocument() }
                Button("Open") { openDocument() }
                Button("Save") { saveDocument() }
                .disabled(!isModified)
                
                Spacer()
                
                Text(fileName + (isModified ? " •" : ""))
                    .font(.headline)
                
                Spacer()
                
                Text("Lines: \(text.components(separatedBy: .newlines).count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.primary.opacity(0.05))
            
            Divider()
            
            // Text editor
            TextEditor(text: $text)
                .font(.system(.body, design: .monospaced))
                .padding()
                .onChange(of: text) { _, _ in
                    isModified = true
                }
        }
    }
    
    private func newDocument() {
        text = ""
        fileName = "Untitled.txt"
        isModified = false
    }
    
    private func openDocument() {
        // Simulate opening a document
        text = "This is a sample document loaded from the file system."
        fileName = "Sample.txt"
        isModified = false
    }
    
    private func saveDocument() {
        // Simulate saving
        isModified = false
    }
}

// MARK: - Calculator
struct CalculatorView: View {
    @State private var display = "0"
    @State private var previousValue: Double = 0
    @State private var operation: Operation?
    @State private var waitingForInput = false
    
    enum Operation {
        case add, subtract, multiply, divide
        
        func perform(_ a: Double, _ b: Double) -> Double {
            switch self {
            case .add: return a + b
            case .subtract: return a - b
            case .multiply: return a * b
            case .divide: return b != 0 ? a / b : 0
            }
        }
        
        var symbol: String {
            switch self {
            case .add: return "+"
            case .subtract: return "−"
            case .multiply: return "×"
            case .divide: return "÷"
            }
        }
    }
    
    private let buttons: [[CalculatorButton]] = [
        [.clear, .negate, .percent, .divide],
        [.seven, .eight, .nine, .multiply],
        [.four, .five, .six, .subtract],
        [.one, .two, .three, .add],
        [.zero, .decimal, .equals]
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Display
            HStack {
                Spacer()
                Text(display)
                    .font(.system(size: 48, weight: .light, design: .rounded))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
            .padding()
            .frame(height: 100)
            .background(Color.primary.opacity(0.05))
            
            // Buttons
            VStack(spacing: 1) {
                ForEach(buttons.indices, id: \.self) { rowIndex in
                    HStack(spacing: 1) {
                        ForEach(buttons[rowIndex], id: \.self) { button in
                            CalculatorButtonView(
                                button: button,
                                action: { buttonPressed(button) }
                            )
                        }
                    }
                }
            }
        }
        .frame(width: 300, height: 500)
    }
    
    private func buttonPressed(_ button: CalculatorButton) {
        switch button {
        case .clear:
            display = "0"
            previousValue = 0
            operation = nil
            waitingForInput = false
            
        case .negate:
            if let value = Double(display) {
                display = formatNumber(-value)
            }
            
        case .percent:
            if let value = Double(display) {
                display = formatNumber(value / 100)
            }
            
        case .equals:
            performCalculation()
            operation = nil
            waitingForInput = true
            
        case .add, .subtract, .multiply, .divide:
            performCalculation()
            operation = button.operation
            previousValue = Double(display) ?? 0
            waitingForInput = true
            
        case .decimal:
            if waitingForInput {
                display = "0."
                waitingForInput = false
            } else if !display.contains(".") {
                display += "."
            }
            
        default:
            let number = button.rawValue
            if waitingForInput {
                display = number
                waitingForInput = false
            } else {
                display = display == "0" ? number : display + number
            }
        }
    }
    
    private func performCalculation() {
        guard let operation = operation,
              let currentValue = Double(display) else { return }
        
        let result = operation.perform(previousValue, currentValue)
        display = formatNumber(result)
        previousValue = result
    }
    
    private func formatNumber(_ number: Double) -> String {
        if number.truncatingRemainder(dividingBy: 1) == 0 {
            return String(Int(number))
        } else {
            return String(number)
        }
    }
}

enum CalculatorButton: String, CaseIterable {
    case zero = "0", one = "1", two = "2", three = "3", four = "4"
    case five = "5", six = "6", seven = "7", eight = "8", nine = "9"
    case decimal = ".", equals = "="
    case add = "+", subtract = "−", multiply = "×", divide = "÷"
    case clear = "C", negate = "±", percent = "%"
    
    var operation: CalculatorView.Operation? {
        switch self {
        case .add: return .add
        case .subtract: return .subtract
        case .multiply: return .multiply
        case .divide: return .divide
        default: return nil
        }
    }
    
    var backgroundColor: Color {
        switch self {
        case .add, .subtract, .multiply, .divide, .equals:
            return .orange
        case .clear, .negate, .percent:
            return .gray
        default:
            return Color.primary.opacity(0.1)
        }
    }
}

struct CalculatorButtonView: View {
    let button: CalculatorButton
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(button.rawValue)
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(button.backgroundColor)
        }
        .frame(height: 70)
    }
}

// MARK: - Placeholder Views for Additional Preferences
struct DisplayPreferencesView: View {
    var body: some View {
        Text("Display Preferences")
            .font(.largeTitle)
    }
}

struct SoundPreferencesView: View {
    var body: some View {
        Text("Sound Preferences")
            .font(.largeTitle)
    }
}

struct NetworkPreferencesView: View {
    var body: some View {
        Text("Network Preferences")
            .font(.largeTitle)
    }
}

struct SecurityPreferencesView: View {
    var body: some View {
        Text("Security Preferences")
            .font(.largeTitle)
    }
}

struct KernelPreferencesView: View {
    var body: some View {
        Text("Kernel Preferences")
            .font(.largeTitle)
    }
}

struct MemoryPreferencesView: View {
    var body: some View {
        Text("Memory Preferences")
            .font(.largeTitle)
    }
}

struct MemoryMonitorView: View {
    let processes: [SystemProcess]
    let memoryUsage: Double
    
    var body: some View {
        Text("Memory Monitor")
            .font(.largeTitle)
    }
}

struct EnergyMonitorView: View {
    var body: some View {
        Text("Energy Monitor")
            .font(.largeTitle)
    }
}

struct DiskMonitorView: View {
    var body: some View {
        Text("Disk Monitor")
            .font(.largeTitle)
    }
}

struct NetworkMonitorView: View {
    var body: some View {
        Text("Network Monitor")
            .font(.largeTitle)
    }
}

struct NetworkUtilityView: View {
    var body: some View {
        Text("Network Utility")
            .font(.largeTitle)
    }
}

struct KernelMonitorView: View {
    var body: some View {
        Text("Kernel Monitor")
            .font(.largeTitle)
    }
}

struct ProcessManagerView: View {
    var body: some View {
        Text("Process Manager")
            .font(.largeTitle)
    }
}

struct SystemInfoView: View {
    var body: some View {
        Text("System Information")
            .font(.largeTitle)
    }
}

// MARK: - Web Browser
struct WebBrowserView: View {
    @State private var url = "https://www.apple.com"
    @State private var currentURL = "https://www.apple.com"
    @State private var isLoading = false
    @State private var canGoBack = false
    @State private var canGoForward = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Navigation Bar
            HStack(spacing: 12) {
                // Back/Forward buttons
                HStack(spacing: 4) {
                    Button(action: {}) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .disabled(!canGoBack)
                    .buttonStyle(.borderless)
                    
                    Button(action: {}) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .disabled(!canGoForward)
                    .buttonStyle(.borderless)
                }
                
                // URL Bar
                HStack {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.green)
                    
                    TextField("Enter URL or search", text: $url)
                        .textFieldStyle(PlainTextFieldStyle())
                        .onSubmit {
                            loadURL()
                        }
                    
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .scaleEffect(0.6)
                    } else {
                        Button(action: { loadURL() }) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 14))
                        }
                        .buttonStyle(.borderless)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.primary.opacity(0.05))
                .cornerRadius(8)
                
                // Action buttons
                HStack(spacing: 4) {
                    Button(action: {}) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 16))
                    }
                    .buttonStyle(.borderless)
                    
                    Button(action: {}) {
                        Image(systemName: "bookmark")
                            .font(.system(size: 16))
                    }
                    .buttonStyle(.borderless)
                }
            }
            .padding()
            .background(Color.primary.opacity(0.02))
            
            // Web Content Area
            ZStack {
                Color.white
                
                VStack(spacing: 20) {
                    Spacer()
                    
                    Image(systemName: "globe")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    VStack(spacing: 8) {
                        Text("RadiateOS Safari")
                            .font(.title)
                            .fontWeight(.semibold)
                        
                        Text("Your web browser for the optical age")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Current URL: \(currentURL)")
                            .font(.system(.body, design: .monospaced))
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                        
                        Text("Features:")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Label("Optical Network Protocol Support", systemImage: "network")
                            Label("Quantum-encrypted Connections", systemImage: "lock.shield")
                            Label("Photonic Content Rendering", systemImage: "lightbulb")
                            Label("Neural Tab Management", systemImage: "brain.head.profile")
                        }
                        .font(.subheadline)
                    }
                    .padding()
                    .background(Color.blue.opacity(0.05))
                    .cornerRadius(12)
                    
                    Spacer()
                }
                .padding()
            }
            
            // Status Bar
            HStack {
                Text("Ready")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("RadiateOS Safari 1.0")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            .padding(.vertical, 4)
            .background(Color.primary.opacity(0.02))
        }
    }
    
    private func loadURL() {
        isLoading = true
        currentURL = url
        
        // Simulate loading
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isLoading = false
            canGoBack = true
        }
    }
}

// MARK: - Development Tools

struct CodeEditorView: View {
    @State private var code = """
import SwiftUI

struct RadiateOSApp: View {
    var body: some View {
        VStack {
            Text("Welcome to RadiateOS")
                .font(.title)
            
            Text("Optical Computing Platform")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}
"""
    @State private var selectedLanguage = "Swift"
    @State private var isRunning = false
    @State private var output = ""
    
    let languages = ["Swift", "Python", "JavaScript", "C++", "Rust"]
    
    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack {
                Picker("Language", selection: $selectedLanguage) {
                    ForEach(languages, id: \.self) { language in
                        Text(language).tag(language)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                
                Spacer()
                
                Button(action: runCode) {
                    HStack {
                        if isRunning {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .scaleEffect(0.7)
                        } else {
                            Image(systemName: "play.fill")
                        }
                        Text(isRunning ? "Running..." : "Run")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isRunning)
                
                Button("Save") {
                    // Save functionality
                }
                .buttonStyle(.bordered)
            }
            .padding()
            .background(Color.primary.opacity(0.05))
            
            HSplitView {
                // Code Editor
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Text("Editor")
                            .font(.headline)
                        Spacer()
                        Text("\(code.components(separatedBy: .newlines).count) lines")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    TextEditor(text: $code)
                        .font(.system(.body, design: .monospaced))
                        .padding()
                        .background(Color.primary.opacity(0.02))
                }
                
                // Output Panel
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Text("Output")
                            .font(.headline)
                        Spacer()
                        Button("Clear") {
                            output = ""
                        }
                        .buttonStyle(.borderless)
                        .font(.caption)
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    ScrollView {
                        Text(output.isEmpty ? "Run code to see output..." : output)
                            .font(.system(.body, design: .monospaced))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                    }
                    .background(Color.black.opacity(0.9))
                    .foregroundColor(.green)
                }
            }
        }
    }
    
    private func runCode() {
        isRunning = true
        output = "Compiling \(selectedLanguage) code...\n"
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            output += """
Compilation successful!
Running on RadiateOS Optical CPU...

Welcome to RadiateOS
Optical Computing Platform

Process completed with exit code 0
Execution time: 0.042s
Memory usage: 2.1MB
Optical cycles: 1,048,576
"""
            isRunning = false
        }
    }
}

struct SwiftCompilerView: View {
    @State private var sourceFiles: [String] = ["main.swift", "App.swift", "Views.swift"]
    @State private var selectedFile = "main.swift"
    @State private var buildOutput = ""
    @State private var isBuilding = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Swift Compiler")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: buildProject) {
                    HStack {
                        if isBuilding {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .scaleEffect(0.7)
                        } else {
                            Image(systemName: "hammer.fill")
                        }
                        Text(isBuilding ? "Building..." : "Build")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isBuilding)
            }
            .padding()
            .background(Color.primary.opacity(0.05))
            
            HSplitView {
                // File List
                VStack(alignment: .leading) {
                    Text("Source Files")
                        .font(.headline)
                        .padding(.horizontal)
                        .padding(.top)
                    
                    List(sourceFiles, id: \.self, selection: $selectedFile) { file in
                        HStack {
                            Image(systemName: "doc.text")
                                .foregroundColor(.blue)
                            Text(file)
                            Spacer()
                        }
                        .padding(.vertical, 2)
                    }
                }
                .frame(minWidth: 200)
                
                // Build Output
                VStack(alignment: .leading) {
                    Text("Build Output")
                        .font(.headline)
                        .padding(.horizontal)
                        .padding(.top)
                    
                    ScrollView {
                        Text(buildOutput.isEmpty ? "Click Build to compile project..." : buildOutput)
                            .font(.system(.body, design: .monospaced))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                    }
                    .background(Color.black.opacity(0.9))
                    .foregroundColor(.white)
                }
            }
        }
    }
    
    private func buildProject() {
        isBuilding = true
        buildOutput = """
RadiateOS Swift Compiler v1.0
Optical Computing Target: x86_64-radiateos-macos

Compiling Swift sources...
[1/3] Compiling main.swift
[2/3] Compiling App.swift  
[3/3] Compiling Views.swift

Linking...
"""
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            buildOutput += """

✓ Build succeeded!

Output: RadiateOSApp.app
Size: 2.1 MB
Optical optimizations: Enabled
Photonic acceleration: Active

Build time: 2.847s
"""
            isBuilding = false
        }
    }
}

struct PackageManagerView: View {
    @State private var searchText = ""
    @State private var installedPackages = ["SwiftUI", "Foundation", "CoreData"]
    @State private var availablePackages = [
        ("Alamofire", "HTTP Networking", "5.6.4"),
        ("SnapKit", "Auto Layout", "5.6.0"),
        ("RxSwift", "Reactive Programming", "6.5.0"),
        ("Kingfisher", "Image Loading", "7.4.1")
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Package Manager")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                TextField("Search packages...", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 200)
            }
            .padding()
            .background(Color.primary.opacity(0.05))
            
            HSplitView {
                // Installed Packages
                VStack(alignment: .leading) {
                    Text("Installed")
                        .font(.headline)
                        .padding(.horizontal)
                        .padding(.top)
                    
                    List(installedPackages, id: \.self) { package in
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text(package)
                            Spacer()
                            Button("Remove") {
                                installedPackages.removeAll { $0 == package }
                            }
                            .buttonStyle(.borderless)
                            .foregroundColor(.red)
                        }
                    }
                }
                .frame(minWidth: 250)
                
                // Available Packages
                VStack(alignment: .leading) {
                    Text("Available")
                        .font(.headline)
                        .padding(.horizontal)
                        .padding(.top)
                    
                    List(availablePackages, id: \.0) { package in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(package.0)
                                    .font(.headline)
                                Text(package.1)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Text("v\(package.2)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Button("Install") {
                                installedPackages.append(package.0)
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
    }
}
