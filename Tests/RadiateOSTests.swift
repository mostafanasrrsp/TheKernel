import XCTest
@testable import RadiateOS

final class RadiateOSTests: XCTestCase {
    
    // MARK: - Kernel Tests
    
    func testKernelInitialization() async throws {
        let kernel = Kernel.shared
        XCTAssertNotNil(kernel)
        XCTAssertFalse(kernel.isBooted)
        
        try await kernel.boot()
        XCTAssertTrue(kernel.isBooted)
    }
    
    func testKernelMemoryManagement() async throws {
        let kernel = Kernel.shared
        let memoryManager = kernel.memoryManager
        
        // Test memory allocation
        let allocation = try memoryManager.allocate(size: 1024 * 1024) // 1MB
        XCTAssertNotNil(allocation)
        XCTAssertEqual(allocation.size, 1024 * 1024)
        
        // Test memory deallocation
        try memoryManager.deallocate(allocation)
        XCTAssertTrue(memoryManager.isAddressFree(allocation.address))
    }
    
    func testProcessScheduling() async throws {
        let scheduler = KernelScheduler()
        await scheduler.start()
        
        // Create test processes
        let process1 = Process(name: "TestProcess1", priority: .normal)
        let process2 = Process(name: "TestProcess2", priority: .high)
        
        try scheduler.schedule(process1)
        try scheduler.schedule(process2)
        
        let runningProcesses = scheduler.listProcesses()
        XCTAssertEqual(runningProcesses.count, 2)
        
        // Verify high priority process runs first
        let nextProcess = scheduler.getNextProcess()
        XCTAssertEqual(nextProcess?.name, "TestProcess2")
    }
    
    // MARK: - Optical CPU Tests
    
    func testOpticalCPUPerformance() async throws {
        let cpu = OpticalCPU()
        
        // Test basic computation
        let result = try await cpu.compute(operation: .add, operands: [5, 3])
        XCTAssertEqual(result, 8)
        
        // Test parallel processing
        let operations = (0..<1000).map { i in
            CPUOperation(type: .multiply, operands: [i, 2])
        }
        
        let startTime = Date()
        let results = try await cpu.computeParallel(operations: operations)
        let executionTime = Date().timeIntervalSince(startTime)
        
        XCTAssertEqual(results.count, 1000)
        XCTAssertLessThan(executionTime, 0.1) // Should complete in < 100ms
    }
    
    func testOpticalCPUFrequency() async throws {
        let cpu = OpticalCPU()
        
        // Test frequency scaling
        cpu.setFrequency(.performance) // Max frequency
        XCTAssertEqual(cpu.currentFrequency, 3.0) // 3.0 THz
        
        cpu.setFrequency(.balanced)
        XCTAssertEqual(cpu.currentFrequency, 2.0) // 2.0 THz
        
        cpu.setFrequency(.efficiency)
        XCTAssertEqual(cpu.currentFrequency, 1.0) // 1.0 THz
    }
    
    // MARK: - File System Tests
    
    func testFileSystemOperations() async throws {
        let fileSystem = FileSystemManager(currentUserName: "test")
        
        // Test directory creation
        try fileSystem.createDirectory(at: "/test/documents")
        XCTAssertTrue(fileSystem.directoryExists(at: "/test/documents"))
        
        // Test file creation and writing
        let testData = "Hello, RadiateOS!".data(using: .utf8)!
        try fileSystem.writeFile(at: "/test/documents/test.txt", data: testData)
        XCTAssertTrue(fileSystem.fileExists(at: "/test/documents/test.txt"))
        
        // Test file reading
        let readData = try fileSystem.readFile(at: "/test/documents/test.txt")
        XCTAssertEqual(readData, testData)
        
        // Test file deletion
        try fileSystem.deleteFile(at: "/test/documents/test.txt")
        XCTAssertFalse(fileSystem.fileExists(at: "/test/documents/test.txt"))
    }
    
