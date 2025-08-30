//
//  ContentView.swift
//  RadiateOS
//

import Foundation

#if canImport(SwiftUI)
import SwiftUI

public struct ContentView: View {
    @StateObject private var appState = AppState()
    @Environment(\.colorScheme) private var scheme

    public init() {}

    public var body: some View {
        NavigationStack {
            HStack(spacing: 0) {
                sidebar
                Divider().overlay(.white.opacity(0.06))
                mainArea
            }
            .background(RadiateColors.background(for: scheme))
            .toolbarBackground(.hidden, for: .navigationBar)
            .navigationTitle(titleForModule(appState.activeModule))
        }
    }

    private var sidebar: some View {
        VStack(spacing: 0) {
            header
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(SystemModule.allCases, id: \.self) { module in
                        Button {
                            withAnimation(RadiateAnimation.smooth) { appState.activeModule = module }
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: iconForModule(module))
                                Text(titleForModule(module))
                                Spacer()
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .foregroundStyle(module == appState.activeModule ? .white : RadiateColors.textSecondary(for: scheme))
                            .background(module == appState.activeModule ? RadiateColors.brand.opacity(0.15) : .clear)
                            .clipShape(RoundedRectangle(cornerRadius: RadiateRadius.md, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(12)
            }
            Divider().overlay(.white.opacity(0.06))
            footer
        }
        .frame(width: 240)
        .background(RadiateColors.surface(for: scheme))
    }

    private var header: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(RadiateColors.spectrumGradient)
                .frame(width: 28, height: 28)
            Text("RadiateOS")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
            Spacer()
        }
        .padding(12)
    }

    private var footer: some View {
        HStack(spacing: 8) {
            Image(systemName: "gearshape.fill")
            Text("Settings")
            Spacer()
        }
        .foregroundStyle(RadiateColors.textSecondary(for: scheme))
        .padding(12)
    }

    private var mainArea: some View {
        ZStack {
            switch appState.activeModule {
            case .desktop: DesktopEnvironmentView()
            case .terminal: TerminalView()
            case .files: FileManagerView()
            case .wifi: WiFiView()
            case .bluetooth: BluetoothView()
            case .hotspot: HotspotView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(colors: [RadiateColors.background(for: scheme), RadiateColors.surface(for: scheme)], startPoint: .topLeading, endPoint: .bottomTrailing)
                .opacity(0.6)
        )
    }

    private func iconForModule(_ module: SystemModule) -> String {
        switch module {
        case .desktop: return "macwindow.on.rectangle"
        case .terminal: return "terminal.fill"
        case .files: return "folder.fill"
        case .wifi: return "wifi"
        case .bluetooth: return "bolt.horizontal.fill" // stylized
        case .hotspot: return "personalhotspot"
        }
    }

    private func titleForModule(_ module: SystemModule) -> String {
        switch module {
        case .desktop: return "Desktop"
        case .terminal: return "Terminal"
        case .files: return "Files"
        case .wifi: return "Wi‑Fi"
        case .bluetooth: return "Bluetooth"
        case .hotspot: return "Hotspot"
        }
    }
}

#else
public struct ContentView {}
#endif


