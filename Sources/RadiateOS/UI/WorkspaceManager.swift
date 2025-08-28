import SwiftUI

/// Advanced workspace and window management system inspired by GNOME and Pop!_OS
public struct WorkspaceView: View {
    @StateObject private var workspaceManager = WorkspaceManager.shared
    @State private var showOverview = false
    @State private var draggedWindow: ManagedWindow?
    
    public var body: some View {
        ZStack {
            // Current workspace content
            WorkspaceContent(workspace: workspaceManager.currentWorkspace)
            
            // Workspace overview (Mission Control style)
            if showOverview {
                WorkspaceOverview(isShowing: $showOverview)
                    .transition(.asymmetric(
                        insertion: .scale(scale: 1.2).combined(with: .opacity),
                        removal: .scale(scale: 0.8).combined(with: .opacity)
                    ))
            }
            
            // Window snap indicators
            WindowSnapIndicators()
            
            // Keyboard shortcuts overlay
            if workspaceManager.showShortcuts {
                KeyboardShortcutsOverlay()
            }
        }
        .onAppear {
            setupKeyboardShortcuts()
        }
    }
    
    private func setupKeyboardShortcuts() {
        // Setup global keyboard shortcuts
        workspaceManager.registerShortcuts()
    }
}

// MARK: - Workspace Content

struct WorkspaceContent: View {
    let workspace: Workspace
    @StateObject private var windowManager = WindowManager.shared
    
    var body: some View {
        ZStack {
            ForEach(windowManager.windows(in: workspace)) { window in
                ManagedWindowView(window: window)
            }
        }
    }
}

// MARK: - Workspace Overview

struct WorkspaceOverview: View {
    @Binding var isShowing: Bool
    @StateObject private var workspaceManager = WorkspaceManager.shared
    @State private var hoveredWorkspace: Int?
    @State private var draggedWindow: ManagedWindow?
    
    let columns = [
        GridItem(.adaptive(minimum: 300, maximum: 400))
    ]
    
    var body: some View {
        ZStack {
            // Background
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture { isShowing = false }
            
            VStack(spacing: 20) {
                // Title
                Text("Workspaces")
                    .font(.largeTitle)
                    .fontWeight(.thin)
                    .foregroundColor(.white)
                
                // Workspace Grid
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 20) {
                        ForEach(workspaceManager.workspaces) { workspace in
                            WorkspaceThumbnail(
                                workspace: workspace,
                                isHovered: hoveredWorkspace == workspace.id,
                                isCurrent: workspaceManager.currentWorkspaceIndex == workspace.id - 1,
                                onSelect: {
                                    workspaceManager.switchToWorkspace(workspace.id - 1)
                                    isShowing = false
                                },
                                onHover: { isHovered in
                                    hoveredWorkspace = isHovered ? workspace.id : nil
                                }
                            )
                        }
                        
                        // Add workspace button
                        AddWorkspaceButton {
                            workspaceManager.addWorkspace()
                        }
                    }
                    .padding(40)
                }
                
                // Quick actions
                HStack(spacing: 20) {
                    Text("⌘+↑ Overview")
                    Text("⌘+← Previous")
                    Text("⌘+→ Next")
                    Text("⌘+Number Switch")
                }
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
                .padding(.bottom)
            }
        }
    }
}

struct WorkspaceThumbnail: View {
    let workspace: Workspace
    let isHovered: Bool
    let isCurrent: Bool
    let onSelect: () -> Void
    let onHover: (Bool) -> Void
    
    @StateObject private var windowManager = WindowManager.shared
    
    var body: some View {
        VStack(spacing: 8) {
            // Workspace preview
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.primary.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isCurrent ? Color.accentColor : Color.clear, lineWidth: 3)
                    )
                
                // Window previews
                GeometryReader { geometry in
                    ForEach(windowManager.windows(in: workspace)) { window in
                        WindowPreview(window: window, in: geometry.size)
                    }
                }
                .padding(10)
                
