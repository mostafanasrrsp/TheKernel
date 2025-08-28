import Foundation

// File System Manager - Virtual file system management
class FileSystemManager: ObservableObject {
    @Published var rootDirectory: Directory
    @Published var currentDirectory: Directory
    @Published var recentFiles: [VirtualFile] = []
    @Published var favoriteDirectories: [Directory] = []
    
    private var fileSystemTree: [String: FileSystemNode] = [:]
    private let maxRecentFiles = 20
    
    init() {
        // Initialize root directory
        self.rootDirectory = Directory(name: "/", path: "/", parent: nil)
        self.currentDirectory = rootDirectory
        
        // Create default directory structure
        createDefaultFileSystem()
    }
    
    private func createDefaultFileSystem() {
        // Create system directories
        let system = createDirectory(at: "/System", in: rootDirectory)
        let library = createDirectory(at: "/Library", in: rootDirectory)
        let applications = createDirectory(at: "/Applications", in: rootDirectory)
        let users = createDirectory(at: "/Users", in: rootDirectory)
        
        // Create user directories
        let userHome = createDirectory(at: "/Users/radiate", in: users)
        let desktop = createDirectory(at: "/Users/radiate/Desktop", in: userHome)
        let documents = createDirectory(at: "/Users/radiate/Documents", in: userHome)
        let downloads = createDirectory(at: "/Users/radiate/Downloads", in: userHome)
        let pictures = createDirectory(at: "/Users/radiate/Pictures", in: userHome)
        let music = createDirectory(at: "/Users/radiate/Music", in: userHome)
        let videos = createDirectory(at: "/Users/radiate/Videos", in: userHome)
        
        // Create system files
        createSystemFiles(in: system)
        
        // Create sample files
        createSampleFiles(in: documents)
        
        // Set favorites
        favoriteDirectories = [desktop, documents, downloads]
    }
    
    private func createSystemFiles(in directory: Directory) {
        // Kernel files
        let _ = createFile(
            name: "kernel",
            extension: "sys",
            content: "RadiateOS Kernel Binary",
            size: 15_234_567,
            in: directory
        )
        
        let _ = createFile(
            name: "optical_driver",
            extension: "drv",
            content: "Optical CPU Driver",
            size: 2_456_789,
            in: directory
        )
        
        let _ = createFile(
            name: "boot",
            extension: "efi",
            content: "Boot Loader",
            size: 524_288,
            in: directory
        )
    }
    
    private func createSampleFiles(in directory: Directory) {
        let _ = createFile(
            name: "Welcome",
            extension: "txt",
            content: "Welcome to RadiateOS!\n\nThis is your new optical computing operating system.",
            size: 1024,
            in: directory
        )
        
        let _ = createFile(
            name: "README",
            extension: "md",
            content: "# RadiateOS Documentation\n\n## Features\n- Optical Computing\n- Advanced Memory Management\n- Multi-level Scheduler",
            size: 2048,
            in: directory
        )
    }
    
    // MARK: - Directory Operations
    
    @discardableResult
    func createDirectory(at path: String, in parent: Directory) -> Directory {
        let name = URL(fileURLWithPath: path).lastPathComponent
        let directory = Directory(name: name, path: path, parent: parent)
        parent.addChild(directory)
        fileSystemTree[path] = directory
        return directory
    }
    
    func deleteDirectory(_ directory: Directory) -> Bool {
        guard directory != rootDirectory else { return false }
        
        // Remove from parent
        directory.parent?.removeChild(directory)
        
        // Remove from tree
        fileSystemTree.removeValue(forKey: directory.path)
        
        // Recursively remove children
        for child in directory.children {
            if let childDir = child as? Directory {
                deleteDirectory(childDir)
            } else if let childFile = child as? VirtualFile {
                deleteFile(childFile)
            }
        }
        
        return true
    }
    
    func moveDirectory(_ directory: Directory, to newParent: Directory) -> Bool {
        guard directory != rootDirectory else { return false }
        
        // Remove from old parent
        directory.parent?.removeChild(directory)
        
        // Add to new parent
        newParent.addChild(directory)
        directory.parent = newParent
        
        // Update path
        let newPath = "\(newParent.path)/\(directory.name)"
        fileSystemTree.removeValue(forKey: directory.path)
        directory.path = newPath
        fileSystemTree[newPath] = directory
        
        return true
    }
    
    // MARK: - File Operations
    
    @discardableResult
    func createFile(name: String, extension ext: String?, content: String, size: Int64, in directory: Directory) -> VirtualFile {
        let fileName = ext != nil ? "\(name).\(ext!)" : name
        let filePath = "\(directory.path)/\(fileName)"
        
        let file = VirtualFile(
            name: fileName,
            path: filePath,
            size: size,
            content: content,
            parent: directory
        )
        
        directory.addChild(file)
        fileSystemTree[filePath] = file
        
        // Add to recent files
        addToRecentFiles(file)
        
        return file
    }
    
    func createFile(at path: String, content: String) -> Bool {
        let url = URL(fileURLWithPath: path)
        let fileName = url.lastPathComponent
        let directoryPath = url.deletingLastPathComponent().path
        
        guard let directory = fileSystemTree[directoryPath] as? Directory else {
            return false
        }
        
        let file = createFile(
            name: url.deletingPathExtension().lastPathComponent,
            extension: url.pathExtension.isEmpty ? nil : url.pathExtension,
            content: content,
            size: Int64(content.count),
            in: directory
        )
        
        return file != nil
    }
    
    func readFile(at path: String) -> String? {
        guard let file = fileSystemTree[path] as? VirtualFile else {
            return nil
        }
        
        // Update access time
        file.lastAccessed = Date()
        
        // Add to recent files
        addToRecentFiles(file)
        
        return file.content
    }
    
