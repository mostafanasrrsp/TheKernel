import Foundation

// Advanced Memory Manager with virtual memory support
class MemoryManager: ObservableObject {
    @Published var totalMemory: UInt64 = 0
    @Published var usedMemory: UInt64 = 0
    @Published var freeMemory: UInt64 = 0
    @Published var cachedMemory: UInt64 = 0
    @Published var swapUsed: UInt64 = 0
    @Published var swapTotal: UInt64 = 0
    
    private var memoryPages: [MemoryPage] = []
    private var pageTable: [Int: [PageTableEntry]] = [:] // Process ID to page table
    private var freeList: [MemoryPage] = []
    private var allocationMap: [Int: [MemoryBlock]] = [:] // Process ID to memory blocks
    
    private let pageSize: Int = 4096 // 4KB pages
    private var nextFreeAddress: UInt64 = 0x1000 // Start after reserved memory
    
    // Memory zones
    private var kernelSpace: MemoryZone!
    private var userSpace: MemoryZone!
    private var deviceSpace: MemoryZone!
    
    // Cache management
    private var pageCache: PageCache
    private var tlbCache: TLBCache // Translation Lookaside Buffer
    
    init() {
        self.pageCache = PageCache()
        self.tlbCache = TLBCache()
    }
    
    func initializeMemory(totalSize: UInt64) {
        self.totalMemory = totalSize
        self.freeMemory = totalSize
        
        // Setup memory zones
        setupMemoryZones()
        
        // Initialize page structures
        let pageCount = Int(totalSize / UInt64(pageSize))
        for i in 0..<pageCount {
            let page = MemoryPage(
                pageNumber: i,
                physicalAddress: UInt64(i * pageSize),
                size: pageSize,
                state: .free
            )
            memoryPages.append(page)
            freeList.append(page)
        }
        
        // Reserve kernel memory
        reserveKernelMemory()
    }
    
    private func setupMemoryZones() {
        // Kernel space: 0x0 - 0x7FFFFFFF (2GB)
        kernelSpace = MemoryZone(
            name: "Kernel",
            startAddress: 0x0,
            endAddress: 0x7FFFFFFF,
            protection: .kernelOnly
        )
        
        // User space: 0x80000000 - 0x3FFFFFFFF (14GB)
        userSpace = MemoryZone(
            name: "User",
            startAddress: 0x80000000,
            endAddress: 0x3FFFFFFFF,
            protection: .userAccessible
        )
        
        // Device space: 0x400000000 - 0x4FFFFFFFF (4GB)
        deviceSpace = MemoryZone(
            name: "Device",
            startAddress: 0x400000000,
            endAddress: 0x4FFFFFFFF,
            protection: .deviceOnly
        )
    }
    
    private func reserveKernelMemory() {
        // Reserve first 256MB for kernel
        let kernelPages = 256 * 1024 * 1024 / pageSize
        for i in 0..<kernelPages {
            if i < memoryPages.count {
                memoryPages[i].state = .allocated
                memoryPages[i].processId = 0 // Kernel process ID
                freeList.removeAll { $0.pageNumber == i }
            }
        }
        usedMemory += UInt64(kernelPages * pageSize)
        freeMemory -= UInt64(kernelPages * pageSize)
    }
    
    // MARK: - Virtual Memory Management
    func setupVirtualMemory() {
        // Setup swap file
        swapTotal = 4 * 1024 * 1024 * 1024 // 4GB swap
        
        // Initialize page replacement algorithm (LRU)
        pageCache.initialize()
    }
    
    func createPageTable(for processId: Int) -> [PageTableEntry] {
        var pageTable: [PageTableEntry] = []
        
        // Create virtual address space for process
        for i in 0..<1024 { // 1024 pages per process initially
            let entry = PageTableEntry(
                virtualPage: i,
                physicalPage: nil, // Not mapped initially
                present: false,
                dirty: false,
                accessed: false,
                protection: .readWrite
            )
            pageTable.append(entry)
        }
        
        self.pageTable[processId] = pageTable
        return pageTable
    }
    
