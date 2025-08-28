import SwiftUI
import Combine

struct DesktopEnvironment: View {
    @EnvironmentObject var kernel: Kernel
    @EnvironmentObject var osManager: OSManager
    @StateObject private var windowManager = WindowManager()
    @State private var showLaunchpad = false
    @State private var showNotificationCenter = false
    @State private var showSpotlight = false
    @State private var currentTime = Date()
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            // Desktop wallpaper
            DesktopWallpaper()
            
            // Desktop icons
            DesktopIcons()
            
            // Windows
            ForEach(windowManager.windows) { window in
                DraggableWindow(window: window, windowManager: windowManager)
            }
            
            // Dock
            VStack {
                Spacer()
                DockView(windowManager: windowManager, showLaunchpad: $showLaunchpad)
            }
            
            // Menu bar
            VStack {
                MenuBar(
                    showNotificationCenter: $showNotificationCenter,
                    showSpotlight: $showSpotlight,
                    currentTime: currentTime
                )
                .environmentObject(kernel)
                Spacer()
            }
            
            // Overlays
            if showLaunchpad {
                LaunchpadView(showLaunchpad: $showLaunchpad, windowManager: windowManager)
            }
            
            if showNotificationCenter {
                NotificationCenterView(show: $showNotificationCenter)
            }
            
            if showSpotlight {
                SpotlightView(show: $showSpotlight, windowManager: windowManager)
            }
        }
        .onReceive(timer) { _ in
            currentTime = Date()
        }
    }
}

// MARK: - Desktop Wallpaper
struct DesktopWallpaper: View {
    @State private var animationPhase: CGFloat = 0
    
    var body: some View {
        ZStack {
            // Animated gradient background
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: Color(red: 0.05, green: 0.05, blue: 0.15), location: 0),
                    .init(color: Color(red: 0.15, green: 0.05, blue: 0.25), location: 0.5),
                    .init(color: Color(red: 0.05, green: 0.1, blue: 0.2), location: 1)
                ]),
                startPoint: UnitPoint(x: 0.5 + cos(animationPhase) * 0.3, y: 0),
                endPoint: UnitPoint(x: 0.5 + sin(animationPhase) * 0.3, y: 1)
            )
            
            // Optical wave effect
            GeometryReader { geometry in
                ForEach(0..<5) { index in
                    OpticalWave(
                        amplitude: 50,
                        frequency: Double(index + 1) * 0.5,
                        phase: animationPhase + Double(index) * 0.5,
                        opacity: 0.1 - Double(index) * 0.02
                    )
                }
            }
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                animationPhase = .pi * 2
            }
        }
    }
}

struct OpticalWave: View {
    let amplitude: Double
    let frequency: Double
    let phase: Double
    let opacity: Double
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let width = geometry.size.width
                let height = geometry.size.height
                let midY = height / 2
                
                path.move(to: CGPoint(x: 0, y: midY))
                
                for x in stride(from: 0, to: width, by: 2) {
                    let relativeX = x / width
                    let y = midY + amplitude * sin(frequency * relativeX * .pi * 2 + phase)
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }
            .stroke(
                LinearGradient(
                    colors: [.cyan.opacity(opacity), .purple.opacity(opacity)],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                lineWidth: 2
            )
        }
    }
}

