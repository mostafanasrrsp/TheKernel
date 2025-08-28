//
//  FileSystemManager.swift
//  RadiateOS
//
//  File system management and virtual file structure
//

import SwiftUI
import Foundation

@MainActor
class FileSystemManager: ObservableObject {
    @Published var currentDirectory: FileSystemNode
    @Published var selectedItems: Set<FileSystemNode> = []
    @Published var clipboard: [FileSystemNode] = []
    @Published var isLoading = false
    
    private let rootNode: FileSystemNode
    private let currentUserName: String
    
    init(currentUserName: String) {
        self.currentUserName = currentUserName
        // Create virtual file system structure
        rootNode = FileSystemNode(
            name: "/",
            type: .directory,
            path: "/",
            size: 0,
            permissions: .init(owner: .readWrite, group: .read, others: .read),
            owner: "root"
        )
        
        currentDirectory = rootNode
        setupFileSystem()
    }
    
    func navigateTo(_ node: FileSystemNode) {
        guard node.type == .directory else { return }
        currentDirectory = node
        selectedItems.removeAll()
    }
    
    func navigateUp() {
        if let parent = currentDirectory.parent {
            currentDirectory = parent
            selectedItems.removeAll()
        }
    }
    
    func navigateToPath(_ path: String) {
        if let node = findNode(at: path) {
            navigateTo(node)
        }
    }
    
    func createDirectory(name: String) {
        let newDir = FileSystemNode(
            name: name,
            type: .directory,
            path: "\(currentDirectory.path)/\(name)",
            size: 0,
            permissions: .init(owner: .readWrite, group: .read, others: .read),
            owner: currentUserName
        )
        currentDirectory.addChild(newDir)
    }
    
    func createFile(name: String, content: String = "") {
        let newFile = FileSystemNode(
            name: name,
            type: .file,
            path: "\(currentDirectory.path)/\(name)",
            size: Int64(content.utf8.count),
            permissions: .init(owner: .readWrite, group: .read, others: .read),
            owner: currentUserName,
            content: content
        )
        currentDirectory.addChild(newFile)
    }
    
    func deleteItems(_ items: [FileSystemNode]) {
        for item in items {
            currentDirectory.removeChild(item)
        }
        selectedItems.removeAll()
    }
    
    func copyItems(_ items: [FileSystemNode]) {
        clipboard = items
    }
    
    func pasteItems() {
        for item in clipboard {
            let copy = item.copy()
            copy.name = getUniqueFileName(copy.name, in: currentDirectory)
            copy.path = "\(currentDirectory.path)/\(copy.name)"
            currentDirectory.addChild(copy)
        }
    }
    
    func findNode(at path: String) -> FileSystemNode? {
        let components = path.split(separator: "/")
        var current = rootNode
        
        for component in components {
            guard let child = current.children.first(where: { $0.name == component }) else {
                return nil
            }
            current = child
        }
        
        return current
    }
    
    private func getUniqueFileName(_ baseName: String, in directory: FileSystemNode) -> String {
        var name = baseName
        var counter = 1
        
        while directory.children.contains(where: { $0.name == name }) {
            if baseName.contains(".") {
                let parts = baseName.split(separator: ".")
                if parts.count > 1 {
                    let nameWithoutExt = parts.dropLast().joined(separator: ".")
                    let ext = parts.last!
                    name = "\(nameWithoutExt) \(counter).\(ext)"
                } else {
                    name = "\(baseName) \(counter)"
                }
            } else {
                name = "\(baseName) \(counter)"
            }
            counter += 1
        }
        
        return name
    }
    
