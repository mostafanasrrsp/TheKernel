import SwiftUI
import Combine

/// Pop!_OS-inspired tiling window manager for RadiateOS
/// Provides automatic window tiling, keyboard shortcuts, and workspace management
public class TilingWindowManager: ObservableObject {
    
    // MARK: - Singleton
    public static let shared = TilingWindowManager()
    
    // MARK: - Properties
    @Published public var windows: [ManagedWindow] = []
    @Published public var activeWindow: ManagedWindow?
    @Published public var currentWorkspace: Int = 1
    @Published public var tilingEnabled: Bool = true
    @Published public var gaps: WindowGaps = WindowGaps()
    @Published public var currentLayout: TilingLayout = .tall
    
    private var workspaces: [Int: [ManagedWindow]] = [:]
    private var floatingWindows: Set<UUID> = []
    private var minimizedWindows: Set<UUID> = []
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Tiling Layouts (Pop!_OS inspired)
    public enum TilingLayout: String, CaseIterable {
        case tall = "Tall"              // Master on left, stack on right
        case wide = "Wide"              // Master on top, stack on bottom
        case grid = "Grid"              // Even grid layout
        case spiral = "Spiral"          // Fibonacci spiral
        case centerMaster = "Center"    // Master in center
        case columns = "Columns"        // Equal columns
        case rows = "Rows"              // Equal rows
        case floating = "Floating"      // No tiling
    }
    
    // MARK: - Window Gaps Configuration
    public struct WindowGaps {
        var outer: CGFloat = 8      // Gap from screen edges
        var inner: CGFloat = 8      // Gap between windows
        var smart: Bool = true      // Hide gaps with single window
    }
    
    // MARK: - Initialization
    private init() {
        setupKeyboardShortcuts()
        initializeWorkspaces()
    }
    
    // MARK: - Window Management
    
    public func addWindow(_ window: ManagedWindow) {
        windows.append(window)
        workspaces[currentWorkspace, default: []].append(window)
        
        if tilingEnabled && !floatingWindows.contains(window.id) {
            retile()
        }
        
        // Auto-focus new window
        activeWindow = window
    }
    
    public func removeWindow(_ window: ManagedWindow) {
        windows.removeAll { $0.id == window.id }
        workspaces[currentWorkspace]?.removeAll { $0.id == window.id }
        floatingWindows.remove(window.id)
        minimizedWindows.remove(window.id)
        
        if activeWindow?.id == window.id {
            activeWindow = windows.first
        }
        
        if tilingEnabled {
            retile()
        }
    }
    
    public func focusWindow(_ window: ManagedWindow) {
        activeWindow = window
        
        // Bring to front if floating
        if floatingWindows.contains(window.id) {
            if let index = windows.firstIndex(where: { $0.id == window.id }) {
                let window = windows.remove(at: index)
                windows.append(window)
            }
        }
    }
    
    public func toggleFloating(for window: ManagedWindow? = nil) {
        let targetWindow = window ?? activeWindow
        guard let targetWindow = targetWindow else { return }
        
        if floatingWindows.contains(targetWindow.id) {
            floatingWindows.remove(targetWindow.id)
            retile()
        } else {
            floatingWindows.insert(targetWindow.id)
            // Center floating window
            centerWindow(targetWindow)
        }
    }
    
    public func minimizeWindow(_ window: ManagedWindow? = nil) {
        let targetWindow = window ?? activeWindow
        guard let targetWindow = targetWindow else { return }
        
        minimizedWindows.insert(targetWindow.id)
        
        // Focus next window
        if activeWindow?.id == targetWindow.id {
            focusNextWindow()
        }
        
        retile()
    }
    
    public func restoreWindow(_ window: ManagedWindow) {
        minimizedWindows.remove(window.id)
        focusWindow(window)
        retile()
    }
    
    // MARK: - Tiling
    
