import Foundation

/// A simple generic LRU cache with optional TTL per entry. Safe for concurrent access via actor isolation.
public actor AsyncLRUCache<Key: Hashable, Value> {
    private final class Node {
        let key: Key
        var value: Value
        var expiresAt: Date?
        var prev: Node?
        var next: Node?

        init(key: Key, value: Value, expiresAt: Date?) {
            self.key = key
            self.value = value
            self.expiresAt = expiresAt
        }
    }

    private var map: [Key: Node] = [:]
    private var head: Node?
    private var tail: Node?
    private let capacity: Int
    private let defaultTTL: TimeInterval?

    public init(capacity: Int, defaultTTL: TimeInterval? = nil) {
        precondition(capacity > 0, "Capacity must be > 0")
        self.capacity = capacity
        self.defaultTTL = defaultTTL
    }

    public func get(_ key: Key) -> Value? {
        guard let node = map[key] else { return nil }
        if let exp = node.expiresAt, exp <= Date() {
            remove(node)
            map[key] = nil
            return nil
        }
        moveToFront(node)
        return node.value
    }

    public func set(_ key: Key, value: Value, ttl: TimeInterval? = nil) {
        let expiry: Date? = (ttl ?? defaultTTL).map { Date().addingTimeInterval($0) }
        if let existing = map[key] {
            existing.value = value
            existing.expiresAt = expiry
            moveToFront(existing)
            return
        }
        let node = Node(key: key, value: value, expiresAt: expiry)
        map[key] = node
        addToFront(node)
        trimIfNeeded()
    }

    public func removeValue(for key: Key) {
        guard let node = map.removeValue(forKey: key) else { return }
        remove(node)
    }

    public func removeAll() {
        map.removeAll(keepingCapacity: false)
        head = nil
        tail = nil
    }

    public var count: Int { map.count }

    private func addToFront(_ node: Node) {
        node.prev = nil
        node.next = head
        head?.prev = node
        head = node
        if tail == nil { tail = node }
    }

    private func moveToFront(_ node: Node) {
        guard head !== node else { return }
        // detach
        node.prev?.next = node.next
        node.next?.prev = node.prev
        if tail === node { tail = node.prev }
        // attach to front
        node.prev = nil
        node.next = head
        head?.prev = node
        head = node
    }

    private func remove(_ node: Node) {
        if head === node { head = node.next }
        if tail === node { tail = node.prev }
        node.prev?.next = node.next
        node.next?.prev = node.prev
        node.prev = nil
        node.next = nil
    }

    private func trimIfNeeded() {
        while map.count > capacity, let last = tail {
            map[last.key] = nil
            remove(last)
        }
    }
}


