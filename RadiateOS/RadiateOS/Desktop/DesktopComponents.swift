import SwiftUI

// MARK: - Window Manager
class WindowManager: ObservableObject {
    @Published var windows: [AppWindow] = []
    private var windowIdCounter = 0
    
    func openWindow(_ appId: String, title: String) {
        let window = AppWindow(
            id: windowIdCounter,
            appId: appId,
            title: title,
            position: CGPoint(x: 100 + CGFloat(windowIdCounter * 30), y: 100 + CGFloat(windowIdCounter * 30)),
            size: CGSize(width: 800, height: 600)
        )
        windows.append(window)
        windowIdCounter += 1
        
        // Bring to front
        bringToFront(window)
    }
    
    func closeWindow(_ window: AppWindow) {
        windows.removeAll { $0.id == window.id }
    }
    
    func minimizeWindow(_ window: AppWindow) {
        if let index = windows.firstIndex(where: { $0.id == window.id }) {
            windows[index].isMinimized.toggle()
        }
    }
    
    func maximizeWindow(_ window: AppWindow) {
        if let index = windows.firstIndex(where: { $0.id == window.id }) {
            windows[index].isMaximized.toggle()
        }
    }
    
    func bringToFront(_ window: AppWindow) {
        if let index = windows.firstIndex(where: { $0.id == window.id }) {
            let window = windows.remove(at: index)
            windows.append(window)
        }
    }
}

// MARK: - App Window Model
class AppWindow: ObservableObject, Identifiable {
    let id: Int
    let appId: String
    @Published var title: String
    @Published var position: CGPoint
    @Published var size: CGSize
    @Published var isMinimized: Bool = false
    @Published var isMaximized: Bool = false
    @Published var zIndex: Int = 0
    
    init(id: Int, appId: String, title: String, position: CGPoint, size: CGSize) {
        self.id = id
        self.appId = appId
        self.title = title
        self.position = position
        self.size = size
    }
}

// MARK: - Draggable Window
struct DraggableWindow: View {
    @ObservedObject var window: AppWindow
    let windowManager: WindowManager
    @State private var dragOffset = CGSize.zero
    @State private var isDragging = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Title bar
            WindowTitleBar(window: window, windowManager: windowManager)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            if !isDragging {
                                windowManager.bringToFront(window)
                                isDragging = true
                            }
                            dragOffset = value.translation
                        }
                        .onEnded { value in
                            window.position.x += value.translation.width
                            window.position.y += value.translation.height
                            dragOffset = .zero
                            isDragging = false
                        }
                )
            
            // Window content
            WindowContent(appId: window.appId)
                .frame(width: window.size.width, height: window.size.height)
        }
        .background(.ultraThinMaterial)
        .cornerRadius(10)
        .shadow(radius: isDragging ? 15 : 10)
        .offset(x: window.position.x + dragOffset.width, y: window.position.y + dragOffset.height)
        .opacity(window.isMinimized ? 0 : 1)
        .scaleEffect(window.isMinimized ? 0.1 : 1)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: window.isMinimized)
    }
}

// MARK: - Window Title Bar
struct WindowTitleBar: View {
    @ObservedObject var window: AppWindow
    let windowManager: WindowManager
    
    var body: some View {
        HStack {
            HStack(spacing: 8) {
                // Close button
                Button(action: { windowManager.closeWindow(window) }) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 12, height: 12)
                        .overlay(
                            Image(systemName: "xmark")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(.red.opacity(0.8))
                                .opacity(0)
                        )
                }
                .buttonStyle(.plain)
                
                // Minimize button
                Button(action: { windowManager.minimizeWindow(window) }) {
                    Circle()
                        .fill(Color.yellow)
                        .frame(width: 12, height: 12)
                        .overlay(
                            Image(systemName: "minus")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(.yellow.opacity(0.8))
                                .opacity(0)
                        )
                }
                .buttonStyle(.plain)
                
                // Maximize button
                Button(action: { windowManager.maximizeWindow(window) }) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 12, height: 12)
                        .overlay(
                            Image(systemName: "arrow.up.left.and.arrow.down.right")
                                .font(.system(size: 6, weight: .bold))
                                .foregroundColor(.green.opacity(0.8))
                                .opacity(0)
                        )
                }
                .buttonStyle(.plain)
            }
            
            Spacer()
            
            Text(window.title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
            
            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.2))
    }
}

// MARK: - Window Content
struct WindowContent: View {
    let appId: String
    
    var body: some View {
        Group {
            switch appId {
            case "terminal":
                TerminalView()
            case "files":
                FileManagerView()
            case "settings":
                SettingsView()
            case "monitor":
                SystemMonitorView()
            case "browser":
                BrowserView()
            case "notes":
                NotesView()
            case "calculator":
                CalculatorView()
            default:
                DefaultAppView(appId: appId)
            }
        }
    }
}

