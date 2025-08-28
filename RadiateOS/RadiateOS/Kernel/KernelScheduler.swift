import Foundation

// Advanced Process Scheduler with multiple scheduling algorithms
class KernelScheduler: ObservableObject {
    @Published var currentProcess: Process?
    @Published var schedulingAlgorithm: SchedulingAlgorithm = .multilevelFeedback
    @Published var contextSwitches: Int = 0
    @Published var averageWaitTime: TimeInterval = 0
    @Published var averageTurnaroundTime: TimeInterval = 0
    
    private var readyQueue: [ProcessQueue] = []
    private var waitingQueue: [Process] = []
    private var runQueue: [Process] = []
    private var quantumTime: TimeInterval = 0.01 // 10ms time slice
    private var schedulerTimer: Timer?
    
    // Multi-level feedback queue parameters
    private let queueLevels = 5
    private var queueQuantums: [TimeInterval] = []
    
    // Statistics
    private var processStats: [Int: ProcessStatistics] = [:]
    
    init() {
        setupQueues()
    }
    
    private func setupQueues() {
        // Setup multi-level feedback queues
        for level in 0..<queueLevels {
            let queue = ProcessQueue(priority: level)
            readyQueue.append(queue)
            
            // Each level has double the quantum of the previous
            let quantum = quantumTime * pow(2, Double(level))
            queueQuantums.append(quantum)
        }
    }
    
    func initialize() {
        // Start scheduler timer
        schedulerTimer = Timer.scheduledTimer(withTimeInterval: quantumTime, repeats: true) { _ in
            self.schedule()
        }
    }
    
    func scheduleProcess(_ process: Process) {
        // Add process to appropriate queue based on priority
        let queueIndex = min(process.priority.rawValue, queueLevels - 1)
        readyQueue[queueIndex].enqueue(process)
        
        // Initialize statistics for process
        processStats[process.pid] = ProcessStatistics(pid: process.pid)
    }
    
    func schedule() {
        switch schedulingAlgorithm {
        case .roundRobin:
            scheduleRoundRobin()
        case .priorityBased:
            schedulePriorityBased()
        case .shortestJobFirst:
            scheduleSJF()
        case .multilevelFeedback:
            scheduleMLFQ()
        case .realTime:
            scheduleRealTime()
        }
    }
    
    // MARK: - Scheduling Algorithms
    
    private func scheduleRoundRobin() {
        // Simple round-robin scheduling
        if let current = currentProcess {
            current.state = .ready
            runQueue.append(current)
        }
        
        if let next = runQueue.first {
            runQueue.removeFirst()
            switchToProcess(next)
        }
    }
    
    private func schedulePriorityBased() {
        // Priority-based scheduling with aging to prevent starvation
        var highestPriority: Process?
        var highestValue = -1
        
        for queue in readyQueue {
            if let process = queue.peek() {
                let priorityValue = process.priority.rawValue + getAgingBonus(process)
                if priorityValue > highestValue {
                    highestValue = priorityValue
                    highestPriority = process
                }
            }
        }
        
        if let process = highestPriority {
            switchToProcess(process)
        }
    }
    
    private func scheduleSJF() {
        // Shortest Job First scheduling
        let allProcesses = readyQueue.flatMap { $0.getAllProcesses() }
        if let shortest = allProcesses.min(by: { 
            estimateRemainingTime($0) < estimateRemainingTime($1) 
        }) {
            switchToProcess(shortest)
        }
    }
    
    private func scheduleMLFQ() {
        // Multi-level Feedback Queue scheduling
        for (index, queue) in readyQueue.enumerated() {
            if let process = queue.dequeue() {
                // Set quantum for this level
                let quantum = queueQuantums[index]
                
                // Execute process
                switchToProcess(process)
                
                // After execution, move to next level if not completed
                DispatchQueue.main.asyncAfter(deadline: .now() + quantum) {
                    if process.state == .running {
                        process.state = .ready
                        let nextLevel = min(index + 1, self.queueLevels - 1)
                        self.readyQueue[nextLevel].enqueue(process)
                    }
                }
                
                break
            }
        }
    }
    
    private func scheduleRealTime() {
        // Real-time scheduling for critical processes
        let realTimeProcesses = readyQueue[0].getAllProcesses().filter { 
            $0.priority == .realtime || $0.priority == .kernel 
        }
        
        if let critical = realTimeProcesses.first {
            // Preempt current process for real-time process
            preemptCurrentProcess()
            switchToProcess(critical)
        } else {
            // Fall back to MLFQ
            scheduleMLFQ()
        }
    }
    
