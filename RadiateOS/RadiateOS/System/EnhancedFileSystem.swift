//
//  EnhancedFileSystem.swift
//  RadiateOS
//
//  Advanced file system with real file operations and storage
//

import SwiftUI
import Foundation

@MainActor
class EnhancedFileSystem: ObservableObject {
    public enum FileSystemError: Error {
        case fileNotFound
        case directoryNotFound
        case permissionDenied
        case fileExists
        case invalidPath
        case diskFull
        case ioError
        case notADirectory
        case isADirectory
    }

    public enum FileType: String {
        case regular = "-"
        case directory = "d"
        case symlink = "l"
        case blockDevice = "b"
        case characterDevice = "c"
        case fifo = "p"
        case socket = "s"
    }

    public enum FilePermission: OptionSet {
        public let rawValue: UInt16

        public init(rawValue: UInt16) {
            self.rawValue = rawValue
        }

        public static let read = FilePermission(rawValue: 1 << 8)
        public static let write = FilePermission(rawValue: 1 << 7)
        public static let execute = FilePermission(rawValue: 1 << 6)
        public static let setuid = FilePermission(rawValue: 1 << 11)
        public static let setgid = FilePermission(rawValue: 1 << 10)
        public static let sticky = FilePermission(rawValue: 1 << 9)

        public static let userRead = FilePermission(rawValue: 1 << 8)
        public static let userWrite = FilePermission(rawValue: 1 << 7)
        public static let userExecute = FilePermission(rawValue: 1 << 6)
        public static let groupRead = FilePermission(rawValue: 1 << 5)
        public static let groupWrite = FilePermission(rawValue: 1 << 4)
        public static let groupExecute = FilePermission(rawValue: 1 << 3)
        public static let otherRead = FilePermission(rawValue: 1 << 2)
        public static let otherWrite = FilePermission(rawValue: 1 << 1)
        public static let otherExecute = FilePermission(rawValue: 1 << 0)

        public static let userAll: FilePermission = [.userRead, .userWrite, .userExecute]
        public static let groupAll: FilePermission = [.groupRead, .groupWrite, .groupExecute]
        public static let otherAll: FilePermission = [.otherRead, .otherWrite, .otherExecute]
        public static let all: FilePermission = [.userAll, .groupAll, .otherAll]

        public static let userReadWrite: FilePermission = [.userRead, .userWrite]
        public static let userReadExecute: FilePermission = [.userRead, .userExecute]
        public static let groupReadWrite: FilePermission = [.groupRead, .groupWrite]
        public static let otherReadWrite: FilePermission = [.otherRead, .otherWrite]
    }

    public struct FileAttributes {
        public let inode: UInt64
        public let type: FileType
        public let size: UInt64
        public let permissions: FilePermission
        public let uid: UInt32
        public let gid: UInt32
        public let accessTime: Date
        public let modificationTime: Date
        public let changeTime: Date
        public let birthTime: Date
        public let nlink: UInt32
        public let blockSize: UInt32
        public let blocks: UInt64
        public let flags: UInt32

        public init(
            inode: UInt64,
            type: FileType,
            size: UInt64,
            permissions: FilePermission,
            uid: UInt32 = 1000,
            gid: UInt32 = 1000,
            accessTime: Date = Date(),
            modificationTime: Date = Date(),
            changeTime: Date = Date(),
            birthTime: Date = Date(),
            nlink: UInt32 = 1,
            blockSize: UInt32 = 4096,
            blocks: UInt64 = 0,
            flags: UInt32 = 0
        ) {
            self.inode = inode
            self.type = type
            self.size = size
            self.permissions = permissions
            self.uid = uid
            self.gid = gid
            self.accessTime = accessTime
            self.modificationTime = modificationTime
            self.changeTime = changeTime
            self.birthTime = birthTime
            self.nlink = nlink
            self.blockSize = blockSize
            self.blocks = blocks
            self.flags = flags
        }

        public var octalPermissions: String {
            let user = permissionBits(permissions, for: .userAll)
            let group = permissionBits(permissions, for: .groupAll)
            let other = permissionBits(permissions, for: .otherAll)
            return "\(user)\(group)\(other)"
        }

        private func permissionBits(_ permissions: FilePermission, for mask: FilePermission) -> Int {
            var bits = 0
            if permissions.contains(.userRead) && mask.contains(.userRead) { bits += 4 }
            if permissions.contains(.userWrite) && mask.contains(.userWrite) { bits += 2 }
            if permissions.contains(.userExecute) && mask.contains(.userExecute) { bits += 1 }
            return bits
        }
    }

    public struct FileItem {
        public let name: String
        public let path: String
        public let attributes: FileAttributes
        public let isDirectory: Bool
        public let size: UInt64
        public let modifiedDate: Date