// MARK: - Launchpad
struct LaunchpadView: View {
    @Binding var showLaunchpad: Bool
    let windowManager: WindowManager
    
    let apps = [
        ("Terminal", "terminal", "terminal"),
        ("Files", "doc.text", "files"),
        ("Browser", "globe", "browser"),
        ("Settings", "gearshape", "settings"),
        ("Monitor", "chart.line.uptrend.xyaxis", "monitor"),
        ("Notes", "note.text", "notes"),
        ("Calculator", "plusminus.circle", "calculator"),
        ("Photos", "photo", "photos"),
        ("Music", "music.note", "music"),
        ("Messages", "message", "messages"),
        ("Mail", "envelope", "mail"),
        ("Calendar", "calendar", "calendar")
    ]
    
    var body: some View {
        ZStack {
            // Background blur
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation {
                        showLaunchpad = false
                    }
                }
            
            // App grid
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(100), spacing: 20), count: 6), spacing: 20) {
                ForEach(apps, id: \.2) { app in
                    LaunchpadIcon(
                        name: app.0,
                        icon: app.1,
                        action: {
                            windowManager.openWindow(app.2, title: app.0)
                            withAnimation {
                                showLaunchpad = false
                            }
                        }
                    )
                }
            }
            .padding(50)
        }
        .transition(.opacity)
    }
}

struct LaunchpadIcon: View {
    let name: String
    let icon: String
    let action: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 70, height: 70)
                        .shadow(radius: isHovered ? 8 : 4)
                    
                    Image(systemName: icon)
                        .font(.system(size: 30))
                        .foregroundColor(.white)
                }
                .scaleEffect(isHovered ? 1.1 : 1.0)
                
                Text(name)
                    .font(.caption)
                    .foregroundColor(.white)
            }
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.spring(response: 0.3)) {
                isHovered = hovering
            }
        }
    }
}

// MARK: - Spotlight Search
struct SpotlightView: View {
    @Binding var show: Bool
    let windowManager: WindowManager
    @State private var searchText = ""
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.white.opacity(0.6))
                
                TextField("Spotlight Search", text: $searchText)
                    .textFieldStyle(.plain)
                    .foregroundColor(.white)
                    .focused($isFocused)
                    .onSubmit {
                        performSearch()
                    }
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(10)
            
            if !searchText.isEmpty {
                SearchResultsView(searchText: searchText, windowManager: windowManager) {
                    show = false
                }
            }
        }
        .frame(width: 600)
        .padding(.top, 100)
        .onAppear {
            isFocused = true
        }
    }
    
    private func performSearch() {
        // Implement search functionality
    }
}

struct SearchResultsView: View {
    let searchText: String
    let windowManager: WindowManager
    let onSelect: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(0..<5, id: \.self) { index in
                HStack {
                    Image(systemName: "doc.text")
                        .foregroundColor(.white.opacity(0.6))
                    
                    VStack(alignment: .leading) {
                        Text("Result \(index + 1)")
                            .foregroundColor(.white)
                        Text("Matching: \(searchText)")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.05))
                .onTapGesture {
                    onSelect()
                }
            }
        }
        .background(.ultraThinMaterial)
        .cornerRadius(10)
        .padding(.top, 5)
    }
}

// MARK: - Notification Center
struct NotificationCenterView: View {
    @Binding var show: Bool
    
    var body: some View {
        HStack {
            Spacer()
            
            VStack {
                HStack {
                    Text("Notification Center")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Button(action: { show = false }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .buttonStyle(.plain)
                }
                .padding()
                
                ScrollView {
                    VStack(spacing: 10) {
                        NotificationCard(
                            app: "System Update",
                            title: "RadiateOS 2.0.1 Available",
                            message: "New optical processing improvements",
                            time: "2 min ago"
                        )
                        
                        NotificationCard(
                            app: "Terminal",
                            title: "Process Completed",
                            message: "Build finished successfully",
                            time: "5 min ago"
                        )
                        
                        NotificationCard(
                            app: "Files",
                            title: "Download Complete",
                            message: "macOS Sonoma 14.7.8 (13.3 GB)",
                            time: "10 min ago"
                        )
                    }
                    .padding()
                }
                
                Spacer()
            }
            .frame(width: 350)
            .background(.ultraThinMaterial)
        }
        .transition(.move(edge: .trailing))
    }
}

struct NotificationCard: View {
    let app: String
    let title: String
    let message: String
    let time: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(app)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                
                Spacer()
                
                Text(time)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.4))
            }
            
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
            
            Text(message)
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(10)
    }
}

// MARK: - Default App View
struct DefaultAppView: View {
    let appId: String
    
    var body: some View {
        VStack {
            Image(systemName: "app.dashed")
                .font(.system(size: 60))
                .foregroundColor(.white.opacity(0.3))
            
            Text("App: \(appId)")
                .font(.title2)
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.2))
    }
}