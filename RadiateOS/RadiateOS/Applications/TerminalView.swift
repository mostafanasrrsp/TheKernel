//
//  TerminalView.swift
//  RadiateOS
//
//  Terminal application with command execution
//

import SwiftUI

struct TerminalView: View {
    @State private var commandHistory: [TerminalEntry] = []
    @State private var currentCommand = ""
    @State private var currentDirectory = "/Users/user"
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Terminal header
            HStack {
                HStack(spacing: 8) {
                    Circle()
                        .fill(.red)
                        .frame(width: 12, height: 12)
                    Circle()
                        .fill(.yellow)
                        .frame(width: 12, height: 12)
                    Circle()
                        .fill(.green)
                        .frame(width: 12, height: 12)
                }
                
                Spacer()
                
                Text("Terminal — \(currentDirectory)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.primary.opacity(0.05))
            
            // Terminal content
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        // Welcome message
                        if commandHistory.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("RadiateOS Terminal v1.0")
                                    .foregroundColor(.green)
                                Text("Welcome to the optical computing shell")
                                    .foregroundColor(.secondary)
                                Text("Type 'help' for available commands")
                                    .foregroundColor(.secondary)
                                Text("")
                            }
                            .font(.system(.body, design: .monospaced))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 16)
                            .padding(.top, 16)
                        }
                        
                        // Command history
                        ForEach(commandHistory) { entry in
                            TerminalEntryView(entry: entry, currentDirectory: currentDirectory)
                        }
                        
                        // Current input line
                        HStack(spacing: 8) {
                            Text(promptString)
                                .foregroundColor(.blue)
                            
                            TextField("", text: $currentCommand)
                                .textFieldStyle(PlainTextFieldStyle())
                                .focused($isInputFocused)
                                .onSubmit {
                                    executeCommand()
                                }
                        }
                        .font(.system(.body, design: .monospaced))
                        .padding(.horizontal, 16)
                        .id("currentInput")
                    }
                }
                .onChange(of: commandHistory.count) { _, _ in
                    withAnimation(.easeOut(duration: 0.3)) {
                        proxy.scrollTo("currentInput", anchor: .bottom)
                    }
                }
            }
            .background(Color.black)
            .foregroundColor(.white)
        }
        .onAppear {
            isInputFocused = true
        }
    }
    
    private var promptString: String {
        "user@radiateos:\(currentDirectory.split(separator: "/").last ?? "~")$"
    }
    
    private func executeCommand() {
        let command = currentCommand.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !command.isEmpty else { return }
        
        let entry = TerminalEntry(
            command: command,
            output: processCommand(command),
            directory: currentDirectory,
            timestamp: Date()
        )
        
        commandHistory.append(entry)
        currentCommand = ""
    }
    
    private func processCommand(_ command: String) -> String {
        let components = command.split(separator: " ").map(String.init)
        guard let cmd = components.first else { return "" }
        
        switch cmd.lowercased() {
        case "help":
            return """
Available commands:
  ls          - List directory contents
  cd          - Change directory
  pwd         - Print working directory
  mkdir       - Create directory
  touch       - Create file
  cat         - Display file contents
  clear       - Clear terminal
  whoami      - Current user
  date        - Current date and time
  ps          - List running processes
  top         - System activity
  kernel      - Kernel information
  optical     - Optical CPU status
  memory      - Memory information
  exit        - Close terminal
"""
            
        case "ls":
            return simulateLS(components)
            
        case "pwd":
            return currentDirectory
            
        case "whoami":
            return OSManager.shared.currentUser.username
            
        case "date":
            let formatter = DateFormatter()
            formatter.dateStyle = .full
            formatter.timeStyle = .long
            return formatter.string(from: Date())
            
        case "clear":
            commandHistory.removeAll()
            return ""
            
        case "cd":
            return changeDirectory(components)
            
        case "mkdir":
            return createDirectory(components)
            
        case "touch":
            return createFile(components)
            
        case "cat":
            return displayFile(components)
            
        case "ps":
            return listProcesses()
            
        case "top":
            return systemActivity()
            
        case "kernel":
            return kernelInfo()
            
        case "optical":
            return opticalCPUStatus()
            
        case "memory":
            return memoryInfo()
            
        case "exit":
            // Close terminal window
            return "Terminal session ended."
            
        default:
            return "radiateos: command not found: \(cmd)"
        }
    }
    
    private func simulateLS(_ components: [String]) -> String {
        let fileSystem = OSManager.shared.fileSystem
        let items = fileSystem.currentDirectory.children
        
        if items.isEmpty {
            return ""
        }
        
        var output = ""
        for item in items {
            let permissions = item.permissions.owner.string + item.permissions.group.string + item.permissions.others.string
            let size = item.type == .directory ? "dir" : "\(item.size)"
            let date = DateFormatter.shortDateTime.string(from: item.dateModified)
            
            output += String(format: "%-10s %8s %12s %s\n", permissions, size, date, item.name)
        }
        
        return output
    }
    
    private func changeDirectory(_ components: [String]) -> String {
        guard components.count > 1 else {
            currentDirectory = "/Users/\(OSManager.shared.currentUser.username)"
            return ""
        }
        
        let path = components[1]
        if path == ".." {
            let pathComponents = currentDirectory.split(separator: "/")
            if pathComponents.count > 1 {
                currentDirectory = "/" + pathComponents.dropLast().joined(separator: "/")
            } else {
                currentDirectory = "/"
            }
        } else if path.hasPrefix("/") {
            currentDirectory = path
        } else {
            currentDirectory = currentDirectory == "/" ? "/\(path)" : "\(currentDirectory)/\(path)"
        }
        
        return ""
    }
    
    private func createDirectory(_ components: [String]) -> String {
        guard components.count > 1 else {
            return "mkdir: missing operand"
        }
        
        return "Directory '\(components[1])' created"
    }
    
    private func createFile(_ components: [String]) -> String {
        guard components.count > 1 else {
            return "touch: missing operand"
        }
        
        return "File '\(components[1])' created"
    }
    
    private func displayFile(_ components: [String]) -> String {
        guard components.count > 1 else {
            return "cat: missing operand"
        }
        
        let filename = components[1]
        
        // Simulate file content
        switch filename {
        case "kernel.conf":
            return """
# RadiateOS Kernel Configuration
optical_cpu_enabled=true
memory_manager=advanced
rom_hot_swap=true
translation_layer=x86_64
debug_mode=false
"""
        case "README.txt":
            return """
Welcome to RadiateOS!

This is a revolutionary optical computing operating system.

Features:
- Optical CPU processing
- Smart memory management
- Ejectable ROM modules
- x86/x64 compatibility layer
"""
        default:
            return "cat: \(filename): No such file or directory"
        }
    }
    
    private func listProcesses() -> String {
        let processes = [
            "PID   COMMAND",
            "1     kernel",
            "2     optical_cpu",
            "3     memory_mgr",
            "4     rom_manager",
            "5     translation",
            "100   terminal",
            "101   filemanager",
            "102   desktop"
        ]
        
        return processes.joined(separator: "\n")
    }
    
    private func systemActivity() -> String {
        return """
Processes: 8 total
Load Avg: 0.25, 0.30, 0.35
CPU Usage: 15%
Memory: 2.1GB used, 5.9GB free
Optical Cores: 4 active
"""
    }
    
    private func kernelInfo() -> String {
        return """
RadiateOS Kernel Information
============================
Version: 1.0.0-optical
Architecture: x147-optical
Build Date: \(DateFormatter.kernelBuild.string(from: Date()))
Optical CPU: Active (4 cores)
Memory Manager: Advanced
ROM Manager: Hot-swap enabled
Translation Layer: x86/x64 compatible
Uptime: 2 hours, 15 minutes
"""
    }
    
    private func opticalCPUStatus() -> String {
        return """
Optical CPU Status
==================
Cores: 4 active
Frequency: 2.5 THz
Temperature: 25°C
Power: 15W
Efficiency: 98.7%
Photonic Gates: 1,048,576 active
Light Wavelength: 1550nm
Coherence: Stable
"""
    }
    
    private func memoryInfo() -> String {
        return """
Memory Information
==================
Total RAM: 8.0 GB
Used: 2.1 GB (26%)
Free: 5.9 GB (74%)
Cached: 512 MB
Buffers: 256 MB
Swap: 0 GB (not used)
Memory Technology: Optical Buffer Array
Access Speed: 0.1 ns
Bandwidth: 1 TB/s
"""
    }
}

struct TerminalEntry: Identifiable {
    let id = UUID()
    let command: String
    let output: String
    let directory: String
    let timestamp: Date
}

struct TerminalEntryView: View {
    let entry: TerminalEntry
    let currentDirectory: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Command line
            HStack(spacing: 8) {
                Text(promptString)
                    .foregroundColor(.blue)
                
                Text(entry.command)
                    .foregroundColor(.white)
            }
            
            // Output
            if !entry.output.isEmpty {
                Text(entry.output)
                    .foregroundColor(.white)
                    .textSelection(.enabled)
            }
        }
        .font(.system(.body, design: .monospaced))
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
    }
    
    private var promptString: String {
        "user@radiateos:\(entry.directory.split(separator: "/").last ?? "~")$"
    }
}

extension DateFormatter {
    static let shortDateTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd HH:mm"
        return formatter
    }()
    
    static let kernelBuild: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()
}

#Preview {
    TerminalView()
        .background(Color.black)
        .preferredColorScheme(.dark)
}
