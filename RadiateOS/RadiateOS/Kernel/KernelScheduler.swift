//
//  KernelScheduler.swift
//  RadiateOS
//
//  Advanced kernel scheduler with real process management
//

import Foundation

public actor KernelScheduler {
    public enum ProcessState: String {
        case ready = "Ready"
        case running = "Running"
        case blocked = "Blocked"
        case terminated = "Terminated"
        case suspended = "Suspended"
    }

    public enum ProcessPriority: Int, Comparable {
        case idle = 0
        case low = 1
        case normal = 2
        case high = 3
        case critical = 4

        public static func < (lhs: ProcessPriority, rhs: ProcessPriority) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }

    public struct Process: Identifiable, Hashable {
        public let id: UUID
        public let pid: Int
        public var name: String
        public var state: ProcessState
        public var priority: ProcessPriority
        public var cpuTime: TimeInterval
        public var memoryUsage: UInt64
        public var parentPID: Int?
        public var children: [Int]
        public var startTime: Date
        public var lastScheduledTime: Date?
        public var quantumRemaining: TimeInterval
        public var exitCode: Int?
        public var executablePath: String?
        public var workingDirectory: String?
        public var environment: [String: String]
        public var fileDescriptors: [Int: FileDescriptor]
        public var signalHandlers: [Int: () -> Void]

        public init(
            pid: Int,
            name: String,
            priority: ProcessPriority = .normal,
            parentPID: Int? = nil,
            executablePath: String? = nil,
            workingDirectory: String? = nil,
            environment: [String: String] = [:]
        ) {
            self.id = UUID()
            self.pid = pid
            self.name = name
            self.state = .ready
            self.priority = priority
            self.cpuTime = 0
            self.memoryUsage = 0
            self.parentPID = parentPID
            self.children = []
            self.startTime = Date()
            self.quantumRemaining = Self.defaultQuantum(for: priority)
            self.executablePath = executablePath
            self.workingDirectory = workingDirectory ?? "/Users/user"
            self.environment = environment
            self.fileDescriptors = [:]
            self.signalHandlers = [:]
        }

        private static func defaultQuantum(for priority: ProcessPriority) -> TimeInterval {
            switch priority {
            case .idle: return 0.1
            case .low: return 0.05
            case .normal: return 0.02
            case .high: return 0.01
            case .critical: return 0.005
            }
        }

        public static func == (lhs: Process, rhs: Process) -> Bool {
            lhs.pid == rhs.pid
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(pid)
        }
    }

    public struct FileDescriptor {
        public let fd: Int
        public let path: String
        public let mode: String
        public let offset: UInt64
        public var flags: Int32
    }

    private var processes: [Int: Process] = [:]
    private var readyQueue: PriorityQueue<Process> = PriorityQueue()
    private var blockedQueue: [Int: Process] = [:]
    private var terminatedProcesses: [Process] = []
    private var schedulerTask: Task<Void, Never>? = nil
    private(set) public var isRunning: Bool = false
    private var nextPID: Int = 1
    private var currentProcess: Process? = nil
    private var timeSlice: TimeInterval = 0.01
    private var lastScheduleTime: Date = Date()
    private var systemLoad: Double = 0.0
    private var contextSwitchCount: UInt64 = 0

    public init() {}

    public func start() async {
        guard schedulerTask == nil else { return }
        isRunning = true

        // Create init process (PID 1)
        await createProcess(name: "init", priority: .critical, executablePath: "/sbin/init")

        schedulerTask = Task.detached(priority: .highest) { [weak self] in
            guard let self else { return }
            await self.schedulerLoop()
        }
    }

    public func stop() async {
        isRunning = false
        schedulerTask?.cancel()
        schedulerTask = nil

        // Terminate all processes
        for (pid, _) in processes {
            await terminateProcess(pid: pid, exitCode: 0)
        }
    }

    public func createProcess(
        name: String,
        priority: ProcessPriority = .normal,
        parentPID: Int? = nil,
        executablePath: String? = nil,
        workingDirectory: String? = nil,
        environment: [String: String] = [:]
    ) async -> Int {
        let pid = nextPID
        nextPID += 1

        var process = Process(
            pid: pid,
            name: name,
            priority: priority,
            parentPID: parentPID,
            executablePath: executablePath,
            workingDirectory: workingDirectory,
            environment: environment
        )

        processes[pid] = process

        // Add to parent's children list
        if let parentPID = parentPID, var parent = processes[parentPID] {
            parent.children.append(pid)
            processes[parentPID] = parent
        }

        // Add to ready queue
        readyQueue.enqueue(process)

        print("Created process: \(name) (PID: \(pid), Priority: \(priority.rawValue))")
        return pid
    }

    public func terminateProcess(pid: Int, exitCode: Int) async {
        guard var process = processes[pid] else { return }

        process.state = .terminated
        process.exitCode = exitCode
        processes[pid] = process

        // Move to terminated list
        terminatedProcesses.append(process)

        // Remove from queues
        readyQueue.remove(where: { $0.pid == pid })
        blockedQueue.removeValue(forKey: pid)

        // Clean up children
        for childPID in process.children {
            await terminateProcess(pid: childPID, exitCode: exitCode)
        }

        print("Terminated process: \(process.name) (PID: \(pid), Exit code: \(exitCode))")
    }

    public func blockProcess(pid: Int) async {
        guard var process = processes[pid], process.state == .running || process.state == .ready else { return }

        process.state = .blocked
        processes[pid] = process

        blockedQueue[pid] = process
        readyQueue.remove(where: { $0.pid == pid })

        print("Blocked process: \(process.name) (PID: \(pid))")
    }

    public func unblockProcess(pid: Int) async {
        guard var process = blockedQueue[pid] else { return }

        process.state = .ready
        processes[pid] = process

        blockedQueue.removeValue(forKey: pid)
        readyQueue.enqueue(process)

        print("Unblocked process: \(process.name) (PID: \(pid))")
    }

    public func suspendProcess(pid: Int) async {
        guard var process = processes[pid] else { return }

        process.state = .suspended
        processes[pid] = process

        readyQueue.remove(where: { $0.pid == pid })
        blockedQueue.removeValue(forKey: pid)

        print("Suspended process: \(process.name) (PID: \(pid))")
    }

    public func resumeProcess(pid: Int) async {
        guard var process = processes[pid], process.state == .suspended else { return }

        process.state = .ready
        processes[pid] = process

        readyQueue.enqueue(process)

        print("Resumed process: \(process.name) (PID: \(pid))")
    }

    public func changePriority(pid: Int, newPriority: ProcessPriority) async {
        guard var process = processes[pid] else { return }

        process.priority = newPriority
        process.quantumRemaining = Process.defaultQuantum(for: newPriority)
        processes[pid] = process

        // Re-queue if in ready queue
        if process.state == .ready {
            readyQueue.remove(where: { $0.pid == pid })
            readyQueue.enqueue(process)
        }

        print("Changed priority for process: \(process.name) (PID: \(pid)) to \(newPriority.rawValue)")
    }

    public func getProcess(pid: Int) -> Process? {
        return processes[pid]
    }

    public func listProcesses() -> [Process] {
        return Array(processes.values).sorted { $0.pid < $1.pid }
    }

    public func getSystemLoad() -> Double {
        return systemLoad
    }

    public func getContextSwitchCount() -> UInt64 {
        return contextSwitchCount
    }

    private func schedulerLoop() async {
        while isRunning && !Task.isCancelled {
            let currentTime = Date()
            let deltaTime = currentTime.timeIntervalSince(lastScheduleTime)

            // Update system load
            updateSystemLoad()

            // Schedule next process
            await scheduleNextProcess()

            // Process time slice
            if let currentProcess = currentProcess {
                var updatedProcess = currentProcess
                updatedProcess.cpuTime += deltaTime
                updatedProcess.quantumRemaining -= deltaTime

                // Check if quantum expired
                if updatedProcess.quantumRemaining <= 0 {
                    await contextSwitch(from: updatedProcess)
                } else {
                    processes[currentProcess.pid] = updatedProcess
                    self.currentProcess = updatedProcess
                }
            }

            // Clean up terminated processes periodically
            if terminatedProcesses.count > 100 {
                terminatedProcesses.removeFirst(terminatedProcesses.count - 50)
            }

            lastScheduleTime = currentTime

            // Sleep for a short time to prevent excessive CPU usage
            try? await Task.sleep(nanoseconds: 1_000_000) // 1ms
        }
    }

    private func scheduleNextProcess() async {
        guard let nextProcess = readyQueue.dequeue() else { return }

        if let currentProcess = currentProcess {
            // Context switch
            await contextSwitch(from: currentProcess, to: nextProcess)
        } else {
            // First process
            await switchToProcess(nextProcess)
        }
    }

    private func contextSwitch(from oldProcess: Process? = nil, to newProcess: Process) async {
        contextSwitchCount += 1

        if let oldProcess = oldProcess {
            var updatedOld = oldProcess
            updatedOld.state = .ready
            updatedOld.lastScheduledTime = Date()
            processes[oldProcess.pid] = updatedOld
            readyQueue.enqueue(updatedOld)
        }

        await switchToProcess(newProcess)
    }

    private func switchToProcess(_ process: Process) async {
        var updatedProcess = process
        updatedProcess.state = .running
        updatedProcess.lastScheduledTime = Date()
        updatedProcess.quantumRemaining = Process.defaultQuantum(for: process.priority)

        processes[process.pid] = updatedProcess
        currentProcess = updatedProcess

        print("Switched to process: \(process.name) (PID: \(process.pid))")
    }

    private func updateSystemLoad() {
        let runningProcesses = processes.values.filter { $0.state == .running }.count
        let totalProcesses = processes.count

        if totalProcesses > 0 {
            systemLoad = Double(runningProcesses) / Double(totalProcesses)
        } else {
            systemLoad = 0.0
        }
    }
}

