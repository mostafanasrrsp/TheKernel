//
//  X86TranslationLayer.swift
//  RadiateOS
//

import Foundation

public struct X86TranslationLayer: Sendable {
    public init() {}

    public func translate(binary: Data) async throws -> Program {
        guard !binary.isEmpty else { throw KernelError.translationFailed }
        let count = min(1024, max(1, binary.count / 8))
        let instructions = (0..<count).map { _ in Instruction.nop }
        return Program(instructions: instructions)
    }
}
