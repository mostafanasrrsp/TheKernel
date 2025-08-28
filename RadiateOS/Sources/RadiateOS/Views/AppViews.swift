import SwiftUI

// MARK: - Safari View
struct SafariView: View {
    @State private var urlText = "https://radiateos.com"
    @State private var currentURL = "https://radiateos.com"
    @State private var isLoading = false
    @State private var progress: Double = 0
    @State private var canGoBack = false
    @State private var canGoForward = false
    @State private var bookmarks = [
        "Apple", "GitHub", "Stack Overflow", "RadiateOS Docs"
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Navigation Bar
            HStack(spacing: RadiateDesign.Spacing.sm) {
                // Navigation Buttons
                Button(action: {}) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(canGoBack ? RadiateDesign.Colors.text : RadiateDesign.Colors.textTertiary)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(!canGoBack)
                
                Button(action: {}) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(canGoForward ? RadiateDesign.Colors.text : RadiateDesign.Colors.textTertiary)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(!canGoForward)
                
                Button(action: { isLoading.toggle() }) {
                    Image(systemName: isLoading ? "xmark" : "arrow.clockwise")
                        .foregroundColor(RadiateDesign.Colors.text)
                }
                .buttonStyle(PlainButtonStyle())
                
                // URL Bar
                HStack {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 12))
                        .foregroundColor(RadiateDesign.Colors.success)
                    
                    TextField("Search or enter website name", text: $urlText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .foregroundColor(RadiateDesign.Colors.text)
                        .onSubmit {
                            currentURL = urlText
                            loadPage()
                        }
                }
                .padding(.horizontal, RadiateDesign.Spacing.sm)
                .padding(.vertical, 6)
                .background(RadiateDesign.Colors.glassDark)
                .cornerRadius(RadiateDesign.CornerRadius.sm)
                
                // Action Buttons
                Button(action: {}) {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(RadiateDesign.Colors.text)
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: {}) {
                    Image(systemName: "book")
                        .foregroundColor(RadiateDesign.Colors.text)
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: {}) {
                    Image(systemName: "square.on.square")
                        .foregroundColor(RadiateDesign.Colors.text)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(RadiateDesign.Spacing.sm)
            .background(RadiateDesign.Colors.surfaceLight.opacity(0.5))
            
            // Progress Bar
            if isLoading {
                ProgressView(value: progress)
                    .progressViewStyle(LinearProgressViewStyle())
                    .accentColor(RadiateDesign.Colors.accentPrimary)
                    .frame(height: 2)
            }
            
            // Web Content (Simulated)
            ScrollView {
                VStack(alignment: .leading, spacing: RadiateDesign.Spacing.lg) {
                    // Hero Section
                    ZStack {
                        RadiateDesign.Colors.indigo
                        
                        VStack(spacing: RadiateDesign.Spacing.md) {
                            Image(systemName: "globe")
                                .font(.system(size: 60))
                                .foregroundColor(.white)
                            
                            Text("Welcome to RadiateOS")
                                .font(RadiateDesign.Typography.largeTitle)
                                .foregroundColor(.white)
                            
                            Text("The Next Generation Operating System")
                                .font(RadiateDesign.Typography.headline)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .padding(RadiateDesign.Spacing.xxl)
                    }
                    .frame(height: 300)
                    
                    // Content
                    VStack(alignment: .leading, spacing: RadiateDesign.Spacing.md) {
                        Text("Features")
                            .font(RadiateDesign.Typography.title1)
                            .foregroundColor(RadiateDesign.Colors.text)
                        
                        ForEach(["Advanced Memory Management", "Spectroscopic UI Design", "Quantum Computing Ready", "AI-Powered Optimization"], id: \.self) { feature in
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(RadiateDesign.Colors.success)
                                
                                Text(feature)
                                    .font(RadiateDesign.Typography.body)
                                    .foregroundColor(RadiateDesign.Colors.text)
                            }
                        }
                    }
                    .padding(RadiateDesign.Spacing.lg)
                }
            }
            .background(RadiateDesign.Colors.surface)
        }
        .onAppear {
            loadPage()
        }
    }
    
    func loadPage() {
        isLoading = true
        progress = 0
        
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            progress += 0.1
            if progress >= 1.0 {
                timer.invalidate()
                isLoading = false
                canGoBack = true
            }
        }
    }
}

