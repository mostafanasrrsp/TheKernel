import XCTest
@testable import RadiateOS

final class PerformancePrimitivesTests: XCTestCase {
    func testInFlightTaskCoalescer() async throws {
        let coalescer = InFlightTaskCoalescer<String, Int>()
        async let a: Int = try coalescer.run(for: "k") { try await work(5) }
        async let b: Int = try coalescer.run(for: "k") { try await work(999) }
        let result = try await (a, b)
        XCTAssertEqual(result.0, 5)
        XCTAssertEqual(result.1, 5)
    }

    func testAsyncLRUCache() async throws {
        let cache = AsyncLRUCache<String, Int>(capacity: 2, defaultTTL: 0.1)
        await cache.set("a", value: 1)
        await cache.set("b", value: 2)
        let va = await cache.get("a")
        XCTAssertEqual(va, 1)
        await cache.set("c", value: 3)
        let vb = await cache.get("b")
        XCTAssertNil(vb) // evicted
        try? await Task.sleep(nanoseconds: 200_000_000)
        let va2 = await cache.get("a")
        XCTAssertNil(va2) // expired
    }

    private func work(_ v: Int) async throws -> Int {
        try await Task.sleep(nanoseconds: 10_000_0)
        return v
    }
}