    func deleteFile(at path: String) -> Bool {
        guard let file = fileSystemTree[path] as? VirtualFile else {
            return false
        }
        
        return deleteFile(file)
    }
    
    func deleteFile(_ file: VirtualFile) -> Bool {
        // Remove from parent
        file.parent?.removeChild(file)
        
        // Remove from tree
        fileSystemTree.removeValue(forKey: file.path)
        
        // Remove from recent files
        recentFiles.removeAll { $0.path == file.path }
        
        return true
    }
    
    func moveFile(_ file: VirtualFile, to directory: Directory) -> Bool {
        // Remove from old parent
        file.parent?.removeChild(file)
        
        // Add to new parent
        directory.addChild(file)
        file.parent = directory
        
        // Update path
        let newPath = "\(directory.path)/\(file.name)"
        fileSystemTree.removeValue(forKey: file.path)
        file.path = newPath
        fileSystemTree[newPath] = file
        
        return true
    }
    
    func copyFile(_ file: VirtualFile, to directory: Directory) -> VirtualFile? {
        let copiedFile = createFile(
            name: file.name,
            extension: nil,
            content: file.content,
            size: file.size,
            in: directory
        )
        
        return copiedFile
    }
    
    // MARK: - Navigation
    
    func navigateTo(_ directory: Directory) {
        currentDirectory = directory
    }
    
    func navigateToPath(_ path: String) -> Bool {
        guard let node = fileSystemTree[path] as? Directory else {
            return false
        }
        
        currentDirectory = node
        return true
    }
    
    func listDirectory(at path: String) -> [String] {
        guard let directory = fileSystemTree[path] as? Directory else {
            return []
        }
        
        return directory.children.map { $0.name }
    }
    
    // MARK: - Search
    
    func search(query: String, in directory: Directory? = nil) -> [FileSystemNode] {
        let searchDirectory = directory ?? rootDirectory
        var results: [FileSystemNode] = []
        
        searchRecursively(query: query.lowercased(), in: searchDirectory, results: &results)
        
        return results
    }
    
    private func searchRecursively(query: String, in directory: Directory, results: inout [FileSystemNode]) {
        for child in directory.children {
            if child.name.lowercased().contains(query) {
                results.append(child)
            }
            
            if let childDir = child as? Directory {
                searchRecursively(query: query, in: childDir, results: &results)
            }
        }
    }
    
    // MARK: - Utilities
    
    private func addToRecentFiles(_ file: VirtualFile) {
        // Remove if already exists
        recentFiles.removeAll { $0.path == file.path }
        
        // Add to beginning
        recentFiles.insert(file, at: 0)
        
        // Limit size
        if recentFiles.count > maxRecentFiles {
            recentFiles.removeLast()
        }
    }
    
    func getFileInfo(_ path: String) -> FileInfo? {
        guard let node = fileSystemTree[path] else { return nil }
        
        return FileInfo(
            name: node.name,
            path: node.path,
            size: node.size,
            isDirectory: node is Directory,
            created: node.created,
            modified: node.modified,
            accessed: node.lastAccessed
        )
    }
    
    func calculateDirectorySize(_ directory: Directory) -> Int64 {
        var totalSize: Int64 = 0
        
        for child in directory.children {
            if let file = child as? VirtualFile {
                totalSize += file.size
            } else if let subDir = child as? Directory {
                totalSize += calculateDirectorySize(subDir)
            }
        }
        
        return totalSize
    }
}

// MARK: - File System Node Protocol
protocol FileSystemNode: AnyObject {
    var name: String { get set }
    var path: String { get set }
    var size: Int64 { get }
    var created: Date { get }
    var modified: Date { get set }
    var lastAccessed: Date { get set }
    var parent: Directory? { get set }
}

// MARK: - Directory Class
class Directory: FileSystemNode, ObservableObject {
    @Published var name: String
    @Published var path: String
    @Published var children: [FileSystemNode] = []
    var parent: Directory?
    let created: Date
    var modified: Date
    var lastAccessed: Date
    
    var size: Int64 {
        return children.reduce(0) { $0 + $1.size }
    }
    
    init(name: String, path: String, parent: Directory?) {
        self.name = name
        self.path = path
        self.parent = parent
        self.created = Date()
        self.modified = Date()
        self.lastAccessed = Date()
    }
    
    func addChild(_ node: FileSystemNode) {
        children.append(node)
        modified = Date()
    }
    
    func removeChild(_ node: FileSystemNode) {
        children.removeAll { $0 === node }
        modified = Date()
    }
    
    func getChild(named name: String) -> FileSystemNode? {
        return children.first { $0.name == name }
    }
}

// MARK: - Virtual File Class
class VirtualFile: FileSystemNode, ObservableObject {
    @Published var name: String
    @Published var path: String
    @Published var size: Int64
    @Published var content: String
    var parent: Directory?
    let created: Date
    var modified: Date
    var lastAccessed: Date
    
    init(name: String, path: String, size: Int64, content: String, parent: Directory?) {
        self.name = name
        self.path = path
        self.size = size
        self.content = content
        self.parent = parent
        self.created = Date()
        self.modified = Date()
        self.lastAccessed = Date()
    }
    
    func updateContent(_ newContent: String) {
        content = newContent
        size = Int64(newContent.count)
        modified = Date()
    }
}

// MARK: - File Info Structure
struct FileInfo {
    let name: String
    let path: String
    let size: Int64
    let isDirectory: Bool
    let created: Date
    let modified: Date
    let accessed: Date
    
    var formattedSize: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }
}