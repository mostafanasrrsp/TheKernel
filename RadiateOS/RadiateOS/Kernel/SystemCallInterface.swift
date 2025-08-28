import Foundation

// MARK: - System Call Interface
class SystemCallInterface: ObservableObject {
    @Published var systemCalls: [SystemCall] = []
    @Published var callHistory: [SystemCallRecord] = []
    @Published var statistics = SystemCallStatistics()
    
    private let queue = DispatchQueue(label: "com.radiateos.syscall", attributes: .concurrent)
    private var handlers: [Int: SystemCallHandler] = [:]
    private let kernel: Kernel
    private let memoryManager: AdvancedMemoryManager
    private let processManager: ProcessManager
    private let fileSystem: FileSystemManager
    private let networkManager: NetworkManager
    
    init(kernel: Kernel) {
        self.kernel = kernel
        self.memoryManager = AdvancedMemoryManager()
        self.processManager = ProcessManager()
        self.fileSystem = FileSystemManager()
        self.networkManager = NetworkManager()
        
        registerSystemCalls()
    }
    
    private func registerSystemCalls() {
        // Process management syscalls
        register(SystemCall.fork)
        register(SystemCall.exec)
        register(SystemCall.exit)
        register(SystemCall.wait)
        register(SystemCall.getpid)
        register(SystemCall.getppid)
        register(SystemCall.kill)
        register(SystemCall.nice)
        
        // File system syscalls
        register(SystemCall.open)
        register(SystemCall.close)
        register(SystemCall.read)
        register(SystemCall.write)
        register(SystemCall.lseek)
        register(SystemCall.stat)
        register(SystemCall.fstat)
        register(SystemCall.mkdir)
        register(SystemCall.rmdir)
        register(SystemCall.unlink)
        register(SystemCall.rename)
        register(SystemCall.chmod)
        register(SystemCall.chown)
        
        // Memory management syscalls
        register(SystemCall.brk)
        register(SystemCall.mmap)
        register(SystemCall.munmap)
        register(SystemCall.mprotect)
        register(SystemCall.mlock)
        register(SystemCall.munlock)
        
        // Network syscalls
        register(SystemCall.socket)
        register(SystemCall.bind)
        register(SystemCall.listen)
        register(SystemCall.accept)
        register(SystemCall.connect)
        register(SystemCall.send)
        register(SystemCall.recv)
        register(SystemCall.sendto)
        register(SystemCall.recvfrom)
        register(SystemCall.shutdown)
        
        // IPC syscalls
        register(SystemCall.pipe)
        register(SystemCall.msgget)
        register(SystemCall.msgsnd)
        register(SystemCall.msgrcv)
        register(SystemCall.semget)
        register(SystemCall.semop)
        register(SystemCall.shmget)
        register(SystemCall.shmat)
        register(SystemCall.shmdt)
        
        // Time syscalls
        register(SystemCall.time)
        register(SystemCall.gettimeofday)
        register(SystemCall.settimeofday)
        register(SystemCall.nanosleep)
        register(SystemCall.clock_gettime)
        
        // Signal syscalls
        register(SystemCall.signal)
        register(SystemCall.sigaction)
        register(SystemCall.sigprocmask)
        register(SystemCall.sigpending)
        register(SystemCall.sigsuspend)
        
        // Device syscalls
        register(SystemCall.ioctl)
        register(SystemCall.fcntl)
        register(SystemCall.poll)
        register(SystemCall.select)
        register(SystemCall.epoll_create)
        register(SystemCall.epoll_ctl)
        register(SystemCall.epoll_wait)
    }
    
