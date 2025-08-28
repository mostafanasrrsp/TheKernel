//
//  Kernel.swift
//  RadiateOS
//
//  High-level kernel façade using Swift concurrency.
//

import Foundation

/// Entry point façade for the experimental kernel.
@MainActor
public final class Kernel: ObservableObject {
    public static let shared = Kernel()

    private let scheduler = KernelScheduler()
    private let cpu = OpticalCPU()
    private let ram = AdvancedMemoryManager(totalMemory: 8 * 1024 * 1024 * 1024) // 8GB
    private let rom = ROMManager()
    private let translator = X86TranslationLayer()
    private let fileSystem = FileSystemManager(currentUserName: "radiateos")
    private let networkManager = NetworkManager()
    private let securityManager = SecurityManager()

    private var kernelProcessID: Int = 0
    private(set) public var isBooted: Bool = false

    private init() {}

    public func boot() async throws {
        print("🚀 RadiateOS Kernel Boot Sequence Starting...")

        // Phase 1: Early initialization
        print("Phase 1: Early kernel initialization")
        try await initializeKernelMemory()

        // Phase 2: Core systems
        print("Phase 2: Initializing core systems")
        try await initializeCoreSystems()

        // Phase 3: Start scheduler
        print("Phase 3: Starting process scheduler")
        await scheduler.start()

        // Phase 4: Launch system processes
        print("Phase 4: Launching system processes")
        try await launchSystemProcesses()

        // Phase 5: Complete boot
        print("Phase 5: Boot sequence complete")
        isBooted = true

        print("✅ RadiateOS Kernel booted successfully!")
        print("   - Memory: \(ram.getMemoryInfo().totalPhysical / 1024 / 1024 / 1024)GB")
        print("   - Processes: \(scheduler.listProcesses().count) running")
        print("   - File System: \(fileSystem.getStatus())")
        print("   - Network: \(await networkManager.getStatus())")
    }

    public func shutdown() async {
        print("🛑 RadiateOS Kernel shutting down...")

        isBooted = false

        // Stop all processes
        await scheduler.stop()

        // Shutdown systems
        await cpu.powerOff()
        await ram.flush()
        await rom.unmountAll()
        await fileSystem.shutdown()
        await networkManager.shutdown()

        print("✅ RadiateOS Kernel shutdown complete")
    }

    public func execute(binary: Data, processID: Int? = nil) async throws -> ExecutionResult {
        let program = try await translator.translate(binary: binary)
        return try await cpu.execute(program: program, memory: ram, processID: processID ?? kernelProcessID)
    }

    public func createProcess(name: String, priority: KernelScheduler.ProcessPriority = .normal, executablePath: String? = nil) async throws -> Int {
        return await scheduler.createProcess(name: name, priority: priority, executablePath: executablePath)
    }

    public func terminateProcess(pid: Int) async throws {
        await scheduler.terminateProcess(pid: pid, exitCode: 0)
    }

    public func getSystemInfo() -> SystemInfo {
        let memoryInfo = ram.getMemoryInfo()
        let processes = scheduler.listProcesses()
        let memoryStats = memoryInfo.statistics

        return SystemInfo(
            kernelVersion: "RadiateOS 1.0.0",
            architecture: "Optical-x64",
            uptime: Date().timeIntervalSince1970, // Simplified
            totalMemory: memoryInfo.totalPhysical,
            freeMemory: memoryInfo.freePhysical,
            usedMemory: memoryInfo.usedPhysical,
            processCount: processes.count,
            cpuUsage: Double(scheduler.getSystemLoad()) * 100.0,
            memoryUsage: memoryStats.bytesAllocated > 0 ? Double(memoryStats.bytesAllocated) / Double(memoryInfo.totalPhysical) * 100.0 : 0.0,
            pageFaults: UInt64(memoryStats.pageFaults),
            contextSwitches: scheduler.getContextSwitchCount()
        )
    }

    // MARK: - Private Methods

    private func initializeKernelMemory() async throws {
        // Allocate kernel memory space
        let kernelMemorySize = 2 * 1024 * 1024 * 1024 // 2GB for kernel
        guard let kernelAddress = ram.allocate(size: Int(kernelMemorySize), flags: [.readable, .writable, .executable, .kernel]) else {
            throw KernelError.memoryAllocationFailed
        }

        print("   ✓ Kernel memory allocated at 0x\(String(format: "%llx", kernelAddress.value))")

        // Create kernel process
        kernelProcessID = await scheduler.createProcess(name: "kernel", priority: .critical, executablePath: "/kernel/kernel")
        print("   ✓ Kernel process created (PID: \(kernelProcessID))")
    }

    private func initializeCoreSystems() async throws {
        // Mount ROM modules
        try await rom.mountDefaultModules()
        print("   ✓ ROM modules mounted")

        // Power on CPU
        try await cpu.powerOn()
        print("   ✓ Optical CPU powered on")

        // Initialize file system
        try await fileSystem.initialize()
        print("   ✓ File system initialized")

        // Initialize network
        try await networkManager.initialize()
        print("   ✓ Network manager initialized")

        // Initialize security
        try await securityManager.initialize()
        print("   ✓ Security manager initialized")
    }

    private func launchSystemProcesses() async throws {
        // Launch essential system processes
        let systemProcesses = [
            ("init", KernelScheduler.ProcessPriority.critical, "/sbin/init"),
            ("systemd", KernelScheduler.ProcessPriority.high, "/sbin/systemd"),
            ("launchd", KernelScheduler.ProcessPriority.high, "/sbin/launchd"),
            ("syslogd", KernelScheduler.ProcessPriority.normal, "/sbin/syslogd"),
            ("cron", KernelScheduler.ProcessPriority.low, "/usr/sbin/cron"),
            ("sshd", KernelScheduler.ProcessPriority.normal, "/usr/sbin/sshd")
        ]

        for (name, priority, path) in systemProcesses {
            let pid = await scheduler.createProcess(name: name, priority: priority, executablePath: path)
            print("   ✓ Launched \(name) (PID: \(pid))")
        }
    }
}

// MARK: - Supporting Types

public struct SystemInfo {
    public let kernelVersion: String
    public let architecture: String
    public let uptime: TimeInterval
    public let totalMemory: UInt64
    public let freeMemory: UInt64
    public let usedMemory: UInt64
    public let processCount: Int
    public let cpuUsage: Double
    public let memoryUsage: Double
    public let pageFaults: UInt64
    public let contextSwitches: UInt64

    public var memoryUsagePercentage: Double {
        return totalMemory > 0 ? Double(usedMemory) / Double(totalMemory) * 100.0 : 0.0
    }
}

enum KernelError: Error {
    case memoryAllocationFailed
    case systemInitializationFailed
    case processCreationFailed
}

public struct ExecutionResult: Sendable, Hashable {
    public let exitCode: Int
    public let output: String
    public let executionTime: TimeInterval

    // Additional optical kernel metrics
    public let cycles: UInt64
    public let instructionsRetired: UInt64
    public let wallTimeNanoseconds: UInt64

    public init(exitCode: Int, output: String, executionTime: TimeInterval, cycles: UInt64 = 0, instructionsRetired: UInt64 = 0, wallTimeNanoseconds: UInt64 = 0) {
        self.exitCode = exitCode
        self.output = output
        self.executionTime = executionTime
        self.cycles = cycles
        self.instructionsRetired = instructionsRetired
        self.wallTimeNanoseconds = wallTimeNanoseconds
        }
}
