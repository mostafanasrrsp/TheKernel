import SwiftUI
import Combine

// MARK: - Desktop Manager

public class DesktopManager: ObservableObject {
    @Published var workspaces: [Workspace] = []
    @Published var currentWorkspace: Int = 0
    @Published var windows: [Window] = []
    
    init() {
        setupWorkspaces()
    }
    
    private func setupWorkspaces() {
        // Create 4 default workspaces
        for i in 1...4 {
            workspaces.append(Workspace(id: i, name: "Workspace \(i)"))
        }
    }
    
    func switchToWorkspace(_ index: Int) {
        guard index >= 0 && index < workspaces.count else { return }
        currentWorkspace = index
    }
    
    func addWindow(_ window: Window) {
        windows.append(window)
        workspaces[currentWorkspace].windowIDs.append(window.id)
    }
    
    func removeWindow(_ windowID: UUID) {
        windows.removeAll { $0.id == windowID }
        for i in workspaces.indices {
            workspaces[i].windowIDs.removeAll { $0 == windowID }
        }
    }
}

// MARK: - Theme Manager

public class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    @Published var currentTheme: Theme = .default
    @Published var accentColor: Color = .blue
    @Published var autoSwitchTheme = false
    
    private init() {
        loadThemePreferences()
    }
    
    func switchTheme(_ theme: Theme) {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentTheme = theme
        }
        saveThemePreferences()
    }
    
    func toggleTheme() {
        switchTheme(currentTheme == .default ? .dark : .default)
    }
    
    private func loadThemePreferences() {
        // Load from UserDefaults
    }
    
    private func saveThemePreferences() {
        // Save to UserDefaults
    }
}

// MARK: - Dock Manager

public class DockManager: ObservableObject {
    @Published var pinnedApps: [DockApp] = []
    @Published var runningApps: [DockApp] = []
    @Published var dockPosition: DockPosition = .bottom
    @Published var autoHide = false
    @Published var iconSize: CGFloat = 48
    
    init() {
        loadDefaultApps()
    }
    
    private func loadDefaultApps() {
        pinnedApps = [
            DockApp(name: "Files", icon: "folder.fill", accentColor: .orange),
            DockApp(name: "Terminal", icon: "terminal.fill", accentColor: .green),
            DockApp(name: "Browser", icon: "globe", accentColor: .blue),
            DockApp(name: "Settings", icon: "gear", accentColor: .gray),
        ]
    }
    
    func launchApp(_ app: DockApp) {
        var runningApp = app
        runningApp.isRunning = true
        
        if !runningApps.contains(where: { $0.id == app.id }) {
            runningApps.append(runningApp)
        }
    }
    
    func focusApp(_ app: DockApp) {
        // Bring app to foreground
    }
    
    func pinApp(_ app: DockApp) {
        if !pinnedApps.contains(where: { $0.id == app.id }) {
            pinnedApps.append(app)
        }
    }
    
    func unpinApp(_ app: DockApp) {
        pinnedApps.removeAll { $0.id == app.id }
    }
}

// MARK: - Application Manager

public class ApplicationManager: ObservableObject {
    @Published var applications: [Application] = []
    @Published var categories = ["All", "Development", "System", "Graphics", "Internet", "Office", "Games"]
    @Published var recentApps: [Application] = []
    @Published var favoriteApps: [Application] = []
    
    init() {
        loadApplications()
    }
    
    private func loadApplications() {
        applications = [
            Application(name: "Files", icon: "folder.fill", category: "System", accentColor: .orange),
            Application(name: "Terminal", icon: "terminal.fill", category: "Development", accentColor: .green),
            Application(name: "Text Editor", icon: "doc.text.fill", category: "Development", accentColor: .blue),
            Application(name: "Browser", icon: "globe", category: "Internet", accentColor: .blue),
            Application(name: "Settings", icon: "gear", category: "System", accentColor: .gray),
            Application(name: "System Monitor", icon: "chart.line.uptrend.xyaxis", category: "System", accentColor: .purple),
            Application(name: "Calculator", icon: "plus.forwardslash.minus", category: "Office", accentColor: .orange),
            Application(name: "Calendar", icon: "calendar", category: "Office", accentColor: .red),
            Application(name: "Music", icon: "music.note", category: "Graphics", accentColor: .pink),
            Application(name: "Photos", icon: "photo.fill", category: "Graphics", accentColor: .yellow),
        ]
    }
    
    func launch(_ app: Application) {
        // Launch application
        addToRecent(app)
    }
    
    private func addToRecent(_ app: Application) {
        recentApps.removeAll { $0.id == app.id }
        recentApps.insert(app, at: 0)
        if recentApps.count > 10 {
            recentApps.removeLast()
        }
    }
    
    func toggleFavorite(_ app: Application) {
        if favoriteApps.contains(where: { $0.id == app.id }) {
            favoriteApps.removeAll { $0.id == app.id }
        } else {
            favoriteApps.append(app)
        }
    }
}

// MARK: - Notification Manager

public class NotificationManager: ObservableObject {
    @Published var notifications: [SystemNotification] = []
    @Published var doNotDisturb = false
    