    private func register(_ syscall: SystemCall) {
        systemCalls.append(syscall)
        
        // Create handler based on syscall type
        let handler: SystemCallHandler
        
        switch syscall {
        // Process management
        case .fork:
            handler = ForkHandler(processManager: processManager)
        case .exec:
            handler = ExecHandler(processManager: processManager)
        case .exit:
            handler = ExitHandler(processManager: processManager)
        case .wait:
            handler = WaitHandler(processManager: processManager)
        case .getpid, .getppid:
            handler = GetPidHandler(processManager: processManager)
        case .kill:
            handler = KillHandler(processManager: processManager)
            
        // File system
        case .open:
            handler = OpenHandler(fileSystem: fileSystem)
        case .close:
            handler = CloseHandler(fileSystem: fileSystem)
        case .read:
            handler = ReadHandler(fileSystem: fileSystem)
        case .write:
            handler = WriteHandler(fileSystem: fileSystem)
        case .mkdir:
            handler = MkdirHandler(fileSystem: fileSystem)
            
        // Memory management
        case .mmap:
            handler = MmapHandler(memoryManager: memoryManager)
        case .munmap:
            handler = MunmapHandler(memoryManager: memoryManager)
        case .brk:
            handler = BrkHandler(memoryManager: memoryManager)
            
        // Network
        case .socket:
            handler = SocketHandler(networkManager: networkManager)
        case .connect:
            handler = ConnectHandler(networkManager: networkManager)
        case .send:
            handler = SendHandler(networkManager: networkManager)
        case .recv:
            handler = RecvHandler(networkManager: networkManager)
            
        default:
            handler = DefaultHandler()
        }
        
        handlers[syscall.number] = handler
    }
    
    // MARK: - System Call Execution
    
    func syscall(_ number: Int, args: SystemCallArguments) -> SystemCallResult {
        let startTime = Date()
        
        // Record the call
        let record = SystemCallRecord(
            number: number,
            name: systemCallName(number),
            args: args,
            timestamp: startTime,
            processID: ProcessInfo.processInfo.processIdentifier
        )
        
        // Check if syscall is valid
        guard let handler = handlers[number] else {
            record.result = .failure(SystemCallError.invalidSyscall)
            record.duration = Date().timeIntervalSince(startTime)
            recordCall(record)
            statistics.failedCalls += 1
            return .failure(SystemCallError.invalidSyscall)
        }
        
        // Check permissions
        if !checkPermissions(for: number, args: args) {
            record.result = .failure(SystemCallError.permissionDenied)
            record.duration = Date().timeIntervalSince(startTime)
            recordCall(record)
            statistics.failedCalls += 1
            return .failure(SystemCallError.permissionDenied)
        }
        
        // Execute the system call
        let result = queue.sync {
            handler.execute(args: args)
        }
        
        // Record result
        record.result = result
        record.duration = Date().timeIntervalSince(startTime)
        recordCall(record)
        
        // Update statistics
        statistics.totalCalls += 1
        if case .success = result {
            statistics.successfulCalls += 1
        } else {
            statistics.failedCalls += 1
        }
        
        return result
    }
    
    private func checkPermissions(for syscall: Int, args: SystemCallArguments) -> Bool {
        // Check if current process has permission to make this syscall
        // Some syscalls require root/kernel privileges
        
        let privilegedSyscalls: Set<Int> = [
            SystemCall.settimeofday.number,
            SystemCall.mlock.number,
            SystemCall.munlock.number,
            SystemCall.ioctl.number
        ]
        
        if privilegedSyscalls.contains(syscall) {
            // Check if process has required privileges
            return processManager.currentProcess?.isPrivileged ?? false
        }
        
        return true
    }
    
    private func systemCallName(_ number: Int) -> String {
        return systemCalls.first { $0.number == number }?.name ?? "unknown"
    }
    
    private func recordCall(_ record: SystemCallRecord) {
        callHistory.insert(record, at: 0)
        
        // Keep only last 1000 calls
        if callHistory.count > 1000 {
            callHistory.removeLast()
        }
    }
    
    // MARK: - Statistics
    
    func getStatistics() -> SystemCallStatistics {
        return statistics
    }
    
    func resetStatistics() {
        statistics = SystemCallStatistics()
    }
}

// MARK: - System Call Definition
struct SystemCall {
    let number: Int
    let name: String
    let category: SystemCallCategory
    
    // Process management
    static let fork = SystemCall(number: 1, name: "fork", category: .process)
    static let exec = SystemCall(number: 2, name: "exec", category: .process)
    static let exit = SystemCall(number: 3, name: "exit", category: .process)
    static let wait = SystemCall(number: 4, name: "wait", category: .process)
    static let getpid = SystemCall(number: 5, name: "getpid", category: .process)
    static let getppid = SystemCall(number: 6, name: "getppid", category: .process)
    static let kill = SystemCall(number: 7, name: "kill", category: .process)
    static let nice = SystemCall(number: 8, name: "nice", category: .process)
    
