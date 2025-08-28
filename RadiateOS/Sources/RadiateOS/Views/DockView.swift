import SwiftUI

struct DockView: View {
    @ObservedObject var osManager: OSManager
    @Binding var selectedApp: OSApplication?
    @Binding var hoveredDockItem: String?
    @Binding var showLaunchpad: Bool
    @State private var draggedItem: OSApplication?
    @State private var dockScale: CGFloat = 1.0
    
    let iconSize: CGFloat = 48
    let magnificationScale: CGFloat = 1.5
    
    var body: some View {
        HStack(spacing: 4) {
            // Finder
            DockIcon(
                icon: "folder.fill",
                name: "Finder",
                color: RadiateDesign.Colors.azure,
                isHovered: hoveredDockItem == "Finder",
                isRunning: true,
                action: {
                    selectedApp = osManager.applications.first { $0.id == "finder" }
                },
                onHover: { isHovered in
                    hoveredDockItem = isHovered ? "Finder" : nil
                }
            )
            
            // Launchpad
            DockIcon(
                icon: "square.grid.3x3.fill",
                name: "Launchpad",
                color: RadiateDesign.Colors.indigo,
                isHovered: hoveredDockItem == "Launchpad",
                isRunning: false,
                action: {
                    withAnimation(RadiateDesign.Animations.spring) {
                        showLaunchpad.toggle()
                    }
                },
                onHover: { isHovered in
                    hoveredDockItem = isHovered ? "Launchpad" : nil
                }
            )
            
            Divider()
                .frame(height: 40)
                .padding(.horizontal, 8)
            
            // Running Applications
            ForEach(osManager.runningApplications) { app in
                DockIcon(
                    icon: app.icon,
                    name: app.name,
                    color: app.accentColor,
                    isHovered: hoveredDockItem == app.id,
                    isRunning: true,
                    action: {
                        selectedApp = app
                        osManager.setActiveApplication(app)
                    },
                    onHover: { isHovered in
                        hoveredDockItem = isHovered ? app.id : nil
                    }
                )
                .onDrag {
                    draggedItem = app
                    return NSItemProvider(object: app.id as NSString)
                }
            }
            
            // Pinned Applications
            ForEach(osManager.pinnedApplications) { app in
                if !osManager.runningApplications.contains(where: { $0.id == app.id }) {
                    DockIcon(
                        icon: app.icon,
                        name: app.name,
                        color: app.accentColor,
                        isHovered: hoveredDockItem == app.id,
                        isRunning: false,
                        action: {
                            osManager.launchApplication(app)
                            selectedApp = app
                        },
                        onHover: { isHovered in
                            hoveredDockItem = isHovered ? app.id : nil
                        }
                    )
                }
            }
            
            Divider()
                .frame(height: 40)
                .padding(.horizontal, 8)
            
            // System Applications
            DockIcon(
                icon: "gear",
                name: "System Settings",
                color: RadiateDesign.Colors.ultraviolet,
                isHovered: hoveredDockItem == "Settings",
                isRunning: false,
                action: {
                    if let settings = osManager.applications.first(where: { $0.id == "settings" }) {
                        selectedApp = settings
                        osManager.launchApplication(settings)
                    }
                },
                onHover: { isHovered in
                    hoveredDockItem = isHovered ? "Settings" : nil
                }
            )
            
            // Trash
            DockIcon(
                icon: osManager.trashCount > 0 ? "trash.fill" : "trash",
                name: "Trash",
                color: LinearGradient(
                    colors: [Color.gray, Color.gray.opacity(0.7)],
                    startPoint: .top,
                    endPoint: .bottom
                ),
                isHovered: hoveredDockItem == "Trash",
                isRunning: false,
                action: {
                    // Open trash
                },
                onHover: { isHovered in
                    hoveredDockItem = isHovered ? "Trash" : nil
                }
            )
        }
        .padding(.horizontal, RadiateDesign.Spacing.md)
        .padding(.vertical, RadiateDesign.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: RadiateDesign.CornerRadius.xl)
                .fill(RadiateDesign.Colors.glassDark)
                .overlay(
                    RoundedRectangle(cornerRadius: RadiateDesign.CornerRadius.xl)
                        .stroke(RadiateDesign.Colors.glassBorder, lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
                .blur(radius: 20)
        )
        .scaleEffect(dockScale)
        .onHover { isHovered in
            withAnimation(RadiateDesign.Animations.fast) {
                dockScale = isHovered ? 1.02 : 1.0
            }
        }
    }
}

struct DockIcon: View {
    let icon: String
    let name: String
    let color: LinearGradient
    let isHovered: Bool
    let isRunning: Bool
    let action: () -> Void
    let onHover: (Bool) -> Void
    
    @State private var bounce = false
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                // Icon Background
                RoundedRectangle(cornerRadius: RadiateDesign.CornerRadius.md)
                    .fill(color)
                    .frame(
                        width: isHovered ? 56 : 48,
                        height: isHovered ? 56 : 48
                    )
                    .shadow(
                        color: color.gradient.stops.first?.color.opacity(0.5) ?? .clear,
                        radius: isHovered ? 15 : 5,
                        x: 0,
                        y: isHovered ? 5 : 2
                    )
                
                // Icon
                Image(systemName: icon)
                    .font(.system(size: isHovered ? 28 : 24, weight: .medium))
                    .foregroundColor(.white)
                    .scaleEffect(bounce ? 1.2 : 1.0)
            }
            .offset(y: isHovered ? -10 : 0)
            .animation(RadiateDesign.Animations.spring, value: isHovered)
            
            // Running Indicator
            if isRunning {
                Circle()
                    .fill(RadiateDesign.Colors.text)
                    .frame(width: 4, height: 4)
                    .shadow(color: RadiateDesign.Colors.neonBlue, radius: 3)
            }
        }
        .onHover { hovering in
            onHover(hovering)
            if hovering {
                withAnimation(RadiateDesign.Animations.bounce) {
                    bounce = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    bounce = false
                }
            }
        }
        .onTapGesture {
            action()
            withAnimation(RadiateDesign.Animations.bounce) {
                bounce = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                bounce = false
            }
        }
    }
}