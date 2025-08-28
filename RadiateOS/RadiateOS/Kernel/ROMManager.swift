//
//  ROMManager.swift
//  RadiateOS
//

import Foundation

public struct ROMModule: Sendable, Hashable, Identifiable {
    public let id: UUID
    public let name: String
    public let payload: Data
    public init(id: UUID = UUID(), name: String, payload: Data) {
        self.id = id
        self.name = name
        self.payload = payload
    }
}

public actor ROMManager {
    private var mounted: [ROMModule] = []

    public init() {}

    public func mountDefaultModules() async throws {
        let boot = ROMModule(name: "BootROM", payload: Data("BOOT".utf8))
        mounted.append(boot)
    }

    public func insert(module: ROMModule) async {
        mounted.append(module)
    }

    public func eject(moduleId: UUID) async {
        mounted.removeAll { $0.id == moduleId }
    }

    public func unmountAll() async {
        mounted.removeAll()
    }

    public func list() async -> [ROMModule] { mounted }
}
