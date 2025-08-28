import SwiftUI

// MARK: - Desktop Content

struct DesktopContent: View {
    @StateObject private var fileManager = DesktopFileManager()
    @State private var selectedItems: Set<String> = []
    
    var body: some View {
        ZStack {
            // Desktop Icons
            ForEach(fileManager.desktopItems) { item in
                DesktopIcon(
                    item: item,
                    isSelected: selectedItems.contains(item.id),
                    onSelect: { 
                        if selectedItems.contains(item.id) {
                            selectedItems.remove(item.id)
                        } else {
                            selectedItems.insert(item.id)
                        }
                    },
                    onOpen: { fileManager.open(item) }
                )
                .position(item.position)
            }
            
            // Desktop Widgets
            VStack {
                HStack {
                    Spacer()
                    SystemWidgets()
                        .padding()
                }
                Spacer()
            }
        }
    }
}

struct DesktopIcon: View {
    let item: DesktopItem
    let isSelected: Bool
    let onSelect: () -> Void
    let onOpen: () -> Void
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: item.icon)
                .font(.system(size: 48))
                .foregroundColor(item.type.color)
                .frame(width: 64, height: 64)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? Color.accentColor.opacity(0.2) : Color.clear)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
                )
            
            Text(item.name)
                .font(.system(size: 11))
                .foregroundColor(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(width: 80)
        }
        .onTapGesture { onSelect() }
        .onTapGesture(count: 2) { onOpen() }
    }
}

// MARK: - System Widgets

struct SystemWidgets: View {
    var body: some View {
        VStack(spacing: 12) {
            ClockWidget()
            WeatherWidget()
            SystemStatsWidget()
        }
    }
}

struct ClockWidget: View {
    @State private var currentTime = Date()
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(spacing: 4) {
            Text(currentTime, style: .time)
                .font(.system(size: 32, weight: .thin, design: .rounded))
            
            Text(currentTime, style: .date)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(width: 200)
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .onReceive(timer) { _ in
            currentTime = Date()
        }
    }
}

struct WeatherWidget: View {
    @State private var temperature = "72°"
    @State private var condition = "Partly Cloudy"
    @State private var icon = "cloud.sun.fill"
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 36))
                .foregroundColor(.yellow)
            
            VStack(alignment: .leading) {
                Text(temperature)
                    .font(.system(size: 24, weight: .medium))
                Text(condition)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(width: 200)
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }
}

struct SystemStatsWidget: View {
    @StateObject private var systemInfo = SystemInfoProvider()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("System")
                .font(.system(size: 14, weight: .semibold))
            
            StatRow(label: "CPU", value: systemInfo.cpuUsage, color: .blue)
            StatRow(label: "Memory", value: systemInfo.memoryUsage, color: .green)
            StatRow(label: "Network", text: systemInfo.networkStatus, color: .purple)
        }
        .padding()
        .frame(width: 200)
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }
}

struct StatRow: View {
    let label: String
    var value: Double? = nil
    var text: String? = nil
    let color: Color
    
    var body: some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
            
            Spacer()
            
            if let value = value {
                Text("\(Int(value))%")
                    .font(.system(size: 12, weight: .medium))
            } else if let text = text {
                Text(text)
                    .font(.system(size: 12, weight: .medium))
            }
        }
    }
}

// MARK: - System Tray

struct SystemTray: View {
    @StateObject private var trayManager = SystemTrayManager()
    
    var body: some View {
        HStack(spacing: 12) {
            ForEach(trayManager.trayItems) { item in
                TrayIcon(item: item)
            }
        }
    }
}

struct TrayIcon: View {
    let item: TrayItem
    @State private var showPopover = false
    
    var body: some View {
        Button(action: { showPopover.toggle() }) {
            Image(systemName: item.icon)
                .foregroundColor(item.isActive ? .primary : .secondary)
        }
        .buttonStyle(.plain)
        .popover(isPresented: $showPopover) {
            item.popoverContent()
                .padding()
        }
    }
}

// MARK: - Quick Settings

struct QuickSettingRow: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .frame(width: 20)
                Text(title)
                Spacer()
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(Color.primary.opacity(0.05))
        .cornerRadius(6)
    }
}

struct PowerButton: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title2)
                Text(title)
                    .font(.caption)
            }
            .frame(width: 80, height: 60)
        }
        .buttonStyle(.plain)
        .background(Color.primary.opacity(0.05))
        .cornerRadius(8)
    }
}

struct CategoryButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.accentColor : Color.primary.opacity(0.1))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Trash Icon

