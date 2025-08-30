//
//  Spacing.swift
//  RadiateOS
//

import Foundation

#if canImport(SwiftUI)
import SwiftUI

public enum RadiateSpacing {
    public static let xs: CGFloat = 4
    public static let sm: CGFloat = 8
    public static let md: CGFloat = 12
    public static let lg: CGFloat = 16
    public static let xl: CGFloat = 24
    public static let xxl: CGFloat = 32
}

public enum RadiateRadius {
    public static let sm: CGFloat = 8
    public static let md: CGFloat = 12
    public static let lg: CGFloat = 16
    public static let pill: CGFloat = 999
}

public struct RadiateShadowSpec {
    public let x: CGFloat
    public let y: CGFloat
    public let blur: CGFloat
    public let opacity: Double
}

public enum RadiateShadow {
    public static let level1 = RadiateShadowSpec(x: 0, y: 6, blur: 16, opacity: 0.25)
    public static let level2 = RadiateShadowSpec(x: 0, y: 10, blur: 24, opacity: 0.28)
    public static let level3 = RadiateShadowSpec(x: 0, y: 14, blur: 32, opacity: 0.32)
}

public extension View {
    func radiateShadow(_ spec: RadiateShadowSpec, color: Color = .black) -> some View {
        shadow(color: color.opacity(spec.opacity), radius: spec.blur, x: spec.x, y: spec.y)
    }
}
#else
public enum RadiateSpacing { public static let dummy = 0 }
public enum RadiateRadius { public static let dummy = 0 }
public struct RadiateShadowSpec { public let x, y, blur: Int; public let opacity: Double }
public enum RadiateShadow {}
#endif


