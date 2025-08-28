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
    private let ram = MemoryManager()
    private let rom = ROMManager()
    private let translator = X86TranslationLayer()

    private init() {}

    public func boot() async throws {
        try await rom.mountDefaultModules()
        try await ram.initialize()
        try await cpu.powerOn()
        await scheduler.start()
    }

    public func shutdown() async {
        await scheduler.stop()
        await cpu.powerOff()
        await ram.flush()
        await rom.unmountAll()
    }

    public func execute(binary: Data) async throws -> ExecutionResult {
        let program = try await translator.translate(binary: binary)
        return try await cpu.execute(program: program, memory: ram)
    }
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
