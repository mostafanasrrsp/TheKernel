import Foundation

/// Coalesces rapid calls and executes only once after the specified delay.
public actor Debouncer<Value> {
    private let delayNanos: UInt64
    private var task: Task<Value, Error>?

    public init(delay: TimeInterval) {
        self.delayNanos = UInt64(delay * 1_000_000_000)
    }

    public func submit(operation: @escaping @Sendable () async throws -> Value) {
        task?.cancel()
        task = Task {
            try Task.checkCancellation()
            try await Task.sleep(nanoseconds: delayNanos)
            return try await operation()
        }
    }

    @discardableResult
    public func value() async throws -> Value {
        guard let t = task else { throw CancellationError() }
        return try await t.value
    }
}


