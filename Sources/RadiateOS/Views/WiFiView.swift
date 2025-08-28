//
//  WiFiView.swift
//  RadiateOS
//

import Foundation

#if canImport(SwiftUI)
import SwiftUI

public struct WiFiNetwork: Identifiable, Equatable {
    public let id = UUID()
    public let ssid: String
    public let strength: Int // 0..3
    public let secure: Bool
}

public struct WiFiView: View {
    @Environment(\.colorScheme) private var scheme
    @State private var isEnabled: Bool = true
    @State private var networks: [WiFiNetwork] = [
        .init(ssid: "Radiate-5G", strength: 3, secure: true),
        .init(ssid: "Guest", strength: 2, secure: false),
        .init(ssid: "Lab-2.4", strength: 1, secure: true)
    ]
    @State private var connected: WiFiNetwork? = nil
    @State private var showConnectSheet: Bool = false
    @State private var selectedForConnect: WiFiNetwork? = nil
    @State private var password: String = ""

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            header
            Divider().overlay(.white.opacity(0.06))
            content
        }
        .background(RadiateColors.background(for: scheme))
        .sheet(isPresented: $showConnectSheet) {
            connectSheet
        }
    }

    private var header: some View {
        HStack(spacing: RadiateSpacing.md) {
            Text("Wi‑Fi").font(RadiateTypography.title(scheme))
            Spacer()
            Toggle(isOn: $isEnabled) { Text("Enabled") }
                .toggleStyle(RadiateToggleStyle())
                .disabled(false)
        }
        .foregroundStyle(RadiateColors.textPrimary(for: scheme))
        .padding(12)
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: RadiateSpacing.md) {
            Text("Available Networks").radiateHeading().foregroundStyle(RadiateColors.textPrimary(for: scheme))
            ForEach(networks) { network in
                RadiateCard {
                    HStack(spacing: RadiateSpacing.md) {
                        Image(systemName: icon(for: network))
                        VStack(alignment: .leading) {
                            Text(network.ssid).radiateBody()
                            if connected == network { Text("Connected").radiateCaption().foregroundStyle(RadiateColors.success) }
                        }
                        Spacer()
                        Button(connected == network ? "Disconnect" : "Connect") {
                            if connected == network {
                                connected = nil
                            } else {
                                selectedForConnect = network
                                showConnectSheet = true
                            }
                        }
                        .buttonStyle(RadiatePrimaryButtonStyle())
                    }
                }
            }
            Spacer()
        }
        .padding(12)
        .background(RadiateColors.surface(for: scheme))
    }

    private var connectSheet: some View {
        VStack(alignment: .leading, spacing: RadiateSpacing.md) {
            HStack {
                Text("Connect to \(selectedForConnect?.ssid ?? "")").radiateHeading()
                Spacer()
            }
            if selectedForConnect?.secure == true {
                SecureField("Password", text: $password)
                    .textFieldStyle(RadiateTextFieldStyle())
            }
            HStack {
                Spacer()
                Button("Cancel") { showConnectSheet = false; password = "" }
                Button("Join") {
                    if let net = selectedForConnect { connected = net }
                    showConnectSheet = false
                }
                .buttonStyle(RadiatePrimaryButtonStyle())
            }
        }
        .padding(20)
        .presentationDetents([.medium])
    }

    private func icon(for network: WiFiNetwork) -> String {
        let base = network.secure ? "lock.wifi" : "wifi"
        switch network.strength {
        case 0: return base
        case 1: return base + ".exclamationmark"
        case 2: return base + ".trianglebadge.exclamationmark"
        default: return base
        }
    }
}

#else
public struct WiFiView {}
#endif

