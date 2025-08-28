import Foundation

/// Simple reusable byte buffer pool to reduce allocations for transient buffers.
public actor ByteBufferPool {
    public struct Buffer {
        public var data: Data
        fileprivate let capacity: Int
    }

    private var pool: [Data] = []
    private let capacity: Int
    private let maxPoolSize: Int

    public init(capacity: Int = 64 * 1024, maxPoolSize: Int = 64) {
        self.capacity = capacity
        self.maxPoolSize = maxPoolSize
    }

    public func acquire() -> Buffer {
        if let idx = pool.indices.last {
            let d = pool.remove(at: idx)
            return Buffer(data: d, capacity: d.count)
        }
        return Buffer(data: Data(count: capacity), capacity: capacity)
    }

    public func release(_ buffer: Buffer) {
        guard buffer.capacity == capacity else { return }
        guard pool.count < maxPoolSize else { return }
        pool.append(buffer.data)
    }
}