    // MARK: - Memory Allocation
    func allocate(size: Int, for processId: Int) -> MemoryBlock? {
        let pagesNeeded = (size + pageSize - 1) / pageSize
        
        guard freeList.count >= pagesNeeded else {
            // Try to free some memory
            performGarbageCollection()
            guard freeList.count >= pagesNeeded else {
                return nil // Out of memory
            }
        }
        
        var allocatedPages: [MemoryPage] = []
        for _ in 0..<pagesNeeded {
            if let page = freeList.popLast() {
                page.state = .allocated
                page.processId = processId
                allocatedPages.append(page)
            }
        }
        
        let block = MemoryBlock(
            address: allocatedPages.first?.physicalAddress ?? 0,
            size: size,
            processId: processId
        )
        
        // Update allocation map
        if allocationMap[processId] == nil {
            allocationMap[processId] = []
        }
        allocationMap[processId]?.append(block)
        
        // Update memory counters
        usedMemory += UInt64(size)
        freeMemory -= UInt64(size)
        
        return block
    }
    
    func free(block: MemoryBlock) {
        // Find and free pages
        let startPage = Int(block.address / UInt64(pageSize))
        let pageCount = (block.size + pageSize - 1) / pageSize
        
        for i in startPage..<(startPage + pageCount) {
            if i < memoryPages.count {
                memoryPages[i].state = .free
                memoryPages[i].processId = nil
                freeList.append(memoryPages[i])
            }
        }
        
        // Remove from allocation map
        allocationMap[block.processId]?.removeAll { $0.address == block.address }
        
        // Update memory counters
        usedMemory -= UInt64(block.size)
        freeMemory += UInt64(block.size)
    }
    
    func freeMemory(for processId: Int) {
        guard let blocks = allocationMap[processId] else { return }
        
        for block in blocks {
            free(block: block)
        }
        
        allocationMap[processId] = nil
        pageTable[processId] = nil
    }
    
    // MARK: - Page Fault Handling
    func handlePageFault(virtualAddress: UInt64 = 0, processId: Int = 0) {
        // Find the page table entry
        guard let pageTable = pageTable[processId] else { return }
        
        let virtualPage = Int(virtualAddress / UInt64(pageSize))
        guard virtualPage < pageTable.count else { return }
        
        var entry = pageTable[virtualPage]
        
        if !entry.present {
            // Page not in memory, need to load it
            if let physicalPage = allocatePhysicalPage() {
                entry.physicalPage = physicalPage.pageNumber
                entry.present = true
                
                // Check if page is in swap
                if swapUsed > 0 {
                    loadFromSwap(virtualPage: virtualPage, physicalPage: physicalPage)
                }
            } else {
                // No free physical pages, need to swap out a page
                performPageReplacement(for: entry)
            }
        }
        
        entry.accessed = true
        self.pageTable[processId]?[virtualPage] = entry
    }
    
    private func allocatePhysicalPage() -> MemoryPage? {
        return freeList.popLast()
    }
    
    private func loadFromSwap(virtualPage: Int, physicalPage: MemoryPage) {
        // Simulate loading from swap
        swapUsed = max(0, swapUsed - UInt64(pageSize))
    }
    
    private func performPageReplacement(for entry: PageTableEntry) {
        // LRU page replacement
        if let victimPage = pageCache.findLRUPage() {
            // Write victim to swap if dirty
            if victimPage.dirty {
                writeToSwap(page: victimPage)
            }
            
            // Use victim's physical page for new allocation
            // Update page tables accordingly
        }
    }
    
    private func writeToSwap(page: CachedPage) {
        swapUsed = min(swapTotal, swapUsed + UInt64(pageSize))
    }
    
