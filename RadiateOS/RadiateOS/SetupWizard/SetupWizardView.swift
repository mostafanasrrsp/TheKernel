import SwiftUI

struct SetupWizardView: View {
    @ObservedObject var setupManager: SetupManager
    @ObservedObject var osManager: OSManager
    @State private var currentStep = 0
    @State private var animateTransition = false
    
    let steps = ["Welcome", "User Setup", "System Configuration", "Privacy", "Complete"]
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.05, green: 0.05, blue: 0.15),
                    Color(red: 0.15, green: 0.05, blue: 0.25)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Progress indicator
                SetupProgressBar(
                    steps: steps,
                    currentStep: currentStep
                )
                .padding(.top, 40)
                .padding(.horizontal, 50)
                
                // Content area
                TabView(selection: $currentStep) {
                    WelcomeStep()
                        .tag(0)
                    
                    UserSetupStep(setupManager: setupManager)
                        .tag(1)
                    
                    SystemConfigurationStep(setupManager: setupManager)
                        .tag(2)
                    
                    PrivacyStep(setupManager: setupManager)
                        .tag(3)
                    
                    CompleteStep(setupManager: setupManager)
                        .tag(4)
                }
                .tabViewStyle(.automatic)
                .animation(.easeInOut, value: currentStep)
                
                // Navigation buttons
                HStack(spacing: 20) {
                    if currentStep > 0 {
                        Button("Back") {
                            withAnimation {
                                currentStep -= 1
                            }
                        }
                        .buttonStyle(SetupButtonStyle(isSecondary: true))
                    }
                    
                    Spacer()
                    
                    if currentStep < steps.count - 1 {
                        Button("Continue") {
                            withAnimation {
                                currentStep += 1
                            }
                        }
                        .buttonStyle(SetupButtonStyle())
                        .disabled(!isCurrentStepValid())
                    } else {
                        Button("Get Started") {
                            completeSetup()
                        }
                        .buttonStyle(SetupButtonStyle())
                    }
                }
                .padding(.horizontal, 50)
                .padding(.bottom, 40)
            }
        }
        .frame(minWidth: 800, minHeight: 600)
    }
    
    private func isCurrentStepValid() -> Bool {
        switch currentStep {
        case 1:
            return !setupManager.userName.isEmpty
        case 2:
            return !setupManager.systemName.isEmpty
        default:
            return true
        }
    }
    
    private func completeSetup() {
        setupManager.setupProgress = 1.0
        setupManager.completeSetup()
    }
}

// MARK: - Setup Steps

struct WelcomeStep: View {
    @State private var showAnimation = false
    
    var body: some View {
        VStack(spacing: 40) {
            // Animated logo
            ZStack {
                ForEach(0..<3) { index in
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [.cyan, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                        .frame(width: CGFloat(120 + index * 40), height: CGFloat(120 + index * 40))
                        .opacity(showAnimation ? 0.3 : 0.8)
                        .scaleEffect(showAnimation ? 1.1 : 1.0)
                        .animation(
                            .easeInOut(duration: 2)
                            .repeatForever()
                            .delay(Double(index) * 0.3),
                            value: showAnimation
                        )
                }
                
                Image(systemName: "cpu")
                    .font(.system(size: 60))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.cyan, .purple],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
            
            VStack(spacing: 20) {
                Text("Welcome to RadiateOS")
                    .font(.system(size: 42, weight: .thin, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, .white.opacity(0.8)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                
                Text("The Future of Optical Computing")
                    .font(.title2)
                    .foregroundColor(.cyan.opacity(0.8))
                
                Text("Experience unprecedented performance with our revolutionary optical processing technology")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 500)
            }
            
            // Features
            HStack(spacing: 40) {
                FeatureCard(
                    icon: "cpu",
                    title: "Optical CPU",
                    description: "8 photonic cores"
                )
                
                FeatureCard(
                    icon: "memorychip",
                    title: "Advanced Memory",
                    description: "Virtual memory with optical cache"
                )
                
                FeatureCard(
                    icon: "bolt.circle",
                    title: "Ultra Fast",
                    description: "3x faster than traditional"
                )
            }
        }
        .padding(50)
        .onAppear {
            showAnimation = true
        }
    }
}

struct UserSetupStep: View {
    @ObservedObject var setupManager: SetupManager
    @FocusState private var isUsernameFocused: Bool
    
    var body: some View {
        VStack(spacing: 40) {
            Image(systemName: "person.circle")
                .font(.system(size: 80))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.cyan, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Text("Create Your Account")
                .font(.title)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Username")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                    
                    TextField("Enter your username", text: $setupManager.userName)
                        .textFieldStyle(SetupTextFieldStyle())
                        .focused($isUsernameFocused)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Computer Name")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                    
                    TextField("Enter computer name", text: $setupManager.systemName)
                        .textFieldStyle(SetupTextFieldStyle())
                }
            }
            .frame(maxWidth: 400)
            
            Text("This information will be used to personalize your RadiateOS experience")
                .font(.caption)
                .foregroundColor(.white.opacity(0.4))
                .multilineTextAlignment(.center)
        }
        .padding(50)
        .onAppear {
            isUsernameFocused = true
        }
    }
}

struct SystemConfigurationStep: View {
    @ObservedObject var setupManager: SetupManager
    @State private var enableOpticalCPU = true
    @State private var enableQuantumFeatures = false
    @State private var performanceMode = "Balanced"
    