                // Workspace number
                VStack {
                    HStack {
                        Text("\(workspace.id)")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Circle().fill(Color.accentColor))
                        Spacer()
                    }
                    Spacer()
                }
                .padding(10)
            }
            .frame(height: 200)
            .scaleEffect(isHovered ? 1.05 : 1.0)
            .shadow(radius: isHovered ? 20 : 10)
            
            // Workspace name
            Text(workspace.name)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)
            
            // Window count
            Text("\(workspace.windowIDs.count) windows")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .onHover { onHover($0) }
        .onTapGesture { onSelect() }
        .animation(.spring(response: 0.3), value: isHovered)
    }
}

struct WindowPreview: View {
    let window: ManagedWindow
    let containerSize: CGSize
    
    var scaledFrame: CGRect {
        let scale = min(containerSize.width / 1920, containerSize.height / 1080)
        return CGRect(
            x: window.frame.origin.x * scale,
            y: window.frame.origin.y * scale,
            width: window.frame.width * scale,
            height: window.frame.height * scale
        )
    }
    
    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(Color.white.opacity(0.2))
            .overlay(
                VStack {
                    HStack {
                        Image(systemName: window.appIcon)
                            .font(.caption)
                        Text(window.title)
                            .font(.caption2)
                            .lineLimit(1)
                        Spacer()
                    }
                    .padding(4)
                    Spacer()
                }
            )
            .frame(width: scaledFrame.width, height: scaledFrame.height)
            .position(x: scaledFrame.midX, y: scaledFrame.midY)
    }
}

struct AddWorkspaceButton: View {
    let action: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        VStack {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.primary.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.primary.opacity(0.2), style: StrokeStyle(lineWidth: 2, dash: [5]))
                    )
                
                Image(systemName: "plus")
                    .font(.system(size: 48))
                    .foregroundColor(.secondary)
            }
            .frame(height: 200)
            .scaleEffect(isHovered ? 1.05 : 1.0)
            
            Text("Add Workspace")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
        .onHover { isHovered = $0 }
        .onTapGesture { action() }
        .animation(.spring(response: 0.3), value: isHovered)
    }
}

// MARK: - Window Management

struct ManagedWindowView: View {
    @ObservedObject var window: ManagedWindow
    @State private var isDragging = false
    @State private var isResizing = false
    @State private var resizeEdge: ResizeEdge?
    
    var body: some View {
        ZStack {
            // Window content
            WindowContent(window: window)
                .frame(width: window.frame.width, height: window.frame.height)
                .background(WindowBackground())
                .overlay(WindowBorder(isActive: window.isActive))
                .shadow(radius: window.isActive ? 20 : 10)
            
            // Window controls
            if window.isActive || window.isHovered {
                WindowControls(window: window)
            }
            
            // Resize handles
            if window.isActive && !window.isMaximized {
                ResizeHandles(window: window)
            }
        }
        .position(x: window.frame.midX, y: window.frame.midY)
        .animation(.spring(response: 0.3), value: window.frame)
        .gesture(
            DragGesture()
                .onChanged { value in
                    if !window.isMaximized {
                        window.frame.origin.x += value.translation.width
                        window.frame.origin.y += value.translation.height
                    }
                }
        )
    }
}

struct WindowContent: View {
    let window: ManagedWindow
    
    var body: some View {
        VStack(spacing: 0) {
            // Title bar
            WindowTitleBar(window: window)
            
            // Content area
            Rectangle()
                .fill(Color.primary.opacity(0.05))
                .overlay(
                    Text(window.content)
                        .padding()
                )
        }
        .cornerRadius(window.isMaximized ? 0 : 8)
    }
}

struct WindowTitleBar: View {
    @ObservedObject var window: ManagedWindow
    
    var body: some View {
        HStack {
            // Traffic lights
            HStack(spacing: 8) {
                WindowButton(color: .red) {
                    WindowManager.shared.closeWindow(window)
                }
                WindowButton(color: .yellow) {
                    window.isMinimized.toggle()
                }
                WindowButton(color: .green) {
                    window.isMaximized.toggle()
                }
            }
            .padding(.leading, 12)
            
            Spacer()
            
            // Title
            Text(window.title)
                .font(.system(size: 13, weight: .medium))
            
            Spacer()
            
            // App icon
            Image(systemName: window.appIcon)
                .padding(.trailing, 12)
        }
        .frame(height: 28)
        .background(.regularMaterial)
    }
}