        public init(name: String, path: String, attributes: FileAttributes) {
            self.name = name
            self.path = path
            self.attributes = attributes
            self.isDirectory = attributes.type == .directory
            self.size = attributes.size
            self.modifiedDate = attributes.modificationTime
        }
    }

    // File system storage
    private var fileStorage: [String: Data] = [:] // Path -> File content
    private var directoryContents: [String: [String]] = [:] // Directory path -> Child names
    private var fileAttributes: [String: FileAttributes] = [:] // Path -> Attributes
    private var inodes: [UInt64: String] = [:] // Inode -> Path
    private var nextInode: UInt64 = 1

    // Current working directory and user info
    private(set) public var currentDirectory: String
    private let currentUserName: String
    private let currentUID: UInt32 = 1000
    private let currentGID: UInt32 = 1000

    public init(currentUserName: String) {
        self.currentUserName = currentUserName
        self.currentDirectory = "/Users/\(currentUserName)"
        setupFileSystem()
    }

    // MARK: - File System Setup

    private func setupFileSystem() {
        print("🔧 Setting up enhanced file system...")

        // Create root directory
        createDirectoryInternal(path: "/", permissions: [.userAll, .groupRead, .groupExecute, .otherRead, .otherExecute])

        // Create standard directories
        let standardDirs = [
            "/bin", "/boot", "/dev", "/etc", "/home", "/lib", "/media", "/mnt",
            "/opt", "/proc", "/root", "/run", "/sbin", "/srv", "/sys", "/tmp",
            "/usr", "/var", "/Users", "/Applications", "/System", "/Library"
        ]

        for dir in standardDirs {
            createDirectoryInternal(path: dir, permissions: [.userAll, .groupRead, .groupExecute, .otherRead, .otherExecute])
        }

        // Create user home directory
        createDirectoryInternal(path: currentDirectory, permissions: [.userAll])

        // Create user subdirectories
        let userDirs = ["Documents", "Downloads", "Desktop", "Pictures", "Music", "Videos"]
        for dir in userDirs {
            createDirectoryInternal(path: "\(currentDirectory)/\(dir)", permissions: [.userAll])
        }

        // Create some system files
        createSystemFiles()

        print("✅ Enhanced file system setup complete")
    }

    private func createSystemFiles() {
        // Kernel configuration
        let kernelConfig = """
# RadiateOS Kernel Configuration
optical_cpu_enabled=true
memory_manager=advanced
rom_hot_swap=true
translation_layer=x86_64
debug_mode=false
scheduler=priority
filesystem=enhanced
networking=enabled
security=enabled

# Optical CPU Settings
cpu_frequency=2.5THz
cpu_cores=4
wavelength=1550nm
power_efficiency=true

# Memory Settings
total_memory=8GB
kernel_memory=2GB
user_memory=6GB
page_size=4KB

# File System Settings
max_file_size=1TB
max_open_files=65536
case_sensitive=true
unicode_support=true
"""

        try? writeFile(at: "/etc/kernel.conf", content: kernelConfig)

        // System information
        let systemInfo = """
RadiateOS System Information
============================
Kernel: RadiateOS 1.0.0 (Optical-x64)
Architecture: Optical Computing Platform
CPU: 4-core Optical Processor @ 2.5THz
Memory: 8GB Optical RAM
Storage: Virtual File System
Network: Integrated Photonic Network
Graphics: Optical Display Interface

Build Date: \(DateFormatter.iso8601.string(from: Date()))
Uptime: System Ready
Load Average: 0.02, 0.05, 0.08
Processes: 42 running
Users: 1 online
"""

        try? writeFile(at: "/etc/systeminfo", content: systemInfo)

        // Welcome message
        let welcome = """
Welcome to RadiateOS!
=====================

This is a revolutionary optical computing operating system featuring:

🖥️  Optical CPU processing with photonic gates
🧠  Advanced neural network acceleration
💾  High-speed optical memory management
🌐  Integrated quantum networking
🔒  Advanced security with photonic encryption
📱  Universal device compatibility

Getting Started:
- Use 'ls' to list files
- Use 'cd' to change directories
- Use 'help' for more commands
- Use 'system' for system information

Enjoy your optical computing experience!
"""

        try? writeFile(at: "\(currentDirectory)/README.txt", content: welcome)

        // Sample configuration
        let bashrc = """
# RadiateOS Shell Configuration

export PATH="/bin:/usr/bin:/usr/local/bin:/opt/bin:$PATH"
export HOME="/Users/\(currentUserName)"
export USER="\(currentUserName)"
export SHELL="/bin/radiatesh"
export TERM="radiateos-terminal"
export LANG="en_US.UTF-8"
export EDITOR="nano"

# Aliases
alias ll='ls -la'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ../..'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# Functions
cls() { clear; }
sysinfo() { uname -a && echo && cat /etc/systeminfo; }

# Welcome message
echo "Welcome to RadiateOS, \(currentUserName)!"
echo "Type 'help' for available commands."
"""

        try? writeFile(at: "\(currentDirectory)/.bashrc", content: bashrc)
    }

