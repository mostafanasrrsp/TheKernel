import Foundation

/// Coalesces concurrent requests for the same key so only one task performs the work.
public actor InFlightTaskCoalescer<Key: Hashable, Value> {
    private var tasks: [Key: Task<Value, Error>] = [:]

    public init() {}

    /// Returns the in-flight task for the key or starts a new one using the provided operation.
    @discardableResult
    public func run(for key: Key, operation: @escaping @Sendable () async throws -> Value) async throws -> Value {
        if let existing = tasks[key] {
            return try await existing.value
        }

        let task = Task<Value, Error> {
            defer { Task { await self.removeTask(for: key) } }
            return try await operation()
        }
        tasks[key] = task
        return try await task.value
    }

    private func removeTask(for key: Key) {
        tasks.removeValue(forKey: key)
    }
}