struct TrashIcon: View {
    @State private var isDragOver = false
    @State private var itemCount = 0
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Image(systemName: itemCount > 0 ? "trash.fill" : "trash")
                    .font(.system(size: 32))
                    .foregroundColor(isDragOver ? .red : .secondary)
                    .frame(width: 48, height: 48)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(isDragOver ? Color.red.opacity(0.1) : Color.clear)
                    )
                
                if itemCount > 0 {
                    Text("\(itemCount)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .padding(4)
                        .background(Circle().fill(Color.red))
                        .offset(x: 16, y: -16)
                }
            }
        }
        .onDrop(of: ["public.data"], isTargeted: $isDragOver) { _ in
            itemCount += 1
            return true
        }
        .onTapGesture(count: 2) {
            if itemCount > 0 {
                withAnimation {
                    itemCount = 0
                }
            }
        }
    }
}

// MARK: - Notification Badge

struct NotificationBadge: View {
    let count: Int
    
    var body: some View {
        if count > 0 {
            Text("\(min(count, 99))")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.white)
                .padding(3)
                .background(Circle().fill(Color.red))
                .offset(x: 8, y: -8)
        }
    }
}

// MARK: - Supporting Managers

class DesktopFileManager: ObservableObject {
    @Published var desktopItems: [DesktopItem] = []
    
    init() {
        loadDesktopItems()
    }
    
    private func loadDesktopItems() {
        desktopItems = [
            DesktopItem(
                name: "Home",
                icon: "house.fill",
                type: .folder,
                position: CGPoint(x: 100, y: 100)
            ),
            DesktopItem(
                name: "Documents",
                icon: "doc.text.fill",
                type: .folder,
                position: CGPoint(x: 100, y: 200)
            ),
            DesktopItem(
                name: "Downloads",
                icon: "arrow.down.circle.fill",
                type: .folder,
                position: CGPoint(x: 100, y: 300)
            ),
            DesktopItem(
                name: "README.md",
                icon: "doc.text",
                type: .file,
                position: CGPoint(x: 100, y: 400)
            ),
        ]
    }
    
    func open(_ item: DesktopItem) {
        // Open file or folder
        print("Opening \(item.name)")
    }
}

class SystemTrayManager: ObservableObject {
    @Published var trayItems: [TrayItem] = []
    
    init() {
        setupTrayItems()
    }
    
    private func setupTrayItems() {
        trayItems = [
            TrayItem(
                icon: "wifi",
                isActive: true,
                popoverContent: { AnyView(NetworkPopover()) }
            ),
            TrayItem(
                icon: "speaker.wave.2.fill",
                isActive: true,
                popoverContent: { AnyView(VolumePopover()) }
            ),
            TrayItem(
                icon: "battery.75",
                isActive: true,
                popoverContent: { AnyView(BatteryPopover()) }
            ),
        ]
    }
}

// MARK: - Popover Views

struct NetworkPopover: View {
    var body: some View {
        VStack(alignment: .leading) {
            Text("Network")
                .font(.headline)
            Divider()
            HStack {
                Image(systemName: "wifi")
                Text("Connected to RadiateNetwork")
            }
            Text("Signal: Excellent")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(width: 250)
    }
}

struct VolumePopover: View {
    @State private var volume: Double = 75
    
    var body: some View {
        VStack {
            Text("Volume")
                .font(.headline)
            Divider()
            HStack {
                Image(systemName: "speaker.fill")
                Slider(value: $volume, in: 0...100)
                Image(systemName: "speaker.wave.3.fill")
            }
            Text("\(Int(volume))%")
                .font(.caption)
        }
        .frame(width: 250)
    }
}

struct BatteryPopover: View {
    var body: some View {
        VStack(alignment: .leading) {
            Text("Battery")
                .font(.headline)
            Divider()
            HStack {
                Image(systemName: "battery.75")
                Text("75% - Charging")
            }
            Text("Time until full: 45 minutes")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(width: 250)
    }
}

// MARK: - Models

struct DesktopItem: Identifiable {
    let id = UUID().uuidString
    let name: String
    let icon: String
    let type: ItemType
    var position: CGPoint
    
    enum ItemType {
        case file
        case folder
        case application
        
        var color: Color {
            switch self {
            case .file: return .blue
            case .folder: return .orange
            case .application: return .green
            }
        }
    }
}

struct TrayItem: Identifiable {
    let id = UUID()
    let icon: String
    let isActive: Bool
    let popoverContent: () -> AnyView
}