    public func retile() {
        guard tilingEnabled else { return }
        
        let visibleWindows = windows.filter { window in
            !floatingWindows.contains(window.id) && 
            !minimizedWindows.contains(window.id) &&
            workspaces[currentWorkspace]?.contains(where: { $0.id == window.id }) ?? false
        }
        
        guard !visibleWindows.isEmpty else { return }
        
        let screenBounds = getScreenBounds()
        let workArea = applyGaps(to: screenBounds, windowCount: visibleWindows.count)
        
        switch currentLayout {
        case .tall:
            layoutTall(windows: visibleWindows, in: workArea)
        case .wide:
            layoutWide(windows: visibleWindows, in: workArea)
        case .grid:
            layoutGrid(windows: visibleWindows, in: workArea)
        case .spiral:
            layoutSpiral(windows: visibleWindows, in: workArea)
        case .centerMaster:
            layoutCenterMaster(windows: visibleWindows, in: workArea)
        case .columns:
            layoutColumns(windows: visibleWindows, in: workArea)
        case .rows:
            layoutRows(windows: visibleWindows, in: workArea)
        case .floating:
            break // No tiling in floating mode
        }
    }
    
    private func layoutTall(windows: [ManagedWindow], in area: CGRect) {
        guard !windows.isEmpty else { return }
        
        if windows.count == 1 {
            // Single window takes full area
            windows[0].frame = area
        } else {
            // Master window on left (50% width)
            let masterWidth = area.width * 0.5 - gaps.inner / 2
            windows[0].frame = CGRect(
                x: area.minX,
                y: area.minY,
                width: masterWidth,
                height: area.height
            )
            
            // Stack remaining windows on right
            let stackX = area.minX + masterWidth + gaps.inner
            let stackWidth = area.width * 0.5 - gaps.inner / 2
            let stackHeight = (area.height - CGFloat(windows.count - 2) * gaps.inner) / CGFloat(windows.count - 1)
            
            for (index, window) in windows.dropFirst().enumerated() {
                window.frame = CGRect(
                    x: stackX,
                    y: area.minY + CGFloat(index) * (stackHeight + gaps.inner),
                    width: stackWidth,
                    height: stackHeight
                )
            }
        }
    }
    
    private func layoutWide(windows: [ManagedWindow], in area: CGRect) {
        guard !windows.isEmpty else { return }
        
        if windows.count == 1 {
            windows[0].frame = area
        } else {
            // Master window on top
            let masterHeight = area.height * 0.5 - gaps.inner / 2
            windows[0].frame = CGRect(
                x: area.minX,
                y: area.minY,
                width: area.width,
                height: masterHeight
            )
            
            // Stack remaining windows below
            let stackY = area.minY + masterHeight + gaps.inner
            let stackHeight = area.height * 0.5 - gaps.inner / 2
            let stackWidth = (area.width - CGFloat(windows.count - 2) * gaps.inner) / CGFloat(windows.count - 1)
            
            for (index, window) in windows.dropFirst().enumerated() {
                window.frame = CGRect(
                    x: area.minX + CGFloat(index) * (stackWidth + gaps.inner),
                    y: stackY,
                    width: stackWidth,
                    height: stackHeight
                )
            }
        }
    }
    
    private func layoutGrid(windows: [ManagedWindow], in area: CGRect) {
        guard !windows.isEmpty else { return }
        
        let count = windows.count
        let cols = Int(ceil(sqrt(Double(count))))
        let rows = Int(ceil(Double(count) / Double(cols)))
        
        let cellWidth = (area.width - CGFloat(cols - 1) * gaps.inner) / CGFloat(cols)
        let cellHeight = (area.height - CGFloat(rows - 1) * gaps.inner) / CGFloat(rows)
        
        for (index, window) in windows.enumerated() {
            let col = index % cols
            let row = index / cols
            
            window.frame = CGRect(
                x: area.minX + CGFloat(col) * (cellWidth + gaps.inner),
                y: area.minY + CGFloat(row) * (cellHeight + gaps.inner),
                width: cellWidth,
                height: cellHeight
            )
        }
    }
    
