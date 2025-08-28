//
//  OSApplication.swift
//  RadiateOS
//
//  Application management system
//

import SwiftUI
import Foundation

struct OSApplication: Identifiable, Hashable {
    let id: UUID
    let name: String
    let bundleIdentifier: String
    let version: String
    let icon: String
    let category: AppCategory
    let mainView: AnyView
    let isSystemApp: Bool
    let permissions: [Permission]
    
    init<Content: View>(
        name: String,
        bundleIdentifier: String,
        version: String = "1.0",
        icon: String,
        category: AppCategory,
        isSystemApp: Bool = false,
        permissions: [Permission] = [],
        @ViewBuilder content: () -> Content
    ) {
        self.id = UUID()
        self.name = name
        self.bundleIdentifier = bundleIdentifier
        self.version = version
        self.icon = icon
        self.category = category
        self.mainView = AnyView(content())
        self.isSystemApp = isSystemApp
        self.permissions = permissions
    }
    
    static func == (lhs: OSApplication, rhs: OSApplication) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    enum AppCategory: String, CaseIterable {
        case system = "System"
        case utilities = "Utilities"
        case productivity = "Productivity"
        case development = "Development"
        case entertainment = "Entertainment"
        case communication = "Communication"
        case graphics = "Graphics & Design"
        case education = "Education"
    }
    
    enum Permission: String, CaseIterable {
        case fileSystem = "File System Access"
        case network = "Network Access"
        case camera = "Camera Access"
        case microphone = "Microphone Access"
        case notifications = "Notifications"
        case systemEvents = "System Events"
        case kernelExtensions = "Kernel Extensions"
    }
    
    static func registerSystemApps() {
        SystemAppRegistry.registerAll()
    }
}

class SystemAppRegistry {
    static func registerAll() {
        // Apps will be registered here
    }
    
    @MainActor static let allSystemApps: [OSApplication] = [
        // File Manager
        OSApplication(
            name: "Files",
            bundleIdentifier: "com.radiateos.files",
            icon: "folder",
            category: .system,
            isSystemApp: true,
            permissions: [.fileSystem]
        ) {
            FileManagerView()
        },
        
        // Terminal
        OSApplication(
            name: "Terminal",
            bundleIdentifier: "com.radiateos.terminal",
            icon: "terminal",
            category: .utilities,
            isSystemApp: true,
            permissions: [.fileSystem, .systemEvents]
        ) {
            TerminalView()
        },
        
        // System Preferences
        OSApplication(
            name: "System Preferences",
            bundleIdentifier: "com.radiateos.preferences",
            icon: "gearshape",
            category: .system,
            isSystemApp: true,
            permissions: [.systemEvents, .kernelExtensions]
        ) {
            SystemPreferencesView()
        },
        
        // Activity Monitor
        OSApplication(
            name: "Activity Monitor",
            bundleIdentifier: "com.radiateos.activity",
            icon: "chart.line.uptrend.xyaxis",
            category: .utilities,
            isSystemApp: true,
            permissions: [.systemEvents]
        ) {
            ActivityMonitorView()
        },
        
        // Text Editor
        OSApplication(
            name: "TextEdit",
            bundleIdentifier: "com.radiateos.textedit",
            icon: "doc.text",
            category: .productivity,
            permissions: [.fileSystem]
        ) {
            TextEditorView()
        },
        
        // Calculator
        OSApplication(
            name: "Calculator",
            bundleIdentifier: "com.radiateos.calculator",
            icon: "function",
            category: .utilities
        ) {
            CalculatorView()
        },
        
        // Web Browser
        OSApplication(
            name: "Safari",
            bundleIdentifier: "com.radiateos.safari",
            icon: "safari",
            category: .communication,
            permissions: [.network]
        ) {
            WebBrowserView()
        },
        
        // Network Utility
        OSApplication(
            name: "Network Utility",
            bundleIdentifier: "com.radiateos.network",
            icon: "network",
            category: .utilities,
            isSystemApp: true,
            permissions: [.network]
        ) {
            NetworkUtilityView()
        },
        
        // Kernel Monitor
        OSApplication(
            name: "Kernel Monitor",
            bundleIdentifier: "com.radiateos.kernel",
            icon: "cpu",
            category: .development,
            isSystemApp: true,
            permissions: [.kernelExtensions, .systemEvents]
        ) {
            KernelMonitorView()
        },
        
        // Process Manager
        OSApplication(
            name: "Process Manager",
            bundleIdentifier: "com.radiateos.processes",
            icon: "list.bullet.rectangle",
            category: .utilities,
            isSystemApp: true,
            permissions: [.systemEvents]
        ) {
            ProcessManagerView()
        },
        
        // System Info
        OSApplication(
            name: "System Information",
            bundleIdentifier: "com.radiateos.sysinfo",
            icon: "info.circle",
            category: .utilities,
            isSystemApp: true
        ) {
            SystemInfoView()
        },
        
        // Code Editor
        OSApplication(
            name: "Code Editor",
            bundleIdentifier: "com.radiateos.code",
            icon: "chevron.left.forwardslash.chevron.right",
            category: .development,
            permissions: [.fileSystem]
        ) {
            CodeEditorView()
        },
        
        // Swift Compiler
        OSApplication(
            name: "Swift Compiler",
            bundleIdentifier: "com.radiateos.swift",
            icon: "hammer.fill",
            category: .development,
            isSystemApp: true,
            permissions: [.fileSystem, .systemEvents]
        ) {
            SwiftCompilerView()
        },
        
        // Package Manager
        OSApplication(
            name: "Package Manager",
            bundleIdentifier: "com.radiateos.packages",
            icon: "shippingbox.fill",
            category: .development,
            permissions: [.network, .fileSystem]
        ) {
            PackageManagerView()
        }
    ]
}
