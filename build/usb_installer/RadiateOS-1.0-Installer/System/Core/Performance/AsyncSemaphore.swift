import Foundation

/// A lightweight async semaphore using Swift Concurrency.
public actor AsyncSemaphore {
    private var availablePermits: Int
    private var waiters: [CheckedContinuation<Void, Never>] = []

    public init(value: Int) {
        precondition(value > 0, "Semaphore value must be > 0")
        availablePermits = value
    }

    public func acquire() async {
        if availablePermits > 0 {
            availablePermits -= 1
            return
        }
        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            waiters.append(cont)
        }
    }

    public func release() {
        if let cont = waiters.first {
            waiters.removeFirst()
            cont.resume()
        } else {
            availablePermits += 1
        }
    }
}