// MARK: - Terminal View
struct TerminalView: View {
    @State private var commandHistory: [String] = [
        "RadiateOS Terminal v1.0.0",
        "Copyright (c) 2024 RadiateOS. All rights reserved.",
        "",
        "Last login: \(Date().formatted())",
    ]
    @State private var currentCommand = ""
    @State private var currentDirectory = "~"
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Terminal Output
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(Array(commandHistory.enumerated()), id: \.offset) { index, line in
                            Text(line)
                                .font(RadiateDesign.Typography.monospace)
                                .foregroundColor(colorForLine(line))
                                .id(index)
                        }
                        
                        // Current Input Line
                        HStack(spacing: 0) {
                            Text("\(currentDirectory) $ ")
                                .font(RadiateDesign.Typography.monospace)
                                .foregroundColor(RadiateDesign.Colors.success)
                            
                            TextField("", text: $currentCommand)
                                .textFieldStyle(PlainTextFieldStyle())
                                .font(RadiateDesign.Typography.monospace)
                                .foregroundColor(RadiateDesign.Colors.text)
                                .focused($isInputFocused)
                                .onSubmit {
                                    executeCommand()
                                }
                            
                            // Cursor
                            Rectangle()
                                .fill(RadiateDesign.Colors.neonGreen)
                                .frame(width: 8, height: 16)
                                .opacity(isInputFocused ? 1 : 0.3)
                                .animation(Animation.easeInOut(duration: 0.5).repeatForever(), value: isInputFocused)
                        }
                    }
                    .padding(RadiateDesign.Spacing.md)
                }
                .onChange(of: commandHistory.count) { _ in
                    withAnimation {
                        proxy.scrollTo(commandHistory.count - 1, anchor: .bottom)
                    }
                }
            }
            .background(Color(hex: "0A0A0F"))
            .onTapGesture {
                isInputFocused = true
            }
        }
        .onAppear {
            isInputFocused = true
        }
    }
    
    func colorForLine(_ line: String) -> Color {
        if line.hasPrefix("Error:") || line.hasPrefix("error:") {
            return RadiateDesign.Colors.error
        } else if line.hasPrefix("Warning:") || line.hasPrefix("warning:") {
            return RadiateDesign.Colors.warning
        } else if line.hasPrefix("Success:") || line.hasPrefix("✓") {
            return RadiateDesign.Colors.success
        } else if line.hasPrefix("$") || line.hasPrefix("~") {
            return RadiateDesign.Colors.neonBlue
        } else {
            return RadiateDesign.Colors.text
        }
    }
    
    func executeCommand() {
        let fullCommand = "\(currentDirectory) $ \(currentCommand)"
        commandHistory.append(fullCommand)
        
        // Simulate command execution
        switch currentCommand.lowercased() {
        case "help":
            commandHistory.append(contentsOf: [
                "Available commands:",
                "  help     - Show this help message",
                "  clear    - Clear the terminal",
                "  ls       - List directory contents",
                "  cd       - Change directory",
                "  pwd      - Print working directory",
                "  echo     - Display a message",
                "  date     - Show current date and time",
                "  whoami   - Display current user",
                "  neofetch - Display system information"
            ])
            
        case "clear":
            commandHistory = []
            
        case "ls":
            commandHistory.append(contentsOf: [
                "Applications  Documents  Downloads  Pictures",
                "Desktop       Library    Movies     Music"
            ])
            
        case "pwd":
            commandHistory.append("/Users/radiate/\(currentDirectory.replacingOccurrences(of: "~", with: ""))")
            
        case "date":
            commandHistory.append(Date().formatted())
            
        case "whoami":
            commandHistory.append("radiate")
            
        case "neofetch":
            commandHistory.append(contentsOf: [
                "        ▄▄▄▄▄▄▄▄▄       radiate@RadiateOS",
                "      ▄█████████████▄    ------------------",
                "    ▄███████████████▄    OS: RadiateOS 1.0.0",
                "   ████████████████████   Kernel: Darwin 23.0",
                "  ██████████████████████  Uptime: 2 hours, 15 mins",
                " ████████████████████████ Shell: zsh 5.9",
                " ████████████████████████ Terminal: RadiateOS Terminal",
                "  ██████████████████████  CPU: Apple M2 Pro",
                "   ████████████████████   Memory: 8192MB / 16384MB",
                "    ▀███████████████▀    ",
                "      ▀█████████████▀    ",
                "        ▀▀▀▀▀▀▀▀▀       "
            ])
            
        case let cmd where cmd.starts(with: "cd "):
            let path = String(cmd.dropFirst(3))
            if path == ".." {
                currentDirectory = "~"
            } else if path == "/" {
                currentDirectory = "/"
            } else {
                currentDirectory = "~/\(path)"
            }
            
        case let cmd where cmd.starts(with: "echo "):
            let message = String(cmd.dropFirst(5))
            commandHistory.append(message)
            
        case "":
            break
            
        default:
            commandHistory.append("Error: Command not found: \(currentCommand)")
        }
        
        currentCommand = ""
    }
}