struct WindowButton: View {
    let color: Color
    let action: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        Circle()
            .fill(isHovered ? color : Color.gray.opacity(0.3))
            .frame(width: 12, height: 12)
            .onHover { isHovered = $0 }
            .onTapGesture { action() }
    }
}

// MARK: - Window Snap Indicators

struct WindowSnapIndicators: View {
    @StateObject private var snapManager = WindowSnapManager.shared
    
    var body: some View {
        ZStack {
            // Left snap zone
            if snapManager.showLeftSnap {
                HStack {
                    Rectangle()
                        .fill(Color.accentColor.opacity(0.3))
                        .frame(width: snapManager.snapZoneWidth)
                    Spacer()
                }
            }
            
            // Right snap zone
            if snapManager.showRightSnap {
                HStack {
                    Spacer()
                    Rectangle()
                        .fill(Color.accentColor.opacity(0.3))
                        .frame(width: snapManager.snapZoneWidth)
                }
            }
            
            // Top snap zone (maximize)
            if snapManager.showTopSnap {
                VStack {
                    Rectangle()
                        .fill(Color.accentColor.opacity(0.3))
                        .frame(height: 40)
                    Spacer()
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

// MARK: - Managers

public class WorkspaceManager: ObservableObject {
    static let shared = WorkspaceManager()
    
    @Published var workspaces: [Workspace] = []
    @Published var currentWorkspaceIndex = 0
    @Published var showShortcuts = false
    
    var currentWorkspace: Workspace {
        workspaces[currentWorkspaceIndex]
    }
    
    private init() {
        setupWorkspaces()
    }
    
    private func setupWorkspaces() {
        for i in 1...4 {
            workspaces.append(Workspace(id: i, name: "Workspace \(i)"))
        }
    }
    
    func addWorkspace() {
        let id = workspaces.count + 1
        workspaces.append(Workspace(id: id, name: "Workspace \(id)"))
    }
    
    func removeWorkspace(_ workspace: Workspace) {
        guard workspaces.count > 1 else { return }
        workspaces.removeAll { $0.id == workspace.id }
    }
    
    func switchToWorkspace(_ index: Int) {
        guard index >= 0 && index < workspaces.count else { return }
        currentWorkspaceIndex = index
    }
    
    func moveToNextWorkspace() {
        let nextIndex = (currentWorkspaceIndex + 1) % workspaces.count
        switchToWorkspace(nextIndex)
    }
    
    func moveToPreviousWorkspace() {
        let prevIndex = currentWorkspaceIndex == 0 ? workspaces.count - 1 : currentWorkspaceIndex - 1
        switchToWorkspace(prevIndex)
    }
    
    func registerShortcuts() {
        // Register global keyboard shortcuts
        // This would interface with the system
    }
}

public class WindowManager: ObservableObject {
    static let shared = WindowManager()
    
    @Published var allWindows: [ManagedWindow] = []
    @Published var activeWindow: ManagedWindow?
    
    private init() {}
    
    func windows(in workspace: Workspace) -> [ManagedWindow] {
        allWindows.filter { workspace.windowIDs.contains($0.id) }
    }
    
    func createWindow(title: String, in workspace: Workspace) -> ManagedWindow {
        let window = ManagedWindow(
            title: title,
            workspaceID: workspace.id
        )
        allWindows.append(window)
        return window
    }
    
    func closeWindow(_ window: ManagedWindow) {
        allWindows.removeAll { $0.id == window.id }
        if activeWindow?.id == window.id {
            activeWindow = allWindows.last
        }
    }
    
    func focusWindow(_ window: ManagedWindow) {
        activeWindow?.isActive = false
        window.isActive = true
        activeWindow = window
    }
}

public class WindowSnapManager: ObservableObject {
    static let shared = WindowSnapManager()
    
    @Published var showLeftSnap = false
    @Published var showRightSnap = false
    @Published var showTopSnap = false
    
    let snapZoneWidth: CGFloat = 400
    
    private init() {}
    
    func checkSnapZone(for window: ManagedWindow, at position: CGPoint) {
        // Check left edge
        showLeftSnap = position.x < 50
        
        // Check right edge
        showRightSnap = position.x > NSScreen.main?.frame.width ?? 1920 - 50
        
        // Check top edge
        showTopSnap = position.y < 50
    }
    
    func snapWindow(_ window: ManagedWindow) {
        if showLeftSnap {
            snapToLeft(window)
        } else if showRightSnap {
            snapToRight(window)
        } else if showTopSnap {
            maximize(window)
        }
        
        clearSnapIndicators()
    }
    
    private func snapToLeft(_ window: ManagedWindow) {
        window.frame = CGRect(
            x: 0,
            y: 0,
            width: (NSScreen.main?.frame.width ?? 1920) / 2,
            height: NSScreen.main?.frame.height ?? 1080
        )
    }
    
    private func snapToRight(_ window: ManagedWindow) {
        let screenWidth = NSScreen.main?.frame.width ?? 1920
        window.frame = CGRect(
            x: screenWidth / 2,
            y: 0,
            width: screenWidth / 2,
            height: NSScreen.main?.frame.height ?? 1080
        )
    }
    
    private func maximize(_ window: ManagedWindow) {
        window.isMaximized = true
        window.frame = NSScreen.main?.frame ?? CGRect(x: 0, y: 0, width: 1920, height: 1080)
    }
    
    private func clearSnapIndicators() {
        showLeftSnap = false
        showRightSnap = false
        showTopSnap = false
    }
}

// MARK: - Models

public class ManagedWindow: ObservableObject, Identifiable {
    public let id = UUID()
    @Published var title: String
    @Published var frame: CGRect
    @Published var isMinimized = false
    @Published var isMaximized = false
    @Published var isActive = false
    @Published var isHovered = false
    @Published var workspaceID: Int
    
    let appIcon: String
    let content: String
    
    init(title: String, workspaceID: Int) {
        self.title = title
        self.workspaceID = workspaceID
        self.appIcon = "app.fill"
        self.content = "Window content for \(title)"
        self.frame = CGRect(
            x: CGFloat.random(in: 100...500),
            y: CGFloat.random(in: 100...500),
            width: 800,
            height: 600
        )
    }
}

struct WindowBackground: View {
    var body: some View {
        Color.primary.opacity(0.95)
            .background(.regularMaterial)
    }
}

struct WindowBorder: View {
    let isActive: Bool
    
    var body: some View {
        RoundedRectangle(cornerRadius: 8)
            .stroke(isActive ? Color.accentColor : Color.clear, lineWidth: 2)
    }
}

struct WindowControls: View {
    let window: ManagedWindow
    
    var body: some View {
        EmptyView() // Implemented in WindowTitleBar
    }
}

struct ResizeHandles: View {
    let window: ManagedWindow
    
    var body: some View {
        EmptyView() // Would implement resize handles here
    }
}

enum ResizeEdge {
    case top, bottom, left, right
    case topLeft, topRight, bottomLeft, bottomRight
}

// MARK: - Keyboard Shortcuts Overlay

struct KeyboardShortcutsOverlay: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Keyboard Shortcuts")
                .font(.title2)
                .fontWeight(.bold)
            
            Divider()
            
            Group {
                ShortcutRow(keys: "⌘ + Space", action: "Application Launcher")
                ShortcutRow(keys: "⌘ + Tab", action: "Switch Applications")
                ShortcutRow(keys: "⌘ + `", action: "Switch Windows")
                ShortcutRow(keys: "⌘ + ↑", action: "Workspace Overview")
                ShortcutRow(keys: "⌘ + ←/→", action: "Switch Workspace")
                ShortcutRow(keys: "⌘ + 1-9", action: "Go to Workspace")
                ShortcutRow(keys: "⌘ + Shift + Q", action: "Close Window")
                ShortcutRow(keys: "⌘ + M", action: "Minimize Window")
                ShortcutRow(keys: "⌘ + F", action: "Fullscreen")
            }
        }
        .padding()
        .background(.regularMaterial)
        .cornerRadius(12)
        .shadow(radius: 20)
        .frame(width: 400)
    }
}

struct ShortcutRow: View {
    let keys: String
    let action: String
    
    var body: some View {
        HStack {
            Text(keys)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.accentColor)
                .frame(width: 120, alignment: .leading)
            
            Text(action)
                .foregroundColor(.secondary)
            
            Spacer()
        }
    }
}