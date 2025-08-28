//
//  NetworkManager.swift
//  RadiateOS
//
//  Network management with offline mode support
//

import Foundation

@MainActor
class NetworkManager: ObservableObject {
    @Published var isOnline: Bool = false
    @Published var isOfflineMode: Bool = true // Default to offline
    @Published var networkInterfaces: [NetworkInterface] = []
    @Published var connectionStatus: ConnectionStatus = .offline

    enum ConnectionStatus: String {
        case offline = "Offline"
        case connecting = "Connecting..."
        case online = "Online"
        case error = "Connection Error"
    }

    struct NetworkInterface {
        let name: String
        let type: InterfaceType
        let isActive: Bool
        let ipAddress: String?
        let macAddress: String
        let status: String

        enum InterfaceType: String {
            case ethernet = "Ethernet"
            case wifi = "Wi-Fi"
            case bluetooth = "Bluetooth"
            case usb = "USB"
            case loopback = "Loopback"
        }
    }

    init() {
        setupOfflineConfiguration()
    }

    func setupOfflineConfiguration() {
        print("🔌 Network Manager: Configuring offline mode")

        // Create loopback interface for local communication
        let loopback = NetworkInterface(
            name: "lo0",
            type: .loopback,
            isActive: true,
            ipAddress: "127.0.0.1",
            macAddress: "00:00:00:00:00:00",
            status: "Active (Offline Mode)"
        )

        networkInterfaces = [loopback]
        connectionStatus = .offline

        print("✅ Network Manager: Offline mode configured successfully")
        print("   - Loopback interface active")
        print("   - All external connections disabled")
        print("   - Local services available")
    }

    func enableOfflineMode() {
        print("🔌 Enabling offline mode...")
        isOfflineMode = true
        isOnline = false
        connectionStatus = .offline

        // Disable all external interfaces
        networkInterfaces = networkInterfaces.map { interface in
            if interface.type != .loopback {
                return NetworkInterface(
                    name: interface.name,
                    type: interface.type,
                    isActive: false,
                    ipAddress: nil,
                    macAddress: interface.macAddress,
                    status: "Disabled (Offline Mode)"
                )
            }
            return interface
        }

        print("✅ Offline mode enabled - External connections blocked")
    }

    func disableOfflineMode() {
        print("🔌 Disabling offline mode...")
        isOfflineMode = false
        connectionStatus = .connecting

        // Simulate connection attempt
        Task {
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            await MainActor.run {
                self.isOnline = true
                self.connectionStatus = .online

                // Re-enable external interfaces
                self.networkInterfaces = self.networkInterfaces.map { interface in
                    if interface.type != .loopback {
                        return NetworkInterface(
                            name: interface.name,
                            type: interface.type,
                            isActive: true,
                            ipAddress: self.generateIPAddress(for: interface),
                            macAddress: interface.macAddress,
                            status: "Connected"
                        )
                    }
                    return interface
                }

                print("✅ Online mode enabled - Network connections available")
            }
        }
    }

    func initialize() async throws {
        print("🔌 Network Manager: Initializing in offline mode")

        // Always start in offline mode as requested
        enableOfflineMode()

        print("✅ Network Manager initialized successfully (Offline Mode)")
    }

    func shutdown() async {
        print("🔌 Network Manager: Shutting down...")
        isOnline = false
        connectionStatus = .offline
        print("✅ Network Manager shutdown complete")
    }

    func getStatus() -> String {
        if isOfflineMode {
            return "Offline Mode - Local services only"
        } else {
            return isOnline ? "Online - Full network access" : "Connecting..."
        }
    }

    func getNetworkInfo() -> String {
        var info = "Network Information\n"
        info += "==================\n"
        info += "Status: \(connectionStatus.rawValue)\n"
        info += "Mode: \(isOfflineMode ? "Offline" : "Online")\n"
        info += "Active Interfaces: \(networkInterfaces.filter { $0.isActive }.count)/\(networkInterfaces.count)\n\n"

        for interface in networkInterfaces {
            info += "\(interface.name) (\(interface.type.rawValue))\n"
            info += "  Status: \(interface.status)\n"
            if let ip = interface.ipAddress {
                info += "  IP: \(ip)\n"
            }
            info += "  MAC: \(interface.macAddress)\n\n"
        }

        return info
    }

    private func generateIPAddress(for interface: NetworkInterface) -> String {
        // Generate a realistic IP for online mode
        switch interface.type {
        case .wifi:
            return "192.168.1.100"
        case .ethernet:
            return "192.168.1.101"
        case .bluetooth:
            return "192.168.1.102"
        case .usb:
            return "192.168.1.103"
        default:
            return "127.0.0.1"
        }
    }
}