//
//  FileManagerView.swift
//  RadiateOS
//
//  File management application
//

import SwiftUI

struct FileManagerView: View {
    @StateObject private var fileSystem = OSManager.shared.fileSystem
    @State private var showingNewFolderDialog = false
    @State private var showingNewFileDialog = false
    @State private var newItemName = ""
    @State private var viewMode: ViewMode = .list
    @State private var showingInfo = false
    @State private var searchText = ""
    
    enum ViewMode: String, CaseIterable {
        case list = "List"
        case icons = "Icons"
        case columns = "Columns"
        
        var icon: String {
            switch self {
            case .list: return "list.bullet"
            case .icons: return "square.grid.2x2"
            case .columns: return "sidebar.left"
            }
        }
    }
    
    var filteredItems: [FileSystemNode] {
        if searchText.isEmpty {
            return fileSystem.currentDirectory.children
        } else {
            return fileSystem.currentDirectory.children.filter {
                $0.name.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack {
                // Navigation buttons
                HStack(spacing: 8) {
                    Button(action: fileSystem.navigateUp) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .disabled(fileSystem.currentDirectory.parent == nil)
                    
                    Button(action: {}) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .disabled(true) // Forward navigation not implemented
                }
                .buttonStyle(ToolbarButtonStyle())
                
                Spacer()
                
                // Path breadcrumb
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(pathComponents, id: \.self) { component in
                            Button(component) {
                                navigateToComponent(component)
                            }
                            .buttonStyle(BreadcrumbButtonStyle())
                            
                            if component != pathComponents.last {
                                Text("/")
                                    .foregroundColor(.secondary)
                                    .font(.system(size: 14))
                            }
                        }
                    }
                    .padding(.horizontal, 8)
                }
                .frame(maxWidth: 300)
                
                Spacer()
                
                // View controls
                HStack(spacing: 8) {
                    Picker("View Mode", selection: $viewMode) {
                        ForEach(ViewMode.allCases, id: \.self) { mode in
                            Image(systemName: mode.icon)
                                .tag(mode)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .frame(width: 120)
                    
                    Menu {
                        Button("New Folder", action: { showingNewFolderDialog = true })
                        Button("New File", action: { showingNewFileDialog = true })
                        Divider()
                        Button("Get Info", action: { showingInfo = true })
                            .disabled(fileSystem.selectedItems.isEmpty)
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .buttonStyle(ToolbarButtonStyle())
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.primary.opacity(0.05))
            
            Divider()
            
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                
                if !searchText.isEmpty {
                    Button("Clear") {
                        searchText = ""
                    }
                    .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.primary.opacity(0.03))
            
            Divider()
            
            // File list
            if filteredItems.isEmpty {
                Spacer()
                VStack(spacing: 16) {
                    Image(systemName: "folder")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    
                    Text("This folder is empty")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    if searchText.isEmpty {
                        Button("Create New Folder") {
                            showingNewFolderDialog = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                Spacer()
            } else {
                switch viewMode {
                case .list:
                    FileListView(items: filteredItems, fileSystem: fileSystem)
                case .icons:
                    FileIconView(items: filteredItems, fileSystem: fileSystem)
                case .columns:
                    FileColumnView(items: filteredItems, fileSystem: fileSystem)
                }
            }
            
            // Status bar
            HStack {
                Text("\(filteredItems.count) items")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if !fileSystem.selectedItems.isEmpty {
                    Text("\(fileSystem.selectedItems.count) selected")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.primary.opacity(0.03))
        }
        .sheet(isPresented: $showingNewFolderDialog) {
            CreateItemDialog(
                title: "New Folder",
                itemName: $newItemName,
                onCreate: {
                    fileSystem.createDirectory(name: newItemName)
                    newItemName = ""
                }
            )
        }
        .sheet(isPresented: $showingNewFileDialog) {
            CreateItemDialog(
                title: "New File",
                itemName: $newItemName,
                onCreate: {
                    fileSystem.createFile(name: newItemName)
                    newItemName = ""
                }
            )
        }
    }
    
    private var pathComponents: [String] {
        let path = fileSystem.currentDirectory.path
        return path.split(separator: "/").map(String.init)
    }
    
    private func navigateToComponent(_ component: String) {
        // Implementation for breadcrumb navigation
        // This would need to build the path and navigate there
    }
}

struct FileListView: View {
    let items: [FileSystemNode]
    let fileSystem: FileSystemManager
    
    var body: some View {
        List(items, selection: Binding(
            get: { fileSystem.selectedItems },
            set: { fileSystem.selectedItems = $0 }
        )) { item in
            FileRowView(item: item, fileSystem: fileSystem)
                .onTapGesture(count: 2) {
                    if item.type == .directory {
                        fileSystem.navigateTo(item)
                    }
                }
        }
        .listStyle(PlainListStyle())
    }
}

struct FileRowView: View {
    let item: FileSystemNode
    let fileSystem: FileSystemManager
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: item.icon)
                .font(.system(size: 20))
                .foregroundColor(iconColor)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.system(size: 14, weight: .medium))
                
                HStack(spacing: 8) {
                    Text(item.sizeString)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    
                    Text(item.dateModified, style: .date)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if item.type == .directory {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
    
    private var iconColor: Color {
        switch item.type {
        case .directory: return .blue
        case .file: return .primary
        case .application: return .purple
        case .systemFile: return .orange
        case .symlink: return .green
        }
    }
}

struct FileIconView: View {
    let items: [FileSystemNode]
    let fileSystem: FileSystemManager
    
    private let columns = Array(repeating: GridItem(.adaptive(minimum: 80)), count: 1)
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(items) { item in
                    VStack(spacing: 8) {
                        Image(systemName: item.icon)
                            .font(.system(size: 32))
                            .foregroundColor(.blue)
                        
                        Text(item.name)
                            .font(.system(size: 12))
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                    }
                    .frame(width: 80, height: 80)
                    .onTapGesture(count: 2) {
                        if item.type == .directory {
                            fileSystem.navigateTo(item)
                        }
                    }
                }
            }
            .padding()
        }
    }
}

struct FileColumnView: View {
    let items: [FileSystemNode]
    let fileSystem: FileSystemManager
    
    var body: some View {
        HStack(spacing: 0) {
            // Left column - current directory
            VStack(alignment: .leading) {
                Text("Current Directory")
                    .font(.headline)
                    .padding()
                
                List(items) { item in
                    FileRowView(item: item, fileSystem: fileSystem)
                }
                .listStyle(PlainListStyle())
            }
            .frame(maxWidth: .infinity)
            
            Divider()
            
            // Right column - preview/details
            VStack {
                if let selectedItem = fileSystem.selectedItems.first {
                    FilePreviewView(item: selectedItem)
                } else {
                    Text("Select an item to preview")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
}

struct FilePreviewView: View {
    let item: FileSystemNode
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // File icon and name
            HStack {
                Image(systemName: item.icon)
                    .font(.system(size: 48))
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading) {
                    Text(item.name)
                        .font(.headline)
                    
                    Text(item.type == .directory ? "Folder" : "File")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            // File details
            VStack(alignment: .leading, spacing: 8) {
                DetailRow(label: "Size", value: item.sizeString)
                DetailRow(label: "Created", value: DateFormatter.mediumDateTime.string(from: item.dateCreated))
                DetailRow(label: "Modified", value: DateFormatter.mediumDateTime.string(from: item.dateModified))
                DetailRow(label: "Owner", value: item.owner)
                DetailRow(label: "Permissions", value: item.permissions.octalString)
            }
            
            // Content preview (for text files)
            if item.type == .file, let content = item.content, !content.isEmpty {
                VStack(alignment: .leading) {
                    Text("Preview")
                        .font(.headline)
                    
                    ScrollView {
                        Text(content)
                            .font(.system(.body, design: .monospaced))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxHeight: 200)
                    .padding(8)
                    .background(Color.primary.opacity(0.05))
                    .cornerRadius(8)
                }
            }
            
            Spacer()
        }
        .padding()
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label + ":")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
                .frame(width: 80, alignment: .leading)
            
            Text(value)
                .font(.system(size: 14))
        }
    }
}

struct CreateItemDialog: View {
    let title: String
    @Binding var itemName: String
    let onCreate: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            Text(title)
                .font(.headline)
            
            TextField("Name", text: $itemName)
                .textFieldStyle(.roundedBorder)
            
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                
                Button("Create") {
                    onCreate()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(itemName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding()
        .frame(width: 300)
    }
}

struct ToolbarButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.primary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.primary.opacity(configuration.isPressed ? 0.2 : 0.1))
            .cornerRadius(6)
    }
}

struct BreadcrumbButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.primary)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.primary.opacity(configuration.isPressed ? 0.2 : 0.0))
            .cornerRadius(4)
    }
}

extension DateFormatter {
    static let mediumDateTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}

#Preview {
    FileManagerView()
        .frame(width: 800, height: 600)
}
