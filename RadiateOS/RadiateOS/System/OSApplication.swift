import Foundation
import SwiftUI

// OS Application Model
class OSApplication: ObservableObject, Identifiable {
    let id: String
    @Published var name: String
    @Published var type: ApplicationType
    @Published var state: ApplicationState = .inactive
    @Published var isActive: Bool = false
    @Published var windows: [ApplicationWindow] = []
    @Published var memoryUsage: Int64 = 0
    @Published var cpuUsage: Double = 0.0
    @Published var icon: String = "app"
    
    private var launchTime: Date?
    private var lastActiveTime: Date?
    
    init(id: String, name: String, type: ApplicationType) {
        self.id = id
        self.name = name
        self.type = type
        setIcon()
    }
    
    private func setIcon() {
        switch id {
        case "finder": icon = "folder"
        case "terminal": icon = "terminal"
        case "browser": icon = "globe"
        case "settings": icon = "gearshape"
        case "monitor": icon = "chart.line.uptrend.xyaxis"
        case "files": icon = "doc.text"
        case "notes": icon = "note.text"
        case "calculator": icon = "plusminus.circle"
        case "music": icon = "music.note"
        case "photos": icon = "photo"
        case "messages": icon = "message"
        case "mail": icon = "envelope"
        default: icon = "app"
        }
    }
    
    func launch() {
        state = .launching
        launchTime = Date()
        
        // Simulate launch delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.state = .running
            self.isActive = true
            self.lastActiveTime = Date()
            
            // Create main window
            self.createWindow()
        }
    }
    
    func terminate() {
        state = .terminating
        
        // Close all windows
        windows.removeAll()
        
        // Clean up resources
        memoryUsage = 0
        cpuUsage = 0.0
        
        state = .inactive
        isActive = false
    }
    
    func suspend() {
        state = .suspended
        isActive = false
    }
    
    func resume() {
        state = .running
        isActive = true
        lastActiveTime = Date()
    }
    
    func createWindow(title: String? = nil) -> ApplicationWindow {
        let window = ApplicationWindow(
            id: UUID(),
            title: title ?? name,
            applicationId: id
        )
        windows.append(window)
        return window
    }
    
    func closeWindow(_ windowId: UUID) {
        windows.removeAll { $0.id == windowId }
        
        // If no windows left, terminate app (unless it's a system app)
        if windows.isEmpty && type != .system {
            terminate()
        }
    }
    
    func bringToFront() {
        isActive = true
        lastActiveTime = Date()
        
        // Bring all windows to front
        for window in windows {
            window.zOrder = Date().timeIntervalSince1970
        }
    }
    
    func getUptime() -> TimeInterval? {
        guard let launch = launchTime else { return nil }
        return Date().timeIntervalSince(launch)
    }
    
    func updateResourceUsage() {
        // Simulate resource usage
        if state == .running {
            memoryUsage = Int64.random(in: 50_000_000...500_000_000) // 50MB - 500MB
            cpuUsage = Double.random(in: 0.1...15.0) // 0.1% - 15%
        } else {
            memoryUsage = 0
            cpuUsage = 0
        }
    }
}

// Application Window
class ApplicationWindow: ObservableObject, Identifiable {
    let id: UUID
    @Published var title: String
    let applicationId: String
    @Published var position: CGPoint = CGPoint(x: 100, y: 100)
    @Published var size: CGSize = CGSize(width: 800, height: 600)
    @Published var isMinimized: Bool = false
    @Published var isMaximized: Bool = false
    @Published var isFullScreen: Bool = false
    @Published var zOrder: TimeInterval = Date().timeIntervalSince1970
    
    init(id: UUID, title: String, applicationId: String) {
        self.id = id
        self.title = title
        self.applicationId = applicationId
    }
    
    func minimize() {
        isMinimized = true
    }
    
    func restore() {
        isMinimized = false
        isMaximized = false
        isFullScreen = false
    }
    
    func maximize() {
        isMaximized = true
        isMinimized = false
    }
    
    func toggleFullScreen() {
        isFullScreen.toggle()
        if isFullScreen {
            isMinimized = false
            isMaximized = false
        }
    }
    
    func move(to point: CGPoint) {
        position = point
    }
    
    func resize(to newSize: CGSize) {
        size = newSize
    }
}

// Application Types
enum ApplicationType {
    case system     // Core system applications
    case user       // User applications
    case utility    // System utilities
    case service    // Background services
    
    var priority: Int {
        switch self {
        case .system: return 10
        case .service: return 8
        case .utility: return 5
        case .user: return 3
        }
    }
}

// Application States
enum ApplicationState {
    case inactive
    case launching
    case running
    case suspended
    case terminating
    
    var description: String {
        switch self {
        case .inactive: return "Inactive"
        case .launching: return "Launching"
        case .running: return "Running"
        case .suspended: return "Suspended"
        case .terminating: return "Terminating"
        }
    }
    
    var color: Color {
        switch self {
        case .inactive: return .gray
        case .launching: return .yellow
        case .running: return .green
        case .suspended: return .orange
        case .terminating: return .red
        }
    }
}