//
//  OSManager.swift
//  RadiateOS
//
//  Core OS management and window system
//

import SwiftUI
import Foundation

@MainActor
class OSManager: ObservableObject {
    static let shared = OSManager()
    
    @Published var runningApplications: [OSApplication] = []
    @Published var openWindows: [OSWindow] = []
    @Published var activeWindow: OSWindow?
    @Published var showDesktop = true
    @Published var currentUser: OSUser
    @Published var systemNotifications: [OSNotification] = []
    @Published var fileSystem: FileSystemManager
    
    private init() {
        let user = OSUser(username: "user", fullName: "RadiateOS User", isAdmin: true)
        self.currentUser = user
        // Avoid referencing OSManager.shared during init; pass current username explicitly
        self.fileSystem = FileSystemManager(currentUserName: user.username)
        
        // Initialize core system applications
        initializeSystemApps()
    }
    
    func launchApplication(_ app: OSApplication) {
        if !runningApplications.contains(where: { $0.id == app.id }) {
            runningApplications.append(app)
        }
        
        let window = OSWindow(
            id: UUID(),
            title: app.name,
            application: app,
            content: app.mainView,
            frame: CGRect(x: 100, y: 100, width: 800, height: 600),
            isMinimized: false
        )
        
        openWindows.append(window)
        activeWindow = window
        showDesktop = false
    }
    
    func closeWindow(_ window: OSWindow) {
        openWindows.removeAll { $0.id == window.id }
        
        // If no windows remain for this app, quit the app
        let appHasOtherWindows = openWindows.contains { $0.application.id == window.application.id }
        if !appHasOtherWindows {
            runningApplications.removeAll { $0.id == window.application.id }
        }
        
        // Set new active window
        activeWindow = openWindows.last
        showDesktop = openWindows.isEmpty
    }
    
    func minimizeWindow(_ window: OSWindow) {
        if let index = openWindows.firstIndex(where: { $0.id == window.id }) {
            openWindows[index].isMinimized = true
            
            // Set new active window
            let visibleWindows = openWindows.filter { !$0.isMinimized }
            activeWindow = visibleWindows.last
            showDesktop = visibleWindows.isEmpty
        }
    }
    
    func restoreWindow(_ window: OSWindow) {
        if let index = openWindows.firstIndex(where: { $0.id == window.id }) {
            openWindows[index].isMinimized = false
            activeWindow = openWindows[index]
            showDesktop = false
        }
    }
    
    func focusWindow(_ window: OSWindow) {
        activeWindow = window
        showDesktop = false
        
        // Bring window to front
        if let index = openWindows.firstIndex(where: { $0.id == window.id }) {
            let window = openWindows.remove(at: index)
            openWindows.append(window)
        }
    }
    
    func showDesktopView() {
        showDesktop = true
        activeWindow = nil
    }
    
    func addNotification(_ notification: OSNotification) {
        systemNotifications.insert(notification, at: 0)
        
        // Auto-remove after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + notification.duration) {
            self.systemNotifications.removeAll { $0.id == notification.id }
        }
    }
    
    private func initializeSystemApps() {
        // These will be available in the system
        OSApplication.registerSystemApps()
    }
}

struct OSUser {
    let id = UUID()
    let username: String
    let fullName: String
    let isAdmin: Bool
    let homeDirectory: String
    
    init(username: String, fullName: String, isAdmin: Bool) {
        self.username = username
        self.fullName = fullName
        self.isAdmin = isAdmin
        self.homeDirectory = "/Users/\(username)"
    }
}

struct OSWindow: Identifiable, Equatable {
    let id: UUID
    var title: String
    let application: OSApplication
    let content: AnyView
    var frame: CGRect
    var isMinimized: Bool
    var isMaximized: Bool = false
    var zIndex: Int = 0
    
    static func == (lhs: OSWindow, rhs: OSWindow) -> Bool {
        lhs.id == rhs.id
    }
}

struct OSNotification: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let type: NotificationType
    let duration: TimeInterval
    let timestamp = Date()
    
    enum NotificationType {
        case info, warning, error, success
        
        var color: Color {
            switch self {
            case .info: return .blue
            case .warning: return .orange
            case .error: return .red
            case .success: return .green
            }
        }
        
        var icon: String {
            switch self {
            case .info: return "info.circle"
            case .warning: return "exclamationmark.triangle"
            case .error: return "xmark.circle"
            case .success: return "checkmark.circle"
            }
        }
    }
}
