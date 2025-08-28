import SwiftUI

/// Modern desktop environment inspired by Pop!_OS COSMIC and Elementary OS Pantheon
public struct ModernDesktopEnvironment: View {
    
    @StateObject private var desktopManager = DesktopManager()
    @StateObject private var themeManager = ThemeManager.shared
    @State private var showApplicationGrid = false
    @State private var showNotificationCenter = false
    @State private var showSystemMenu = false
    
    public var body: some View {
        ZStack {
            // Desktop Background
            DesktopBackground()
            
            // Desktop Icons and Widgets
            DesktopContent()
            
            // Dock (inspired by Elementary OS)
            VStack {
                Spacer()
                IntelligentDock()
                    .padding(.bottom, 10)
            }
            
            // Top Panel (inspired by GNOME/COSMIC)
            VStack {
                TopPanel(
                    showSystemMenu: $showSystemMenu,
                    showNotificationCenter: $showNotificationCenter
                )
                Spacer()
            }
            
            // Application Grid Overlay
            if showApplicationGrid {
                ApplicationGrid(isShowing: $showApplicationGrid)
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .opacity),
                        removal: .scale.combined(with: .opacity)
                    ))
            }
            
            // Notification Center
            if showNotificationCenter {
                HStack {
                    Spacer()
                    NotificationCenter(isShowing: $showNotificationCenter)
                        .transition(.move(edge: .trailing))
                }
            }
            
            // System Menu
            if showSystemMenu {
                VStack {
                    HStack {
                        Spacer()
                        SystemMenu(isShowing: $showSystemMenu)
                            .padding(.top, 45)
                            .padding(.trailing, 10)
                    }
                    Spacer()
                }
            }
        }
        .preferredColorScheme(themeManager.currentTheme.colorScheme)
        .animation(.spring(), value: showApplicationGrid)
        .animation(.spring(), value: showNotificationCenter)
        .animation(.spring(), value: showSystemMenu)
    }
}

// MARK: - Desktop Background

struct DesktopBackground: View {
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                colors: themeManager.currentTheme.backgroundGradient,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Animated particles (inspired by Elementary OS)
            ParticleEffect()
                .opacity(0.3)
        }
    }
}

// MARK: - Top Panel

struct TopPanel: View {
    @Binding var showSystemMenu: Bool
    @Binding var showNotificationCenter: Bool
    @StateObject private var systemInfo = SystemInfoProvider()
    
    var body: some View {
        HStack {
            // Activities Button
            Button(action: {}) {
                Text("Activities")
                    .font(.system(size: 14, weight: .medium))
            }
            .buttonStyle(PanelButtonStyle())
            
            // Current App Name
            Text(systemInfo.currentAppName)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)
            
            Spacer()
            
            // System Tray
            SystemTray()
            
            // Date & Time
            Text(systemInfo.currentDateTime)
                .font(.system(size: 14, weight: .medium))
                .monospacedDigit()
            
            // Notification Button
            Button(action: { showNotificationCenter.toggle() }) {
                Image(systemName: "bell.fill")
                    .overlay(
                        NotificationBadge(count: systemInfo.unreadNotifications)
                    )
            }
            .buttonStyle(PanelButtonStyle())
            
            // System Menu Button
            Button(action: { showSystemMenu.toggle() }) {
                Image(systemName: "power")
            }
            .buttonStyle(PanelButtonStyle())
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
    }
}

// MARK: - Intelligent Dock

struct IntelligentDock: View {
    @StateObject private var dockManager = DockManager()
    @State private var hoveredApp: String?
    @State private var draggedApp: String?
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(dockManager.pinnedApps) { app in
                DockItem(
                    app: app,
                    isHovered: hoveredApp == app.id,
                    onHover: { hoveredApp = $0 ? app.id : nil },
                    onLaunch: { dockManager.launchApp(app) }
                )
                .scaleEffect(hoveredApp == app.id ? 1.2 : 1.0)
                .animation(.spring(response: 0.3), value: hoveredApp)
            }
            
            Divider()
                .frame(height: 40)
            
            ForEach(dockManager.runningApps) { app in
                DockItem(
                    app: app,
                    isHovered: hoveredApp == app.id,
                    onHover: { hoveredApp = $0 ? app.id : nil },
                    onLaunch: { dockManager.focusApp(app) }
                )
                .scaleEffect(hoveredApp == app.id ? 1.2 : 1.0)
                .animation(.spring(response: 0.3), value: hoveredApp)
            }
            
            Spacer()
            
            // Trash
            TrashIcon()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .shadow(radius: 10)
    }
}

struct DockItem: View {
    let app: DockApp
    let isHovered: Bool
    let onHover: (Bool) -> Void
    let onLaunch: () -> Void
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: app.icon)
                .font(.system(size: 32))
                .foregroundColor(app.accentColor)
                .frame(width: 48, height: 48)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.regularMaterial)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
            
            // Running indicator
            if app.isRunning {
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: 4, height: 4)
            }
        }
        .onHover { onHover($0) }
        .onTapGesture { onLaunch() }
        .help(app.name)
    }
}

// MARK: - Application Grid

struct ApplicationGrid: View {
    @Binding var isShowing: Bool
    @StateObject private var appManager = ApplicationManager()
    @State private var searchText = ""
    @State private var selectedCategory = "All"
    
    let columns = [
        GridItem(.adaptive(minimum: 100, maximum: 120))
    ]
    