    // MARK: - Directory Operations

    public func listContents(of path: String) async throws -> [FileItem] {
        let resolvedPath = resolvePath(path)
        guard let contents = directoryContents[resolvedPath] else {
            throw FileSystemError.directoryNotFound
        }

        var items: [FileItem] = []
        for name in contents {
            let itemPath = resolvedPath == "/" ? "/\(name)" : "\(resolvedPath)/\(name)"
            guard let attributes = fileAttributes[itemPath] else { continue }

            let item = FileItem(
                name: name,
                path: itemPath,
                attributes: attributes
            )
            items.append(item)
        }

        return items.sorted { $0.name < $1.name }
    }

    public func createDirectory(at path: String, permissions: FilePermission = [.userAll, .groupRead, .groupExecute, .otherRead, .otherExecute]) throws {
        let resolvedPath = resolvePath(path)

        // Check if parent directory exists
        let parentPath = getParentPath(resolvedPath)
        guard directoryContents[parentPath] != nil else {
            throw FileSystemError.directoryNotFound
        }

        // Check if file already exists
        guard fileAttributes[resolvedPath] == nil else {
            throw FileSystemError.fileExists
        }

        try createDirectoryInternal(path: resolvedPath, permissions: permissions)
        updateParentDirectoryModificationTime(parentPath)
    }

    private func createDirectoryInternal(path: String, permissions: FilePermission) {
        let inode = nextInode
        nextInode += 1

        let attributes = FileAttributes(
            inode: inode,
            type: .directory,
            size: 0,
            permissions: permissions,
            uid: currentUID,
            gid: currentGID,
            nlink: 2 // . and ..
        )

        fileAttributes[path] = attributes
        directoryContents[path] = []
        inodes[inode] = path

        // Add to parent directory
        let parentPath = getParentPath(path)
        if var parentContents = directoryContents[parentPath] {
            let dirName = (path as NSString).lastPathComponent
            if !parentContents.contains(dirName) {
                parentContents.append(dirName)
                directoryContents[parentPath] = parentContents.sorted()
            }
        }
    }

    public func removeItem(at path: String) throws {
        let resolvedPath = resolvePath(path)
        guard let attributes = fileAttributes[resolvedPath] else {
            throw FileSystemError.fileNotFound
        }

        if attributes.type == .directory {
            // Remove directory contents recursively
            if let contents = directoryContents[resolvedPath] {
                for item in contents {
                    let itemPath = resolvedPath == "/" ? "/\(item)" : "\(resolvedPath)/\(item)"
                    try removeItem(at: itemPath)
                }
            }
        }

        // Remove from storage
        fileStorage.removeValue(forKey: resolvedPath)
        fileAttributes.removeValue(forKey: resolvedPath)
        directoryContents.removeValue(forKey: resolvedPath)
        inodes.removeValue(forKey: attributes.inode)

        // Remove from parent directory
        let parentPath = getParentPath(resolvedPath)
        if var parentContents = directoryContents[parentPath] {
            let itemName = (resolvedPath as NSString).lastPathComponent
            parentContents.removeAll { $0 == itemName }
            directoryContents[parentPath] = parentContents
        }

        updateParentDirectoryModificationTime(parentPath)
    }

    // MARK: - File Operations

    public func readFile(at path: String) async throws -> String {
        let resolvedPath = resolvePath(path)
        guard let attributes = fileAttributes[resolvedPath] else {
            throw FileSystemError.fileNotFound
        }

        guard attributes.type == .regular else {
            throw FileSystemError.notADirectory
        }

        // Check read permission
        guard checkPermission(attributes.permissions, for: .userRead) else {
            throw FileSystemError.permissionDenied
        }

        if let content = fileStorage[resolvedPath] {
            return String(data: content, encoding: .utf8) ?? ""
        }

        return ""
    }

    public func writeFile(at path: String, content: String) throws {
        let resolvedPath = resolvePath(path)
        let data = content.data(using: .utf8) ?? Data()
        try writeFile(at: resolvedPath, data: data)
    }