    // File system
    static let open = SystemCall(number: 10, name: "open", category: .fileSystem)
    static let close = SystemCall(number: 11, name: "close", category: .fileSystem)
    static let read = SystemCall(number: 12, name: "read", category: .fileSystem)
    static let write = SystemCall(number: 13, name: "write", category: .fileSystem)
    static let lseek = SystemCall(number: 14, name: "lseek", category: .fileSystem)
    static let stat = SystemCall(number: 15, name: "stat", category: .fileSystem)
    static let fstat = SystemCall(number: 16, name: "fstat", category: .fileSystem)
    static let mkdir = SystemCall(number: 17, name: "mkdir", category: .fileSystem)
    static let rmdir = SystemCall(number: 18, name: "rmdir", category: .fileSystem)
    static let unlink = SystemCall(number: 19, name: "unlink", category: .fileSystem)
    static let rename = SystemCall(number: 20, name: "rename", category: .fileSystem)
    static let chmod = SystemCall(number: 21, name: "chmod", category: .fileSystem)
    static let chown = SystemCall(number: 22, name: "chown", category: .fileSystem)
    
    // Memory management
    static let brk = SystemCall(number: 30, name: "brk", category: .memory)
    static let mmap = SystemCall(number: 31, name: "mmap", category: .memory)
    static let munmap = SystemCall(number: 32, name: "munmap", category: .memory)
    static let mprotect = SystemCall(number: 33, name: "mprotect", category: .memory)
    static let mlock = SystemCall(number: 34, name: "mlock", category: .memory)
    static let munlock = SystemCall(number: 35, name: "munlock", category: .memory)
    
    // Network
    static let socket = SystemCall(number: 40, name: "socket", category: .network)
    static let bind = SystemCall(number: 41, name: "bind", category: .network)
    static let listen = SystemCall(number: 42, name: "listen", category: .network)
    static let accept = SystemCall(number: 43, name: "accept", category: .network)
    static let connect = SystemCall(number: 44, name: "connect", category: .network)
    static let send = SystemCall(number: 45, name: "send", category: .network)
    static let recv = SystemCall(number: 46, name: "recv", category: .network)
    static let sendto = SystemCall(number: 47, name: "sendto", category: .network)
    static let recvfrom = SystemCall(number: 48, name: "recvfrom", category: .network)
    static let shutdown = SystemCall(number: 49, name: "shutdown", category: .network)
    
    // IPC
    static let pipe = SystemCall(number: 50, name: "pipe", category: .ipc)
    static let msgget = SystemCall(number: 51, name: "msgget", category: .ipc)
    static let msgsnd = SystemCall(number: 52, name: "msgsnd", category: .ipc)
    static let msgrcv = SystemCall(number: 53, name: "msgrcv", category: .ipc)
    static let semget = SystemCall(number: 54, name: "semget", category: .ipc)
    static let semop = SystemCall(number: 55, name: "semop", category: .ipc)
    static let shmget = SystemCall(number: 56, name: "shmget", category: .ipc)
    static let shmat = SystemCall(number: 57, name: "shmat", category: .ipc)
    static let shmdt = SystemCall(number: 58, name: "shmdt", category: .ipc)
    
    // Time
    static let time = SystemCall(number: 60, name: "time", category: .time)
    static let gettimeofday = SystemCall(number: 61, name: "gettimeofday", category: .time)
    static let settimeofday = SystemCall(number: 62, name: "settimeofday", category: .time)
    static let nanosleep = SystemCall(number: 63, name: "nanosleep", category: .time)
    static let clock_gettime = SystemCall(number: 64, name: "clock_gettime", category: .time)
    
    // Signals
    static let signal = SystemCall(number: 70, name: "signal", category: .signal)
    static let sigaction = SystemCall(number: 71, name: "sigaction", category: .signal)
    static let sigprocmask = SystemCall(number: 72, name: "sigprocmask", category: .signal)
    static let sigpending = SystemCall(number: 73, name: "sigpending", category: .signal)
    static let sigsuspend = SystemCall(number: 74, name: "sigsuspend", category: .signal)
    
