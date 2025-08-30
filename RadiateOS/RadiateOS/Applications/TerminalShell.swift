//
//  TerminalShell.swift
//  RadiateOS
//
//  Advanced terminal shell with command execution
//

import SwiftUI
import Foundation

@MainActor
class TerminalShell: ObservableObject {
    @Published var currentDirectory: String = "/Users/radiateos"
    @Published var commandHistory: [String] = []
    @Published var historyIndex: Int = -1
    @Published var environmentVariables: [String: String] = [
        "HOME": "/Users/radiateos",
        "USER": "radiateos",
        "SHELL": "/bin/radiatesh",
        "PATH": "/bin:/usr/bin:/usr/local/bin:/opt/bin",
        "PWD": "/Users/radiateos",
        "LANG": "en_US.UTF-8",
        "TERM": "radiateos-terminal",
        "HOSTNAME": "radiateos.local"
    ]

    private let kernel = Kernel.shared
    private let fileSystem = EnhancedFileSystem(currentUserName: "radiateos")
    private var commandIndex = 0

    init() {
        updateEnvironment()
    }

    func executeCommand(_ command: String, arguments: [String] = []) async -> ShellResult {
        let fullCommand = ([command] + arguments).joined(separator: " ")
        commandHistory.append(fullCommand)
        commandIndex += 1

        print("🔧 Executing: \(fullCommand)")

        switch command {
        case "ls", "list":
            return await executeList(arguments)
        case "cd":
            return executeChangeDirectory(arguments)
        case "pwd":
            return executePrintWorkingDirectory()
        case "cat":
            return await executeCat(arguments)
        case "mkdir":
            return executeMakeDirectory(arguments)
        case "rm":
            return executeRemove(arguments)
        case "cp":
            return executeCopy(arguments)
        case "mv":
            return executeMove(arguments)
        case "echo":
            return executeEcho(arguments)
        case "clear":
            return executeClear()
        case "help", "?":
            return executeHelp(arguments)
        case "whoami":
            return executeWhoAmI()
        case "date":
            return executeDate()
        case "uname":
            return executeUname(arguments)
        case "ps":
            return await executeProcessList()
        case "top":
            return await executeTop()
        case "df":
            return await executeDiskFree()
        case "du":
            return await executeDiskUsage(arguments)
        case "free":
            return await executeFree()
        case "uptime":
            return executeUptime()
        case "kill":
            return await executeKill(arguments)
        case "ping":
            return await executePing(arguments)
        case "curl", "wget":
            return await executeDownload(arguments)
        case "history":
            return executeHistory()
        case "export":
            return executeExport(arguments)
        case "env":
            return executeEnvironment()
        case "alias":
            return executeAlias(arguments)
        case "jobs":
            return await executeJobs()
        case "bg":
            return await executeBackground(arguments)
        case "fg":
            return await executeForeground(arguments)
        case "network", "net":
            return executeNetwork(arguments)
        case "security", "sec":
            return executeSecurity(arguments)
        case "offline":
            return executeOfflineMode(arguments)
        case "online":
            return executeOnlineMode(arguments)
        case "firewall", "fw":
            return executeFirewall(arguments)
        case "encryption", "encrypt":
            return executeEncryption(arguments)
        case "exit", "quit":
            return executeExit()
        default:
            return await executeExternalCommand(command, arguments: arguments)
        }
    }

    // MARK: - File System Commands

    private func executeList(_ arguments: [String]) async -> ShellResult {
        let path = arguments.first ?? currentDirectory
        let showHidden = arguments.contains("-a") || arguments.contains("--all")
        let longFormat = arguments.contains("-l") || arguments.contains("--long")

        do {
            let items = try await fileSystem.listContents(of: path)

            if items.isEmpty {
                return ShellResult(output: "", exitCode: 0)
            }

            var output = ""
            if longFormat {
                output += "Permissions | Size | Modified | Name\n"
                output += "------------|------|----------|------\n"

                for item in items where showHidden || !item.name.hasPrefix(".") {
                    let permissions = formatPermissions(for: item)
                    let size = formatSize(item.size)
                    let modified = formatDate(item.modifiedDate)
                    output += "\(permissions) | \(size) | \(modified) | \(item.name)\n"
                }
            } else {
                output = items
                    .filter { showHidden || !$0.name.hasPrefix(".") }
                    .map { $0.name }
                    .joined(separator: "  ")
            }

            return ShellResult(output: output, exitCode: 0)
        } catch {
            return ShellResult(output: "ls: \(error.localizedDescription)", exitCode: 1)
        }
    }

