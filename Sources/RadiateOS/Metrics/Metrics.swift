import Foundation
import os

/// Ultra-lightweight metrics and signpost helpers.
public enum Metrics {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "RadiateOS"
    private static let log = OSLog(subsystem: subsystem, category: "metrics")

    public static func counter(_ name: StaticString, _ value: Int64 = 1) {
        os_log("%{public}@:%{public}ld", log: log, type: .info, String(describing: name), value)
    }

    public static func signpostBegin(_ name: StaticString, id: OSSignpostID = .exclusive) -> OSSignpostID {
        let spid = id == .exclusive ? OSSignpostID(log: log) : id
        if #available(macOS 10.14, iOS 12.0, *) {
            os_signpost(.begin, log: log, name: name, signpostID: spid)
        }
        return spid
    }

    public static func signpostEnd(_ name: StaticString, id: OSSignpostID) {
        if #available(macOS 10.14, iOS 12.0, *) {
            os_signpost(.end, log: log, name: name, signpostID: id)
        }
    }

    public static func time<T>(_ name: StaticString, _ block: () throws -> T) rethrows -> T {
        let start = DispatchTime.now().uptimeNanoseconds
        let result = try block()
        let end = DispatchTime.now().uptimeNanoseconds
        let delta = Int64(end &- start)
        counter(name, delta)
        return result
    }
}


