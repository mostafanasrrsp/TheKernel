import SwiftUI

struct ControlCenterView: View {
    @ObservedObject var osManager: OSManager
    @Binding var isShowing: Bool
    @State private var expandedSection: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Spacer()
                
                VStack(spacing: RadiateDesign.Spacing.md) {
                    // Network Controls
                    NetworkControlsSection(
                        osManager: osManager,
                        isExpanded: expandedSection == "network"
                    ) {
                        withAnimation(RadiateDesign.Animations.spring) {
                            expandedSection = expandedSection == "network" ? nil : "network"
                        }
                    }
                    
                    // Display & Sound Controls
                    HStack(spacing: RadiateDesign.Spacing.md) {
                        DisplayControlTile(osManager: osManager)
                        SoundControlTile(osManager: osManager)
                    }
                    
                    // Quick Actions
                    QuickActionsGrid(osManager: osManager)
                    
                    // Media Controls
                    MediaControlsSection(osManager: osManager)
                }
                .frame(width: 380)
                .padding(RadiateDesign.Spacing.lg)
                .background(
                    RoundedRectangle(cornerRadius: RadiateDesign.CornerRadius.xl)
                        .fill(RadiateDesign.Colors.surface)
                        .glassMorphism()
                )
                .padding(.top, 40)
                .padding(.trailing, RadiateDesign.Spacing.md)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(RadiateDesign.Animations.spring) {
                        isShowing = false
                    }
                }
        )
    }
}

// MARK: - Network Controls Section
struct NetworkControlsSection: View {
    @ObservedObject var osManager: OSManager
    let isExpanded: Bool
    let toggleExpansion: () -> Void
    
    var body: some View {
        VStack(spacing: RadiateDesign.Spacing.sm) {
            // Wi-Fi and Bluetooth Row
            HStack(spacing: RadiateDesign.Spacing.sm) {
                // Wi-Fi Control
                ControlTile(
                    icon: osManager.networkManager.isWiFiConnected ? "wifi" : "wifi.slash",
                    title: "Wi-Fi",
                    subtitle: osManager.networkManager.currentNetwork ?? "Not Connected",
                    isActive: osManager.networkManager.isWiFiConnected,
                    gradient: RadiateDesign.Colors.azure,
                    action: {
                        osManager.networkManager.toggleWiFi()
                    },
                    longPressAction: toggleExpansion
                )
                
                // Bluetooth Control
                ControlTile(
                    icon: osManager.bluetoothManager.isEnabled ? "bluetoothicon" : "bluetooth.slash",
                    title: "Bluetooth",
                    subtitle: osManager.bluetoothManager.connectedDevices.first ?? "Off",
                    isActive: osManager.bluetoothManager.isEnabled,
                    gradient: RadiateDesign.Colors.indigo,
                    action: {
                        osManager.bluetoothManager.toggle()
                    },
                    longPressAction: toggleExpansion
                )
            }
            
            // AirDrop and Hotspot Row
            HStack(spacing: RadiateDesign.Spacing.sm) {
                // AirDrop Control
                ControlTile(
                    icon: "airplayaudio",
                    title: "AirDrop",
                    subtitle: osManager.airdropStatus,
                    isActive: osManager.isAirDropEnabled,
                    gradient: RadiateDesign.Colors.emerald,
                    action: {
                        osManager.toggleAirDrop()
                    }
                )
                
                // Personal Hotspot Control
                ControlTile(
                    icon: "personalhotspot",
                    title: "Hotspot",
                    subtitle: osManager.hotspotManager.isEnabled ? "\(osManager.hotspotManager.connectedDevices) devices" : "Off",
                    isActive: osManager.hotspotManager.isEnabled,
                    gradient: RadiateDesign.Colors.amber,
                    action: {
                        osManager.hotspotManager.toggle()
                    }
                )
            }
            
            // Expanded Network List
            if isExpanded {
                VStack(alignment: .leading, spacing: RadiateDesign.Spacing.xs) {
                    Text("Available Networks")
                        .font(RadiateDesign.Typography.caption1)
                        .foregroundColor(RadiateDesign.Colors.textSecondary)
                        .padding(.top, RadiateDesign.Spacing.sm)
                    
                    ForEach(osManager.networkManager.availableNetworks, id: \.self) { network in
                        NetworkListItem(
                            network: network,
                            isConnected: network == osManager.networkManager.currentNetwork,
                            signalStrength: Int.random(in: 2...4),
                            isSecured: Bool.random()
                        ) {
                            osManager.networkManager.connect(to: network)
                        }
                    }
                }
                .padding(RadiateDesign.Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: RadiateDesign.CornerRadius.md)
                        .fill(RadiateDesign.Colors.glassDark)
                )
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.9).combined(with: .opacity),
                    removal: .scale(scale: 0.9).combined(with: .opacity)
                ))
            }
        }
    }
}