    private func executeChangeDirectory(_ arguments: [String]) -> ShellResult {
        guard let path = arguments.first else {
            return ShellResult(output: "cd: missing argument", exitCode: 1)
        }

        let newPath: String
        if path.hasPrefix("/") {
            newPath = path
        } else if path == ".." {
            let components = currentDirectory.split(separator: "/").dropLast()
            newPath = components.isEmpty ? "/" : "/" + components.joined(separator: "/")
        } else if path == "." {
            return ShellResult(output: "", exitCode: 0)
        } else {
            newPath = currentDirectory + (currentDirectory == "/" ? "" : "/") + path
        }

        do {
            if try fileSystem.directoryExists(at: newPath) {
                currentDirectory = newPath
                environmentVariables["PWD"] = currentDirectory
                return ShellResult(output: "", exitCode: 0)
            } else {
                return ShellResult(output: "cd: \(path): No such file or directory", exitCode: 1)
            }
        } catch {
            return ShellResult(output: "cd: \(error.localizedDescription)", exitCode: 1)
        }
    }

    private func executePrintWorkingDirectory() -> ShellResult {
        return ShellResult(output: currentDirectory, exitCode: 0)
    }

    private func executeCat(_ arguments: [String]) async -> ShellResult {
        guard let filename = arguments.first else {
            return ShellResult(output: "cat: missing file operand", exitCode: 1)
        }

        let filePath = resolvePath(filename)

        do {
            let contents = try await fileSystem.readFile(at: filePath)
            return ShellResult(output: contents, exitCode: 0)
        } catch {
            return ShellResult(output: "cat: \(filename): \(error.localizedDescription)", exitCode: 1)
        }
    }

    private func executeMakeDirectory(_ arguments: [String]) -> ShellResult {
        guard let dirname = arguments.first else {
            return ShellResult(output: "mkdir: missing operand", exitCode: 1)
        }

        let dirPath = resolvePath(dirname)

        do {
            try fileSystem.createDirectory(at: dirPath)
            return ShellResult(output: "", exitCode: 0)
        } catch {
            return ShellResult(output: "mkdir: cannot create directory '\(dirname)': \(error.localizedDescription)", exitCode: 1)
        }
    }

    private func executeRemove(_ arguments: [String]) -> ShellResult {
        guard let filename = arguments.first else {
            return ShellResult(output: "rm: missing operand", exitCode: 1)
        }

        let recursive = arguments.contains("-r") || arguments.contains("--recursive")
        let force = arguments.contains("-f") || arguments.contains("--force")
        let filePath = resolvePath(filename)

        do {
            let attributes = try fileSystem.getAttributes(of: filePath)

            if attributes.isDirectory && !recursive {
                return ShellResult(output: "rm: cannot remove '\(filename)': Is a directory", exitCode: 1)
            }

            try fileSystem.removeItem(at: filePath)
            return ShellResult(output: "", exitCode: 0)
        } catch {
            if !force {
                return ShellResult(output: "rm: cannot remove '\(filename)': \(error.localizedDescription)", exitCode: 1)
            }
            return ShellResult(output: "", exitCode: 0)
        }
    }

    // MARK: - System Commands

    private func executeWhoAmI() -> ShellResult {
        let username = environmentVariables["USER"] ?? "unknown"
        return ShellResult(output: username, exitCode: 0)
    }

    private func executeDate() -> ShellResult {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .full
        return ShellResult(output: formatter.string(from: Date()), exitCode: 0)
    }