    // Device
    static let ioctl = SystemCall(number: 80, name: "ioctl", category: .device)
    static let fcntl = SystemCall(number: 81, name: "fcntl", category: .device)
    static let poll = SystemCall(number: 82, name: "poll", category: .device)
    static let select = SystemCall(number: 83, name: "select", category: .device)
    static let epoll_create = SystemCall(number: 84, name: "epoll_create", category: .device)
    static let epoll_ctl = SystemCall(number: 85, name: "epoll_ctl", category: .device)
    static let epoll_wait = SystemCall(number: 86, name: "epoll_wait", category: .device)
}

// MARK: - System Call Categories
enum SystemCallCategory {
    case process
    case fileSystem
    case memory
    case network
    case ipc
    case time
    case signal
    case device
}

// MARK: - System Call Arguments
struct SystemCallArguments {
    let values: [Any]
    
    func int(at index: Int) -> Int? {
        guard index < values.count else { return nil }
        return values[index] as? Int
    }
    
    func string(at index: Int) -> String? {
        guard index < values.count else { return nil }
        return values[index] as? String
    }
    
    func pointer(at index: Int) -> UnsafeRawPointer? {
        guard index < values.count else { return nil }
        return values[index] as? UnsafeRawPointer
    }
    
    func data(at index: Int) -> Data? {
        guard index < values.count else { return nil }
        return values[index] as? Data
    }
}

// MARK: - System Call Result
enum SystemCallResult {
    case success(Any?)
    case failure(SystemCallError)
}

// MARK: - System Call Error
enum SystemCallError: Error {
    case invalidSyscall
    case invalidArgument
    case permissionDenied
    case resourceUnavailable
    case operationNotSupported
    case outOfMemory
    case fileNotFound
    case accessDenied
    case busy
    case interrupted
    case ioError
    
    var errorCode: Int {
        switch self {
        case .invalidSyscall: return -1
        case .invalidArgument: return -22
        case .permissionDenied: return -13
        case .resourceUnavailable: return -11
        case .operationNotSupported: return -95
        case .outOfMemory: return -12
        case .fileNotFound: return -2
        case .accessDenied: return -13
        case .busy: return -16
        case .interrupted: return -4
        case .ioError: return -5
        }
    }
}

// MARK: - System Call Handlers

protocol SystemCallHandler {
    func execute(args: SystemCallArguments) -> SystemCallResult
}

// Process Management Handlers
class ForkHandler: SystemCallHandler {
    let processManager: ProcessManager
    
    init(processManager: ProcessManager) {
        self.processManager = processManager
    }
    
    func execute(args: SystemCallArguments) -> SystemCallResult {
        if let pid = processManager.fork() {
            return .success(pid)
        }
        return .failure(.resourceUnavailable)
    }
}

class ExecHandler: SystemCallHandler {
    let processManager: ProcessManager
    
    init(processManager: ProcessManager) {
        self.processManager = processManager
    }
    
    func execute(args: SystemCallArguments) -> SystemCallResult {
        guard let path = args.string(at: 0) else {
            return .failure(.invalidArgument)
        }
        
        if processManager.exec(path: path) {
            return .success(nil)
        }
        return .failure(.fileNotFound)
    }
}

class ExitHandler: SystemCallHandler {
    let processManager: ProcessManager
    
    init(processManager: ProcessManager) {
        self.processManager = processManager
    }
    
    func execute(args: SystemCallArguments) -> SystemCallResult {
        let exitCode = args.int(at: 0) ?? 0
        processManager.exit(code: exitCode)
        return .success(nil)
    }
}

class WaitHandler: SystemCallHandler {
    let processManager: ProcessManager
    
    init(processManager: ProcessManager) {
        self.processManager = processManager
    }
    
    func execute(args: SystemCallArguments) -> SystemCallResult {
        if let status = processManager.wait() {
            return .success(status)
        }
        return .failure(.interrupted)
    }
}

class GetPidHandler: SystemCallHandler {
    let processManager: ProcessManager
    
    init(processManager: ProcessManager) {
        self.processManager = processManager
    }
    
    func execute(args: SystemCallArguments) -> SystemCallResult {
        return .success(processManager.currentProcess?.pid)
    }
}

