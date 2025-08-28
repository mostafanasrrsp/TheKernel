//
//  DesktopComponents.swift
//  RadiateOS
//
//  Desktop UI components (menu bar, dock, windows)
//

import SwiftUI

// MARK: - Menu Bar
struct MenuBarView: View {
    @Binding var showApplicationLauncher: Bool
    @State private var currentTime = Date()
    @State private var showUserMenu = false
    @State private var showSystemMenu = false
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        HStack {
            // Apple/System menu
            Menu {
                Button("About RadiateOS") { }
                Divider()
                Button("Setup Wizard") {
                    NotificationCenter.default.post(name: .showSetupWizard, object: nil)
                }
                Button("System Preferences") {
                    let app = SystemAppRegistry.allSystemApps.first { $0.name == "System Preferences" }!
                    OSManager.shared.launchApplication(app)
                }
                Button("Activity Monitor") {
                    let app = SystemAppRegistry.allSystemApps.first { $0.name == "Activity Monitor" }!
                    OSManager.shared.launchApplication(app)
                }
                Divider()
                Button("Restart") { }
                Button("Shut Down") { }
            } label: {
                Image(systemName: "sparkles")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
            }
            .menuStyle(BorderlessButtonMenuStyle())
            
            // Application name (if any active)
            if let activeWindow = OSManager.shared.activeWindow {
                Text(activeWindow.application.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
            }
            
            Spacer()
            
            // Right side items
            HStack(spacing: 16) {
                // System status
                SystemStatusMenuView()
                
                // User menu
                Menu {
                    Button("User Account") { }
                    Divider()
                    Button("Lock Screen") { }
                    Button("Log Out") { }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "person.circle")
                        Text(OSManager.shared.currentUser.username)
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                }
                .menuStyle(BorderlessButtonMenuStyle())
                
                // Time and date
                Button(action: {}) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(currentTime, style: .time)
                            .font(.system(size: 14, weight: .medium))
                        
                        Text(currentTime, formatter: DateFormatter.shortDate)
                            .font(.system(size: 12))
                    }
                    .foregroundColor(.white)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            LinearGradient(
                colors: [Color.black.opacity(0.8), Color.black.opacity(0.6)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .onReceive(timer) { _ in
            currentTime = Date()
        }
    }
}

struct SystemStatusMenuView: View {
    @State private var cpuUsage: Double = 25.0
    @State private var memoryUsage: Double = 35.0
    @State private var showDetails = false
    
    var body: some View {
        Menu {
            VStack(alignment: .leading, spacing: 8) {
                Text("System Status")
                    .font(.headline)
                
                HStack {
                    Text("CPU:")
                    Spacer()
                    Text("\(Int(cpuUsage))%")
                    ProgressView(value: cpuUsage / 100)
                        .frame(width: 60)
                }
                
                HStack {
                    Text("Memory:")
                    Spacer()
                    Text("\(Int(memoryUsage))%")
                    ProgressView(value: memoryUsage / 100)
                        .frame(width: 60)
                }
                
                Divider()
                
                Button("Open Activity Monitor") {
                    let app = SystemAppRegistry.allSystemApps.first { $0.name == "Activity Monitor" }!
                    OSManager.shared.launchApplication(app)
                }
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(cpuUsage > 80 ? .red : .white)
                Text("\(Int(cpuUsage))%")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
            }
        }
        .menuStyle(BorderlessButtonMenuStyle())
    }
}

// MARK: - Dock
struct DockView: View {
    @StateObject private var osManager = OSManager.shared
    // Show core system apps in dock - Files, Terminal, System Preferences, Activity Monitor
    private let dockApps = SystemAppRegistry.allSystemApps.filter { app in
        app.category == .system || app.name == "Terminal" || app.name == "Activity Monitor"
    }.prefix(8)
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(dockApps, id: \.id) { app in
                DockItemView(application: app)
            }
            
            // Separator
            Rectangle()
                .fill(Color.white.opacity(0.3))
                .frame(width: 1, height: 40)
                .padding(.horizontal, 4)
            
            // Running applications
            ForEach(osManager.runningApplications.filter { app in
                !dockApps.contains(where: { $0.id == app.id })
            }) { app in
                DockItemView(application: app, isRunning: true)
            }
            
            // Minimized windows
            ForEach(osManager.openWindows.filter { $0.isMinimized }) { window in
                MinimizedWindowView(window: window)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
    }
}

struct DockItemView: View {
    let application: OSApplication
    var isRunning: Bool = false
    @State private var isHovered = false
    @State private var bounceOffset: CGFloat = 0
    
    var body: some View {
        VStack(spacing: 4) {
            Button(action: {
                if isRunning {
                    // If app is running, bring to front or launch new window
                    if let window = OSManager.shared.openWindows.first(where: { $0.application.id == application.id }) {
                        OSManager.shared.focusWindow(window)
                    }
                } else {
                    OSManager.shared.launchApplication(application)
                    triggerBounce()
                }
            }) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(isHovered ? 0.2 : 0.1))
                        .frame(width: 64, height: 64)
                    
                    Image(systemName: application.icon)
                        .font(.system(size: 32))
                        .foregroundColor(.white)
                }
                .scaleEffect(isHovered ? 1.2 : 1.0)
                .offset(y: bounceOffset)
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isHovered)
                .animation(.spring(response: 0.4, dampingFraction: 0.5), value: bounceOffset)
            }
            .buttonStyle(PlainButtonStyle())
            .onHover { hovering in
                isHovered = hovering
            }
            
            // Running indicator
            if isRunning {
                Circle()
                    .fill(Color.white)
                    .frame(width: 4, height: 4)
            }
        }
    }
    
    private func triggerBounce() {
        bounceOffset = -8
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            bounceOffset = 0
        }
    }
}

