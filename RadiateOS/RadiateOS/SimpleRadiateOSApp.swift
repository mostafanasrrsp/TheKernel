import SwiftUI
import CoreData

@main
struct SimpleRadiateOSApp: App {
    @StateObject private var kernel = Kernel.shared
    @StateObject private var osManager = OSManager.shared
    @StateObject private var setupManager = SetupManager()
    
    var body: some Scene {
        WindowGroup {
            if setupManager.isFirstLaunch {
                SetupWizardView(isPresented: .constant(true))
                    .environmentObject(kernel)
            } else {
                ContentView()
                    .environmentObject(kernel)
                    .environmentObject(osManager)
                    .onAppear {
                        Task { try? await kernel.boot() }
                    }
            }
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About RadiateOS") {
                    osManager.showAboutDialog()
                }
            }
            CommandMenu("System") {
                Button("System Monitor") {
                    osManager.openSystemMonitor()
                }
                .keyboardShortcut("M", modifiers: [.command, .shift])
                
                Button("Activity Monitor") {
                    osManager.openActivityMonitor()
                }
                .keyboardShortcut("A", modifiers: [.command, .shift])
                
                Divider()
                
                Button("Restart") {
                    kernel.restart()
                }
                
                Button("Shut Down") {
                    kernel.shutdown()
                }
            }
        }
    }
}

// Setup Manager for first launch configuration
class SetupManager: ObservableObject {
    @Published var isFirstLaunch: Bool
    @Published var userName: String = ""
    @Published var systemName: String = "RadiateOS"
    @Published var enableTelemetry: Bool = false
    @Published var setupProgress: Double = 0.0
    
    init() {
        self.isFirstLaunch = UserDefaults.standard.object(forKey: "HasCompletedSetup") == nil
    }
    
    func completeSetup() {
        UserDefaults.standard.set(true, forKey: "HasCompletedSetup")
        UserDefaults.standard.set(userName, forKey: "UserName")
        UserDefaults.standard.set(systemName, forKey: "SystemName")
        UserDefaults.standard.set(enableTelemetry, forKey: "EnableTelemetry")
        isFirstLaunch = false
    }
}