class KillHandler: SystemCallHandler {
    let processManager: ProcessManager
    
    init(processManager: ProcessManager) {
        self.processManager = processManager
    }
    
    func execute(args: SystemCallArguments) -> SystemCallResult {
        guard let pid = args.int(at: 0),
              let signal = args.int(at: 1) else {
            return .failure(.invalidArgument)
        }
        
        if processManager.kill(pid: pid, signal: signal) {
            return .success(nil)
        }
        return .failure(.invalidArgument)
    }
}

// File System Handlers
class OpenHandler: SystemCallHandler {
    let fileSystem: FileSystemManager
    
    init(fileSystem: FileSystemManager) {
        self.fileSystem = fileSystem
    }
    
    func execute(args: SystemCallArguments) -> SystemCallResult {
        guard let path = args.string(at: 0) else {
            return .failure(.invalidArgument)
        }
        
        let flags = args.int(at: 1) ?? 0
        let mode = args.int(at: 2) ?? 0644
        
        if let fd = fileSystem.open(path: path, flags: flags, mode: mode) {
            return .success(fd)
        }
        return .failure(.fileNotFound)
    }
}

class CloseHandler: SystemCallHandler {
    let fileSystem: FileSystemManager
    
    init(fileSystem: FileSystemManager) {
        self.fileSystem = fileSystem
    }
    
    func execute(args: SystemCallArguments) -> SystemCallResult {
        guard let fd = args.int(at: 0) else {
            return .failure(.invalidArgument)
        }
        
        if fileSystem.close(fd: fd) {
            return .success(nil)
        }
        return .failure(.invalidArgument)
    }
}

class ReadHandler: SystemCallHandler {
    let fileSystem: FileSystemManager
    
    init(fileSystem: FileSystemManager) {
        self.fileSystem = fileSystemManager
    }
    
    func execute(args: SystemCallArguments) -> SystemCallResult {
        guard let fd = args.int(at: 0),
              let count = args.int(at: 1) else {
            return .failure(.invalidArgument)
        }
        
        if let data = fileSystem.read(fd: fd, count: count) {
            return .success(data)
        }
        return .failure(.ioError)
    }
}

class WriteHandler: SystemCallHandler {
    let fileSystem: FileSystemManager
    
    init(fileSystem: FileSystemManager) {
        self.fileSystem = fileSystemManager
    }
    
    func execute(args: SystemCallArguments) -> SystemCallResult {
        guard let fd = args.int(at: 0),
              let data = args.data(at: 1) else {
            return .failure(.invalidArgument)
        }
        
        let bytesWritten = fileSystem.write(fd: fd, data: data)
        return .success(bytesWritten)
    }
}

class MkdirHandler: SystemCallHandler {
    let fileSystem: FileSystemManager
    
    init(fileSystem: FileSystemManager) {
        self.fileSystem = fileSystemManager
    }
    
    func execute(args: SystemCallArguments) -> SystemCallResult {
        guard let path = args.string(at: 0) else {
            return .failure(.invalidArgument)
        }
        
        let mode = args.int(at: 1) ?? 0755
        
        if fileSystem.mkdir(path: path, mode: mode) {
            return .success(nil)
        }
        return .failure(.accessDenied)
    }
}

// Memory Management Handlers
class MmapHandler: SystemCallHandler {
    let memoryManager: AdvancedMemoryManager
    
    init(memoryManager: AdvancedMemoryManager) {
        self.memoryManager = memoryManager
    }
    
    func execute(args: SystemCallArguments) -> SystemCallResult {
        guard let size = args.int(at: 0) else {
            return .failure(.invalidArgument)
        }
        
        let protection = MemoryProtection(rawValue: UInt32(args.int(at: 1) ?? 0))
        let flags = MMapFlags(rawValue: UInt32(args.int(at: 2) ?? 0))
        
        if let address = memoryManager.mmap(size: size, protection: protection, flags: flags) {
            return .success(address)
        }
        return .failure(.outOfMemory)
    }
}

class MunmapHandler: SystemCallHandler {
    let memoryManager: AdvancedMemoryManager
    
    init(memoryManager: AdvancedMemoryManager) {
        self.memoryManager = memoryManager
    }
    
