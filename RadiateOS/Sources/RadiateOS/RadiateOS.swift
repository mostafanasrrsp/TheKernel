import SwiftUI

// MARK: - RadiateOS Main App
@main
public struct RadiateOSApp: App {
    public init() {}
    
    public var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 1280, minHeight: 720)
                .preferredColorScheme(.dark)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .commands {
            // Custom menu commands
            CommandGroup(replacing: .appInfo) {
                Button("About RadiateOS") {
                    // Show about window
                }
            }
            
            CommandGroup(replacing: .newItem) {
                Button("New Window") {
                    // Create new window
                }
                .keyboardShortcut("N", modifiers: .command)
            }
        }
    }
}

// MARK: - Public API Exports
public extension RadiateOS {
    static let version = "1.0.0"
    static let buildNumber = "2024.1"
    
    // Export main views
    typealias MainView = ContentView
    typealias Desktop = DesktopEnvironment
    typealias ControlCenter = ControlCenterView
    typealias NotificationCenter = NotificationCenterView
    typealias Launchpad = LaunchpadView
    
    // Export design system
    typealias Design = RadiateDesign
    typealias Colors = RadiateDesign.Colors
    typealias Typography = RadiateDesign.Typography
    typealias Spacing = RadiateDesign.Spacing
    typealias Animations = RadiateDesign.Animations
}