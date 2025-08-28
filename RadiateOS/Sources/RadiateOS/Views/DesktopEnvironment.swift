import SwiftUI

struct DesktopEnvironment: View {
    @ObservedObject var osManager: OSManager
    @Binding var selectedApp: OSApplication?
    @State private var windowPositions: [String: CGPoint] = [:]
    @State private var windowSizes: [String: CGSize] = [:]
    @State private var minimizedApps: Set<String> = []
    @State private var fullscreenApp: String?
    
    var body: some View {
        ZStack {
            // Desktop Icons
            DesktopIconGrid(osManager: osManager)
                .opacity(selectedApp == nil ? 1 : 0.3)
            
            // Application Windows
            ForEach(osManager.runningApplications) { app in
                if !minimizedApps.contains(app.id) && app.id != "finder" {
                    ApplicationWindow(
                        app: app,
                        isActive: osManager.activeApplication?.id == app.id,
                        isFullscreen: fullscreenApp == app.id,
                        position: binding(for: app.id, in: $windowPositions),
                        size: binding(for: app.id, in: $windowSizes),
                        onClose: {
                            osManager.quitApplication(app)
                        },
                        onMinimize: {
                            withAnimation(RadiateDesign.Animations.spring) {
                                minimizedApps.insert(app.id)
                            }
                        },
                        onMaximize: {
                            withAnimation(RadiateDesign.Animations.spring) {
                                fullscreenApp = fullscreenApp == app.id ? nil : app.id
                            }
                        },
                        onFocus: {
                            osManager.setActiveApplication(app)
                        }
                    )
                }
            }
            
            // Finder is always visible
            if let finder = osManager.runningApplications.first(where: { $0.id == "finder" }) {
                FinderWindow(
                    osManager: osManager,
                    isActive: osManager.activeApplication?.id == "finder",
                    onFocus: {
                        osManager.setActiveApplication(finder)
                    }
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func binding(for appId: String, in dict: Binding<[String: CGPoint]>) -> Binding<CGPoint> {
        Binding(
            get: { dict.wrappedValue[appId] ?? CGPoint(x: 100, y: 100) },
            set: { dict.wrappedValue[appId] = $0 }
        )
    }
    
    private func binding(for appId: String, in dict: Binding<[String: CGSize]>) -> Binding<CGSize> {
        Binding(
            get: { dict.wrappedValue[appId] ?? CGSize(width: 800, height: 600) },
            set: { dict.wrappedValue[appId] = $0 }
        )
    }
}

// MARK: - Desktop Icon Grid
struct DesktopIconGrid: View {
    @ObservedObject var osManager: OSManager
    
    let columns = Array(repeating: GridItem(.fixed(80), spacing: 20), count: 8)
    
    var body: some View {
        VStack {
            HStack {
                LazyVGrid(columns: columns, spacing: 20) {
                    DesktopIcon(
                        icon: "internaldrive",
                        title: "Macintosh HD",
                        gradient: RadiateDesign.Colors.ultraviolet
                    )
                    
                    DesktopIcon(
                        icon: "folder.fill",
                        title: "Documents",
                        gradient: RadiateDesign.Colors.azure
                    )
                    
                    DesktopIcon(
                        icon: "folder.fill",
                        title: "Downloads",
                        gradient: RadiateDesign.Colors.emerald
                    )
                    
                    DesktopIcon(
                        icon: "folder.fill",
                        title: "Applications",
                        gradient: RadiateDesign.Colors.indigo
                    )
                }
                .padding(RadiateDesign.Spacing.xl)
                
                Spacer()
            }
            
            Spacer()
        }
    }
}

// MARK: - Desktop Icon
struct DesktopIcon: View {
    let icon: String
    let title: String
    let gradient: LinearGradient
    @State private var isHovered = false
    @State private var isSelected = false
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                RoundedRectangle(cornerRadius: RadiateDesign.CornerRadius.md)
                    .fill(gradient)
                    .frame(width: 60, height: 60)
                    .shadow(
                        color: gradient.gradient.stops.first?.color.opacity(0.3) ?? .clear,
                        radius: isHovered ? 10 : 5
                    )
                
                Image(systemName: icon)
                    .font(.system(size: 30))
                    .foregroundColor(.white)
            }
            .scaleEffect(isHovered ? 1.1 : 1.0)
            
            Text(title)
                .font(RadiateDesign.Typography.caption1)
                .foregroundColor(RadiateDesign.Colors.text)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(width: 70)
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(
                    isSelected ? RadiateDesign.Colors.accentPrimary.opacity(0.3) : Color.clear
                )
                .cornerRadius(4)
        }
        .onHover { hovering in
            withAnimation(RadiateDesign.Animations.fast) {
                isHovered = hovering
            }
        }
        .onTapGesture {
            isSelected.toggle()
        }
    }
}

// MARK: - Application Window
struct ApplicationWindow: View {
    let app: OSApplication
    let isActive: Bool
    let isFullscreen: Bool
    @Binding var position: CGPoint
    @Binding var size: CGSize
    let onClose: () -> Void
    let onMinimize: () -> Void
    let onMaximize: () -> Void
    let onFocus: () -> Void
    