    func testFileSystemPermissions() async throws {
        let fileSystem = FileSystemManager(currentUserName: "test")
        
        // Create file with specific permissions
        let permissions = FilePermissions(owner: .readWrite, group: .read, others: .none)
        try fileSystem.createFile(at: "/test/secure.txt", permissions: permissions)
        
        // Verify permissions
        let fileInfo = try fileSystem.getFileInfo(at: "/test/secure.txt")
        XCTAssertEqual(fileInfo.permissions, permissions)
        
        // Test permission change
        try fileSystem.setPermissions(at: "/test/secure.txt", permissions: .readOnly)
        let updatedInfo = try fileSystem.getFileInfo(at: "/test/secure.txt")
        XCTAssertEqual(updatedInfo.permissions, .readOnly)
    }
    
    // MARK: - Network Tests
    
    func testNetworkConnectivity() async throws {
        let networkManager = NetworkManager()
        
        // Test network initialization
        try await networkManager.initialize()
        XCTAssertTrue(networkManager.isInitialized)
        
        // Test connectivity check
        let isConnected = await networkManager.checkConnectivity()
        XCTAssertTrue(isConnected)
        
        // Test network interfaces
        let interfaces = await networkManager.getNetworkInterfaces()
        XCTAssertGreaterThan(interfaces.count, 0)
    }
    
    func testOpticalNetworkProtocol() async throws {
        let networkManager = NetworkManager()
        
        // Enable optical network protocol
        try await networkManager.enableOpticalProtocol()
        XCTAssertTrue(networkManager.isOpticalEnabled)
        
        // Test optical data transmission
        let testData = Data(repeating: 0xFF, count: 1024 * 1024) // 1MB
        let startTime = Date()
        
        try await networkManager.transmitOptical(data: testData, to: "localhost")
        
        let transmissionTime = Date().timeIntervalSince(startTime)
        let throughput = Double(testData.count) / transmissionTime / 1_000_000 // MB/s
        
        XCTAssertGreaterThan(throughput, 100) // Should achieve > 100 MB/s
    }
    
    // MARK: - GPU Integration Tests
    
    func testGPUDetection() async throws {
        let gpuManager = GPUManager()
        
        // Detect available GPUs
        let gpus = try await gpuManager.detectGPUs()
        XCTAssertGreaterThan(gpus.count, 0)
        
        // Verify GPU capabilities
        if let primaryGPU = gpus.first {
            XCTAssertNotNil(primaryGPU.name)
            XCTAssertGreaterThan(primaryGPU.memory, 0)
            XCTAssertTrue(primaryGPU.supportsCompute)
        }
    }
    
    func testGPUComputation() async throws {
        let gpuManager = GPUManager()
        try await gpuManager.initialize()
        
        // Test matrix multiplication on GPU
        let matrixA = Matrix(rows: 1000, columns: 1000, randomFill: true)
        let matrixB = Matrix(rows: 1000, columns: 1000, randomFill: true)
        
        let startTime = Date()
        let result = try await gpuManager.multiplyMatrices(matrixA, matrixB)
        let computeTime = Date().timeIntervalSince(startTime)
        
        XCTAssertEqual(result.rows, 1000)
        XCTAssertEqual(result.columns, 1000)
        XCTAssertLessThan(computeTime, 0.5) // Should complete in < 500ms
    }
    
    // MARK: - Security Tests
    
    func testEncryption() async throws {
        let securityManager = SecurityManager()
        
        // Test quantum-resistant encryption
        let plaintext = "Secret RadiateOS Data"
        let encrypted = try securityManager.encrypt(plaintext, algorithm: .quantumResistant)
        XCTAssertNotEqual(encrypted, plaintext)
        
        // Test decryption
        let decrypted = try securityManager.decrypt(encrypted, algorithm: .quantumResistant)
        XCTAssertEqual(decrypted, plaintext)
    }
    
    func testSecureBootVerification() async throws {
        let securityManager = SecurityManager()
        
        // Verify boot integrity
        let bootIntegrity = try await securityManager.verifyBootIntegrity()
        XCTAssertTrue(bootIntegrity.isValid)
        XCTAssertNotNil(bootIntegrity.signature)
        
        // Verify kernel signature
        let kernelValid = try await securityManager.verifyKernelSignature()
        XCTAssertTrue(kernelValid)
    }
    
