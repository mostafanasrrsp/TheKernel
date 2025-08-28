//
//  AppState.swift
//  RadiateOS
//

import Foundation
#if canImport(Combine)
import Combine
#endif

public enum SystemModule: String, CaseIterable, Codable, Equatable {
    case desktop
    case terminal
    case files
    case wifi
    case bluetooth
    case hotspot
}

#if canImport(Combine)
public final class AppState: ObservableObject {
    @Published public var activeModule: SystemModule = .desktop
    @Published public var searchQuery: String = ""
    public init() {}
}
#else
public final class AppState {
    public var activeModule: SystemModule = .desktop
    public var searchQuery: String = ""
    public init() {}
}
#endif