    public func writeFile(at path: String, data: Data) throws {
        let resolvedPath = resolvePath(path)
        let isNewFile = fileAttributes[resolvedPath] == nil

        if isNewFile {
            // Create new file
            try createFile(at: resolvedPath, data: data)
        } else {
            // Update existing file
            guard var attributes = fileAttributes[resolvedPath] else {
                throw FileSystemError.fileNotFound
            }

            guard attributes.type == .regular else {
                throw FileSystemError.isADirectory
            }

            // Check write permission
            guard checkPermission(attributes.permissions, for: .userWrite) else {
                throw FileSystemError.permissionDenied
            }

            fileStorage[resolvedPath] = data
            attributes.size = UInt64(data.count)
            attributes.modificationTime = Date()
            attributes.changeTime = Date()
            fileAttributes[resolvedPath] = attributes

            updateParentDirectoryModificationTime(getParentPath(resolvedPath))
        }
    }

    private func createFile(at path: String, data: Data) throws {
        let parentPath = getParentPath(path)
        guard directoryContents[parentPath] != nil else {
            throw FileSystemError.directoryNotFound
        }

        guard fileAttributes[path] == nil else {
            throw FileSystemError.fileExists
        }

        let inode = nextInode
        nextInode += 1

        let attributes = FileAttributes(
            inode: inode,
            type: .regular,
            size: UInt64(data.count),
            permissions: [.userRead, .userWrite, .groupRead, .otherRead],
            uid: currentUID,
            gid: currentGID
        )

        fileAttributes[path] = attributes
        fileStorage[path] = data
        inodes[inode] = path

        // Add to parent directory
        if var parentContents = directoryContents[parentPath] {
            let fileName = (path as NSString).lastPathComponent
            if !parentContents.contains(fileName) {
                parentContents.append(fileName)
                directoryContents[parentPath] = parentContents.sorted()
            }
        }

        updateParentDirectoryModificationTime(parentPath)
    }

    // MARK: - File Attributes

    public func getAttributes(of path: String) throws -> FileAttributes {
        let resolvedPath = resolvePath(path)
        guard let attributes = fileAttributes[resolvedPath] else {
            throw FileSystemError.fileNotFound
        }
        return attributes
    }

    public func setPermissions(of path: String, permissions: FilePermission) throws {
        let resolvedPath = resolvePath(path)
        guard var attributes = fileAttributes[resolvedPath] else {
            throw FileSystemError.fileNotFound
        }

        attributes.permissions = permissions
        attributes.changeTime = Date()
        fileAttributes[resolvedPath] = attributes
    }

    // MARK: - Utility Methods

    public func fileExists(at path: String) -> Bool {
        let resolvedPath = resolvePath(path)
        return fileAttributes[resolvedPath] != nil
    }

    public func directoryExists(at path: String) -> Bool {
        let resolvedPath = resolvePath(path)
        guard let attributes = fileAttributes[resolvedPath] else {
            return false
        }
        return attributes.type == .directory
    }

    public func getStatus() -> String {
        let fileCount = fileAttributes.values.filter { $0.type == .regular }.count
        let dirCount = fileAttributes.values.filter { $0.type == .directory }.count
        let totalSize = fileStorage.values.reduce(0) { $0 + $1.count }

        return "Enhanced File System: \(fileCount) files, \(dirCount) directories, \(formatBytes(UInt64(totalSize))) used"
    }

    private func resolvePath(_ path: String) -> String {
        if path.hasPrefix("/") {
            return (path as NSString).standardizingPath
        } else {
            let fullPath = currentDirectory == "/" ? "/\(path)" : "\(currentDirectory)/\(path)"
            return (fullPath as NSString).standardizingPath
        }
    }

    private func getParentPath(_ path: String) -> String {
        let nsPath = path as NSString
        return nsPath.deletingLastPathComponent
    }

    private func checkPermission(_ permissions: FilePermission, for permission: FilePermission) -> Bool {
        return permissions.contains(permission)
    }

    private func updateParentDirectoryModificationTime(_ path: String) {
        if var attributes = fileAttributes[path] {
            attributes.modificationTime = Date()
            attributes.changeTime = Date()
            fileAttributes[path] = attributes
        }
    }

    private func formatBytes(_ bytes: UInt64) -> String {
        let units = ["B", "KB", "MB", "GB", "TB"]
        var value = Double(bytes)
        var unitIndex = 0

        while value >= 1024 && unitIndex < units.count - 1 {
            value /= 1024
            unitIndex += 1
        }

        return String(format: "%.1f %@", value, units[unitIndex])
    }
}

// MARK: - Extensions

extension NSString {
    var lastPathComponent: String {
        return self.lastPathComponent
    }

    var deletingLastPathComponent: String {
        return self.deletingLastPathComponent
    }

    var standardizingPath: String {
        return self.standardizingPath
    }
}