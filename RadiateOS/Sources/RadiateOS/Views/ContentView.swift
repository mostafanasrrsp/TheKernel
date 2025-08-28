import SwiftUI

public struct ContentView: View {
    @StateObject private var osManager = OSManager()
    @State private var showControlCenter = false
    @State private var showNotificationCenter = false
    @State private var selectedApp: OSApplication?
    @State private var dockMagnification: CGFloat = 1.0
    @State private var hoveredDockItem: String?
    @State private var showLaunchpad = false
    @State private var searchText = ""
    
    public init() {}
    
    public var body: some View {
        ZStack {
            // Dynamic Gradient Background
            AnimatedGradientBackground()
            
            // Desktop Environment
            DesktopEnvironment(osManager: osManager, selectedApp: $selectedApp)
                .blur(radius: showLaunchpad ? 20 : 0)
                .scaleEffect(showLaunchpad ? 0.95 : 1.0)
            
            // Menu Bar
            VStack {
                MenuBar(
                    osManager: osManager,
                    showControlCenter: $showControlCenter,
                    showNotificationCenter: $showNotificationCenter
                )
                .frame(height: 32)
                .background(
                    VisualEffectBlur(material: .hudWindow, blendingMode: .withinWindow)
                        .overlay(RadiateDesign.Colors.glassDark)
                )
                
                Spacer()
                
                // Dock
                if !showLaunchpad {
                    DockView(
                        osManager: osManager,
                        selectedApp: $selectedApp,
                        hoveredDockItem: $hoveredDockItem,
                        showLaunchpad: $showLaunchpad
                    )
                    .padding(.bottom, 8)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            
            // Control Center
            if showControlCenter {
                ControlCenterView(osManager: osManager, isShowing: $showControlCenter)
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .move(edge: .top).combined(with: .opacity)
                    ))
                    .zIndex(100)
            }
            
            // Notification Center
            if showNotificationCenter {
                NotificationCenterView(osManager: osManager, isShowing: $showNotificationCenter)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .trailing).combined(with: .opacity)
                    ))
                    .zIndex(100)
            }
            
            // Launchpad
            if showLaunchpad {
                LaunchpadView(
                    osManager: osManager,
                    selectedApp: $selectedApp,
                    showLaunchpad: $showLaunchpad,
                    searchText: $searchText
                )
                .transition(.opacity.combined(with: .scale))
                .zIndex(200)
            }
        }
        .animation(RadiateDesign.Animations.spring, value: showControlCenter)
        .animation(RadiateDesign.Animations.spring, value: showNotificationCenter)
        .animation(RadiateDesign.Animations.spring, value: showLaunchpad)
    }
}

// MARK: - Animated Gradient Background
struct AnimatedGradientBackground: View {
    @State private var animateGradient = false
    
    var body: some View {
        LinearGradient(
            colors: [
                RadiateDesign.Colors.background,
                Color(hex: "1A1A2E"),
                Color(hex: "0F0F23"),
                RadiateDesign.Colors.surface
            ],
            startPoint: animateGradient ? .topLeading : .bottomLeading,
            endPoint: animateGradient ? .bottomTrailing : .topTrailing
        )
        .ignoresSafeArea()
        .onAppear {
            withAnimation(Animation.linear(duration: 8).repeatForever(autoreverses: true)) {
                animateGradient.toggle()
            }
        }
        .overlay(
            // Subtle noise texture
            GeometryReader { geometry in
                ForEach(0..<50) { _ in
                    Circle()
                        .fill(RadiateDesign.Colors.glassLight)
                        .frame(width: .random(in: 1...3))
                        .position(
                            x: .random(in: 0...geometry.size.width),
                            y: .random(in: 0...geometry.size.height)
                        )
                        .opacity(.random(in: 0.1...0.3))
                }
            }
        )
    }
}

// MARK: - Menu Bar
struct MenuBar: View {
    @ObservedObject var osManager: OSManager
    @Binding var showControlCenter: Bool
    @Binding var showNotificationCenter: Bool
    @State private var currentTime = Date()
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        HStack(spacing: RadiateDesign.Spacing.md) {
            // Apple Logo
            Image(systemName: "applelogo")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(RadiateDesign.Colors.text)
                .padding(.horizontal, RadiateDesign.Spacing.md)
            
            // App Name
            if let activeApp = osManager.activeApplication {
                Text(activeApp.name)
                    .font(RadiateDesign.Typography.headline)
                    .foregroundColor(RadiateDesign.Colors.text)
            } else {
                Text("RadiateOS")
                    .font(RadiateDesign.Typography.headline)
                    .foregroundColor(RadiateDesign.Colors.text)
            }
            
            Spacer()
            
            // System Status Icons
            HStack(spacing: RadiateDesign.Spacing.sm) {
                // Wi-Fi Status
                Button(action: { showControlCenter.toggle() }) {
                    Image(systemName: osManager.networkManager.isWiFiConnected ? "wifi" : "wifi.slash")
                        .font(.system(size: 14))
                        .foregroundColor(RadiateDesign.Colors.text)
                }
                .buttonStyle(PlainButtonStyle())
                
                // Bluetooth Status
                Image(systemName: osManager.bluetoothManager.isEnabled ? "bluetoothicon" : "bluetooth.slash")
                    .font(.system(size: 14))
                    .foregroundColor(RadiateDesign.Colors.text)
                
                // Battery Status
                BatteryIndicator(level: osManager.batteryLevel, isCharging: osManager.isCharging)
                
                // Control Center Toggle
                Button(action: { showControlCenter.toggle() }) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 14))
                        .foregroundColor(RadiateDesign.Colors.text)
                }
                .buttonStyle(PlainButtonStyle())
                
                // Notification Center Toggle
                Button(action: { showNotificationCenter.toggle() }) {
                    ZStack {
                        Image(systemName: "bell.fill")
                            .font(.system(size: 14))
                            .foregroundColor(RadiateDesign.Colors.text)
                        
                        if osManager.unreadNotifications > 0 {
                            Circle()
                                .fill(RadiateDesign.Colors.error)
                                .frame(width: 8, height: 8)
                                .offset(x: 6, y: -6)
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                // Date and Time
                Text(currentTime, style: .time)
                    .font(RadiateDesign.Typography.callout)
                    .foregroundColor(RadiateDesign.Colors.text)
                    .onReceive(timer) { _ in
                        currentTime = Date()
                    }
            }
            .padding(.horizontal, RadiateDesign.Spacing.md)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Battery Indicator
struct BatteryIndicator: View {
    let level: Double
    let isCharging: Bool
    
    var batteryColor: Color {
        if isCharging {
            return RadiateDesign.Colors.success
        } else if level < 0.2 {
            return RadiateDesign.Colors.error
        } else if level < 0.5 {
            return RadiateDesign.Colors.warning
        } else {
            return RadiateDesign.Colors.text
        }
    }
    
    var body: some View {
        HStack(spacing: 2) {
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .stroke(batteryColor, lineWidth: 1)
                    .frame(width: 22, height: 10)
                
                RoundedRectangle(cornerRadius: 1)
                    .fill(batteryColor)
                    .frame(width: 20 * level, height: 8)
                    .padding(.horizontal, 1)
            }
            
            RoundedRectangle(cornerRadius: 1)
                .fill(batteryColor)
                .frame(width: 2, height: 4)
            
            if isCharging {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 10))
                    .foregroundColor(batteryColor)
            }
        }
    }
}

// MARK: - Visual Effect Blur
struct VisualEffectBlur: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}

// MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .frame(width: 1440, height: 900)
    }
}