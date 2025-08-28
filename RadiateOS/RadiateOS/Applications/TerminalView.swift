//
//  TerminalView.swift
//  RadiateOS
//
//  Terminal application with command execution
//

import SwiftUI

struct TerminalView: View {
    @StateObject private var shell = TerminalShell()
    @State private var commandHistory: [TerminalEntry] = []
    @State private var currentCommand = ""
    @FocusState private var isInputFocused: Bool
    @State private var historyIndex: Int = -1
    
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
                
                Text("Terminal — \(shell.currentDirectory)")
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
                            TerminalEntryView(entry: entry, currentDirectory: shell.currentDirectory)
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
                                .onChange(of: currentCommand) { _, _ in
                                    // Reset history index when user starts typing
                                    if historyIndex != -1 {
                                        historyIndex = -1
                                    }
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
        "user@radiateos:\(shell.currentDirectory.split(separator: "/").last ?? "~")$"
    }
    
    private func executeCommand() {
        let command = currentCommand.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !command.isEmpty else { return }

        Task {
            let components = command.split(separator: " ").map(String.init)
            guard let cmd = components.first else { return }

            let arguments = Array(components.dropFirst())
            let result = await shell.executeCommand(cmd, arguments: arguments)

            let entry = TerminalEntry(
                command: command,
                output: result.output,
                directory: shell.currentDirectory,
                timestamp: Date(),
                exitCode: result.exitCode
            )

            await MainActor.run {
                commandHistory.append(entry)
                currentCommand = ""

                if result.shouldExit {
                    // Close terminal window
                    if let window = OSManager.shared.openWindows.first(where: { $0.application.name == "Terminal" }) {
                        OSManager.shared.closeWindow(window)
                    }
                }

                if result.clearScreen {
                    commandHistory.removeAll()
                }
            }
        }
        }

    // Command history navigation
    private func navigateHistory(up: Bool) {
        let historyCount = shell.commandHistory.count
        guard historyCount > 0 else { return }

        if up {
            if historyIndex == -1 {
                historyIndex = historyCount - 1
            } else if historyIndex > 0 {
                historyIndex -= 1
            }
        } else {
            if historyIndex != -1 {
                historyIndex += 1
                if historyIndex >= historyCount {
                    historyIndex = -1
                }
            }
        }

        if historyIndex == -1 {
            currentCommand = ""
        } else {
            currentCommand = shell.commandHistory[historyIndex]
        }
    }

}

struct TerminalEntry: Identifiable {
    let id = UUID()
    let command: String
    let output: String
    let directory: String
    let timestamp: Date
    let exitCode: Int
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
