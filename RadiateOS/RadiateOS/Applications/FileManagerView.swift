import SwiftUI

struct FileManagerView: View {
    @State private var currentPath = "/Users/radiate"
    @State private var selectedFile: FileItem?
    @State private var showInspector = false
    @State private var searchText = ""
    @State private var viewMode: ViewMode = .list
    
    enum ViewMode {
        case list, grid, columns
    }
    
    let files = [
        FileItem(name: "Applications", type: .folder, size: 0, modified: Date()),
        FileItem(name: "Desktop", type: .folder, size: 0, modified: Date()),
        FileItem(name: "Documents", type: .folder, size: 0, modified: Date()),
        FileItem(name: "Downloads", type: .folder, size: 0, modified: Date()),
        FileItem(name: "Library", type: .folder, size: 0, modified: Date()),
        FileItem(name: "Music", type: .folder, size: 0, modified: Date()),
        FileItem(name: "Pictures", type: .folder, size: 0, modified: Date()),
        FileItem(name: "System", type: .folder, size: 0, modified: Date()),
        FileItem(name: "kernel.log", type: .file, size: 15234, modified: Date()),
        FileItem(name: "readme.txt", type: .file, size: 2048, modified: Date()),
        FileItem(name: "config.json", type: .file, size: 512, modified: Date())
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            FileManagerToolbar(
                currentPath: $currentPath,
                searchText: $searchText,
                viewMode: $viewMode,
                showInspector: $showInspector
            )
            
            // Content
            HStack(spacing: 0) {
                // Sidebar
                FileManagerSidebar()
                    .frame(width: 200)
                
                Divider()
                
                // File list
                switch viewMode {
                case .list:
                    FileListView(files: filteredFiles, selectedFile: $selectedFile)
                case .grid:
                    FileGridView(files: filteredFiles, selectedFile: $selectedFile)
                case .columns:
                    FileColumnsView(files: filteredFiles, selectedFile: $selectedFile)
                }
                
                // Inspector
                if showInspector {
                    Divider()
                    FileInspector(file: selectedFile)
                        .frame(width: 250)
                }
            }
        }
        .background(Color.black.opacity(0.2))
    }
    
    var filteredFiles: [FileItem] {
        if searchText.isEmpty {
            return files
        } else {
            return files.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
}

struct FileManagerToolbar: View {
    @Binding var currentPath: String
    @Binding var searchText: String
    @Binding var viewMode: FileManagerView.ViewMode
    @Binding var showInspector: Bool
    
    var body: some View {
        HStack {
            // Navigation buttons
            Button(action: {}) {
                Image(systemName: "chevron.left")
            }
            .buttonStyle(.plain)
            .disabled(true)
            
            Button(action: {}) {
                Image(systemName: "chevron.right")
            }
            .buttonStyle(.plain)
            .disabled(true)
            
            // Path bar
            HStack(spacing: 2) {
                ForEach(currentPath.split(separator: "/"), id: \.self) { component in
                    if component != currentPath.split(separator: "/").first {
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.4))
                    }
                    Text(String(component))
                        .font(.caption)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Color.white.opacity(0.05))
            .cornerRadius(5)
            
            Spacer()
            
            // Search field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.white.opacity(0.4))
                TextField("Search", text: $searchText)
                    .textFieldStyle(.plain)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.white.opacity(0.05))
            .cornerRadius(5)
            .frame(width: 200)
            
            // View mode buttons
            Picker("View", selection: $viewMode) {
                Image(systemName: "list.bullet").tag(FileManagerView.ViewMode.list)
                Image(systemName: "square.grid.2x2").tag(FileManagerView.ViewMode.grid)
                Image(systemName: "rectangle.split.3x1").tag(FileManagerView.ViewMode.columns)
            }
            .pickerStyle(SegmentedPickerStyle())
            .frame(width: 100)
            
            // Inspector toggle
            Button(action: { showInspector.toggle() }) {
                Image(systemName: "info.circle")
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.3))
    }
}

struct FileManagerSidebar: View {
    @State private var selectedCategory = "Home"
    
    let categories = [
        ("Home", "house"),
        ("Desktop", "desktopcomputer"),
        ("Documents", "doc"),
        ("Downloads", "arrow.down.circle"),
        ("Applications", "app"),
        ("System", "gearshape")
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Favorites")
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
                .padding(.horizontal)
                .padding(.top, 10)
            
            ForEach(categories, id: \.0) { category in
                SidebarItem(
                    title: category.0,
                    icon: category.1,
                    isSelected: selectedCategory == category.0,
                    action: { selectedCategory = category.0 }
                )
            }
            
            Spacer()
            
            // Storage indicator
            VStack(alignment: .leading, spacing: 5) {
                Text("Storage")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                
                HStack {
                    Image(systemName: "internaldrive")
                    Text("Optical Drive")
                        .font(.caption)
                    Spacer()
                }
                
                ProgressView(value: 0.42)
                    .tint(.cyan)
                
                Text("108 GB of 256 GB used")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.4))
            }
            .padding()
            .background(Color.white.opacity(0.05))
            .cornerRadius(8)
            .padding()
        }
        .background(Color.white.opacity(0.02))
    }
}

struct SidebarItem: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .frame(width: 20)
                Text(title)
                    .font(.system(size: 13))
                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 6)
            .background(isSelected ? Color.blue.opacity(0.3) : Color.clear)
            .foregroundColor(isSelected ? .white : .white.opacity(0.8))
        }
        .buttonStyle(.plain)
    }
}

