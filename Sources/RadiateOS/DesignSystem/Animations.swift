//
//  Animations.swift
//  RadiateOS
//

import Foundation

#if canImport(SwiftUI)
import SwiftUI

public enum RadiateAnimation {
    public static let fast: Animation = .spring(response: 0.25, dampingFraction: 0.85, blendDuration: 0.15)
    public static let smooth: Animation = .spring(response: 0.5, dampingFraction: 0.9, blendDuration: 0.25)
    public static let bouncy: Animation = .interpolatingSpring(stiffness: 120, damping: 12)

    public static func elevate(_ scheme: ColorScheme) -> AnyTransition {
        AnyTransition.asymmetric(
            insertion: .scale(scale: 0.98).combined(with: .opacity).combined(with: .move(edge: .bottom)),
            removal: .scale(scale: 0.98).combined(with: .opacity)
        )
    }

    public static let fade: AnyTransition = .opacity.animation(.easeInOut(duration: 0.25))
    public static let slide: AnyTransition = .move(edge: .trailing).combined(with: .opacity)
}
#else
public enum RadiateAnimation {}
#endif