    var filteredApps: [Application] {
        appManager.applications.filter { app in
            (selectedCategory == "All" || app.category == selectedCategory) &&
            (searchText.isEmpty || app.name.localizedCaseInsensitiveContains(searchText))
        }
    }
    
    var body: some View {
        ZStack {
            // Background
            Color.black.opacity(0.8)
                .ignoresSafeArea()
                .onTapGesture { isShowing = false }
            
            VStack(spacing: 20) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search applications...", text: $searchText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 18))
                }
                .padding()
                .background(.regularMaterial)
                .cornerRadius(10)
                .frame(maxWidth: 600)
                
                // Category Selector
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(appManager.categories, id: \.self) { category in
                            CategoryButton(
                                title: category,
                                isSelected: selectedCategory == category,
                                action: { selectedCategory = category }
                            )
                        }
                    }
                }
                .frame(maxWidth: 800)
                
                // App Grid
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 20) {
                        ForEach(filteredApps) { app in
                            ApplicationIcon(app: app) {
                                appManager.launch(app)
                                isShowing = false
                            }
                        }
                    }
                    .padding()
                }
                .frame(maxWidth: 1200, maxHeight: 600)
            }
            .padding(40)
        }
    }
}

struct ApplicationIcon: View {
    let app: Application
    let action: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: app.icon)
                .font(.system(size: 48))
                .foregroundColor(app.accentColor)
                .frame(width: 80, height: 80)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.regularMaterial)
                )
                .scaleEffect(isHovered ? 1.1 : 1.0)
            
            Text(app.name)
                .font(.system(size: 12))
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(width: 100)
        }
        .onHover { isHovered = $0 }
        .onTapGesture { action() }
        .animation(.spring(response: 0.3), value: isHovered)
    }
}

// MARK: - Notification Center

struct NotificationCenter: View {
    @Binding var isShowing: Bool
    @StateObject private var notificationManager = NotificationManager()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("Notifications")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("Clear All") {
                    notificationManager.clearAll()
                }
                .buttonStyle(.plain)
                .foregroundColor(.accentColor)
                
                Button(action: { isShowing = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()
            
            Divider()
            
            // Notifications List
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(notificationManager.notifications) { notification in
                        NotificationCard(
                            notification: notification,
                            onDismiss: {
                                notificationManager.dismiss(notification)
                            }
                        )
                    }
                }
                .padding()
            }
        }
        .frame(width: 400)
        .frame(maxHeight: 600)
        .background(.regularMaterial)
        .cornerRadius(12)
        .shadow(radius: 20)
    }
}

struct NotificationCard: View {
    let notification: SystemNotification
    let onDismiss: () -> Void
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // App Icon
            Image(systemName: notification.icon)
                .font(.title2)
                .foregroundColor(notification.type.color)
                .frame(width: 32, height: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(notification.title)
                    .font(.system(size: 14, weight: .semibold))
                
                Text(notification.message)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                Text(notification.timeAgo)
                    .font(.system(size: 10))
                    .foregroundColor(.tertiary)
            }
            
            Spacer()
            
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(Color.primary.opacity(0.05))
        .cornerRadius(8)
    }
}

// MARK: - System Menu

struct SystemMenu: View {
    @Binding var isShowing: Bool
    @StateObject private var powerManager = PowerManager()
    
    var body: some View {
        VStack(spacing: 0) {
            // User Info
            HStack {
                Image(systemName: "person.circle.fill")
                    .font(.largeTitle)
                
                VStack(alignment: .leading) {
                    Text("User")
                        .font(.headline)
                    Text("user@radiateos")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding()
            
            Divider()
            
            // Quick Settings
            VStack(spacing: 8) {
                QuickSettingRow(
                    icon: "gear",
                    title: "Settings",
                    action: { }
                )
                
                QuickSettingRow(
                    icon: "lock.fill",
                    title: "Lock Screen",
                    action: { powerManager.lockScreen() }
                )
                
                QuickSettingRow(
                    icon: "arrow.right.square",
                    title: "Log Out",
                    action: { powerManager.logOut() }
                )
            }
            .padding()
            
            Divider()
            
            // Power Options
            HStack(spacing: 16) {
                PowerButton(
                    icon: "power",
                    title: "Shut Down",
                    action: { powerManager.shutdown() }
                )
                
                PowerButton(
                    icon: "restart",
                    title: "Restart",
                    action: { powerManager.restart() }
                )
                
                PowerButton(
                    icon: "moon.fill",
                    title: "Suspend",
                    action: { powerManager.suspend() }
                )
            }
            .padding()
        }
        .frame(width: 320)
        .background(.regularMaterial)
        .cornerRadius(12)
        .shadow(radius: 20)
    }
}

// MARK: - Supporting Views

struct ParticleEffect: View {
    var body: some View {
        // Simplified particle effect
        GeometryReader { geometry in
            ForEach(0..<20) { _ in
                Circle()
                    .fill(Color.white.opacity(Double.random(in: 0.1...0.3)))
                    .frame(width: CGFloat.random(in: 2...6))
                    .position(
                        x: CGFloat.random(in: 0...geometry.size.width),
                        y: CGFloat.random(in: 0...geometry.size.height)
                    )
            }
        }
    }
}

struct PanelButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(configuration.isPressed ? Color.primary.opacity(0.1) : Color.clear)
            .cornerRadius(4)
    }
}