    @State private var isDragging = false
    @State private var isResizing = false
    @State private var dragOffset = CGSize.zero
    
    var body: some View {
        VStack(spacing: 0) {
            // Window Title Bar
            WindowTitleBar(
                title: app.name,
                icon: app.icon,
                isActive: isActive,
                onClose: onClose,
                onMinimize: onMinimize,
                onMaximize: onMaximize
            )
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if !isDragging {
                            isDragging = true
                            onFocus()
                        }
                        dragOffset = value.translation
                    }
                    .onEnded { value in
                        position.x += value.translation.width
                        position.y += value.translation.height
                        dragOffset = .zero
                        isDragging = false
                    }
            )
            
            // Window Content
            WindowContent(app: app)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: isFullscreen ? NSScreen.main?.frame.width : size.width,
               height: isFullscreen ? NSScreen.main?.frame.height : size.height)
        .background(RadiateDesign.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: isFullscreen ? 0 : RadiateDesign.CornerRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: isFullscreen ? 0 : RadiateDesign.CornerRadius.md)
                .stroke(isActive ? RadiateDesign.Colors.accentPrimary : RadiateDesign.Colors.glassBorder, lineWidth: 1)
        )
        .shadow(color: .black.opacity(isActive ? 0.3 : 0.2), radius: isActive ? 20 : 10)
        .position(x: position.x + dragOffset.width, y: position.y + dragOffset.height)
        .animation(RadiateDesign.Animations.spring, value: isFullscreen)
        .onTapGesture {
            onFocus()
        }
    }
}

// MARK: - Window Title Bar
struct WindowTitleBar: View {
    let title: String
    let icon: String
    let isActive: Bool
    let onClose: () -> Void
    let onMinimize: () -> Void
    let onMaximize: () -> Void
    
    @State private var isHoveringControls = false
    
    var body: some View {
        HStack(spacing: RadiateDesign.Spacing.sm) {
            // Traffic Light Controls
            HStack(spacing: 8) {
                TrafficLightButton(color: .red, symbol: "xmark", action: onClose, isActive: isActive || isHoveringControls)
                TrafficLightButton(color: .yellow, symbol: "minus", action: onMinimize, isActive: isActive || isHoveringControls)
                TrafficLightButton(color: .green, symbol: "arrow.up.left.and.arrow.down.right", action: onMaximize, isActive: isActive || isHoveringControls)
            }
            .padding(.leading, RadiateDesign.Spacing.sm)
            .onHover { hovering in
                isHoveringControls = hovering
            }
            
            Spacer()
            
            // Window Title
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(RadiateDesign.Colors.textSecondary)
                
                Text(title)
                    .font(RadiateDesign.Typography.callout)
                    .foregroundColor(RadiateDesign.Colors.text)
            }
            
            Spacer()
            
            // Right side spacer for symmetry
            Color.clear
                .frame(width: 80)
        }
        .frame(height: 32)
        .background(RadiateDesign.Colors.surfaceLight.opacity(0.5))
    }
}

// MARK: - Traffic Light Button
struct TrafficLightButton: View {
    let color: Color
    let symbol: String
    let action: () -> Void
    let isActive: Bool
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(isActive || isHovered ? color : Color.gray.opacity(0.3))
                    .frame(width: 12, height: 12)
                
                if isHovered {
                    Image(systemName: symbol)
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.black.opacity(0.7))
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Window Content
struct WindowContent: View {
    let app: OSApplication
    
    var body: some View {
        Group {
            switch app.id {
            case "safari":
                SafariView()
            case "terminal":
                TerminalView()
            case "messages":
                MessagesView()
            case "settings":
                SettingsView()
            case "activity":
                ActivityMonitorView()
            default:
                DefaultAppView(app: app)
            }
        }
    }
}

// MARK: - Finder Window
struct FinderWindow: View {
    @ObservedObject var osManager: OSManager
    let isActive: Bool
    let onFocus: () -> Void
    @State private var selectedPath = "/"
    @State private var searchText = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Finder Title Bar
            HStack {
                HStack(spacing: 8) {
                    TrafficLightButton(color: .red, symbol: "xmark", action: {}, isActive: isActive)
                    TrafficLightButton(color: .yellow, symbol: "minus", action: {}, isActive: isActive)
                    TrafficLightButton(color: .green, symbol: "arrow.up.left.and.arrow.down.right", action: {}, isActive: isActive)
                }
                .padding(.leading, RadiateDesign.Spacing.sm)
                
                Spacer()
                
                Text("Finder")
                    .font(RadiateDesign.Typography.headline)
                    .foregroundColor(RadiateDesign.Colors.text)
                
                Spacer()
                
                // Search Field
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(RadiateDesign.Colors.textTertiary)
                    
                    TextField("Search", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .foregroundColor(RadiateDesign.Colors.text)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(RadiateDesign.Colors.glassDark)
                .cornerRadius(6)
                .frame(width: 200)
                .padding(.trailing, RadiateDesign.Spacing.sm)
            }
            .frame(height: 32)
            .background(RadiateDesign.Colors.surfaceLight.opacity(0.5))
            
            // Finder Content
            HSplitView {
                // Sidebar
                FinderSidebar(selectedPath: $selectedPath)
                    .frame(minWidth: 200, idealWidth: 250, maxWidth: 300)
                
                // File List
                FinderFileList(path: selectedPath)
                    .frame(minWidth: 400)
            }
        }
        .frame(width: 900, height: 600)
        .background(RadiateDesign.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: RadiateDesign.CornerRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: RadiateDesign.CornerRadius.md)
                .stroke(isActive ? RadiateDesign.Colors.accentPrimary : RadiateDesign.Colors.glassBorder, lineWidth: 1)
        )
        .shadow(color: .black.opacity(isActive ? 0.3 : 0.2), radius: isActive ? 20 : 10)
        .position(x: 500, y: 350)
        .onTapGesture {
            onFocus()
        }
    }
}