    init() {
        loadSampleNotifications()
    }
    
    private func loadSampleNotifications() {
        notifications = [
            SystemNotification(
                title: "Security Update Available",
                message: "A new security update is ready to install",
                icon: "shield.fill",
                type: .security,
                timestamp: Date().addingTimeInterval(-300)
            ),
            SystemNotification(
                title: "Backup Complete",
                message: "Your system has been successfully backed up",
                icon: "checkmark.circle.fill",
                type: .success,
                timestamp: Date().addingTimeInterval(-1800)
            ),
            SystemNotification(
                title: "Low Disk Space",
                message: "You have less than 10GB of free space",
                icon: "exclamationmark.triangle.fill",
                type: .warning,
                timestamp: Date().addingTimeInterval(-3600)
            ),
        ]
    }
    
    func addNotification(_ notification: SystemNotification) {
        guard !doNotDisturb else { return }
        notifications.insert(notification, at: 0)
    }
    
    func dismiss(_ notification: SystemNotification) {
        notifications.removeAll { $0.id == notification.id }
    }
    
    func clearAll() {
        notifications.removeAll()
    }
}

// MARK: - System Info Provider

public class SystemInfoProvider: ObservableObject {
    @Published var currentAppName = "RadiateOS"
    @Published var currentDateTime = ""
    @Published var unreadNotifications = 3
    @Published var cpuUsage: Double = 0
    @Published var memoryUsage: Double = 0
    @Published var networkStatus = "Connected"
    
    private var timer: Timer?
    
    init() {
        startUpdating()
    }
    
    private func startUpdating() {
        updateDateTime()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            self.updateDateTime()
            self.updateSystemStats()
        }
    }
    
    private func updateDateTime() {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d  h:mm a"
        currentDateTime = formatter.string(from: Date())
    }
    
    private func updateSystemStats() {
        // Update CPU and memory usage
        cpuUsage = Double.random(in: 10...40)
        memoryUsage = Double.random(in: 30...60)
    }
    
    deinit {
        timer?.invalidate()
    }
}

// MARK: - Power Manager

public class PowerManager: ObservableObject {
    @Published var batteryLevel: Int = 85
    @Published var isCharging = false
    @Published var powerProfile: PowerProfile = .balanced
    
    func shutdown() {
        SecurityCore.shared.logSecurityEvent("System shutdown initiated", severity: .info)
        // Implement shutdown
    }
    
    func restart() {
        SecurityCore.shared.logSecurityEvent("System restart initiated", severity: .info)
        // Implement restart
    }
    
    func suspend() {
        SecurityCore.shared.logSecurityEvent("System suspend initiated", severity: .info)
        // Implement suspend
    }
    
    func lockScreen() {
        SecurityCore.shared.lockSystem()
    }
    
    func logOut() {
        SecurityCore.shared.logSecurityEvent("User logout initiated", severity: .info)
        // Implement logout
    }
    
    enum PowerProfile {
        case powersaver
        case balanced
        case performance
    }
}

// MARK: - Models

public struct Workspace: Identifiable {
    let id: Int
    let name: String
    var windowIDs: [UUID] = []
}

public struct Window: Identifiable {
    let id = UUID()
    let title: String
    var position: CGPoint
    var size: CGSize
    var isMinimized = false
    var isMaximized = false
    var workspaceID: Int
}

public struct Theme {
    let name: String
    let colorScheme: ColorScheme?
    let backgroundGradient: [Color]
    let accentColor: Color
    
    static let `default` = Theme(
        name: "Light",
        colorScheme: .light,
        backgroundGradient: [Color(hex: "E3F2FD"), Color(hex: "BBDEFB")],
        accentColor: .blue
    )
    
    static let dark = Theme(
        name: "Dark",
        colorScheme: .dark,
        backgroundGradient: [Color(hex: "1A237E"), Color(hex: "283593")],
        accentColor: .cyan
    )
    
    static let cosmic = Theme(
        name: "Cosmic",
        colorScheme: .dark,
        backgroundGradient: [Color(hex: "2E1A47"), Color(hex: "48257C")],
        accentColor: .purple
    )
}

public struct DockApp: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let accentColor: Color
    var isRunning = false
}

public struct Application: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let category: String
    let accentColor: Color
}

public struct SystemNotification: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let icon: String
    let type: NotificationType
    let timestamp: Date
    
    var timeAgo: String {
        let interval = Date().timeIntervalSince(timestamp)
        if interval < 60 {
            return "Just now"
        } else if interval < 3600 {
            return "\(Int(interval / 60))m ago"
        } else if interval < 86400 {
            return "\(Int(interval / 3600))h ago"
        } else {
            return "\(Int(interval / 86400))d ago"
        }
    }
}

public enum NotificationType {
    case info
    case success
    case warning
    case error
    case security
    
    var color: Color {
        switch self {
        case .info: return .blue
        case .success: return .green
        case .warning: return .orange
        case .error: return .red
        case .security: return .purple
        }
    }
}

public enum DockPosition {
    case bottom
    case left
    case right
}

// MARK: - Helper Extensions

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}