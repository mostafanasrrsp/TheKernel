import SwiftUI

/// Main RadiateOS Application - Inspired by Ubuntu-based distributions
@main
struct RadiateOSApp: App {
    @StateObject private var securityCore = SecurityCore.shared
    @StateObject private var themeManager = ThemeManager.shared
    @State private var showLoginScreen = true
    @State private var currentUser: AuthenticatedUser?
    
    var body: some Scene {
        WindowGroup {
            if showLoginScreen {
                LoginScreen(
                    onAuthenticated: { user in
                        currentUser = user
                        showLoginScreen = false
                    }
                )
                .preferredColorScheme(themeManager.currentTheme.colorScheme)
            } else {
                MainDesktop(user: currentUser)
                    .preferredColorScheme(themeManager.currentTheme.colorScheme)
            }
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        
        Settings {
            SettingsView()
        }
    }
}

// MARK: - Login Screen

struct LoginScreen: View {
    let onAuthenticated: (AuthenticatedUser) -> Void
    
    @State private var username = ""
    @State private var password = ""
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isAuthenticating = false
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: themeManager.currentTheme.backgroundGradient,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Particle effect
            ParticleEffect()
                .opacity(0.2)
            
            // Login Card
            VStack(spacing: 30) {
                // Logo
                Image(systemName: "cube.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Text("RadiateOS")
                    .font(.system(size: 36, weight: .thin, design: .rounded))
                    .foregroundColor(.white)
                
                Text("Secure • Modern • Powerful")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                
                // Login Form
                VStack(spacing: 16) {
                    // Username Field
                    HStack {
                        Image(systemName: "person.fill")
                            .foregroundColor(.white.opacity(0.7))
                        
                        TextField("Username", text: $username)
                            .textFieldStyle(.plain)
                            .foregroundColor(.white)
                    }
                    .padding()
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(8)
                    
                    // Password Field
                    HStack {
                        Image(systemName: "lock.fill")
                            .foregroundColor(.white.opacity(0.7))
                        
                        SecureField("Password", text: $password)
                            .textFieldStyle(.plain)
                            .foregroundColor(.white)
                    }
                    .padding()
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(8)
                    
                    // Error Message
                    if showError {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                    
                    // Login Button
                    Button(action: authenticate) {
                        if isAuthenticating {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Login")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .disabled(isAuthenticating)
                    
                    // Alternative Login Options
                    HStack(spacing: 20) {
                        Button(action: { authenticateWithBiometrics() }) {
                            Image(systemName: "faceid")
                                .font(.title2)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        
                        Button(action: {}) {
                            Image(systemName: "key.fill")
                                .font(.title2)
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                }
                .frame(width: 350)
                
                // Footer
                VStack(spacing: 8) {
                    Button("Guest Session") {
                        loginAsGuest()
                    }
                    .foregroundColor(.white.opacity(0.7))
                    
                    Text("Version 1.0.0 • Inspired by Ubuntu")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            .padding(40)
            .background(.ultraThinMaterial)
            .cornerRadius(20)
        }
        .frame(width: 1200, height: 800)
        .onSubmit {
            authenticate()
        }
    }
    
    private func authenticate() {
        guard !username.isEmpty && !password.isEmpty else {
            showError = true
            errorMessage = "Please enter username and password"
            return
        }
        
        isAuthenticating = true
        showError = false
        
        // Simulate authentication delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            let result = SecurityCore.shared.authenticateUser(
                username: username,
                password: password
            )
            
            switch result {
            case .success(let token):
                let user = AuthenticatedUser(
                    username: username,
                    token: token,
                    role: .admin
                )
                onAuthenticated(user)
                
            case .failure:
                showError = true
                errorMessage = "Invalid username or password"
                isAuthenticating = false
                
            case .accountLocked:
                showError = true
                errorMessage = "Account locked due to too many failed attempts"
                isAuthenticating = false
            }
        }
    }
    
    private func authenticateWithBiometrics() {
        SecurityCore.shared.authenticateWithBiometrics { success in
            if success {
                let user = AuthenticatedUser(
                    username: "User",
                    token: "biometric_token",
                    role: .user
                )
                onAuthenticated(user)
            } else {
                showError = true
                errorMessage = "Biometric authentication failed"
            }
        }
    }
    
    private func loginAsGuest() {
        let user = AuthenticatedUser(
            username: "Guest",
            token: "guest_token",
            role: .guest
        )
        onAuthenticated(user)
    }
}

// MARK: - Main Desktop

struct MainDesktop: View {
    let user: AuthenticatedUser?
    @State private var showSystemMonitor = false
    @State private var showSettings = false
    
    var body: some View {
        ZStack {
            // Main Desktop Environment
            ModernDesktopEnvironment()
            
            // Workspace Manager Layer
            WorkspaceView()
                .allowsHitTesting(false)
            
            // System Monitor (floating window)
            if showSystemMonitor {
                FloatingWindow(
                    title: "System Monitor",
                    isShowing: $showSystemMonitor
                ) {
                    SystemMonitorDashboard()
                }
            }
            
            // Settings (floating window)
            if showSettings {
                FloatingWindow(
                    title: "Settings",
                    isShowing: $showSettings
                ) {
                    SettingsView()
                }
            }
        }
        .frame(minWidth: 1200, minHeight: 800)
        .onAppear {
            setupSystem()
        }
    }
    
    private func setupSystem() {
        // Initialize system components
        FirewallManager.shared.enable()
        ProcessIsolation.shared.sandboxProcess(
            "RadiateOS",
            withProfile: "terminal"
        )
        
        // Log successful login
        SecurityCore.shared.logSecurityEvent(
            "User \(user?.username ?? "Unknown") logged in",
            severity: .info
        )
    }
}

// MARK: - Settings View

struct SettingsView: View {
    @StateObject private var themeManager = ThemeManager.shared
    @State private var selectedCategory = "Appearance"
    
    let categories = ["Appearance", "Security", "Network", "System", "About"]
    
    var body: some View {
        HStack(spacing: 0) {
            // Sidebar
            VStack(alignment: .leading, spacing: 0) {
                ForEach(categories, id: \.self) { category in
                    SettingsCategoryButton(
                        title: category,
                        isSelected: selectedCategory == category,
                        action: { selectedCategory = category }
                    )
                }
                Spacer()
            }
            .frame(width: 200)
            .background(Color.primary.opacity(0.05))
            
            // Content
            ScrollView {
                switch selectedCategory {
                case "Appearance":
                    AppearanceSettings()
                case "Security":
                    SecuritySettings()
                case "Network":
                    NetworkSettings()
                case "System":
                    SystemSettings()
                case "About":
                    AboutView()
                default:
                    EmptyView()
                }
            }
            .padding()
        }
        .frame(width: 800, height: 600)
    }
}

struct SettingsCategoryButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .foregroundColor(isSelected ? .accentColor : .primary)
                Spacer()
            }
            .padding()
            .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
        }
        .buttonStyle(.plain)
    }
}

struct AppearanceSettings: View {
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Appearance")
                .font(.title)
            
