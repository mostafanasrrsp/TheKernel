//
//  HotspotView.swift
//  RadiateOS
//

import Foundation

#if canImport(SwiftUI)
import SwiftUI

public struct HotspotView: View {
    @Environment(\.colorScheme) private var scheme
    @State private var isEnabled: Bool = false
    @State private var networkName: String = "RadiateOS Hotspot"
    @State private var password: String = "radiate123"
    @State private var shareOverUSB: Bool = false
    @State private var shareOverBT: Bool = false

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            header
            Divider().overlay(.white.opacity(0.06))
            content
        }
        .background(RadiateColors.background(for: scheme))
    }

    private var header: some View {
        HStack(spacing: RadiateSpacing.md) {
            Text("Hotspot").font(RadiateTypography.title(scheme))
            Spacer()
            Toggle(isOn: $isEnabled) { Text("Enabled") }
                .toggleStyle(RadiateToggleStyle())
        }
        .foregroundStyle(RadiateColors.textPrimary(for: scheme))
        .padding(12)
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: RadiateSpacing.md) {
            RadiateCard {
                VStack(alignment: .leading, spacing: RadiateSpacing.md) {
                    Text("Configuration").radiateHeading().foregroundStyle(RadiateColors.textPrimary(for: scheme))
                    TextField("Name", text: $networkName).textFieldStyle(RadiateTextFieldStyle())
                    SecureField("Password", text: $password).textFieldStyle(RadiateTextFieldStyle())
                    HStack {
                        Toggle(isOn: $shareOverUSB) { Text("USB") }.toggleStyle(RadiateToggleStyle())
                        Toggle(isOn: $shareOverBT) { Text("Bluetooth") }.toggleStyle(RadiateToggleStyle())
                    }
                }
            }

            RadiateCard {
                HStack {
                    Text("Status: ").radiateBody()
                    Text(isEnabled ? "Sharing" : "Off").radiateBody().foregroundStyle(isEnabled ? RadiateColors.success : RadiateColors.textSecondary(for: scheme))
                    Spacer()
                    Button(isEnabled ? "Stop" : "Start") { isEnabled.toggle() }
                        .buttonStyle(RadiatePrimaryButtonStyle())
                }
            }
            Spacer()
        }
        .padding(12)
        .background(RadiateColors.surface(for: scheme))
    }
}

#else
public struct HotspotView {}
#endif

