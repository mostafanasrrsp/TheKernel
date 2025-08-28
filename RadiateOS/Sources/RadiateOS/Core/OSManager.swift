import SwiftUI
import Combine

// MARK: - OS Manager
public class OSManager: ObservableObject {
    @Published var applications: [OSApplication] = []
    @Published var runningApplications: [OSApplication] = []
    @Published var pinnedApplications: [OSApplication] = []
    @Published var activeApplication: OSApplication?
    @Published var notifications: [SystemNotification] = []
    @Published var unreadNotifications: Int = 0
    
    // System Status
    @Published var batteryLevel: Double = 0.85
    @Published var isCharging: Bool = false
    @Published var cpuUsage: Double = 0.23
    @Published var memoryUsage: Double = 0.45
    @Published var diskUsage: Double = 0.67
    
    // Network & Connectivity
    @Published var networkManager = NetworkManager()
    @Published var bluetoothManager = BluetoothManager()
    @Published var hotspotManager = HotspotManager()
    
    // System Features
    @Published var isAirDropEnabled = true
    @Published var airdropStatus = "Everyone"
    @Published var trashCount = 3
    
    init() {
        setupApplications()
        setupPinnedApps()
        simulateSystemActivity()
    }
    
    private func setupApplications() {
        applications = [
            OSApplication(
                id: "finder",
                name: "Finder",
                icon: "folder.fill",
                accentColor: RadiateDesign.Colors.azure,
                category: .productivity
            ),
            OSApplication(
                id: "safari",
                name: "Safari",
                icon: "safari.fill",
                accentColor: RadiateDesign.Colors.indigo,
                category: .productivity
            ),
            OSApplication(
                id: "messages",
                name: "Messages",
                icon: "message.fill",
                accentColor: RadiateDesign.Colors.emerald,
                category: .communication
            ),
            OSApplication(
                id: "mail",
                name: "Mail",
                icon: "envelope.fill",
                accentColor: RadiateDesign.Colors.azure,
                category: .communication
            ),
            OSApplication(
                id: "calendar",
                name: "Calendar",
                icon: "calendar",
                accentColor: RadiateDesign.Colors.crimson,
                category: .productivity
            ),
            OSApplication(
                id: "photos",
                name: "Photos",
                icon: "photo.fill",
                accentColor: RadiateDesign.Colors.amber,
                category: .media
            ),
            OSApplication(
                id: "music",
                name: "Music",
                icon: "music.note",
                accentColor: RadiateDesign.Colors.crimson,
                category: .media
            ),
            OSApplication(
                id: "terminal",
                name: "Terminal",
                icon: "terminal.fill",
                accentColor: LinearGradient(
                    colors: [Color.black, Color.gray],
                    startPoint: .top,
                    endPoint: .bottom
                ),
                category: .developer
            ),
            OSApplication(
                id: "xcode",
                name: "Xcode",
                icon: "hammer.fill",
                accentColor: RadiateDesign.Colors.indigo,
                category: .developer
            ),
            OSApplication(
                id: "settings",
                name: "System Settings",
                icon: "gear",
                accentColor: RadiateDesign.Colors.ultraviolet,
                category: .system
            ),
            OSApplication(
                id: "activity",
                name: "Activity Monitor",
                icon: "chart.line.uptrend.xyaxis",
                accentColor: RadiateDesign.Colors.emerald,
                category: .utilities
            ),
            OSApplication(
                id: "notes",
                name: "Notes",
                icon: "note.text",
                accentColor: RadiateDesign.Colors.amber,
                category: .productivity
            )
        ]
    }
    
    private func setupPinnedApps() {
        pinnedApplications = [
            applications[0], // Finder
            applications[1], // Safari
            applications[2], // Messages
            applications[4], // Calendar
            applications[7], // Terminal
        ]
        
        // Simulate some running apps
        runningApplications = [
            applications[0], // Finder always running
            applications[1], // Safari
            applications[7], // Terminal
        ]
        
        activeApplication = runningApplications.first
    }
    
    func launchApplication(_ app: OSApplication) {
        if !runningApplications.contains(where: { $0.id == app.id }) {
            withAnimation(RadiateDesign.Animations.spring) {
                runningApplications.append(app)
            }
        }
        setActiveApplication(app)
    }
    
    func quitApplication(_ app: OSApplication) {
        withAnimation(RadiateDesign.Animations.spring) {
            runningApplications.removeAll { $0.id == app.id }
            if activeApplication?.id == app.id {
                activeApplication = runningApplications.first
            }
        }
    }
    
    func setActiveApplication(_ app: OSApplication) {
        withAnimation(RadiateDesign.Animations.fast) {
            activeApplication = app
        }
    }
    
    func toggleAirDrop() {
        isAirDropEnabled.toggle()
        if !isAirDropEnabled {
            airdropStatus = "Off"
        } else {
            airdropStatus = "Everyone"
        }
    }
    