    // MARK: - Garbage Collection
    private func performGarbageCollection() {
        // Mark and sweep garbage collection
        var reachablePages = Set<Int>()
        
        // Mark phase - find all reachable pages
        for (_, blocks) in allocationMap {
            for block in blocks {
                let startPage = Int(block.address / UInt64(pageSize))
                let pageCount = (block.size + pageSize - 1) / pageSize
                for i in startPage..<(startPage + pageCount) {
                    reachablePages.insert(i)
                }
            }
        }
        
        // Sweep phase - free unreachable pages
        for (index, page) in memoryPages.enumerated() {
            if page.state == .allocated && !reachablePages.contains(index) {
                page.state = .free
                page.processId = nil
                freeList.append(page)
                
                let freedSize = UInt64(pageSize)
                usedMemory -= freedSize
                freeMemory += freedSize
            }
        }
    }
    
    // MARK: - Memory Statistics
    func getUsedMemory() -> UInt64 {
        return usedMemory
    }
    
    func getTotalMemory() -> UInt64 {
        return totalMemory
    }
    
    func getMemoryInfo() -> MemoryInfo {
        return MemoryInfo(
            total: totalMemory,
            used: usedMemory,
            free: freeMemory,
            cached: cachedMemory,
            swapTotal: swapTotal,
            swapUsed: swapUsed
        )
    }
    
    func cleanup() {
        // Cleanup all memory structures
        memoryPages.removeAll()
        freeList.removeAll()
        allocationMap.removeAll()
        pageTable.removeAll()
    }
}

// MARK: - Supporting Types
class MemoryPage {
    let pageNumber: Int
    let physicalAddress: UInt64
    let size: Int
    var state: PageState
    var processId: Int?
    var lastAccessed: Date = Date()
    
    init(pageNumber: Int, physicalAddress: UInt64, size: Int, state: PageState) {
        self.pageNumber = pageNumber
        self.physicalAddress = physicalAddress
        self.size = size
        self.state = state
    }
}

enum PageState {
    case free, allocated, cached, swapped
}

struct PageTableEntry {
    var virtualPage: Int
    var physicalPage: Int?
    var present: Bool
    var dirty: Bool
    var accessed: Bool
    var protection: PageProtection
}

enum PageProtection {
    case readOnly, readWrite, execute, noAccess
}

struct MemoryZone {
    let name: String
    let startAddress: UInt64
    let endAddress: UInt64
    let protection: ZoneProtection
}

enum ZoneProtection {
    case kernelOnly, userAccessible, deviceOnly
}

struct MemoryInfo {
    let total: UInt64
    let used: UInt64
    let free: UInt64
    let cached: UInt64
    let swapTotal: UInt64
    let swapUsed: UInt64
}

// Page Cache for caching frequently accessed pages
class PageCache {
    private var cache: [Int: CachedPage] = [:]
    private var lruList: [Int] = []
    
    func initialize() {
        cache.removeAll()
        lruList.removeAll()
    }
    
    func findLRUPage() -> CachedPage? {
        guard let pageId = lruList.first else { return nil }
        return cache[pageId]
    }
    
    func addPage(_ page: CachedPage) {
        cache[page.id] = page
        lruList.append(page.id)
    }
    
    func accessPage(_ pageId: Int) {
        if let index = lruList.firstIndex(of: pageId) {
            lruList.remove(at: index)
            lruList.append(pageId)
        }
    }
}

struct CachedPage {
    let id: Int
    var dirty: Bool
    var data: Data?
}

// TLB Cache for fast virtual to physical address translation
class TLBCache {
    private var cache: [UInt64: UInt64] = [:] // Virtual to physical mapping
    
    func lookup(_ virtualAddress: UInt64) -> UInt64? {
        return cache[virtualAddress]
    }
    
    func insert(_ virtualAddress: UInt64, physicalAddress: UInt64) {
        cache[virtualAddress] = physicalAddress
    }
    
    func invalidate() {
        cache.removeAll()
    }
}