// MARK: - Control Tile
struct ControlTile: View {
    let icon: String
    let title: String
    let subtitle: String
    let isActive: Bool
    let gradient: LinearGradient
    var action: () -> Void
    var longPressAction: (() -> Void)? = nil
    
    @State private var isPressed = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: RadiateDesign.Spacing.xs) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(isActive ? .white : RadiateDesign.Colors.textSecondary)
                    .frame(width: 24, height: 24)
                
                Spacer()
            }
            
            Spacer()
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(RadiateDesign.Typography.footnote)
                    .foregroundColor(isActive ? .white : RadiateDesign.Colors.text)
                
                Text(subtitle)
                    .font(RadiateDesign.Typography.caption2)
                    .foregroundColor(isActive ? .white.opacity(0.7) : RadiateDesign.Colors.textTertiary)
                    .lineLimit(1)
            }
        }
        .padding(RadiateDesign.Spacing.sm)
        .frame(maxWidth: .infinity)
        .frame(height: 80)
        .background(
            Group {
                if isActive {
                    gradient
                        .opacity(isPressed ? 0.8 : 1.0)
                } else {
                    RadiateDesign.Colors.surfaceLight
                        .opacity(isPressed ? 0.6 : 1.0)
                }
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: RadiateDesign.CornerRadius.md))
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .onTapGesture {
            action()
        }
        .onLongPressGesture(minimumDuration: 0.5) {
            longPressAction?()
        } onPressingChanged: { pressing in
            withAnimation(RadiateDesign.Animations.fast) {
                isPressed = pressing
            }
        }
    }
}

// MARK: - Network List Item
struct NetworkListItem: View {
    let network: String
    let isConnected: Bool
    let signalStrength: Int
    let isSecured: Bool
    let action: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: wifiIcon)
                .font(.system(size: 14))
                .foregroundColor(isConnected ? RadiateDesign.Colors.accentPrimary : RadiateDesign.Colors.textSecondary)
            
            Text(network)
                .font(RadiateDesign.Typography.callout)
                .foregroundColor(RadiateDesign.Colors.text)
            
            Spacer()
            
            if isSecured {
                Image(systemName: "lock.fill")
                    .font(.system(size: 10))
                    .foregroundColor(RadiateDesign.Colors.textTertiary)
            }
            
            if isConnected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(RadiateDesign.Colors.success)
            }
        }
        .padding(.horizontal, RadiateDesign.Spacing.sm)
        .padding(.vertical, RadiateDesign.Spacing.xs)
        .contentShape(Rectangle())
        .onTapGesture {
            action()
        }
    }
    
    var wifiIcon: String {
        switch signalStrength {
        case 4: return "wifi"
        case 3: return "wifi.medium"
        case 2: return "wifi.weak"
        default: return "wifi.slash"
        }
    }
}

// MARK: - Display Control Tile
struct DisplayControlTile: View {
    @ObservedObject var osManager: OSManager
    @State private var brightness: Double = 0.7
    @State private var nightShift = false
    @State private var trueTone = true
    
    var body: some View {
        VStack(spacing: RadiateDesign.Spacing.sm) {
            HStack {
                Image(systemName: "sun.max.fill")
                    .font(.system(size: 20))
                    .foregroundColor(RadiateDesign.Colors.amber.gradient.stops.first?.color)
                
                Slider(value: $brightness, in: 0...1)
                    .accentColor(RadiateDesign.Colors.amber.gradient.stops.first?.color)
            }
            
            HStack(spacing: RadiateDesign.Spacing.sm) {
                SmallToggle(
                    icon: "moon.fill",
                    isOn: $nightShift,
                    color: Color.orange
                )
                
                SmallToggle(
                    icon: "display",
                    isOn: $trueTone,
                    color: Color.blue
                )
            }
        }
        .padding(RadiateDesign.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: RadiateDesign.CornerRadius.md)
                .fill(RadiateDesign.Colors.surfaceLight)
        )
    }
}

// MARK: - Sound Control Tile
struct SoundControlTile: View {
    @ObservedObject var osManager: OSManager
    @State private var volume: Double = 0.5
    @State private var isMuted = false
    
