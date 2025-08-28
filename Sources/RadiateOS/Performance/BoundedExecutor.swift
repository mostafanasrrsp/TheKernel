import Foundation

/// Executes tasks with bounded concurrency and backpressure.
public actor BoundedExecutor {
    private let semaphore: AsyncSemaphore
    private var isShutdown = false

    public init(maxConcurrent: Int) {
        self.semaphore = AsyncSemaphore(value: maxConcurrent)
    }

    public func submit<T>(_ operation: @escaping @Sendable () async throws -> T) async throws -> T {
        try Task.checkCancellation()
        guard !isShutdown else { throw CancellationError() }
        await semaphore.acquire()
        defer { Task { await semaphore.release() } }
        return try await operation()
    }

    public func shutdown() {
        isShutdown = true
    }
}