    // MARK: - Performance Tests
    
    func testBootPerformance() throws {
        measure {
            let expectation = XCTestExpectation(description: "Boot completion")
            
            Task {
                let kernel = Kernel.shared
                try await kernel.boot()
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 5.0) // Boot should complete in < 5 seconds
        }
    }
    
    func testMemoryAllocationPerformance() throws {
        let memoryManager = AdvancedMemoryManager(totalMemory: 8 * 1024 * 1024 * 1024)
        
        measure {
            // Allocate and deallocate 1000 memory blocks
            var allocations: [MemoryAllocation] = []
            
            for _ in 0..<1000 {
                if let allocation = try? memoryManager.allocate(size: 1024) {
                    allocations.append(allocation)
                }
            }
            
            for allocation in allocations {
                try? memoryManager.deallocate(allocation)
            }
        }
    }
    
    func testFileSystemPerformance() throws {
        let fileSystem = FileSystemManager(currentUserName: "test")
        let testData = Data(repeating: 0xAA, count: 1024 * 1024) // 1MB
        
        measure {
            // Write and read 100 files
            for i in 0..<100 {
                let path = "/test/perf/file_\(i).dat"
                try? fileSystem.writeFile(at: path, data: testData)
                _ = try? fileSystem.readFile(at: path)
                try? fileSystem.deleteFile(at: path)
            }
        }
    }
    
    // MARK: - Integration Tests
    
    func testFullSystemIntegration() async throws {
        // Boot the system
        let kernel = Kernel.shared
        try await kernel.boot()
        
        // Initialize OS Manager
        let osManager = OSManager.shared
        osManager.initializeSystem()
        
        // Launch a test application
        let testApp = OSApplication(
            name: "TestApp",
            bundleIdentifier: "com.radiateos.testapp",
            icon: "app.fill",
            category: .utilities
        ) {
            Text("Test Application")
        }
        
        osManager.launchApplication(testApp)
        
        // Verify application is running
        XCTAssertTrue(osManager.runningApplications.contains(where: { $0.id == testApp.id }))
        
        // Verify window is open
        XCTAssertTrue(osManager.openWindows.contains(where: { $0.application.id == testApp.id }))
        
        // Close application
        if let window = osManager.openWindows.first(where: { $0.application.id == testApp.id }) {
            osManager.closeWindow(window)
        }
        
        // Verify cleanup
        XCTAssertFalse(osManager.openWindows.contains(where: { $0.application.id == testApp.id }))
    }
    
    func testPowerManagement() async throws {
        let powerManager = PowerManager()
        
        // Test power profiles
        powerManager.setPowerProfile(.performance)
        XCTAssertEqual(powerManager.currentProfile, .performance)
        
        // Monitor power usage
        let powerUsage = await powerManager.getCurrentPowerUsage()
        XCTAssertGreaterThan(powerUsage.cpu, 0)
        XCTAssertGreaterThan(powerUsage.memory, 0)
        
        // Test adaptive scaling
        powerManager.enableAdaptiveScaling()
        XCTAssertTrue(powerManager.isAdaptiveScalingEnabled)
        
        // Simulate low battery
        powerManager.simulateBatteryLevel(20)
        XCTAssertEqual(powerManager.currentProfile, .efficiency)
    }
}

// MARK: - Test Helpers

extension RadiateOSTests {
    
    struct Matrix {
        let rows: Int
        let columns: Int
        let data: [Double]
        
        init(rows: Int, columns: Int, randomFill: Bool = false) {
            self.rows = rows
            self.columns = columns
            
            if randomFill {
                self.data = (0..<(rows * columns)).map { _ in Double.random(in: 0...1) }
            } else {
                self.data = Array(repeating: 0.0, count: rows * columns)
            }
        }
    }
    
    struct MemoryAllocation {
        let address: UInt64
        let size: Int
    }
    
    struct Process {
        let name: String
        let priority: Priority
        
        enum Priority {
            case low, normal, high, realtime
        }
    }
    
    struct CPUOperation {
        let type: OperationType
        let operands: [Int]
        
        enum OperationType {
            case add, subtract, multiply, divide
        }
    }
}