import SwiftUI

struct TerminalView: View {
    @State private var commandHistory: [String] = [
        "RadiateOS Terminal v2.0",
        "Type 'help' for available commands",
        ""
    ]
    @State private var currentCommand = ""
    @State private var commandHistoryIndex = 0
    @State private var savedCommands: [String] = []
    @FocusState private var isInputFocused: Bool
    
    let prompt = "radiate@optical:~$ "
    
    var body: some View {
        VStack(spacing: 0) {
            // Terminal output
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(Array(commandHistory.enumerated()), id: \.offset) { index, line in
                            Text(line)
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(colorForLine(line))
                                .textSelection(.enabled)
                                .id(index)
                        }
                        
                        // Current input line
                        HStack(spacing: 0) {
                            Text(prompt)
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(.green)
                            
                            TextField("", text: $currentCommand)
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(.white)
                                .textFieldStyle(.plain)
                                .focused($isInputFocused)
                                .onSubmit {
                                    executeCommand()
                                }
                                .onAppear {
                                    isInputFocused = true
                                }
                        }
                        .id("input")
                    }
                    .padding()
                }
                .onChange(of: commandHistory.count) { _ in
                    withAnimation {
                        proxy.scrollTo("input", anchor: .bottom)
                    }
                }
            }
            .background(Color.black)
            
            // Terminal toolbar
            HStack {
                Button(action: clearTerminal) {
                    Label("Clear", systemImage: "clear")
                }
                .buttonStyle(.plain)
                
                Divider()
                    .frame(height: 20)
                
                Button(action: { /* Export log */ }) {
                    Label("Export", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Text("UTF-8")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(.horizontal)
            .padding(.vertical, 5)
            .background(Color.black.opacity(0.8))
        }
        .background(Color.black)
        .onAppear {
            setupTerminal()
        }
    }
    
    private func setupTerminal() {
        // Initialize terminal with system info
        commandHistory.append(contentsOf: [
            "System: RadiateOS 2.0.0",
            "Kernel: \(Kernel().kernelVersion)",
            "Optical CPU: Enabled (8 cores @ 3.0 THz)",
            ""
        ])
    }
    
    private func executeCommand() {
        guard !currentCommand.isEmpty else { return }
        
        // Add command to history
        commandHistory.append(prompt + currentCommand)
        savedCommands.append(currentCommand)
        
        // Parse and execute command
        let parts = currentCommand.split(separator: " ").map(String.init)
        let command = parts.first ?? ""
        let args = Array(parts.dropFirst())
        
        let output = processCommand(command, args: args)
        commandHistory.append(contentsOf: output)
        commandHistory.append("")
        
        // Reset input
        currentCommand = ""
        commandHistoryIndex = savedCommands.count
    }
    
    private func processCommand(_ command: String, args: [String]) -> [String] {
        switch command.lowercased() {
        case "help":
            return [
                "Available commands:",
                "  help          - Show this help message",
                "  clear         - Clear terminal screen",
                "  ls            - List directory contents",
                "  pwd           - Print working directory",
                "  cd <dir>      - Change directory",
                "  cat <file>    - Display file contents",
                "  echo <text>   - Print text",
                "  ps            - List running processes",
                "  top           - Show system resources",
                "  optical       - Show optical CPU status",
                "  kernel        - Show kernel information",
                "  neofetch      - Display system information",
                "  date          - Show current date and time",
                "  whoami        - Display current user",
                "  uname         - Show system information",
                "  exit          - Exit terminal"
            ]
            
        case "clear":
            clearTerminal()
            return []
            
        case "ls":
            return [
                "Applications/  Desktop/  Documents/  Downloads/",
                "Library/      Music/    Pictures/   Public/",
                "System/       Videos/"
            ]
            
        case "pwd":
            return ["/Users/radiate"]
            
        case "cd":
            if args.isEmpty {
                return ["cd: missing directory argument"]
            }
            return ["Changed directory to: \(args[0])"]
            
        case "echo":
            return [args.joined(separator: " ")]
            
        case "ps":
            return [
                "  PID TTY          TIME CMD",
                "    1 ?        00:00:02 init",
                "    2 ?        00:00:00 kernel_task",
                "    3 ?        00:00:01 optical_processor",
                "  142 pts/0    00:00:00 terminal",
                "  156 pts/0    00:00:00 ps"
            ]
            
        case "top":
            return [
                "RadiateOS - up 2:15, load average: 0.12, 0.15, 0.09",
                "Tasks: 42 total, 2 running, 40 sleeping",
                "CPU:  12.3% user, 5.2% system, 82.5% idle",
                "Mem:  16384MB total, 4096MB used, 12288MB free",
                "Optical: 8 cores active, 95% efficiency"
            ]
            
        case "optical":
            return [
                "Optical CPU Status:",
                "  Cores: 8 photonic cores",
                "  Frequency: 3.0 THz",
                "  Wavelengths: 64 channels",
                "  Processing Rate: 95.2%",
                "  Temperature: 22°C (optical cooling)",
                "  Power: 15W (85% less than traditional)"
            ]
            
        case "kernel":
            return [
                "RadiateOS Kernel 2.0.0",
                "  Architecture: x86_64 with optical extensions",
                "  Scheduler: Multi-level Feedback Queue",
                "  Memory Manager: Virtual Memory with Optical Cache",
                "  Translation Layer: X86 to Optical enabled",
                "  Boot time: 0.8 seconds"
            ]
            
        case "neofetch":
            return generateNeofetch()
            
        case "date":
            let formatter = DateFormatter()
            formatter.dateFormat = "E MMM d HH:mm:ss zzz yyyy"
            return [formatter.string(from: Date())]
            
        case "whoami":
            return ["radiate"]
            
        case "uname":
            var result = "RadiateOS"
            if args.contains("-a") {
                result += " 2.0.0 RadiateOS-2.0.0-OPTICAL x86_64"
            }
            return [result]
            
        case "exit":
            return ["Goodbye!"]
            
        default:
            return ["bash: \(command): command not found"]
        }
    }
    
    private func generateNeofetch() -> [String] {
        return [
            "       ▄▄▄▄▄▄▄▄▄▄▄       radiate@optical",
            "      ▄█████████████▄     ---------------",
            "     ███████████████▌     OS: RadiateOS 2.0.0 x86_64",
            "    ▐██████▀▀▀███████     Host: Optical Workstation",
            "    ███████    ██████▌    Kernel: 2.0.0-OPTICAL",
            "    ███████    ██████▌    Uptime: 2 hours, 15 mins",
            "    ▐██████▄▄▄███████     Packages: 1337",
            "     ███████████████▌     Shell: bash 5.0",
            "      ▀█████████████▀     Terminal: RadiateOS Terminal",
            "       ▀▀▀▀▀▀▀▀▀▀▀       CPU: Optical CPU (8) @ 3.000THz",
            "                          GPU: Photonic Graphics",
            "    ████████████████      Memory: 4096MB / 16384MB",
            "    ████████████████      Disk: 42GB / 256GB",
            "                          ",
            "                          ████████████████"
        ]
    }
    
    private func clearTerminal() {
        commandHistory = ["Terminal cleared", ""]
    }
    
    private func colorForLine(_ line: String) -> Color {
        if line.starts(with: prompt) || line.starts(with: "radiate@") {
            return .green
        } else if line.starts(with: "bash:") || line.contains("error") || line.contains("Error") {
            return .red
        } else if line.starts(with: "  ") || line.starts(with: "\t") {
            return .white.opacity(0.8)
        } else {
            return .white
        }
    }
}

struct TerminalView_Previews: PreviewProvider {
    static var previews: some View {
        TerminalView()
            .frame(width: 800, height: 600)
    }
}