    var body: some View {
        VStack(spacing: RadiateDesign.Spacing.sm) {
            HStack {
                Image(systemName: volumeIcon)
                    .font(.system(size: 20))
                    .foregroundColor(RadiateDesign.Colors.text)
                    .onTapGesture {
                        isMuted.toggle()
                    }
                
                Slider(value: $volume, in: 0...1)
                    .accentColor(RadiateDesign.Colors.text)
                    .disabled(isMuted)
            }
            
            // Output Device
            HStack {
                Image(systemName: "airpodspro")
                    .font(.system(size: 14))
                    .foregroundColor(RadiateDesign.Colors.textSecondary)
                
                Text("AirPods Pro")
                    .font(RadiateDesign.Typography.caption1)
                    .foregroundColor(RadiateDesign.Colors.textSecondary)
                
                Spacer()
            }
        }
        .padding(RadiateDesign.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: RadiateDesign.CornerRadius.md)
                .fill(RadiateDesign.Colors.surfaceLight)
        )
    }
    
    var volumeIcon: String {
        if isMuted {
            return "speaker.slash.fill"
        } else if volume < 0.33 {
            return "speaker.fill"
        } else if volume < 0.66 {
            return "speaker.wave.2.fill"
        } else {
            return "speaker.wave.3.fill"
        }
    }
}

// MARK: - Small Toggle
struct SmallToggle: View {
    let icon: String
    @Binding var isOn: Bool
    let color: Color
    
    var body: some View {
        Button(action: { isOn.toggle() }) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(isOn ? .white : RadiateDesign.Colors.textSecondary)
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(isOn ? color : RadiateDesign.Colors.glassDark)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Quick Actions Grid
struct QuickActionsGrid: View {
    @ObservedObject var osManager: OSManager
    
    let actions = [
        QuickAction(icon: "lock.fill", title: "Lock", color: RadiateDesign.Colors.crimson),
        QuickAction(icon: "moon.fill", title: "Sleep", color: RadiateDesign.Colors.indigo),
        QuickAction(icon: "rectangle.portrait.and.arrow.right", title: "Log Out", color: RadiateDesign.Colors.amber),
        QuickAction(icon: "restart", title: "Restart", color: RadiateDesign.Colors.emerald),
    ]
    
    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: RadiateDesign.Spacing.sm) {
            ForEach(actions) { action in
                QuickActionButton(action: action) {
                    // Handle action
                }
            }
        }
    }
}

struct QuickAction: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let color: LinearGradient
}

struct QuickActionButton: View {
    let action: QuickAction
    let onTap: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        VStack(spacing: RadiateDesign.Spacing.xs) {
            Image(systemName: action.icon)
                .font(.system(size: 24))
                .foregroundColor(.white)
            
            Text(action.title)
                .font(RadiateDesign.Typography.caption1)
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 60)
        .background(action.color)
        .clipShape(RoundedRectangle(cornerRadius: RadiateDesign.CornerRadius.md))
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .onTapGesture {
            onTap()
        }
        .onLongPressGesture(minimumDuration: 0) {
        } onPressingChanged: { pressing in
            withAnimation(RadiateDesign.Animations.fast) {
                isPressed = pressing
            }
        }
    }
}

// MARK: - Media Controls Section
struct MediaControlsSection: View {
    @ObservedObject var osManager: OSManager
    @State private var isPlaying = false
    @State private var progress: Double = 0.3
    
    var body: some View {
        VStack(spacing: RadiateDesign.Spacing.sm) {
            // Now Playing
            HStack(spacing: RadiateDesign.Spacing.md) {
                RoundedRectangle(cornerRadius: RadiateDesign.CornerRadius.sm)
                    .fill(RadiateDesign.Colors.ultraviolet)
                    .frame(width: 48, height: 48)
                    .overlay(
                        Image(systemName: "music.note")
                            .foregroundColor(.white)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Cosmic Journey")
                        .font(RadiateDesign.Typography.callout)
                        .foregroundColor(RadiateDesign.Colors.text)
                    
                    Text("Radiate Artist")
                        .font(RadiateDesign.Typography.caption1)
                        .foregroundColor(RadiateDesign.Colors.textSecondary)
                }
                
                Spacer()
            }
            
            // Progress Bar
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle())
                .accentColor(RadiateDesign.Colors.accentPrimary)
            
            // Media Controls
            HStack(spacing: RadiateDesign.Spacing.lg) {
                Button(action: {}) {
                    Image(systemName: "backward.fill")
                        .font(.system(size: 20))
                        .foregroundColor(RadiateDesign.Colors.text)
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: { isPlaying.toggle() }) {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 24))
                        .foregroundColor(RadiateDesign.Colors.text)
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: {}) {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 20))
                        .foregroundColor(RadiateDesign.Colors.text)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(RadiateDesign.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: RadiateDesign.CornerRadius.md)
                .fill(RadiateDesign.Colors.surfaceLight)
        )
    }
}