    private func layoutSpiral(windows: [ManagedWindow], in area: CGRect) {
        guard !windows.isEmpty else { return }
        
        var currentArea = area
        
        for (index, window) in windows.enumerated() {
            if index == windows.count - 1 {
                // Last window takes remaining space
                window.frame = currentArea
            } else {
                // Split current area
                let isHorizontal = index % 2 == 0
                
                if isHorizontal {
                    let splitWidth = currentArea.width / 2
                    window.frame = CGRect(
                        x: currentArea.minX,
                        y: currentArea.minY,
                        width: splitWidth - gaps.inner / 2,
                        height: currentArea.height
                    )
                    currentArea = CGRect(
                        x: currentArea.minX + splitWidth + gaps.inner / 2,
                        y: currentArea.minY,
                        width: currentArea.width - splitWidth - gaps.inner / 2,
                        height: currentArea.height
                    )
                } else {
                    let splitHeight = currentArea.height / 2
                    window.frame = CGRect(
                        x: currentArea.minX,
                        y: currentArea.minY,
                        width: currentArea.width,
                        height: splitHeight - gaps.inner / 2
                    )
                    currentArea = CGRect(
                        x: currentArea.minX,
                        y: currentArea.minY + splitHeight + gaps.inner / 2,
                        width: currentArea.width,
                        height: currentArea.height - splitHeight - gaps.inner / 2
                    )
                }
            }
        }
    }
    
    private func layoutCenterMaster(windows: [ManagedWindow], in area: CGRect) {
        guard !windows.isEmpty else { return }
        
        if windows.count == 1 {
            windows[0].frame = area
        } else if windows.count == 2 {
            // Two windows side by side
            let width = (area.width - gaps.inner) / 2
            windows[0].frame = CGRect(x: area.minX, y: area.minY, width: width, height: area.height)
            windows[1].frame = CGRect(x: area.minX + width + gaps.inner, y: area.minY, width: width, height: area.height)
        } else {
            // Master in center, others on sides
            let sideWidth = area.width * 0.25 - gaps.inner
            let centerWidth = area.width * 0.5
            
            // Master window in center
            windows[0].frame = CGRect(
                x: area.minX + sideWidth + gaps.inner,
                y: area.minY,
                width: centerWidth,
                height: area.height
            )
            
            // Left side windows
            let leftCount = (windows.count - 1) / 2
            let leftHeight = (area.height - CGFloat(leftCount - 1) * gaps.inner) / CGFloat(leftCount)
            
            for i in 1...leftCount {
                windows[i].frame = CGRect(
                    x: area.minX,
                    y: area.minY + CGFloat(i - 1) * (leftHeight + gaps.inner),
                    width: sideWidth,
                    height: leftHeight
                )
            }
            
            // Right side windows
            let rightCount = windows.count - 1 - leftCount
            let rightHeight = (area.height - CGFloat(rightCount - 1) * gaps.inner) / CGFloat(rightCount)
            
            for i in 0..<rightCount {
                let windowIndex = leftCount + 1 + i
                windows[windowIndex].frame = CGRect(
                    x: area.maxX - sideWidth,
                    y: area.minY + CGFloat(i) * (rightHeight + gaps.inner),
                    width: sideWidth,
                    height: rightHeight
                )
            }
        }
    }
    
    private func layoutColumns(windows: [ManagedWindow], in area: CGRect) {
        guard !windows.isEmpty else { return }
        
        let columnWidth = (area.width - CGFloat(windows.count - 1) * gaps.inner) / CGFloat(windows.count)
        
        for (index, window) in windows.enumerated() {
            window.frame = CGRect(
                x: area.minX + CGFloat(index) * (columnWidth + gaps.inner),
                y: area.minY,
                width: columnWidth,
                height: area.height
            )
        }
    }
    
    private func layoutRows(windows: [ManagedWindow], in area: CGRect) {
        guard !windows.isEmpty else { return }
        
        let rowHeight = (area.height - CGFloat(windows.count - 1) * gaps.inner) / CGFloat(windows.count)
        
        for (index, window) in windows.enumerated() {
            window.frame = CGRect(
                x: area.minX,
                y: area.minY + CGFloat(index) * (rowHeight + gaps.inner),
                width: area.width,
                height: rowHeight
            )
        }
    }
    
    // MARK: - Workspace Management
    