// MARK: - Finder Sidebar
struct FinderSidebar: View {
    @Binding var selectedPath: String
    
    let favorites = [
        ("AirDrop", "wifi"),
        ("Recents", "clock.arrow.circlepath"),
        ("Applications", "square.grid.3x3"),
        ("Desktop", "menubar.dock.rectangle"),
        ("Documents", "doc.text"),
        ("Downloads", "arrow.down.circle")
    ]
    
    let iCloud = [
        ("iCloud Drive", "icloud"),
        ("Shared", "person.2"),
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Favorites Section
            SidebarSection(title: "Favorites") {
                ForEach(favorites, id: \.0) { item in
                    SidebarItem(
                        icon: item.1,
                        title: item.0,
                        isSelected: selectedPath == item.0,
                        action: {
                            selectedPath = item.0
                        }
                    )
                }
            }
            
            // iCloud Section
            SidebarSection(title: "iCloud") {
                ForEach(iCloud, id: \.0) { item in
                    SidebarItem(
                        icon: item.1,
                        title: item.0,
                        isSelected: selectedPath == item.0,
                        action: {
                            selectedPath = item.0
                        }
                    )
                }
            }
            
            Spacer()
        }
        .padding(.vertical, RadiateDesign.Spacing.sm)
        .background(RadiateDesign.Colors.surfaceLight.opacity(0.3))
    }
}

// MARK: - Sidebar Section
struct SidebarSection<Content: View>: View {
    let title: String
    let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title.uppercased())
                .font(RadiateDesign.Typography.caption2)
                .foregroundColor(RadiateDesign.Colors.textTertiary)
                .padding(.horizontal, RadiateDesign.Spacing.md)
                .padding(.vertical, RadiateDesign.Spacing.xs)
            
            content()
        }
        .padding(.bottom, RadiateDesign.Spacing.sm)
    }
}

// MARK: - Sidebar Item
struct SidebarItem: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: RadiateDesign.Spacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(isSelected ? .white : RadiateDesign.Colors.textSecondary)
                
                Text(title)
                    .font(RadiateDesign.Typography.callout)
                    .foregroundColor(isSelected ? .white : RadiateDesign.Colors.text)
                
                Spacer()
            }
            .padding(.horizontal, RadiateDesign.Spacing.md)
            .padding(.vertical, 6)
            .background(
                isSelected ? RadiateDesign.Colors.accentPrimary : Color.clear
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Finder File List
struct FinderFileList: View {
    let path: String
    
    let files = [
        ("Documents", "folder.fill", "Folder", "2.4 GB"),
        ("Downloads", "folder.fill", "Folder", "8.7 GB"),
        ("Pictures", "folder.fill", "Folder", "12.3 GB"),
        ("RadiateOS.app", "app.fill", "Application", "256 MB"),
        ("README.md", "doc.text", "Document", "4 KB"),
        ("config.json", "doc.text.fill", "JSON", "2 KB"),
    ]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 1) {
                ForEach(files, id: \.0) { file in
                    FileListItem(
                        icon: file.1,
                        name: file.0,
                        kind: file.2,
                        size: file.3
                    )
                }
            }
            .padding(RadiateDesign.Spacing.md)
        }
        .background(RadiateDesign.Colors.surface)
    }
}

// MARK: - File List Item
struct FileListItem: View {
    let icon: String
    let name: String
    let kind: String
    let size: String
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: RadiateDesign.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(RadiateDesign.Colors.accentPrimary)
            
            Text(name)
                .font(RadiateDesign.Typography.body)
                .foregroundColor(RadiateDesign.Colors.text)
            
            Spacer()
            
            Text(kind)
                .font(RadiateDesign.Typography.caption1)
                .foregroundColor(RadiateDesign.Colors.textTertiary)
                .frame(width: 100, alignment: .leading)
            
            Text(size)
                .font(RadiateDesign.Typography.caption1)
                .foregroundColor(RadiateDesign.Colors.textTertiary)
                .frame(width: 80, alignment: .trailing)
        }
        .padding(.horizontal, RadiateDesign.Spacing.sm)
        .padding(.vertical, 6)
        .background(isHovered ? RadiateDesign.Colors.glassDark : Color.clear)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}