// MARK: - Menu Bar
struct MenuBar: View {
    @EnvironmentObject var kernel: Kernel
    @Binding var showNotificationCenter: Bool
    @Binding var showSpotlight: Bool
    let currentTime: Date
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "E MMM d  h:mm a"
        return formatter
    }
    
    var body: some View {
        HStack {
            // Apple menu
            Image(systemName: "applelogo")
                .font(.system(size: 14))
                .padding(.horizontal, 10)
            
            Text("RadiateOS")
                .font(.system(size: 13, weight: .semibold))
            
            Spacer()
            
            // Status items
            HStack(spacing: 15) {
                // Optical CPU indicator
                if kernel.opticalComputingEnabled {
                    Image(systemName: "cpu")
                        .foregroundColor(.cyan)
                        .help("Optical Computing Active")
                }
                
                // CPU usage
                Text("\(Int(kernel.cpuUsage))%")
                    .font(.system(size: 12, design: .monospaced))
                
                // Memory usage
                Image(systemName: "memorychip")
                Text("\(Int(kernel.memoryUsage))%")
                    .font(.system(size: 12, design: .monospaced))
                
                // Network
                Image(systemName: "wifi")
                
                // Battery
                Image(systemName: "battery.100")
                
                // Spotlight
                Button(action: { showSpotlight.toggle() }) {
                    Image(systemName: "magnifyingglass")
                }
                .buttonStyle(.plain)
                
                // Notification Center
                Button(action: { showNotificationCenter.toggle() }) {
                    Image(systemName: "list.bullet.rectangle")
                }
                .buttonStyle(.plain)
                
                // Time
                Text(timeFormatter.string(from: currentTime))
                    .font(.system(size: 12))
            }
            .padding(.horizontal, 10)
        }
        .frame(height: 24)
        .background(.ultraThinMaterial)
        .foregroundColor(.white)
    }
}

// MARK: - Dock
struct DockView: View {
    let windowManager: WindowManager
    @Binding var showLaunchpad: Bool
    @State private var hoveredApp: String?
    
    let apps = [
        ("finder", "Finder", "folder"),
        ("terminal", "Terminal", "terminal"),
        ("files", "Files", "doc.text"),
        ("browser", "Browser", "globe"),
        ("settings", "Settings", "gearshape"),
        ("monitor", "System Monitor", "chart.line.uptrend.xyaxis"),
        ("notes", "Notes", "note.text"),
        ("calculator", "Calculator", "plusminus.circle")
    ]
    
    var body: some View {
        HStack(spacing: 5) {
            ForEach(apps, id: \.0) { app in
                DockIcon(
                    icon: app.2,
                    title: app.1,
                    isHovered: hoveredApp == app.0,
                    action: {
                        windowManager.openWindow(app.0, title: app.1)
                    }
                )
                .onHover { hovering in
                    hoveredApp = hovering ? app.0 : nil
                }
            }
            
            Divider()
                .frame(height: 40)
            
            // Launchpad
            DockIcon(
                icon: "square.grid.3x3",
                title: "Launchpad",
                isHovered: hoveredApp == "launchpad",
                action: { showLaunchpad.toggle() }
            )
            .onHover { hovering in
                hoveredApp = hovering ? "launchpad" : nil
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(.ultraThinMaterial)
        .cornerRadius(15)
        .shadow(radius: 10)
        .padding(.bottom, 10)
    }
}

struct DockIcon: View {
    let icon: String
    let title: String
    let isHovered: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: isHovered ? 35 : 30))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, .white.opacity(0.8)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: .cyan.opacity(0.3), radius: isHovered ? 5 : 0)
                    .scaleEffect(isHovered ? 1.2 : 1.0)
                    .offset(y: isHovered ? -5 : 0)
                
                if isHovered {
                    Text(title)
                        .font(.caption2)
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.black.opacity(0.7))
                        .cornerRadius(4)
                        .offset(y: -5)
                }
            }
            .frame(width: 50, height: 50)
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
    }
}

// MARK: - Desktop Icons
struct DesktopIcons: View {
    let icons = [
        ("Macintosh HD", "internaldrive"),
        ("Network", "network"),
        ("Trash", "trash")
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            ForEach(icons, id: \.0) { icon in
                DesktopIcon(name: icon.0, systemImage: icon.1)
            }
            Spacer()
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct DesktopIcon: View {
    let name: String
    let systemImage: String
    @State private var isSelected = false
    
    var body: some View {
        VStack(spacing: 5) {
            Image(systemName: systemImage)
                .font(.system(size: 40))
                .foregroundColor(.white.opacity(0.9))
            
            Text(name)
                .font(.caption)
                .foregroundColor(.white)
                .padding(.horizontal, 4)
                .background(isSelected ? Color.blue.opacity(0.5) : Color.clear)
                .cornerRadius(3)
        }
        .frame(width: 80)
        .onTapGesture {
            isSelected.toggle()
        }
    }
}