    public func switchToWorkspace(_ workspace: Int) {
        guard workspace != currentWorkspace else { return }
        
        // Hide current workspace windows
        for window in workspaces[currentWorkspace] ?? [] {
            window.isVisible = false
        }
        
        currentWorkspace = workspace
        
        // Show new workspace windows
        for window in workspaces[workspace] ?? [] {
            window.isVisible = true
        }
        
        // Focus first window in new workspace
        activeWindow = workspaces[workspace]?.first
        
        retile()
    }
    
    public func moveWindowToWorkspace(_ window: ManagedWindow, workspace: Int) {
        workspaces[currentWorkspace]?.removeAll { $0.id == window.id }
        workspaces[workspace, default: []].append(window)
        
        if workspace != currentWorkspace {
            window.isVisible = false
        }
        
        retile()
    }
    
    // MARK: - Keyboard Shortcuts
    
    private func setupKeyboardShortcuts() {
        // This would register actual keyboard shortcuts in a real implementation
        // For demo purposes, we'll define the shortcuts that would be available
        
        /*
        Super + Enter: Launch terminal
        Super + Q: Close window
        Super + Space: Toggle floating
        Super + Tab: Cycle windows
        Super + 1-9: Switch workspace
        Super + Shift + 1-9: Move window to workspace
        Super + T: Tall layout
        Super + W: Wide layout
        Super + G: Grid layout
        Super + F: Fullscreen
        Super + M: Minimize
        Super + Arrow: Focus direction
        Super + Shift + Arrow: Move window
        Super + Ctrl + Arrow: Resize window
        */
    }
    
