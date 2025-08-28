//
//  Typography.swift
//  RadiateOS
//

import Foundation

#if canImport(SwiftUI)
import SwiftUI

public enum RadiateTypography {
    public static func h1(_ scheme: ColorScheme) -> Font { .system(size: 34, weight: .bold, design: .rounded) }
    public static func h2(_ scheme: ColorScheme) -> Font { .system(size: 28, weight: .semibold, design: .rounded) }
    public static func h3(_ scheme: ColorScheme) -> Font { .system(size: 22, weight: .semibold, design: .rounded) }
    public static func title(_ scheme: ColorScheme) -> Font { .system(size: 20, weight: .semibold, design: .rounded) }
    public static func body(_ scheme: ColorScheme) -> Font { .system(size: 16, weight: .regular, design: .rounded) }
    public static func callout(_ scheme: ColorScheme) -> Font { .system(size: 15, weight: .regular, design: .rounded) }
    public static func caption(_ scheme: ColorScheme) -> Font { .system(size: 13, weight: .medium, design: .rounded) }
    public static func mono(_ scheme: ColorScheme) -> Font { .system(size: 14, weight: .regular, design: .monospaced) }
}

public extension Text {
    func radiateHeading() -> some View { self.font(.system(size: 22, weight: .semibold, design: .rounded)) }
    func radiateBody() -> some View { self.font(.system(size: 16, weight: .regular, design: .rounded)) }
    func radiateCaption() -> some View { self.font(.system(size: 12, weight: .medium, design: .rounded)) }
}
#else
// Non-SwiftUI environments do not need typography helpers.
public enum RadiateTypography {}
#endif

