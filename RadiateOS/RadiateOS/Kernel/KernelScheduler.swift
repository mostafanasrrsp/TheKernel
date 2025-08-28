//
//  KernelScheduler.swift
//  RadiateOS
//

import Foundation

public actor KernelScheduler {
    private var loopTask: Task<Void, Never>? = nil
    private(set) public var isRunning: Bool = false

    public init() {}

    public func start() {
        guard loopTask == nil else { return }
        isRunning = true
        loopTask = Task.detached(priority: .high) { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000)
            }
        }
    }

    public func stop() {
        loopTask?.cancel()
        loopTask = nil
        isRunning = false
    }
}