struct MinimizedWindowView: View {
    let window: OSWindow
    @State private var isHovered = false
    
    var body: some View {
        Button(action: {
            OSManager.shared.restoreWindow(window)
        }) {
            VStack(spacing: 4) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 40, height: 30)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                    
                    Image(systemName: window.application.icon)
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                }
                .scaleEffect(isHovered ? 1.1 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isHovered)
                
                Text(window.title)
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(1)
                    .frame(maxWidth: 60)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Window Management
struct WindowView: View {
    let window: OSWindow
    @State private var dragOffset = CGSize.zero
    @State private var isBeingDragged = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Title bar
            WindowTitleBarView(window: window, dragOffset: $dragOffset, isBeingDragged: $isBeingDragged)
            
            // Content
            window.content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(nsColor: .controlBackgroundColor))
                .clipped()
        }
        .frame(width: window.frame.width, height: window.frame.height)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
        .offset(x: window.frame.minX + dragOffset.width, y: window.frame.minY + dragOffset.height)
        .scaleEffect(isBeingDragged ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isBeingDragged)
    }
}

struct WindowTitleBarView: View {
    let window: OSWindow
    @Binding var dragOffset: CGSize
    @Binding var isBeingDragged: Bool
    
    var body: some View {
        HStack {
            // Window controls
            HStack(spacing: 8) {
                Button(action: {
                    OSManager.shared.closeWindow(window)
                }) {
                    Circle()
                        .fill(.red)
                        .frame(width: 12, height: 12)
                        .overlay(
                            Image(systemName: "xmark")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(.white.opacity(0.8))
                        )
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: {
                    OSManager.shared.minimizeWindow(window)
                }) {
                    Circle()
                        .fill(.yellow)
                        .frame(width: 12, height: 12)
                        .overlay(
                            Rectangle()
                                .fill(.white.opacity(0.8))
                                .frame(width: 8, height: 1)
                        )
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: {
                    // Toggle maximize
                }) {
                    Circle()
                        .fill(.green)
                        .frame(width: 12, height: 12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 1)
                                .stroke(.white.opacity(0.8), lineWidth: 1)
                                .frame(width: 6, height: 6)
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            Spacer()
            
            // Window title
            Text(window.title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.primary.opacity(0.8))
            
            Spacer()
            
            // App icon
            Image(systemName: window.application.icon)
                .font(.system(size: 14))
                .foregroundColor(.primary.opacity(0.6))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.primary.opacity(0.05))
        .gesture(
            DragGesture()
                .onChanged { value in
                    dragOffset = value.translation
                    isBeingDragged = true
                }
                .onEnded { _ in
                    dragOffset = .zero
                    isBeingDragged = false
                }
        )
    }
}

// MARK: - Application Launcher
struct ApplicationLauncherView: View {
    @Binding var isPresented: Bool
    @State private var searchText = ""
    @State private var selectedCategory: OSApplication.AppCategory = .system
    
    private var filteredApps: [OSApplication] {
        let apps = SystemAppRegistry.allSystemApps
        let categoryFiltered = apps.filter { $0.category == selectedCategory }
        
        if searchText.isEmpty {
            return categoryFiltered
        } else {
            return categoryFiltered.filter {
                $0.name.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Applications")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button("Done") {
                    isPresented = false
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            
            // Search
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.white.opacity(0.6))
                
                TextField("Search applications", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .foregroundColor(.white)
            }
            .padding()
            .background(Color.white.opacity(0.1))
            .cornerRadius(8)
            .padding(.horizontal)
            
            // Categories
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(OSApplication.AppCategory.allCases, id: \.self) { category in
                        Button(category.rawValue) {
                            selectedCategory = category
                        }
                        .foregroundColor(selectedCategory == category ? .black : .white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(selectedCategory == category ? Color.white : Color.white.opacity(0.2))
                        .cornerRadius(20)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
            
            // App grid
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.adaptive(minimum: 100)), count: 1), spacing: 20) {
                    ForEach(filteredApps) { app in
                        LauncherAppView(application: app, isPresented: $isPresented)
                    }
                }
                .padding(.horizontal)
            }
        }
        .frame(width: 600, height: 500)
        .background(
            LinearGradient(
                colors: [Color.black.opacity(0.9), Color.blue.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.5), radius: 20, x: 0, y: 10)
    }
}

struct LauncherAppView: View {
    let application: OSApplication
    @Binding var isPresented: Bool
    @State private var isHovered = false
    
    var body: some View {
        VStack(spacing: 8) {
            Button(action: {
                OSManager.shared.launchApplication(application)
                isPresented = false
            }) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(isHovered ? 0.2 : 0.1))
                        .frame(width: 64, height: 64)
                    
                    Image(systemName: application.icon)
                        .font(.system(size: 32))
                        .foregroundColor(.white)
                }
                .scaleEffect(isHovered ? 1.1 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isHovered)
            }
            .buttonStyle(PlainButtonStyle())
            .onHover { hovering in
                isHovered = hovering
            }
            
            Text(application.name)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white)
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .frame(width: 80)
    }
}

// MARK: - Notification View
struct NotificationView: View {
    let notification: OSNotification
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: notification.type.icon)
                .font(.system(size: 16))
                .foregroundColor(notification.type.color)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(notification.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(notification.message)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .lineLimit(3)
            }
            
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(nsColor: .controlBackgroundColor))
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
        .frame(width: 300)
    }
}

extension DateFormatter {
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        return formatter
    }()
}

extension Notification.Name {
    static let showSetupWizard = Notification.Name("showSetupWizard")
}

#Preview {
    DesktopEnvironment()
        .preferredColorScheme(.dark)
}