    var body: some View {
        VStack(spacing: 40) {
            Image(systemName: "gearshape")
                .font(.system(size: 80))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.cyan, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Text("System Configuration")
                .font(.title)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 25) {
                // Optical Computing
                GroupBox {
                    Toggle(isOn: $enableOpticalCPU) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Enable Optical Computing")
                                .font(.body)
                            Text("Use photonic processors for enhanced performance")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                    .tint(.cyan)
                }
                
                // Quantum Features
                GroupBox {
                    Toggle(isOn: $enableQuantumFeatures) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Quantum Features (Experimental)")
                                .font(.body)
                            Text("Enable quantum entanglement for faster processing")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                    .tint(.purple)
                    .disabled(!enableOpticalCPU)
                }
                
                // Performance Mode
                GroupBox {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Performance Mode")
                            .font(.body)
                        
                        Picker("", selection: $performanceMode) {
                            Text("Power Saver").tag("PowerSaver")
                            Text("Balanced").tag("Balanced")
                            Text("High Performance").tag("HighPerformance")
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                }
            }
            .frame(maxWidth: 500)
        }
        .padding(50)
    }
}

struct PrivacyStep: View {
    @ObservedObject var setupManager: SetupManager
    @State private var shareAnalytics = false
    @State private var enableLocationServices = false
    
    var body: some View {
        VStack(spacing: 40) {
            Image(systemName: "lock.shield")
                .font(.system(size: 80))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.cyan, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Text("Privacy & Security")
                .font(.title)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 25) {
                GroupBox {
                    Toggle(isOn: $setupManager.enableTelemetry) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Share Analytics")
                                .font(.body)
                            Text("Help improve RadiateOS by sharing anonymous usage data")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                    .tint(.cyan)
                }
                
                GroupBox {
                    Toggle(isOn: $enableLocationServices) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Location Services")
                                .font(.body)
                            Text("Allow apps to use your location")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                    .tint(.cyan)
                }
                
                Text("Your privacy is important to us. You can change these settings anytime in System Preferences.")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.4))
                    .padding(.top)
            }
            .frame(maxWidth: 500)
        }
        .padding(50)
    }
}

struct CompleteStep: View {
    @ObservedObject var setupManager: SetupManager
    @State private var showCelebration = false
    
    var body: some View {
        VStack(spacing: 40) {
            ZStack {
                if showCelebration {
                    ForEach(0..<8) { index in
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.cyan, .purple, .pink],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 10, height: 10)
                            .offset(x: 0, y: showCelebration ? -100 : 0)
                            .rotationEffect(.degrees(Double(index) * 45))
                            .opacity(showCelebration ? 0 : 1)
                            .animation(
                                .easeOut(duration: 1.5)
                                .delay(Double(index) * 0.1),
                                value: showCelebration
                            )
                    }
                }
                
                Image(systemName: "checkmark.circle")
                    .font(.system(size: 80))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.green, .cyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .scaleEffect(showCelebration ? 1.2 : 1.0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.6), value: showCelebration)
            }
            
            VStack(spacing: 20) {
                Text("Setup Complete!")
                    .font(.largeTitle)
                    .fontWeight(.semibold)
                
                Text("Welcome to RadiateOS, \(setupManager.userName)")
                    .font(.title2)
                    .foregroundColor(.cyan.opacity(0.8))
                
                Text("Your optical computing system is ready to use")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.6))
            }
            
            VStack(spacing: 15) {
                InfoRow(label: "System", value: setupManager.systemName)
                InfoRow(label: "User", value: setupManager.userName)
                InfoRow(label: "Optical CPU", value: "Enabled")
                InfoRow(label: "Memory", value: "16 GB")
                InfoRow(label: "Storage", value: "256 GB")
            }
            .padding()
            .background(Color.white.opacity(0.05))
            .cornerRadius(10)
            .frame(maxWidth: 400)
        }
        .padding(50)
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                showCelebration = true
            }
        }
    }
}

// MARK: - Supporting Views

struct SetupProgressBar: View {
    let steps: [String]
    let currentStep: Int
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<steps.count, id: \.self) { index in
                HStack(spacing: 0) {
                    // Step circle
                    ZStack {
                        Circle()
                            .fill(index <= currentStep ? Color.cyan : Color.white.opacity(0.2))
                            .frame(width: 30, height: 30)
                        
                        if index < currentStep {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                        } else {
                            Text("\(index + 1)")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(index == currentStep ? .white : .white.opacity(0.5))
                        }
                    }
                    
                    // Connecting line
                    if index < steps.count - 1 {
                        Rectangle()
                            .fill(index < currentStep ? Color.cyan : Color.white.opacity(0.2))
                            .frame(height: 2)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        
        // Step labels
        HStack {
            ForEach(0..<steps.count, id: \.self) { index in
                Text(steps[index])
                    .font(.caption)
                    .foregroundColor(index <= currentStep ? .white : .white.opacity(0.5))
                    .frame(maxWidth: .infinity)
                
                if index < steps.count - 1 {
                    Spacer()
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.top, 10)
    }
}

struct FeatureCard: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 30))
                .foregroundColor(.cyan)
            
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
            
            Text(description)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
        }
        .frame(width: 120)
    }
}

struct SetupTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Color.white.opacity(0.1))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.cyan.opacity(0.3), lineWidth: 1)
            )
            .foregroundColor(.white)
    }
}

struct SetupButtonStyle: ButtonStyle {
    var isSecondary: Bool = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 30)
            .padding(.vertical, 12)
            .background(
                isSecondary
                    ? Color.white.opacity(0.1)
                    : LinearGradient(
                        colors: [.cyan, .purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
            )
            .foregroundColor(.white)
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}