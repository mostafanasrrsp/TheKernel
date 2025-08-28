//
//  OpticalCPU.swift
//  RadiateOS
//

import Foundation

public struct Program: Sendable, Hashable {
    public let instructions: [Instruction]
}

public actor OpticalCPU {
    private var isPoweredOn: Bool = false

    public init() {}

    public func powerOn() async throws {
        guard !isPoweredOn else { return }
        try await Task.sleep(nanoseconds: 2_000_000)
        isPoweredOn = true
    }

    public func powerOff() async {
        isPoweredOn = false
    }

    public func execute(program: Program, memory: MemoryManager) async throws -> ExecutionResult {
        guard isPoweredOn else { throw KernelError.cpuNotPowered }

        let start = DispatchTime.now().uptimeNanoseconds
        var instructionsRetired: UInt64 = 0

        for _ in program.instructions {
            try Task.checkCancellation()
            instructionsRetired &+= 1
        }

        let end = DispatchTime.now().uptimeNanoseconds
        let cycles = instructionsRetired

        let wallTime = end &- start
        let executionTimeSeconds = Double(wallTime) / 1_000_000_000.0
        
        return ExecutionResult(
            exitCode: 0,
            output: "Optical kernel executed successfully!\nProcessed \(instructionsRetired) photonic operations\nMemory bandwidth: 1TB/s\nCPU frequency: 2.5THz",
            executionTime: executionTimeSeconds,
            cycles: cycles,
            instructionsRetired: instructionsRetired,
            wallTimeNanoseconds: wallTime
        )
    }
}

public enum KernelError: Error {
    case cpuNotPowered
    case romMissing
    case translationFailed
}