// MARK: - Messages View
struct MessagesView: View {
    @State private var selectedConversation = 0
    @State private var messageText = ""
    
    let conversations = [
        ("Alice Johnson", "Hey! How's the new OS?", "2m ago"),
        ("Bob Smith", "Meeting at 3 PM", "1h ago"),
        ("Carol White", "Check out this link!", "3h ago"),
        ("David Brown", "Thanks for the help!", "Yesterday"),
    ]
    
    let messages = [
        (true, "Hey! How's the new RadiateOS coming along?"),
        (false, "It's amazing! The spectroscopic UI is incredible"),
        (true, "That sounds awesome! Can't wait to try it"),
        (false, "I'll send you a beta build soon"),
        (true, "Perfect, thanks!"),
    ]
    
    var body: some View {
        HSplitView {
            // Conversations List
            VStack(alignment: .leading, spacing: 0) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(RadiateDesign.Colors.textTertiary)
                    
                    TextField("Search", text: .constant(""))
                        .textFieldStyle(PlainTextFieldStyle())
                        .foregroundColor(RadiateDesign.Colors.text)
                }
                .padding(RadiateDesign.Spacing.sm)
                .background(RadiateDesign.Colors.glassDark)
                .cornerRadius(RadiateDesign.CornerRadius.sm)
                .padding(RadiateDesign.Spacing.sm)
                
                // Conversations
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(Array(conversations.enumerated()), id: \.offset) { index, conversation in
                            ConversationRow(
                                name: conversation.0,
                                lastMessage: conversation.1,
                                time: conversation.2,
                                isSelected: selectedConversation == index,
                                hasUnread: index == 0
                            ) {
                                selectedConversation = index
                            }
                        }
                    }
                }
            }
            .frame(minWidth: 250, idealWidth: 300, maxWidth: 350)
            .background(RadiateDesign.Colors.surfaceLight.opacity(0.5))
            
            // Message Thread
            VStack(spacing: 0) {
                // Header
                HStack {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(RadiateDesign.Colors.accentPrimary)
                    
                    VStack(alignment: .leading) {
                        Text(conversations[selectedConversation].0)
                            .font(RadiateDesign.Typography.headline)
                            .foregroundColor(RadiateDesign.Colors.text)
                        
                        Text("Active now")
                            .font(RadiateDesign.Typography.caption1)
                            .foregroundColor(RadiateDesign.Colors.success)
                    }
                    
                    Spacer()
                    
                    Button(action: {}) {
                        Image(systemName: "video")
                            .foregroundColor(RadiateDesign.Colors.text)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: {}) {
                        Image(systemName: "phone")
                            .foregroundColor(RadiateDesign.Colors.text)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(RadiateDesign.Spacing.md)
                .background(RadiateDesign.Colors.surfaceLight.opacity(0.3))
                
                // Messages
                ScrollView {
                    VStack(alignment: .leading, spacing: RadiateDesign.Spacing.md) {
                        ForEach(Array(messages.enumerated()), id: \.offset) { _, message in
                            MessageBubble(
                                text: message.1,
                                isFromUser: message.0
                            )
                        }
                    }
                    .padding(RadiateDesign.Spacing.md)
                }
                
                // Input Bar
                HStack(spacing: RadiateDesign.Spacing.sm) {
                    Button(action: {}) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(RadiateDesign.Colors.accentPrimary)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    HStack {
                        TextField("Type a message...", text: $messageText)
                            .textFieldStyle(PlainTextFieldStyle())
                            .foregroundColor(RadiateDesign.Colors.text)
                        
                        Button(action: {}) {
                            Image(systemName: "face.smiling")
                                .foregroundColor(RadiateDesign.Colors.textSecondary)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal, RadiateDesign.Spacing.md)
                    .padding(.vertical, RadiateDesign.Spacing.sm)
                    .background(RadiateDesign.Colors.glassDark)
                    .cornerRadius(RadiateDesign.CornerRadius.full)
                    
                    Button(action: {}) {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                            .frame(width: 36, height: 36)
                            .background(RadiateDesign.Colors.accentPrimary)
                            .clipShape(Circle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(RadiateDesign.Spacing.md)
                .background(RadiateDesign.Colors.surfaceLight.opacity(0.3))
            }
        }
    }
}

// MARK: - Conversation Row
struct ConversationRow: View {
    let name: String
    let lastMessage: String
    let time: String
    let isSelected: Bool
    let hasUnread: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: RadiateDesign.Spacing.sm) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(RadiateDesign.Colors.accentSecondary)
                    
                    if hasUnread {
                        Circle()
                            .fill(RadiateDesign.Colors.neonBlue)
                            .frame(width: 12, height: 12)
                            .offset(x: 2, y: -2)
                    }
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(name)
                        .font(RadiateDesign.Typography.headline)
                        .foregroundColor(RadiateDesign.Colors.text)
                    
                    Text(lastMessage)
                        .font(RadiateDesign.Typography.caption1)
                        .foregroundColor(RadiateDesign.Colors.textSecondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                Text(time)
                    .font(RadiateDesign.Typography.caption2)
                    .foregroundColor(RadiateDesign.Colors.textTertiary)
            }
            .padding(RadiateDesign.Spacing.sm)
            .background(isSelected ? RadiateDesign.Colors.accentPrimary.opacity(0.2) : Color.clear)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Message Bubble
struct MessageBubble: View {
    let text: String
    let isFromUser: Bool
    
    var body: some View {
        HStack {
            if !isFromUser { Spacer() }
            
            Text(text)
                .font(RadiateDesign.Typography.body)
                .foregroundColor(isFromUser ? RadiateDesign.Colors.text : .white)
                .padding(RadiateDesign.Spacing.sm)
                .background(
                    isFromUser ? RadiateDesign.Colors.glassDark : RadiateDesign.Colors.accentPrimary
                )
                .cornerRadius(RadiateDesign.CornerRadius.md)
            
            if isFromUser { Spacer() }
        }
    }
}

// MARK: - Settings View
struct SettingsView: View {
    @State private var selectedCategory = "General"
    
    let categories = [
        ("General", "gear"),
        ("Network", "wifi"),
        ("Bluetooth", "bluetoothicon"),
        ("Display", "display"),
        ("Sound", "speaker.wave.3"),
        ("Security", "lock.shield"),
        ("Privacy", "hand.raised"),
        ("Accessibility", "accessibility"),
    ]
    
    var body: some View {
        HSplitView {
            // Categories
            ScrollView {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(categories, id: \.0) { category in
                        SettingsCategoryRow(
                            icon: category.1,
                            title: category.0,
                            isSelected: selectedCategory == category.0
                        ) {
                            selectedCategory = category.0
                        }
                    }
                }
                .padding(RadiateDesign.Spacing.sm)
            }
            .frame(minWidth: 200, idealWidth: 250, maxWidth: 300)
            .background(RadiateDesign.Colors.surfaceLight.opacity(0.3))
            
            // Settings Content
            ScrollView {
                VStack(alignment: .leading, spacing: RadiateDesign.Spacing.lg) {
                    Text(selectedCategory)
                        .font(RadiateDesign.Typography.largeTitle)
                        .foregroundColor(RadiateDesign.Colors.text)
                        .padding(.bottom, RadiateDesign.Spacing.md)
                    
                    // Dynamic content based on selected category
                    Group {
                        switch selectedCategory {
                        case "Network":
                            NetworkSettings()
                        case "Bluetooth":
                            BluetoothSettings()
                        case "Display":
                            DisplaySettings()
                        default:
                            GeneralSettings()
                        }
                    }
                }
                .padding(RadiateDesign.Spacing.xl)
            }
        }
    }
}

// MARK: - Settings Category Row
struct SettingsCategoryRow: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: RadiateDesign.Spacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(isSelected ? .white : RadiateDesign.Colors.textSecondary)
                    .frame(width: 24)
                
                Text(title)
                    .font(RadiateDesign.Typography.body)
                    .foregroundColor(isSelected ? .white : RadiateDesign.Colors.text)
                
                Spacer()
            }
            .padding(RadiateDesign.Spacing.sm)
            .background(isSelected ? RadiateDesign.Colors.accentPrimary : Color.clear)
            .cornerRadius(RadiateDesign.CornerRadius.sm)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Settings Panels
struct GeneralSettings: View {
    @State private var appearance = "Auto"
    @State private var accentColor = "Blue"
    
    var body: some View {
        VStack(alignment: .leading, spacing: RadiateDesign.Spacing.lg) {
            SettingsSection(title: "Appearance") {
                Picker("Appearance", selection: $appearance) {
                    Text("Light").tag("Light")
                    Text("Dark").tag("Dark")
                    Text("Auto").tag("Auto")
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            
            SettingsSection(title: "Accent Color") {
                HStack(spacing: RadiateDesign.Spacing.sm) {
                    ForEach(["Blue", "Purple", "Pink", "Green", "Orange"], id: \.self) { color in
                        Circle()
                            .fill(colorForName(color))
                            .frame(width: 32, height: 32)
                            .overlay(
                                Circle()
                                    .stroke(RadiateDesign.Colors.text, lineWidth: accentColor == color ? 2 : 0)
                            )
                            .onTapGesture {
                                accentColor = color
                            }
                    }
                }
            }
        }
    }
    
    func colorForName(_ name: String) -> Color {
        switch name {
        case "Blue": return Color.blue
        case "Purple": return Color.purple
        case "Pink": return Color.pink
        case "Green": return Color.green
        case "Orange": return Color.orange
        default: return Color.blue
        }
    }
}

struct NetworkSettings: View {
    @State private var wifiEnabled = true
    @State private var autoJoin = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: RadiateDesign.Spacing.lg) {
            SettingsSection(title: "Wi-Fi") {
                Toggle("Wi-Fi Enabled", isOn: $wifiEnabled)
                Toggle("Auto-Join Networks", isOn: $autoJoin)
            }
            
            SettingsSection(title: "Known Networks") {
                VStack(alignment: .leading, spacing: RadiateDesign.Spacing.sm) {
                    ForEach(["RadiateNet 5G", "Guest Network", "Office WiFi"], id: \.self) { network in
                        HStack {
                            Image(systemName: "wifi")
                                .foregroundColor(RadiateDesign.Colors.textSecondary)
                            Text(network)
                                .foregroundColor(RadiateDesign.Colors.text)
                            Spacer()
                            Button("Forget") {}
                                .buttonStyle(PlainButtonStyle())
                                .foregroundColor(RadiateDesign.Colors.error)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
    }
}

struct BluetoothSettings: View {
    @State private var bluetoothEnabled = true
    @State private var discoverable = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: RadiateDesign.Spacing.lg) {
            SettingsSection(title: "Bluetooth") {
                Toggle("Bluetooth Enabled", isOn: $bluetoothEnabled)
                Toggle("Discoverable", isOn: $discoverable)
            }
            
            SettingsSection(title: "Paired Devices") {
                VStack(alignment: .leading, spacing: RadiateDesign.Spacing.sm) {
                    ForEach(["AirPods Pro", "Magic Mouse", "iPhone 15 Pro"], id: \.self) { device in
                        HStack {
                            Image(systemName: "bluetoothicon")
                                .foregroundColor(RadiateDesign.Colors.textSecondary)
                            Text(device)
                                .foregroundColor(RadiateDesign.Colors.text)
                            Spacer()
                            Text("Connected")
                                .font(RadiateDesign.Typography.caption1)
                                .foregroundColor(RadiateDesign.Colors.success)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
    }
}

struct DisplaySettings: View {
    @State private var brightness: Double = 0.7
    @State private var trueTone = true
    @State private var nightShift = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: RadiateDesign.Spacing.lg) {
            SettingsSection(title: "Brightness") {
                Slider(value: $brightness, in: 0...1)
            }
            
            SettingsSection(title: "Display Options") {
                Toggle("True Tone", isOn: $trueTone)
                Toggle("Night Shift", isOn: $nightShift)
            }
        }
    }
}

struct SettingsSection<Content: View>: View {
    let title: String
    let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: RadiateDesign.Spacing.sm) {
            Text(title)
                .font(RadiateDesign.Typography.headline)
                .foregroundColor(RadiateDesign.Colors.text)
            
            content()
                .padding(RadiateDesign.Spacing.md)
                .background(RadiateDesign.Colors.glassDark)
                .cornerRadius(RadiateDesign.CornerRadius.md)
        }
    }
}

// MARK: - Activity Monitor View
struct ActivityMonitorView: View {
    @State private var selectedTab = "CPU"
    let tabs = ["CPU", "Memory", "Energy", "Disk", "Network"]
    
    var body: some View {
        VStack(spacing: 0) {
            // Tab Bar
            HStack(spacing: 0) {
                ForEach(tabs, id: \.self) { tab in
                    Button(action: { selectedTab = tab }) {
                        Text(tab)
                            .font(RadiateDesign.Typography.callout)
                            .foregroundColor(selectedTab == tab ? RadiateDesign.Colors.text : RadiateDesign.Colors.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, RadiateDesign.Spacing.sm)
                            .background(
                                selectedTab == tab ? RadiateDesign.Colors.glassDark : Color.clear
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .background(RadiateDesign.Colors.surfaceLight.opacity(0.5))
            
            // Content
            ScrollView {
                VStack(spacing: RadiateDesign.Spacing.lg) {
                    // Graph
                    ZStack {
                        RoundedRectangle(cornerRadius: RadiateDesign.CornerRadius.md)
                            .fill(RadiateDesign.Colors.glassDark)
                            .frame(height: 200)
                        
                        VStack {
                            Text("\(selectedTab) Usage")
                                .font(RadiateDesign.Typography.headline)
                                .foregroundColor(RadiateDesign.Colors.text)
                            
                            Text("23%")
                                .font(RadiateDesign.Typography.largeTitle)
                                .foregroundColor(RadiateDesign.Colors.accentPrimary)
                        }
                    }
                    
                    // Process List
                    VStack(alignment: .leading, spacing: 1) {
                        // Header
                        HStack {
                            Text("Process Name")
                                .font(RadiateDesign.Typography.caption1)
                                .foregroundColor(RadiateDesign.Colors.textSecondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Text("% \(selectedTab)")
                                .font(RadiateDesign.Typography.caption1)
                                .foregroundColor(RadiateDesign.Colors.textSecondary)
                                .frame(width: 80)
                            
                            Text("Memory")
                                .font(RadiateDesign.Typography.caption1)
                                .foregroundColor(RadiateDesign.Colors.textSecondary)
                                .frame(width: 80)
                        }
                        .padding(RadiateDesign.Spacing.sm)
                        .background(RadiateDesign.Colors.surfaceLight)
                        
                        // Processes
                        ForEach(["RadiateOS", "Safari", "Terminal", "Messages", "Finder"], id: \.self) { process in
                            ProcessRow(name: process, cpu: Double.random(in: 0...30), memory: Double.random(in: 50...500))
                        }
                    }
                }
                .padding(RadiateDesign.Spacing.md)
            }
        }
    }
}

struct ProcessRow: View {
    let name: String
    let cpu: Double
    let memory: Double
    
    var body: some View {
        HStack {
            HStack(spacing: RadiateDesign.Spacing.sm) {
                Circle()
                    .fill(RadiateDesign.Colors.success)
                    .frame(width: 8, height: 8)
                
                Text(name)
                    .font(RadiateDesign.Typography.body)
                    .foregroundColor(RadiateDesign.Colors.text)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Text(String(format: "%.1f%%", cpu))
                .font(RadiateDesign.Typography.caption1)
                .foregroundColor(cpuColor)
                .frame(width: 80)
            
            Text(String(format: "%.0f MB", memory))
                .font(RadiateDesign.Typography.caption1)
                .foregroundColor(RadiateDesign.Colors.textSecondary)
                .frame(width: 80)
        }
        .padding(RadiateDesign.Spacing.sm)
        .background(Color.clear)
    }
    
    var cpuColor: Color {
        if cpu > 20 {
            return RadiateDesign.Colors.error
        } else if cpu > 10 {
            return RadiateDesign.Colors.warning
        } else {
            return RadiateDesign.Colors.textSecondary
        }
    }
}

// MARK: - Default App View
struct DefaultAppView: View {
    let app: OSApplication
    
    var body: some View {
        VStack {
            Spacer()
            
            Image(systemName: app.icon)
                .font(.system(size: 80))
                .foregroundStyle(app.accentColor)
            
            Text(app.name)
                .font(RadiateDesign.Typography.largeTitle)
                .foregroundColor(RadiateDesign.Colors.text)
                .padding(.top, RadiateDesign.Spacing.md)
            
            Text("Version 1.0.0")
                .font(RadiateDesign.Typography.caption1)
                .foregroundColor(RadiateDesign.Colors.textSecondary)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(RadiateDesign.Colors.surface)
    }
}