            // Theme Selection
            VStack(alignment: .leading) {
                Text("Theme")
                    .font(.headline)
                
                HStack(spacing: 16) {
                    ThemeOption(
                        name: "Light",
                        colors: [Color(hex: "E3F2FD"), Color(hex: "BBDEFB")],
                        isSelected: themeManager.currentTheme.name == "Light",
                        action: { themeManager.switchTheme(.default) }
                    )
                    
                    ThemeOption(
                        name: "Dark",
                        colors: [Color(hex: "1A237E"), Color(hex: "283593")],
                        isSelected: themeManager.currentTheme.name == "Dark",
                        action: { themeManager.switchTheme(.dark) }
                    )
                    
                    ThemeOption(
                        name: "Cosmic",
                        colors: [Color(hex: "2E1A47"), Color(hex: "48257C")],
                        isSelected: themeManager.currentTheme.name == "Cosmic",
                        action: { themeManager.switchTheme(.cosmic) }
                    )
                }
            }
            
            Divider()
            
            // Accent Color
            VStack(alignment: .leading) {
                Text("Accent Color")
                    .font(.headline)
                
                HStack {
                    ForEach([Color.blue, .purple, .pink, .red, .orange, .yellow, .green], id: \.self) { color in
                        Circle()
                            .fill(color)
                            .frame(width: 30, height: 30)
                            .overlay(
                                Circle()
                                    .stroke(Color.primary, lineWidth: themeManager.accentColor == color ? 2 : 0)
                            )
                            .onTapGesture {
                                themeManager.accentColor = color
                            }
                    }
                }
            }
            
            Spacer()
        }
    }
}

struct ThemeOption: View {
    let name: String
    let colors: [Color]
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        VStack {
            LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
                .frame(width: 100, height: 60)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
                )
            
            Text(name)
                .font(.caption)
        }
        .onTapGesture { action() }
    }
}

struct SecuritySettings: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Security")
                .font(.title)
            
            Toggle("Enable Firewall", isOn: .constant(true))
            Toggle("Automatic Security Updates", isOn: .constant(true))
            Toggle("Encrypt Home Folder", isOn: .constant(false))
            
            Spacer()
        }
    }
}

struct NetworkSettings: View {
    var body: some View {
        Text("Network settings...")
    }
}

struct SystemSettings: View {
    var body: some View {
        Text("System settings...")
    }
}

struct AboutView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "cube.fill")
                .font(.system(size: 80))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Text("RadiateOS")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Version 1.0.0")
                .font(.title3)
                .foregroundColor(.secondary)
            
            Text("A modern, secure operating system inspired by the best Ubuntu distributions")
                .multilineTextAlignment(.center)
                .padding()
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Inspired by:")
                    .font(.headline)
                
                Text("• Pop!_OS COSMIC Desktop")
                Text("• Elementary OS Pantheon")
                Text("• Ubuntu Security Features")
                Text("• GNOME Workspace Management")
            }
            .padding()
            .background(Color.primary.opacity(0.05))
            .cornerRadius(8)
            
            Spacer()
        }
    }
}

// MARK: - Floating Window

struct FloatingWindow<Content: View>: View {
    let title: String
    @Binding var isShowing: Bool
    let content: () -> Content
    
    @State private var windowPosition = CGPoint(x: 600, y: 400)
    @State private var isDragging = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Title Bar
            HStack {
                Text(title)
                    .fontWeight(.medium)
                
                Spacer()
                
                Button(action: { isShowing = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(.regularMaterial)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        windowPosition.x += value.translation.width
                        windowPosition.y += value.translation.height
                    }
            )
            
            // Content
            content()
        }
        .background(.regularMaterial)
        .cornerRadius(12)
        .shadow(radius: 20)
        .position(windowPosition)
    }
}

// MARK: - Models

struct AuthenticatedUser {
    let username: String
    let token: String
    let role: UserRole
}

enum UserRole {
    case admin
    case user
    case guest
}