    func execute(args: SystemCallArguments) -> SystemCallResult {
        guard let addressValue = args.int(at: 0),
              let size = args.int(at: 1) else {
            return .failure(.invalidArgument)
        }
        
        let address = VirtualAddress(value: UInt64(addressValue))
        memoryManager.munmap(address: address, size: size)
        return .success(nil)
    }
}

class BrkHandler: SystemCallHandler {
    let memoryManager: AdvancedMemoryManager
    
    init(memoryManager: AdvancedMemoryManager) {
        self.memoryManager = memoryManager
    }
    
    func execute(args: SystemCallArguments) -> SystemCallResult {
        guard let newBrk = args.int(at: 0) else {
            return .failure(.invalidArgument)
        }
        
        // Simulate brk system call
        return .success(newBrk)
    }
}

// Network Handlers
class SocketHandler: SystemCallHandler {
    let networkManager: NetworkManager
    
    init(networkManager: NetworkManager) {
        self.networkManager = networkManager
    }
    
    func execute(args: SystemCallArguments) -> SystemCallResult {
        // Create socket
        return .success(Int.random(in: 100...999)) // Return socket fd
    }
}

class ConnectHandler: SystemCallHandler {
    let networkManager: NetworkManager
    
    init(networkManager: NetworkManager) {
        self.networkManager = networkManager
    }
    
    func execute(args: SystemCallArguments) -> SystemCallResult {
        guard let sockfd = args.int(at: 0),
              let address = args.string(at: 1),
              let port = args.int(at: 2) else {
            return .failure(.invalidArgument)
        }
        
        let connection = networkManager.createConnection(to: address, port: port, protocol: .tcp)
        return .success(nil)
    }
}

class SendHandler: SystemCallHandler {
    let networkManager: NetworkManager
    
    init(networkManager: NetworkManager) {
        self.networkManager = networkManager
    }
    
    func execute(args: SystemCallArguments) -> SystemCallResult {
        guard let sockfd = args.int(at: 0),
              let data = args.data(at: 1) else {
            return .failure(.invalidArgument)
        }
        
        // Send data
        return .success(data.count)
    }
}

class RecvHandler: SystemCallHandler {
    let networkManager: NetworkManager
    
    init(networkManager: NetworkManager) {
        self.networkManager = networkManager
    }
    
    func execute(args: SystemCallArguments) -> SystemCallResult {
        guard let sockfd = args.int(at: 0),
              let size = args.int(at: 1) else {
            return .failure(.invalidArgument)
        }
        
        // Receive data
        let data = Data(repeating: 0, count: size)
        return .success(data)
    }
}

// Default Handler
class DefaultHandler: SystemCallHandler {
    func execute(args: SystemCallArguments) -> SystemCallResult {
        return .failure(.operationNotSupported)
    }
}

// MARK: - Process Manager (Stub)
class ProcessManager {
    var currentProcess: ProcessInfo?
    
    struct ProcessInfo {
        let pid: Int
        let ppid: Int
        let isPrivileged: Bool
    }
    
    func fork() -> Int? {
        return Int.random(in: 1000...9999)
    }
    
    func exec(path: String) -> Bool {
        return true
    }
    
    func exit(code: Int) {
        // Exit process
    }
    
    func wait() -> Int? {
        return 0
    }
    
    func kill(pid: Int, signal: Int) -> Bool {
        return true
    }
}

// MARK: - System Call Record
class SystemCallRecord {
    let number: Int
    let name: String
    let args: SystemCallArguments
    let timestamp: Date
    let processID: Int32
    var result: SystemCallResult?
    var duration: TimeInterval?
    
    init(number: Int, name: String, args: SystemCallArguments, timestamp: Date, processID: Int32) {
        self.number = number
        self.name = name
        self.args = args
        self.timestamp = timestamp
        self.processID = processID
    }
}

// MARK: - System Call Statistics
struct SystemCallStatistics {
    var totalCalls: Int = 0
    var successfulCalls: Int = 0
    var failedCalls: Int = 0
    var callsByCategory: [SystemCallCategory: Int] = [:]
    var averageExecutionTime: TimeInterval = 0
    var maxExecutionTime: TimeInterval = 0
    var minExecutionTime: TimeInterval = Double.infinity
}