    private func setupFileSystem() {
        // System directories
        let applications = FileSystemNode(name: "Applications", type: .directory, path: "/Applications")
        let system = FileSystemNode(name: "System", type: .directory, path: "/System")
        let users = FileSystemNode(name: "Users", type: .directory, path: "/Users")
        let tmp = FileSystemNode(name: "tmp", type: .directory, path: "/tmp")
        let var_ = FileSystemNode(name: "var", type: .directory, path: "/var")
        let etc = FileSystemNode(name: "etc", type: .directory, path: "/etc")
        
        rootNode.addChild(applications)
        rootNode.addChild(system)
        rootNode.addChild(users)
        rootNode.addChild(tmp)
        rootNode.addChild(var_)
        rootNode.addChild(etc)
        
        // User directory
        let userHome = FileSystemNode(name: currentUserName, type: .directory, path: "/Users/\(currentUserName)")
        users.addChild(userHome)
        
        // User subdirectories
        let documents = FileSystemNode(name: "Documents", type: .directory, path: "\(userHome.path)/Documents")
        let downloads = FileSystemNode(name: "Downloads", type: .directory, path: "\(userHome.path)/Downloads")
        let desktop = FileSystemNode(name: "Desktop", type: .directory, path: "\(userHome.path)/Desktop")
        let pictures = FileSystemNode(name: "Pictures", type: .directory, path: "\(userHome.path)/Pictures")
        
        userHome.addChild(documents)
        userHome.addChild(downloads)
        userHome.addChild(desktop)
        userHome.addChild(pictures)
        
        // System files
        let kernelConfig = FileSystemNode(
            name: "kernel.conf",
            type: .file,
            path: "/etc/kernel.conf",
            content: "# RadiateOS Kernel Configuration\noptical_cpu_enabled=true\nmemory_manager=advanced\nrom_hot_swap=true"
        )
        etc.addChild(kernelConfig)
        
        // Sample documents
        let readme = FileSystemNode(
            name: "README.txt",
            type: .file,
            path: "\(documents.path)/README.txt",
            content: "Welcome to RadiateOS!\n\nThis is a revolutionary optical computing operating system.\n\nFeatures:\n- Optical CPU processing\n- Smart memory management\n- Ejectable ROM modules\n- x86/x64 compatibility layer"
        )
        documents.addChild(readme)
        
        // Sample application
        let sampleApp = FileSystemNode(name: "TextEdit.app", type: .application, path: "/Applications/TextEdit.app")
        applications.addChild(sampleApp)
    }
}

class FileSystemNode: ObservableObject, Identifiable, Hashable {
    let id = UUID()
    @Published var name: String
    let type: FileType
    @Published var path: String
    @Published var size: Int64
    let permissions: FilePermissions
    let owner: String
    let dateCreated: Date
    @Published var dateModified: Date
    @Published var content: String?
    @Published var children: [FileSystemNode] = []
    weak var parent: FileSystemNode?
    
    init(name: String, type: FileType, path: String, size: Int64 = 0, permissions: FilePermissions? = nil, owner: String = "user", content: String? = nil) {
        self.name = name
        self.type = type
        self.path = path
        self.size = size
        self.permissions = permissions ?? FilePermissions(owner: .readWrite, group: .read, others: .read)
        self.owner = owner
        self.dateCreated = Date()
        self.dateModified = Date()
        self.content = content
    }
    
    func addChild(_ child: FileSystemNode) {
        child.parent = self
        children.append(child)
        children.sort { $0.name < $1.name }
        dateModified = Date()
    }
    
    func removeChild(_ child: FileSystemNode) {
        children.removeAll { $0.id == child.id }
        dateModified = Date()
    }
    
    func copy() -> FileSystemNode {
        let copy = FileSystemNode(
            name: name,
            type: type,
            path: path,
            size: size,
            permissions: permissions,
            owner: owner,
            content: content
        )
        
        for child in children {
            copy.addChild(child.copy())
        }
        
        return copy
    }
    
    var icon: String {
        switch type {
        case .directory:
            return "folder"
        case .file:
            if name.hasSuffix(".txt") { return "doc.text" }
            if name.hasSuffix(".conf") { return "gearshape.fill" }
            if name.hasSuffix(".log") { return "doc.plaintext" }
            return "doc"
        case .application:
            return "app"
        case .systemFile:
            return "gear"
        case .symlink:
            return "link"
        }
    }
    
    var sizeString: String {
        if type == .directory {
            return "\(children.count) items"
        }
        
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }
    
    static func == (lhs: FileSystemNode, rhs: FileSystemNode) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    enum FileType {
        case directory
        case file
        case application
        case systemFile
        case symlink
    }
}

struct FilePermissions {
    let owner: Permission
    let group: Permission
    let others: Permission
    
    enum Permission {
        case none
        case read
        case write
        case readWrite
        case execute
        case readExecute
        case writeExecute
        case readWriteExecute
        
        var string: String {
            switch self {
            case .none: return "---"
            case .read: return "r--"
            case .write: return "-w-"
            case .readWrite: return "rw-"
            case .execute: return "--x"
            case .readExecute: return "r-x"
            case .writeExecute: return "-wx"
            case .readWriteExecute: return "rwx"
            }
        }
    }
    
    var octalString: String {
        let ownerValue = permissionValue(owner)
        let groupValue = permissionValue(group)
        let othersValue = permissionValue(others)
        return "\(ownerValue)\(groupValue)\(othersValue)"
    }
    
    private func permissionValue(_ permission: Permission) -> Int {
        switch permission {
        case .none: return 0
        case .execute: return 1
        case .write: return 2
        case .writeExecute: return 3
        case .read: return 4
        case .readExecute: return 5
        case .readWrite: return 6
        case .readWriteExecute: return 7
        }
    }
}
