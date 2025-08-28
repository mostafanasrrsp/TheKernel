import SwiftUI

struct ContentView: View {
    @EnvironmentObject var kernel: Kernel
    @EnvironmentObject var osManager: OSManager
    @State private var showBootScreen = true
    @State private var bootProgress: Double = 0.0
    @State private var bootMessage: String = "Initializing..."
    
    var body: some View {
        ZStack {
            if showBootScreen {
                BootScreenView(progress: $bootProgress, message: $bootMessage)
                    .onAppear {
                        performBoot()
                    }
            } else {
                DesktopEnvironment()
                    .environmentObject(kernel)
                    .environmentObject(osManager)
            }
        }
        .frame(minWidth: 1280, minHeight: 720)
        .preferredColorScheme(.dark)
    }
    
    private func performBoot() {
        // Simulate boot process
        let bootSteps = [
            (0.1, "Loading RadiateOS Kernel..."),
            (0.2, "Initializing Optical CPU..."),
            (0.3, "Setting up Memory Management..."),
            (0.4, "Loading System Services..."),
            (0.5, "Initializing Desktop Environment..."),
            (0.6, "Loading User Profile..."),
            (0.7, "Starting Network Services..."),
            (0.8, "Mounting File Systems..."),
            (0.9, "Finalizing Boot Sequence..."),
            (1.0, "Welcome to RadiateOS")
        ]
        
        for (progress, message) in bootSteps {
            DispatchQueue.main.asyncAfter(deadline: .now() + progress * 3) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    bootProgress = progress
                    bootMessage = message
                }
                
                if progress >= 1.0 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            showBootScreen = false
                        }
                    }
                }
            }
        }
    }
}

struct BootScreenView: View {
    @Binding var progress: Double
    @Binding var message: String
    @State private var glowAnimation = false
    
    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.05, green: 0.05, blue: 0.15),
                    Color(red: 0.1, green: 0.05, blue: 0.2)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                // Logo
                ZStack {
                    // Optical effect circles
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
                            .frame(width: CGFloat(100 + index * 30), height: CGFloat(100 + index * 30))
                            .opacity(glowAnimation ? 0.3 : 0.8)
                            .animation(
                                .easeInOut(duration: 2)
                                .repeatForever()
                                .delay(Double(index) * 0.2),
                                value: glowAnimation
                            )
                    }
                    
                    // RadiateOS Text
                    Text("RadiateOS")
                        .font(.system(size: 48, weight: .thin, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.cyan, .purple, .pink],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: .cyan.opacity(0.5), radius: 10)
                }
                
                // Progress bar
                VStack(spacing: 15) {
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white.opacity(0.1))
                            .frame(width: 400, height: 8)
                        
                        RoundedRectangle(cornerRadius: 10)
                            .fill(
                                LinearGradient(
                                    colors: [.cyan, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: 400 * progress, height: 8)
                            .shadow(color: .cyan, radius: 5)
                    }
                    
                    Text(message)
                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                        .foregroundColor(.white.opacity(0.8))
                }
                
                // System info
                VStack(spacing: 5) {
                    Text("Kernel Version: 2.0.0")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.4))
                    
                    Text("Optical Computing: Enabled")
                        .font(.caption)
                        .foregroundColor(.cyan.opacity(0.6))
                }
            }
        }
        .onAppear {
            glowAnimation = true
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(Kernel())
            .environmentObject(OSManager())
    }
}