    public func handleKeyboardShortcut(_ shortcut: KeyboardShortcut) {
        switch shortcut.action {
        case .cycleWindows:
            focusNextWindow()
        case .cycleLayoutForward:
            nextLayout()
        case .cycleLayoutBackward:
            previousLayout()
        case .toggleFloating:
            toggleFloating()
        case .toggleFullscreen:
            toggleFullscreen()
        case .closeWindow:
            closeActiveWindow()
        case .minimize:
            minimizeWindow()
        case .focusDirection(let direction):
            focusWindowInDirection(direction)
        case .moveDirection(let direction):
            moveWindowInDirection(direction)
        case .resizeDirection(let direction, let amount):
            resizeWindowInDirection(direction, amount: amount)
        case .switchWorkspace(let workspace):
            switchToWorkspace(workspace)
        case .moveToWorkspace(let workspace):
            if let activeWindow = activeWindow {
                moveWindowToWorkspace(activeWindow, workspace: workspace)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func getScreenBounds() -> CGRect {
        // Return screen bounds minus panels/docks
        return CGRect(x: 0, y: 30, width: 1920, height: 1050) // Example values
    }
    
    private func applyGaps(to bounds: CGRect, windowCount: Int) -> CGRect {
        if gaps.smart && windowCount == 1 {
            // No gaps for single window
            return bounds
        }
        
        return CGRect(
            x: bounds.minX + gaps.outer,
            y: bounds.minY + gaps.outer,
            width: bounds.width - gaps.outer * 2,
            height: bounds.height - gaps.outer * 2
        )
    }
    
    private func centerWindow(_ window: ManagedWindow) {
        let screen = getScreenBounds()
        let width = min(window.frame.width, screen.width * 0.8)
        let height = min(window.frame.height, screen.height * 0.8)
        
        window.frame = CGRect(
            x: screen.midX - width / 2,
            y: screen.midY - height / 2,
            width: width,
            height: height
        )
    }
    
    private func focusNextWindow() {
        let visibleWindows = windows.filter { !minimizedWindows.contains($0.id) }
        guard !visibleWindows.isEmpty else { return }
        
        if let current = activeWindow,
           let index = visibleWindows.firstIndex(where: { $0.id == current.id }) {
            let nextIndex = (index + 1) % visibleWindows.count
            focusWindow(visibleWindows[nextIndex])
        } else {
            focusWindow(visibleWindows[0])
        }
    }
    
    private func nextLayout() {
        let layouts = TilingLayout.allCases
        if let index = layouts.firstIndex(of: currentLayout) {
            currentLayout = layouts[(index + 1) % layouts.count]
            retile()
        }
    }
    
    private func previousLayout() {
        let layouts = TilingLayout.allCases
        if let index = layouts.firstIndex(of: currentLayout) {
            let prevIndex = index == 0 ? layouts.count - 1 : index - 1
            currentLayout = layouts[prevIndex]
            retile()
        }
    }
    
    private func toggleFullscreen() {
        guard let window = activeWindow else { return }
        
        if window.isFullscreen {
            window.isFullscreen = false
            retile()
        } else {
            window.isFullscreen = true
            window.frame = getScreenBounds()
        }
    }
    
    private func closeActiveWindow() {
        if let window = activeWindow {
            removeWindow(window)
        }
    }
    
    private func focusWindowInDirection(_ direction: Direction) {
        // Focus window in specified direction relative to active window
        guard let active = activeWindow else { return }
        
        let candidates = windows.filter { window in
            !minimizedWindows.contains(window.id) && window.id != active.id
        }
        
        let closest = candidates.min { w1, w2 in
            let dist1 = distanceInDirection(from: active, to: w1, direction: direction)
            let dist2 = distanceInDirection(from: active, to: w2, direction: direction)
            return dist1 < dist2
        }
        
        if let closest = closest {
            focusWindow(closest)
        }
    }
    
    private func moveWindowInDirection(_ direction: Direction) {
        guard let window = activeWindow else { return }
        
        // Swap with window in direction
        focusWindowInDirection(direction)
        if let other = activeWindow, other.id != window.id {
            swapWindows(window, other)
        }
    }
    
    private func resizeWindowInDirection(_ direction: Direction, amount: CGFloat) {
        guard let window = activeWindow else { return }
        guard floatingWindows.contains(window.id) else { return }
        
        var frame = window.frame
        
        switch direction {
        case .up:
            frame.size.height -= amount
        case .down:
            frame.size.height += amount
        case .left:
            frame.size.width -= amount
        case .right:
            frame.size.width += amount
        }
        
        window.frame = frame
    }
    
    private func swapWindows(_ w1: ManagedWindow, _ w2: ManagedWindow) {
        let tempFrame = w1.frame
        w1.frame = w2.frame
        w2.frame = tempFrame
    }
    
    private func distanceInDirection(from: ManagedWindow, to: ManagedWindow, direction: Direction) -> CGFloat {
        let fromCenter = CGPoint(x: from.frame.midX, y: from.frame.midY)
        let toCenter = CGPoint(x: to.frame.midX, y: to.frame.midY)
        
        switch direction {
        case .up:
            return toCenter.y < fromCenter.y ? fromCenter.y - toCenter.y : CGFloat.infinity
        case .down:
            return toCenter.y > fromCenter.y ? toCenter.y - fromCenter.y : CGFloat.infinity
        case .left:
            return toCenter.x < fromCenter.x ? fromCenter.x - toCenter.x : CGFloat.infinity
        case .right:
            return toCenter.x > fromCenter.x ? toCenter.x - fromCenter.x : CGFloat.infinity
        }
    }
    
    private func initializeWorkspaces() {
        for i in 1...9 {
            workspaces[i] = []
        }
    }
}

// MARK: - Supporting Types

public class ManagedWindow: ObservableObject, Identifiable {
    public let id = UUID()
    @Published public var frame: CGRect
    @Published public var title: String
    @Published public var isVisible: Bool = true
    @Published public var isFullscreen: Bool = false
    public let applicationName: String
    
    public init(frame: CGRect, title: String, applicationName: String) {
        self.frame = frame
        self.title = title
        self.applicationName = applicationName
    }
}

public enum Direction {
    case up, down, left, right
}

public struct KeyboardShortcut {
    public enum Action {
        case cycleWindows
        case cycleLayoutForward
        case cycleLayoutBackward
        case toggleFloating
        case toggleFullscreen
        case closeWindow
        case minimize
        case focusDirection(Direction)
        case moveDirection(Direction)
        case resizeDirection(Direction, amount: CGFloat)
        case switchWorkspace(Int)
        case moveToWorkspace(Int)
    }
    
    let modifiers: Set<KeyModifier>
    let key: String
    let action: Action
}

public enum KeyModifier {
    case command
    case shift
    case control
    case option
    case `super` // Super/Windows key
}