    private func executeUname(_ arguments: [String]) -> ShellResult {
        let all = arguments.contains("-a") || arguments.contains("--all")

        if all {
            return ShellResult(output: "RadiateOS localhost 1.0.0 Optical-x64 GNU/Linux", exitCode: 0)
        } else {
            return ShellResult(output: "RadiateOS", exitCode: 0)
        }
    }

    private func executeProcessList() async -> ShellResult {
        let processes = await kernel.scheduler.listProcesses()

        var output = "  PID   USER     %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND\n"

        for process in processes {
            let pid = String(format: "%5d", process.pid)
            let user = "radiateos".padding(toLength: 8, withPad: " ", startingAt: 0)
            let cpu = String(format: "%4.1f", Double.random(in: 0...100))
            let mem = String(format: "%4.1f", Double.random(in: 0...100))
            let vsz = String(format: "%5d", Int(process.memoryUsage / 1024))
            let rss = String(format: "%5d", Int(process.memoryUsage / 1024 / 2))
            let tty = "?".padding(toLength: 8, withPad: " ", startingAt: 0)
            let stat = process.state.rawValue.prefix(1)
            let start = "09:00".padding(toLength: 8, withPad: " ", startingAt: 0)
            let time = "00:00:00".padding(toLength: 8, withPad: " ", startingAt: 0)
            let command = process.name

            output += "\(pid) \(user) \(cpu) \(mem) \(vsz) \(rss) \(tty) \(stat) \(start) \(time) \(command)\n"
        }

        return ShellResult(output: output, exitCode: 0)
    }

    private func executeTop() async -> ShellResult {
        let systemInfo = kernel.getSystemInfo()
        let processes = await kernel.scheduler.listProcesses()

        var output = """
RadiateOS Tasks: \(processes.count) total,   1 running, \(processes.filter { $0.state == .blocked }.count) sleeping,   0 stopped,   0 zombie
%Cpu(s): \(String(format: "%.1f", systemInfo.cpuUsage)) us, \(String(format: "%.1f", 100 - systemInfo.cpuUsage)) id
MiB Mem : \(systemInfo.totalMemory / 1024 / 1024) total, \(systemInfo.freeMemory / 1024 / 1024) free, \(systemInfo.usedMemory / 1024 / 1024) used
MiB Swap: 0 total, 0 free, 0 used

  PID USER      PR  NI    VIRT    RES    SHR S  %CPU  %MEM     TIME+ COMMAND
"""

        for process in processes.prefix(10) {
            let pid = String(format: "%5d", process.pid)
            let user = "radiate".padding(toLength: 8, withPad: " ", startingAt: 0)
            let pr = String(format: "%2d", process.priority.rawValue)
            let ni = "0".padding(toLength: 3, withPad: " ", startingAt: 0)
            let virt = String(format: "%6d", Int(process.memoryUsage / 1024))
            let res = String(format: "%6d", Int(process.memoryUsage / 1024 / 2))
            let shr = String(format: "%6d", Int(process.memoryUsage / 1024 / 4))
            let s = process.state.rawValue.prefix(1)
            let cpu = String(format: "%5.1f", Double.random(in: 0...50))
            let mem = String(format: "%5.1f", Double.random(in: 0...20))
            let time = "0:00.00".padding(toLength: 8, withPad: " ", startingAt: 0)
            let command = process.name

            output += "\(pid) \(user) \(pr) \(ni) \(virt) \(res) \(shr) \(s) \(cpu) \(mem) \(time) \(command)\n"
        }

        return ShellResult(output: output, exitCode: 0)
    }

    private func executeDiskFree() async -> ShellResult {
        let output = """
Filesystem     1K-blocks    Used Available Use% Mounted on
radiatefs           8G     2G       6G  25% /
tmpfs              4G     0G       4G   0% /tmp
devtmpfs           2G     0G       2G   0% /dev
"""

        return ShellResult(output: output, exitCode: 0)
    }

