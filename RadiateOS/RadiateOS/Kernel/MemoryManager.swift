//
//  MemoryManager.swift
//  RadiateOS
//

import Foundation

public actor MemoryManager {
    private var storage: [UInt64: Data] = [:]
    private(set) public var initialized: Bool = false

    public init() {}

    public func initialize() async throws {
        guard !initialized else { return }
        initialized = true
    }

    public func flush() async {
        storage.removeAll(keepingCapacity: true)
        initialized = false
    }

    public func allocate(page: UInt64, size: Int) async throws {
        storage[page] = Data(count: size)
    }

    public func write(page: UInt64, offset: Int, bytes: Data) async throws {
        guard var pageData = storage[page] else { throw MemoryError.pageMissing }
        let end = min(pageData.count, offset + bytes.count)
        let range = offset..<end
        if range.isEmpty { return }
        pageData.replaceSubrange(range, with: bytes.prefix(end - offset))
        storage[page] = pageData
    }

    public func read(page: UInt64, offset: Int, length: Int) async throws -> Data {
        guard let pageData = storage[page] else { throw MemoryError.pageMissing }
        let end = min(pageData.count, offset + length)
        if offset >= end { return Data() }
        return pageData.subdata(in: offset..<end)
    }
}

public enum MemoryError: Error {
    case pageMissing
}
