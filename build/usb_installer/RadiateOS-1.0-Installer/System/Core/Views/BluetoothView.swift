//
//  BluetoothView.swift
//  RadiateOS
//

import Foundation

#if canImport(SwiftUI)
import SwiftUI

public struct BTDevice: Identifiable, Equatable {
    public let id = UUID()
    public let name: String
    public var isPaired: Bool
    public var isConnected: Bool
}

public struct BluetoothView: View {
    @Environment(\.colorScheme) private var scheme
    @State private var isEnabled: Bool = true
    @State private var devices: [BTDevice] = [
        .init(name: "AirPods Pro", isPaired: true, isConnected: true),
        .init(name: "MX Master 3S", isPaired: true, isConnected: false),
        .init(name: "Keyboard K2", isPaired: false, isConnected: false)
    ]

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
            Text("Bluetooth").font(RadiateTypography.title(scheme))
            Spacer()
            Toggle(isOn: $isEnabled) { Text("Enabled") }
                .toggleStyle(RadiateToggleStyle())
        }
        .foregroundStyle(RadiateColors.textPrimary(for: scheme))
        .padding(12)
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: RadiateSpacing.md) {
            Text("Devices").radiateHeading().foregroundStyle(RadiateColors.textPrimary(for: scheme))
            ForEach($devices) { $device in
                RadiateCard {
                    HStack {
                        Image(systemName: deviceIcon(device))
                        VStack(alignment: .leading) {
                            Text(device.name).radiateBody()
                            if device.isConnected { Text("Connected").radiateCaption().foregroundStyle(RadiateColors.success) }
                        }
                        Spacer()
                        if device.isPaired {
                            Button(device.isConnected ? "Disconnect" : "Connect") { device.isConnected.toggle() }
                                .buttonStyle(RadiatePrimaryButtonStyle())
                        } else {
                            Button("Pair") { device.isPaired = true }
                                .buttonStyle(RadiatePrimaryButtonStyle())
                        }
                    }
                }
            }
            Spacer()
        }
        .padding(12)
        .background(RadiateColors.surface(for: scheme))
    }

    private func deviceIcon(_ device: BTDevice) -> String {
        if device.name.lowercased().contains("airpods") { return "earpods" }
        if device.name.lowercased().contains("mouse") || device.name.lowercased().contains("master") { return "computermouse" }
        if device.name.lowercased().contains("keyboard") { return "keyboard" }
        return "bolt.horizontal.circle"
    }
}

#else
public struct BluetoothView {}
#endif