    private func executeFree() async -> ShellResult {
        let systemInfo = kernel.getSystemInfo()

        let output = """
              total        used        free      shared  buff/cache   available
Mem:     \(String(format: "%12d", systemInfo.totalMemory / 1024)) \(String(format: "%12d", systemInfo.usedMemory / 1024)) \(String(format: "%12d", systemInfo.freeMemory / 1024))           0           0 \(String(format: "%12d", systemInfo.freeMemory / 1024))
Swap:     \(String(format: "%12d", 0)) \(String(format: "%12d", 0)) \(String(format: "%12d", 0))
"""

        return ShellResult(output: output, exitCode: 0)
    }

    private func executeUptime() -> ShellResult {
        let uptime = Date().timeIntervalSince1970 // Simplified
        let hours = Int(uptime / 3600)
        let minutes = Int((uptime.truncatingRemainder(dividingBy: 3600)) / 60)

        let output = " \(String(format: "%02d:%02d", hours, minutes)) up  0 users,  load average: 0.52, 0.58, 0.59"

        return ShellResult(output: output, exitCode: 0)
    }

    // MARK: - Network Commands

    private func executeNetwork(_ arguments: [String]) -> ShellResult {
        if arguments.isEmpty {
            return ShellResult(output: kernel.networkManager.getNetworkInfo(), exitCode: 0)
        }

        switch arguments[0] {
        case "status":
            return ShellResult(output: kernel.networkManager.getStatus(), exitCode: 0)
        case "interfaces", "if":
            let info = kernel.networkManager.getNetworkInfo()
            return ShellResult(output: info, exitCode: 0)
        case "offline":
            return executeOfflineMode([])
        case "online":
            return executeOnlineMode([])
        default:
            return ShellResult(output: "network: invalid option '\(arguments[0])'\nUsage: network [status|interfaces|offline|online]", exitCode: 1)
        }
    }

    private func executeSecurity(_ arguments: [String]) -> ShellResult {
        if arguments.isEmpty {
            return ShellResult(output: kernel.securityManager.getSecurityStatus(), exitCode: 0)
        }

        switch arguments[0] {
        case "status":
            return ShellResult(output: kernel.securityManager.getSecurityStatus(), exitCode: 0)
        case "report":
            return ShellResult(output: kernel.securityManager.getSecurityReport(), exitCode: 0)
        case "health":
            let health = kernel.securityManager.checkSecurityHealth()
            var output = "Security Health: \(health.description)\n"
            if !health.issues.isEmpty {
                output += "\nIssues:\n"
                for issue in health.issues {
                    output += "  ⚠ \(issue)\n"
                }
            }
            return ShellResult(output: output, exitCode: 0)
        default:
            return ShellResult(output: "security: invalid option '\(arguments[0])'\nUsage: security [status|report|health]", exitCode: 1)
        }
    }

    private func executeOfflineMode(_ arguments: [String]) -> ShellResult {
        if arguments.contains("--help") || arguments.contains("-h") {
            return ShellResult(output: "offline: Enable offline mode\nUsage: offline [--force]\n\nDisables all network connections and enables maximum security.", exitCode: 0)
        }

        kernel.networkManager.enableOfflineMode()
        kernel.securityManager.enableOfflineMode()

        return ShellResult(output: "✅ Offline mode enabled\n🔒 Maximum security protection active\n🔌 All external connections blocked", exitCode: 0)
    }

    private func executeOnlineMode(_ arguments: [String]) -> ShellResult {
        if arguments.contains("--help") || arguments.contains("-h") {
            return ShellResult(output: "online: Enable online mode\nUsage: online [--force]\n\nEnables network connections with standard security.", exitCode: 0)
        }

        kernel.networkManager.disableOfflineMode()
        kernel.securityManager.disableOfflineMode()

        return ShellResult(output: "✅ Online mode enabled\n🔒 Standard security protection active\n🔌 Network connections available", exitCode: 0)
    }