    private func simulateSystemActivity() {
        // Simulate battery drain
        Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            if !self.isCharging && self.batteryLevel > 0 {
                self.batteryLevel -= 0.001
            } else if self.isCharging && self.batteryLevel < 1.0 {
                self.batteryLevel += 0.002
            }
        }
        
        // Simulate CPU usage fluctuation
        Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { _ in
            withAnimation(RadiateDesign.Animations.slow) {
                self.cpuUsage = Double.random(in: 0.1...0.4)
                self.memoryUsage = Double.random(in: 0.3...0.6)
            }
        }
        
        // Simulate notifications
        Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { _ in
            self.addNotification(SystemNotification(
                id: UUID().uuidString,
                app: self.applications.randomElement()!,
                title: "New Update Available",
                message: "A new version is ready to install",
                timestamp: Date(),
                type: .info
            ))
        }
    }
    
    func addNotification(_ notification: SystemNotification) {
        withAnimation(RadiateDesign.Animations.spring) {
            notifications.insert(notification, at: 0)
            unreadNotifications += 1
        }
    }
    
    func markNotificationsAsRead() {
        unreadNotifications = 0
    }
}

// MARK: - OS Application Model
public struct OSApplication: Identifiable {
    public let id: String
    public let name: String
    public let icon: String
    public let accentColor: LinearGradient
    public let category: AppCategory
    
    public enum AppCategory: String, CaseIterable {
        case productivity = "Productivity"
        case communication = "Communication"
        case media = "Media"
        case developer = "Developer"
        case utilities = "Utilities"
        case system = "System"
        case games = "Games"
        case education = "Education"
    }
}

// MARK: - System Notification
public struct SystemNotification: Identifiable {
    public let id: String
    public let app: OSApplication
    public let title: String
    public let message: String
    public let timestamp: Date
    public let type: NotificationType
    
    public enum NotificationType {
        case info, warning, error, success
    }
}

// MARK: - Network Manager
public class NetworkManager: ObservableObject {
    @Published var isWiFiConnected = true
    @Published var currentNetwork: String? = "RadiateNet 5G"
    @Published var signalStrength = 4
    @Published var availableNetworks: [String] = [
        "RadiateNet 5G",
        "Guest Network",
        "Neighbor's WiFi",
        "Coffee Shop Free",
        "Airport_Free_WiFi"
    ]
    @Published var downloadSpeed: Double = 245.6 // Mbps
    @Published var uploadSpeed: Double = 125.3 // Mbps
    
    func toggleWiFi() {
        withAnimation(RadiateDesign.Animations.spring) {
            isWiFiConnected.toggle()
            if !isWiFiConnected {
                currentNetwork = nil
            } else {
                currentNetwork = availableNetworks.first
            }
        }
    }
    
    func connect(to network: String) {
        withAnimation(RadiateDesign.Animations.spring) {
            currentNetwork = network
            isWiFiConnected = true
            signalStrength = Int.random(in: 2...4)
        }
    }
    
    func disconnect() {
        withAnimation(RadiateDesign.Animations.spring) {
            currentNetwork = nil
            isWiFiConnected = false
        }
    }
}

// MARK: - Bluetooth Manager
public class BluetoothManager: ObservableObject {
    @Published var isEnabled = true
    @Published var connectedDevices: [String] = ["AirPods Pro"]
    @Published var availableDevices: [String] = [
        "Magic Mouse",
        "Magic Keyboard",
        "iPhone 15 Pro",
        "iPad Pro",
        "Apple Watch Series 9"
    ]
    @Published var isScanning = false
    
    func toggle() {
        withAnimation(RadiateDesign.Animations.spring) {
            isEnabled.toggle()
            if !isEnabled {
                connectedDevices.removeAll()
            }
        }
    }
    
    func connect(to device: String) {
        withAnimation(RadiateDesign.Animations.spring) {
            if !connectedDevices.contains(device) {
                connectedDevices.append(device)
            }
        }
    }
    
    func disconnect(device: String) {
        withAnimation(RadiateDesign.Animations.spring) {
            connectedDevices.removeAll { $0 == device }
        }
    }
    
    func startScanning() {
        isScanning = true
        // Simulate scanning
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.isScanning = false
        }
    }
}

// MARK: - Hotspot Manager
public class HotspotManager: ObservableObject {
    @Published var isEnabled = false
    @Published var networkName = "RadiateOS Hotspot"
    @Published var password = "radiate2024"
    @Published var connectedDevices = 0
    @Published var dataUsed: Double = 0 // MB
    @Published var securityType = "WPA3"
    @Published var band = "5 GHz"
    
    func toggle() {
        withAnimation(RadiateDesign.Animations.spring) {
            isEnabled.toggle()
            if !isEnabled {
                connectedDevices = 0
                dataUsed = 0
            } else {
                // Simulate device connections
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self.connectedDevices = Int.random(in: 1...3)
                }
            }
        }
    }
    
    func updateSettings(name: String, password: String) {
        networkName = name
        self.password = password
    }
    
    func changeBand() {
        band = band == "5 GHz" ? "2.4 GHz" : "5 GHz"
    }
}
