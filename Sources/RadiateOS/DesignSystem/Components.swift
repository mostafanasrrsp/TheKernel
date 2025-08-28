//
//  Components.swift
//  RadiateOS
//

import Foundation

#if canImport(SwiftUI)
import SwiftUI

// MARK: - Button Styles
public struct RadiatePrimaryButtonStyle: ButtonStyle {
    public init() {}
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold, design: .rounded))
            .foregroundStyle(.white)
            .padding(.vertical, 10)
            .padding(.horizontal, 16)
            .background(
                RadiateColors.spectrumGradient
                    .opacity(configuration.isPressed ? 0.9 : 1.0)
            )
            .clipShape(RoundedRectangle(cornerRadius: RadiateRadius.md, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

public struct RadiateIconButton: View {
    public enum ShapeStyleKind { case rounded, circle }
    private let systemName: String
    private let kind: ShapeStyleKind
    private let action: () -> Void
    @Environment(\.colorScheme) private var scheme

    public init(systemName: String, kind: ShapeStyleKind = .rounded, action: @escaping () -> Void) {
        self.systemName = systemName
        self.kind = kind
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(RadiateColors.textPrimary(for: scheme))
                .frame(width: 36, height: 36)
                .background(RadiateColors.surfaceSecondary(for: scheme))
        }
        .clipShape(kind == .circle ? Circle() : RoundedRectangle(cornerRadius: RadiateRadius.md, style: .continuous))
        .buttonStyle(.plain)
        .overlay(
            RoundedRectangle(cornerRadius: RadiateRadius.md, style: .continuous)
                .stroke(.white.opacity(0.06))
        )
    }
}

// MARK: - Card / Surface
public struct RadiateCard<Content: View>: View {
    private let content: Content
    @Environment(\.colorScheme) private var scheme

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        content
            .padding(RadiateSpacing.lg)
            .background(RadiateColors.surface(for: scheme))
            .clipShape(RoundedRectangle(cornerRadius: RadiateRadius.lg, style: .continuous))
            .radiateShadow(.level1)
    }
}

// MARK: - TextField Style
public struct RadiateTextFieldStyle: TextFieldStyle {
    @Environment(\.colorScheme) private var scheme
    public init() {}
    public func _body(configuration: TextField<_Label>) -> some View {
        configuration
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .background(RadiateColors.surfaceSecondary(for: scheme))
            .clipShape(RoundedRectangle(cornerRadius: RadiateRadius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: RadiateRadius.md, style: .continuous)
                    .stroke(.white.opacity(0.06))
            )
    }
}

// MARK: - Toggle Style
public struct RadiateToggleStyle: ToggleStyle {
    @Environment(\.colorScheme) private var scheme
    public init() {}
    public func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: RadiateSpacing.md) {
            configuration.label
                .font(.system(size: 15, weight: .medium, design: .rounded))

            Spacer(minLength: 12)

            RoundedRectangle(cornerRadius: RadiateRadius.pill, style: .continuous)
                .fill(configuration.isOn ? RadiateColors.brand : RadiateColors.surfaceSecondary(for: scheme))
                .frame(width: 48, height: 28)
                .overlay(
                    Circle()
                        .fill(Color.white)
                        .frame(width: 22, height: 22)
                        .offset(x: configuration.isOn ? 10 : -10)
                        .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                        .animation(RadiateAnimation.smooth, value: configuration.isOn)
                )
                .onTapGesture { configuration.isOn.toggle() }
        }
    }
}

// MARK: - Chips
public struct RadiateChip: View {
    @Environment(\.colorScheme) private var scheme
    private let text: String
    private let isSelected: Bool
    public init(_ text: String, isSelected: Bool = false) { self.text = text; self.isSelected = isSelected }
    public var body: some View {
        Text(text)
            .font(.system(size: 13, weight: .semibold, design: .rounded))
            .foregroundStyle(isSelected ? .white : RadiateColors.textSecondary(for: scheme))
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .background(isSelected ? RadiateColors.brand : RadiateColors.surfaceSecondary(for: scheme))
            .clipShape(Capsule())
    }
}

public extension View {
    func radiateToolbarTitle() -> some View {
        self.font(.system(size: 16, weight: .semibold, design: .rounded))
    }
}

#else
public struct RadiatePrimaryButtonStyle {}
#endif


