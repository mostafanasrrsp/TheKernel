import XCTest
@testable import RadiateOS

final class RadiateOSTests: XCTestCase {
    
    func testDesignSystemColors() {
        // Test that colors are properly initialized
        XCTAssertNotNil(RadiateDesign.Colors.ultraviolet)
        XCTAssertNotNil(RadiateDesign.Colors.indigo)
        XCTAssertNotNil(RadiateDesign.Colors.azure)
        XCTAssertNotNil(RadiateDesign.Colors.emerald)
        XCTAssertNotNil(RadiateDesign.Colors.amber)
        XCTAssertNotNil(RadiateDesign.Colors.crimson)
    }
    
    func testOSManagerInitialization() {
        let osManager = OSManager()
        
        // Test that applications are loaded
        XCTAssertFalse(osManager.applications.isEmpty)
        
        // Test that essential apps exist
        XCTAssertNotNil(osManager.applications.first { $0.id == "finder" })
        XCTAssertNotNil(osManager.applications.first { $0.id == "safari" })
        XCTAssertNotNil(osManager.applications.first { $0.id == "terminal" })
        
        // Test that Finder is always running
        XCTAssertTrue(osManager.runningApplications.contains { $0.id == "finder" })
    }
    
    func testNetworkManager() {
        let networkManager = NetworkManager()
        
        // Test initial state
        XCTAssertTrue(networkManager.isWiFiConnected)
        XCTAssertNotNil(networkManager.currentNetwork)
        XCTAssertFalse(networkManager.availableNetworks.isEmpty)
        
        // Test toggle functionality
        networkManager.toggleWiFi()
        XCTAssertFalse(networkManager.isWiFiConnected)
        XCTAssertNil(networkManager.currentNetwork)
        
        networkManager.toggleWiFi()
        XCTAssertTrue(networkManager.isWiFiConnected)
        XCTAssertNotNil(networkManager.currentNetwork)
    }
    
    func testBluetoothManager() {
        let bluetoothManager = BluetoothManager()
        
        // Test initial state
        XCTAssertTrue(bluetoothManager.isEnabled)
        XCTAssertFalse(bluetoothManager.connectedDevices.isEmpty)
        
        // Test toggle functionality
        bluetoothManager.toggle()
        XCTAssertFalse(bluetoothManager.isEnabled)
        XCTAssertTrue(bluetoothManager.connectedDevices.isEmpty)
        
        bluetoothManager.toggle()
        XCTAssertTrue(bluetoothManager.isEnabled)
    }
    
    func testHotspotManager() {
        let hotspotManager = HotspotManager()
        
        // Test initial state
        XCTAssertFalse(hotspotManager.isEnabled)
        XCTAssertEqual(hotspotManager.connectedDevices, 0)
        
        // Test toggle functionality
        hotspotManager.toggle()
        XCTAssertTrue(hotspotManager.isEnabled)
        
        // Test settings update
        hotspotManager.updateSettings(name: "TestHotspot", password: "test123")
        XCTAssertEqual(hotspotManager.networkName, "TestHotspot")
        XCTAssertEqual(hotspotManager.password, "test123")
    }
    
    func testApplicationLaunch() {
        let osManager = OSManager()
        let testApp = osManager.applications.first { $0.id == "safari" }!
        
        let initialCount = osManager.runningApplications.count
        osManager.launchApplication(testApp)
        
        // Test that app is now running
        XCTAssertTrue(osManager.runningApplications.contains { $0.id == testApp.id })
        XCTAssertEqual(osManager.activeApplication?.id, testApp.id)
        
        // Test that launching again doesn't duplicate
        osManager.launchApplication(testApp)
        let duplicates = osManager.runningApplications.filter { $0.id == testApp.id }
        XCTAssertEqual(duplicates.count, 1)
    }
    
    func testApplicationQuit() {
        let osManager = OSManager()
        let testApp = osManager.applications.first { $0.id == "safari" }!
        
        osManager.launchApplication(testApp)
        XCTAssertTrue(osManager.runningApplications.contains { $0.id == testApp.id })
        
        osManager.quitApplication(testApp)
        XCTAssertFalse(osManager.runningApplications.contains { $0.id == testApp.id })
    }
    
    func testNotificationSystem() {
        let osManager = OSManager()
        let initialCount = osManager.notifications.count
        
        let testNotification = SystemNotification(
            id: "test-1",
            app: osManager.applications.first!,
            title: "Test Notification",
            message: "This is a test",
            timestamp: Date(),
            type: .info
        )
        
        osManager.addNotification(testNotification)
        XCTAssertEqual(osManager.notifications.count, initialCount + 1)
        XCTAssertEqual(osManager.unreadNotifications, 1)
        
        osManager.markNotificationsAsRead()
        XCTAssertEqual(osManager.unreadNotifications, 0)
    }
}