struct FileListView: View {
    let files: [FileItem]
    @Binding var selectedFile: FileItem?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Name")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("Size")
                        .frame(width: 80, alignment: .trailing)
                    Text("Modified")
                        .frame(width: 150, alignment: .trailing)
                }
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
                .padding(.horizontal)
                .padding(.vertical, 5)
                .background(Color.white.opacity(0.05))
                
                // Files
                ForEach(files) { file in
                    FileListRow(file: file, isSelected: selectedFile?.id == file.id)
                        .onTapGesture {
                            selectedFile = file
                        }
                }
            }
        }
    }
}

struct FileListRow: View {
    let file: FileItem
    let isSelected: Bool
    
    var body: some View {
        HStack {
            Image(systemName: file.icon)
                .foregroundColor(file.iconColor)
                .frame(width: 20)
            
            Text(file.name)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text(file.formattedSize)
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
                .frame(width: 80, alignment: .trailing)
            
            Text(file.formattedDate)
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
                .frame(width: 150, alignment: .trailing)
        }
        .padding(.horizontal)
        .padding(.vertical, 6)
        .background(isSelected ? Color.blue.opacity(0.3) : Color.clear)
    }
}

struct FileGridView: View {
    let files: [FileItem]
    @Binding var selectedFile: FileItem?
    
    let columns = [
        GridItem(.adaptive(minimum: 100))
    ]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(files) { file in
                    FileGridItem(file: file, isSelected: selectedFile?.id == file.id)
                        .onTapGesture {
                            selectedFile = file
                        }
                }
            }
            .padding()
        }
    }
}

struct FileGridItem: View {
    let file: FileItem
    let isSelected: Bool
    
    var body: some View {
        VStack {
            Image(systemName: file.icon)
                .font(.system(size: 40))
                .foregroundColor(file.iconColor)
            
            Text(file.name)
                .font(.caption)
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .frame(width: 80, height: 80)
        .padding()
        .background(isSelected ? Color.blue.opacity(0.3) : Color.white.opacity(0.05))
        .cornerRadius(8)
    }
}

struct FileColumnsView: View {
    let files: [FileItem]
    @Binding var selectedFile: FileItem?
    
    var body: some View {
        HStack(spacing: 0) {
            // First column
            ScrollView {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(files.filter { $0.type == .folder }) { file in
                        FileColumnItem(file: file, isSelected: selectedFile?.id == file.id)
                            .onTapGesture {
                                selectedFile = file
                            }
                    }
                }
            }
            .frame(width: 250)
            
            Divider()
            
            // Second column
            ScrollView {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(files.filter { $0.type == .file }) { file in
                        FileColumnItem(file: file, isSelected: selectedFile?.id == file.id)
                            .onTapGesture {
                                selectedFile = file
                            }
                    }
                }
            }
            .frame(width: 250)
            
            Divider()
            
            // Preview column
            if let selected = selectedFile {
                FilePreview(file: selected)
                    .frame(maxWidth: .infinity)
            } else {
                Spacer()
            }
        }
    }
}

struct FileColumnItem: View {
    let file: FileItem
    let isSelected: Bool
    
    var body: some View {
        HStack {
            Image(systemName: file.icon)
                .foregroundColor(file.iconColor)
                .frame(width: 20)
            
            Text(file.name)
                .font(.system(size: 13))
            
            Spacer()
            
            if file.type == .folder {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.4))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(isSelected ? Color.blue.opacity(0.3) : Color.clear)
        .contentShape(Rectangle())
    }
}

struct FilePreview: View {
    let file: FileItem
    
    var body: some View {
        VStack {
            Image(systemName: file.icon)
                .font(.system(size: 60))
                .foregroundColor(file.iconColor)
                .padding()
            
            Text(file.name)
                .font(.title3)
                .fontWeight(.medium)
            
            Text(file.formattedSize)
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
            
            Spacer()
        }
        .padding()
    }
}

struct FileInspector: View {
    let file: FileItem?
    
    var body: some View {
        ScrollView {
            if let file = file {
                VStack(alignment: .leading, spacing: 15) {
                    // File icon and name
                    VStack {
                        Image(systemName: file.icon)
                            .font(.system(size: 60))
                            .foregroundColor(file.iconColor)
                        
                        Text(file.name)
                            .font(.title3)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    
                    Divider()
                    
                    // File info
                    VStack(alignment: .leading, spacing: 10) {
                        InfoRow(label: "Kind", value: file.type == .folder ? "Folder" : "Document")
                        InfoRow(label: "Size", value: file.formattedSize)
                        InfoRow(label: "Modified", value: file.formattedDate)
                        InfoRow(label: "Created", value: file.formattedDate)
                    }
                    .padding(.horizontal)
                    
                    Divider()
                    
                    // Permissions
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Permissions")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                        
                        HStack {
                            Text("Read & Write")
                                .font(.caption)
                            Spacer()
                            Image(systemName: "checkmark")
                                .foregroundColor(.green)
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                }
            } else {
                VStack {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 40))
                        .foregroundColor(.white.opacity(0.3))
                    
                    Text("Select a file")
                        .foregroundColor(.white.opacity(0.6))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Color.white.opacity(0.02))
    }
}

// MARK: - File Item Model
struct FileItem: Identifiable {
    let id = UUID()
    let name: String
    let type: FileType
    let size: Int64
    let modified: Date
    
    enum FileType {
        case file, folder
    }
    
    var icon: String {
        switch type {
        case .folder:
            return "folder"
        case .file:
            if name.hasSuffix(".txt") {
                return "doc.text"
            } else if name.hasSuffix(".json") {
                return "doc.text.below.ecg"
            } else if name.hasSuffix(".log") {
                return "doc.text.magnifyingglass"
            } else {
                return "doc"
            }
        }
    }
    
    var iconColor: Color {
        switch type {
        case .folder:
            return .blue
        case .file:
            return .white.opacity(0.8)
        }
    }
    
    var formattedSize: String {
        if type == .folder {
            return "--"
        }
        
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: modified)
    }
}