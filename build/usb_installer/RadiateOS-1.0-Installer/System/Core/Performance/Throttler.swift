import Foundation

/// Ensures operations are not executed more frequently than the specified interval.
public actor Throttler {
    private let minimumInterval: UInt64 // nanoseconds
    private var lastExecution: UInt64 = 0 // DispatchTime.uptimeNanoseconds

    public init(minimumInterval: TimeInterval) {
        self.minimumInterval = UInt64(minimumInterval * 1_000_000_000)
    }

    public func run<T>(operation: @escaping @Sendable () async throws -> T) async throws -> T {
        let now = DispatchTime.now().uptimeNanoseconds
        let elapsed = now &- lastExecution
        if elapsed < minimumInterval {
            let remaining = minimumInterval &- elapsed
            try? await Task.sleep(nanoseconds: remaining)
        }
        lastExecution = DispatchTime.now().uptimeNanoseconds
        return try await operation()
    }
}