// Priority Queue implementation
public struct PriorityQueue<T: Comparable> {
    private var heap: [T] = []

    public init() {}

    public mutating func enqueue(_ element: T) {
        heap.append(element)
        siftUp(from: heap.count - 1)
    }

    public mutating func dequeue() -> T? {
        guard !heap.isEmpty else { return nil }

        if heap.count == 1 {
            return heap.removeFirst()
        }

        let root = heap[0]
        heap[0] = heap.removeLast()
        siftDown(from: 0)
        return root
    }

    public mutating func remove(where predicate: (T) -> Bool) {
        heap.removeAll(where: predicate)
        buildHeap()
    }

    public func peek() -> T? {
        return heap.first
    }

    public var isEmpty: Bool {
        return heap.isEmpty
    }

    public var count: Int {
        return heap.count
    }

    private mutating func siftUp(from index: Int) {
        var childIndex = index
        let child = heap[childIndex]
        var parentIndex = (childIndex - 1) / 2

        while childIndex > 0 && heap[parentIndex] < child {
            heap[childIndex] = heap[parentIndex]
            childIndex = parentIndex
            parentIndex = (childIndex - 1) / 2
        }

        heap[childIndex] = child
    }

    private mutating func siftDown(from index: Int) {
        let leftChildIndex = 2 * index + 1
        let rightChildIndex = 2 * index + 2
        var largestIndex = index

        if leftChildIndex < heap.count && heap[leftChildIndex] > heap[largestIndex] {
            largestIndex = leftChildIndex
        }

        if rightChildIndex < heap.count && heap[rightChildIndex] > heap[largestIndex] {
            largestIndex = rightChildIndex
        }

        if largestIndex != index {
            heap.swapAt(index, largestIndex)
            siftDown(from: largestIndex)
        }
    }

    private mutating func buildHeap() {
        for i in stride(from: heap.count / 2 - 1, through: 0, by: -1) {
            siftDown(from: i)
        }
    }
}

// Make Process conform to Comparable for PriorityQueue
extension KernelScheduler.Process: Comparable {
    public static func < (lhs: KernelScheduler.Process, rhs: KernelScheduler.Process) -> Bool {
        // Higher priority processes come first (lower priority number means higher priority)
        if lhs.priority != rhs.priority {
            return lhs.priority.rawValue > rhs.priority.rawValue
        }
        // If same priority, FCFS based on PID
        return lhs.pid < rhs.pid
    }
}