    // MARK: - Context Switching
    
    private func switchToProcess(_ process: Process) {
        // Save current process state
        if let current = currentProcess {
            saveProcessContext(current)
        }
        
        // Load new process context
        loadProcessContext(process)
        
        // Update current process
        currentProcess = process
        process.state = .running
        
        // Update statistics
        contextSwitches += 1
        updateProcessStatistics(process)
    }
    
    private func preemptCurrentProcess() {
        if let current = currentProcess {
            current.state = .ready
            // Move to appropriate queue based on priority
            let queueIndex = min(current.priority.rawValue, queueLevels - 1)
            readyQueue[queueIndex].enqueue(current)
        }
    }
    
    private func saveProcessContext(_ process: Process) {
        // Save CPU registers, program counter, etc.
        // This is simulated in our implementation
        process.cpuTime += quantumTime
    }
    
    private func loadProcessContext(_ process: Process) {
        // Load CPU registers, program counter, etc.
        // This is simulated in our implementation
    }
    
    // MARK: - Helper Methods
    
    private func getAgingBonus(_ process: Process) -> Int {
        // Prevent starvation by increasing priority over time
        guard let stats = processStats[process.pid] else { return 0 }
        let waitTime = Date().timeIntervalSince(stats.lastExecuted)
        return Int(waitTime / 10) // +1 priority every 10 seconds
    }
    
    private func estimateRemainingTime(_ process: Process) -> TimeInterval {
        // Estimate based on historical data
        guard let stats = processStats[process.pid] else { return 1.0 }
        return stats.averageBurstTime
    }
    
    private func updateProcessStatistics(_ process: Process) {
        guard var stats = processStats[process.pid] else { return }
        
        let now = Date()
        stats.lastExecuted = now
        stats.executionCount += 1
        
        // Update average burst time
        let burstTime = quantumTime
        stats.totalBurstTime += burstTime
        stats.averageBurstTime = stats.totalBurstTime / Double(stats.executionCount)
        
        // Update wait time
        let waitTime = now.timeIntervalSince(stats.arrivalTime)
        stats.totalWaitTime = waitTime - stats.totalBurstTime
        
        processStats[process.pid] = stats
        
        // Update global statistics
        updateGlobalStatistics()
    }
    
    private func updateGlobalStatistics() {
        let allStats = Array(processStats.values)
        guard !allStats.isEmpty else { return }
        
        let totalWait = allStats.reduce(0) { $0 + $1.totalWaitTime }
        averageWaitTime = totalWait / Double(allStats.count)
        
        let totalTurnaround = allStats.reduce(0) { $0 + ($1.totalWaitTime + $1.totalBurstTime) }
        averageTurnaroundTime = totalTurnaround / Double(allStats.count)
    }
    
    func tick() {
        // Called by timer interrupt
        schedule()
    }
    
    func addToWaitingQueue(_ process: Process) {
        process.state = .waiting
        waitingQueue.append(process)
    }
    
    func wakeupProcess(_ process: Process) {
        if let index = waitingQueue.firstIndex(where: { $0.pid == process.pid }) {
            waitingQueue.remove(at: index)
            process.state = .ready
            scheduleProcess(process)
        }
    }
}

// MARK: - Supporting Types

enum SchedulingAlgorithm {
    case roundRobin
    case priorityBased
    case shortestJobFirst
    case multilevelFeedback
    case realTime
}

class ProcessQueue {
    private var queue: [Process] = []
    let priority: Int
    
    init(priority: Int) {
        self.priority = priority
    }
    
    func enqueue(_ process: Process) {
        queue.append(process)
    }
    
    func dequeue() -> Process? {
        guard !queue.isEmpty else { return nil }
        return queue.removeFirst()
    }
    
    func peek() -> Process? {
        return queue.first
    }
    
    func getAllProcesses() -> [Process] {
        return queue
    }
    
    func isEmpty() -> Bool {
        return queue.isEmpty
    }
}

struct ProcessStatistics {
    let pid: Int
    var arrivalTime: Date = Date()
    var lastExecuted: Date = Date()
    var executionCount: Int = 0
    var totalBurstTime: TimeInterval = 0
    var averageBurstTime: TimeInterval = 0
    var totalWaitTime: TimeInterval = 0
    var turnaroundTime: TimeInterval = 0
}