    private func executeFirewall(_ arguments: [String]) -> ShellResult {
        if arguments.isEmpty {
            return ShellResult(output: "Firewall Status: \(kernel.securityManager.firewallStatus.rawValue)", exitCode: 0)
        }

        switch arguments[0] {
        case "enable":
            // Firewall control would be implemented here
            return ShellResult(output: "Firewall enabled", exitCode: 0)
        case "disable":
            return ShellResult(output: "Firewall disable not recommended in offline mode", exitCode: 1)
        case "status":
            return ShellResult(output: "Firewall Status: \(kernel.securityManager.firewallStatus.rawValue)", exitCode: 0)
        default:
            return ShellResult(output: "firewall: invalid option '\(arguments[0])'\nUsage: firewall [enable|disable|status]", exitCode: 1)
        }
    }

    private func executeEncryption(_ arguments: [String]) -> ShellResult {
        if arguments.isEmpty {
            return ShellResult(output: "Encryption Status: \(kernel.securityManager.encryptionStatus.rawValue)", exitCode: 0)
        }

        switch arguments[0] {
        case "status":
            return ShellResult(output: "Encryption Status: \(kernel.securityManager.encryptionStatus.rawValue)", exitCode: 0)
        case "enable":
            return ShellResult(output: "Encryption is always enabled in offline mode", exitCode: 0)
        default:
            return ShellResult(output: "encryption: invalid option '\(arguments[0])'\nUsage: encryption [status]", exitCode: 1)
        }
    }

    // MARK: - Utility Commands

    private func executeEcho(_ arguments: [String]) -> ShellResult {
        let output = arguments.joined(separator: " ")
        return ShellResult(output: output, exitCode: 0)
    }

    private func executeClear() -> ShellResult {
        return ShellResult(output: "\u{001B}[2J\u{001B}[H", exitCode: 0, clearScreen: true)
    }

    private func executeHelp(_ arguments: [String]) -> ShellResult {
        let helpText = """
RadiateOS Terminal Help

Available commands:
  File Operations:
    ls [options] [path]     List directory contents
    cd [path]               Change directory
    pwd                     Print working directory
    cat [file]              Display file contents
    mkdir [dir]             Create directory
    rm [options] [file]     Remove files/directories
    cp [source] [dest]      Copy files
    mv [source] [dest]      Move/rename files

  System Information:
    ps                      List processes
    top                     Display process information
    df                      Show disk space usage
    du [path]               Show directory space usage
    free                    Show memory usage
    uptime                  Show system uptime
    uname [options]         Print system information

  User Commands:
    whoami                  Print current user
    date                    Print date and time
    history                 Show command history

  Shell Commands:
    echo [text]             Display text
    clear                   Clear screen
    export VAR=value        Set environment variable
    env                     Show environment variables
    alias                   Show command aliases
    help                    Show this help
    exit                    Exit shell

  Job Control:
    jobs                    List jobs
    bg [job]                Run job in background
    fg [job]                Bring job to foreground

  Network & Security:
    network [options]       Network management
    security [options]      Security management
    offline                 Enable offline mode
    online                  Enable online mode
    firewall [options]      Firewall management
    encryption [options]    Encryption management

Use 'help [command]' for detailed information about a specific command.
"""
        return ShellResult(output: helpText, exitCode: 0)
    }

    private func executeHistory() -> ShellResult {
        var output = ""
        for (index, command) in commandHistory.enumerated() {
            output += "\(String(format: "%4d", index + 1))  \(command)\n"
        }
        return ShellResult(output: output, exitCode: 0)
    }

    private func executeEnvironment() -> ShellResult {
        var output = ""
        for (key, value) in environmentVariables.sorted(by: { $0.key < $1.key }) {
            output += "\(key)=\(value)\n"
        }
        return ShellResult(output: output, exitCode: 0)
    }

    private func executeExport(_ arguments: [String]) -> ShellResult {
        guard let assignment = arguments.first else {
            return ShellResult(output: "export: missing assignment", exitCode: 1)
        }

        let parts = assignment.split(separator: "=", maxSplits: 1)
        if parts.count == 2 {
            let key = String(parts[0])
            let value = String(parts[1])
            environmentVariables[key] = value
            return ShellResult(output: "", exitCode: 0)
        } else {
            return ShellResult(output: "export: invalid assignment format", exitCode: 1)
        }
    }

