//
//  DesktopEnvironmentView.swift
//  RadiateOS
//

import Foundation

#if canImport(SwiftUI)
import SwiftUI

public struct DesktopEnvironmentView: View {
    @Environment(\.colorScheme) private var scheme

    public init() {}

    public var body: some View {
        ZStack {
            background
            VStack(alignment: .leading, spacing: RadiateSpacing.lg) {
                topBar
                HStack(alignment: .top, spacing: RadiateSpacing.lg) {
                    RadiateCard { widgetSystemStatus }
                        .frame(maxWidth: 340)
                    RadiateCard { quickActions }
                    Spacer()
                }
                Spacer()
            }
            .padding(RadiateSpacing.xl)
        }
    }

    private var background: some View {
        LinearGradient(colors: [
            Color.black.opacity(0.4),
            RadiateColors.brand.opacity(0.25),
            .clear
        ], startPoint: .topLeading, endPoint: .bottomTrailing)
        .background(
            Image(systemName: "sparkles")
                .font(.system(size: 220))
                .foregroundStyle(RadiateColors.brand.opacity(0.06))
                .rotationEffect(.degrees(-18))
                .offset(x: -120, y: -80)
        )
    }

    private var topBar: some View {
        HStack(spacing: RadiateSpacing.md) {
            Text("Desktop")
                .font(RadiateTypography.h2(scheme))
                .foregroundStyle(RadiateColors.textPrimary(for: scheme))
            Spacer()
            RadiateChip("Stable", isSelected: true)
            RadiateIconButton(systemName: "magnifyingglass", action: {})
            RadiateIconButton(systemName: "gearshape.fill", action: {})
            RadiateIconButton(systemName: "power", action: {})
        }
    }

    private var widgetSystemStatus: some View {
        VStack(alignment: .leading, spacing: RadiateSpacing.md) {
            Text("System Status")
                .font(RadiateTypography.title(scheme))
                .foregroundStyle(RadiateColors.textPrimary(for: scheme))
            HStack {
                Label("CPU 14%", systemImage: "cpu")
                Spacer()
                Label("Mem 42%", systemImage: "memorychip")
            }
            .foregroundStyle(RadiateColors.textSecondary(for: scheme))

            ProgressView(value: 0.42)
                .tint(RadiateColors.brand)
        }
    }

    private var quickActions: some View {
        VStack(alignment: .leading, spacing: RadiateSpacing.md) {
            Text("Quick Actions")
                .font(RadiateTypography.title(scheme))
                .foregroundStyle(RadiateColors.textPrimary(for: scheme))
            HStack {
                Button("Open Terminal") {}
                    .buttonStyle(RadiatePrimaryButtonStyle())
                Button("Open Files") {}
                    .buttonStyle(RadiatePrimaryButtonStyle())
            }
        }
    }
}

#else
public struct DesktopEnvironmentView {}
#endif