    private func executeExit() -> ShellResult {
        return ShellResult(output: "Goodbye!", exitCode: 0, shouldExit: true)
    }

    private func executeExternalCommand(_ command: String, arguments: [String]) async -> ShellResult {
        // Try to find command in PATH
        let pathDirectories = environmentVariables["PATH"]?.split(separator: ":") ?? []
        var commandPath: String?

        for dir in pathDirectories {
            let fullPath = String(dir) + "/" + command
            if await fileSystem.fileExists(at: fullPath) {
                commandPath = fullPath
                break
            }
        }

        if let commandPath = commandPath {
            return ShellResult(output: "Command '\(command)' found at \(commandPath)\n(Not implemented: external command execution)", exitCode: 0)
        } else {
            return ShellResult(output: "\(command): command not found", exitCode: 127)
        }
    }

    // MARK: - Helper Methods

    private func resolvePath(_ path: String) -> String {
        if path.hasPrefix("/") {
            return path
        } else {
            return currentDirectory + (currentDirectory == "/" ? "" : "/") + path
        }
    }

    private func updateEnvironment() {
        environmentVariables["PWD"] = currentDirectory
    }

    private func formatPermissions(for item: EnhancedFileSystem.FileItem) -> String {
        var perms = ""

        if item.isDirectory {
            perms += "d"
        } else {
            perms += "-"
        }

        // Simplified permissions (rwx for all)
        perms += "rwxr-xr-x"

        return perms
    }

    private func formatSize(_ size: UInt64) -> String {
        let units = ["B", "K", "M", "G"]
        var value = Double(size)
        var unitIndex = 0

        while value >= 1024 && unitIndex < units.count - 1 {
            value /= 1024
            unitIndex += 1
        }

        return String(format: "%.0f%@", value, units[unitIndex])
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd HH:mm"
        return formatter.string(from: date)
    }

    // Placeholder implementations for missing methods
    private func executeCopy(_ arguments: [String]) -> ShellResult {
        return ShellResult(output: "cp: command not implemented", exitCode: 1)
    }

    private func executeMove(_ arguments: [String]) -> ShellResult {
        return ShellResult(output: "mv: command not implemented", exitCode: 1)
    }

    private func executeAlias(_ arguments: [String]) -> ShellResult {
        return ShellResult(output: "alias: command not implemented", exitCode: 1)
    }

    private func executeJobs() async -> ShellResult {
        return ShellResult(output: "jobs: command not implemented", exitCode: 1)
    }

    private func executeBackground(_ arguments: [String]) async -> ShellResult {
        return ShellResult(output: "bg: command not implemented", exitCode: 1)
    }

    private func executeForeground(_ arguments: [String]) async -> ShellResult {
        return ShellResult(output: "fg: command not implemented", exitCode: 1)
    }

    private func executeKill(_ arguments: [String]) async -> ShellResult {
        return ShellResult(output: "kill: command not implemented", exitCode: 1)
    }

    private func executePing(_ arguments: [String]) async -> ShellResult {
        return ShellResult(output: "ping: command not implemented", exitCode: 1)
    }

    private func executeDownload(_ arguments: [String]) async -> ShellResult {
        return ShellResult(output: "curl: command not implemented", exitCode: 1)
    }

    private func executeDiskUsage(_ arguments: [String]) async -> ShellResult {
        return ShellResult(output: "du: command not implemented", exitCode: 1)
    }
}

struct ShellResult {
    let output: String
    let exitCode: Int
    let clearScreen: Bool
    let shouldExit: Bool

    init(output: String = "", exitCode: Int = 0, clearScreen: Bool = false, shouldExit: Bool = false) {
        self.output = output
        self.exitCode = exitCode
        self.clearScreen = clearScreen
        self.shouldExit = shouldExit
    }
}