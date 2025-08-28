//
//  LaunchScreenView.swift
//  RadiateOS
//
//  Professional launch screen with kernel boot animation
//

import SwiftUI

struct LaunchScreenView: View {
    @Binding var isLaunching: Bool
    @Binding var kernelBooted: Bool
    
    @State private var logoScale: CGFloat = 0.5
    @State private var logoOpacity: Double = 0.0
    @State private var particlesVisible = false
    @State private var bootProgress: Double = 0.0
    @State private var bootStage = 0
    @State private var glowIntensity: Double = 0.0
    
    private let bootStages = [
        "Initializing Optical Matrix...",
        "Loading Photonic Drivers...",
        "Calibrating Light Processors...",
        "Starting Quantum Threads...",
        "Mounting ROM Modules...",
        "Activating Translation Layer...",
        "RadiateOS Ready"
    ]
    
    var body: some View {
        ZStack {
            // Dynamic background
            AnimatedLaunchBackground(particlesVisible: particlesVisible, glowIntensity: glowIntensity)
            
            VStack(spacing: 40) {
                Spacer()
                
                // Logo and brand
                VStack(spacing: 20) {
                    // Main logo
                    ZStack {
                        // Outer glow
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        Color.blue.opacity(glowIntensity * 0.5),
                                        Color.purple.opacity(glowIntensity * 0.3),
                                        Color.clear
                                    ],
                                    center: .center,
                                    startRadius: 40,
                                    endRadius: 120
                                )
                            )
                            .frame(width: 240, height: 240)
                            .scaleEffect(1.0 + glowIntensity * 0.2)
                        
                        // Inner circle with gradient
                        Circle()
                            .fill(
                                AngularGradient(
                                    colors: [
                                        .blue, .purple, .indigo, .blue
                                    ],
                                    center: .center,
                                    startAngle: .degrees(0),
                                    endAngle: .degrees(360)
                                )
                            )
                            .frame(width: 120, height: 120)
                            .rotationEffect(.degrees(bootProgress * 360))
                        
                        // Logo symbol
                        Image(systemName: "sparkles")
                            .font(.system(size: 50, weight: .light))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.white, .white.opacity(0.9)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .scaleEffect(logoScale)
                            .opacity(logoOpacity)
                            .shadow(color: .white.opacity(0.5), radius: 10)
                    }
                    
                    // Brand name
                    VStack(spacing: 8) {
                        Text("RadiateOS")
                            .font(.system(size: 42, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.white, .blue.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .opacity(logoOpacity)
                            .shadow(color: .blue.opacity(0.3), radius: 5)
                        
                        Text("Optical Computing Platform")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                            .opacity(logoOpacity * 0.8)
                    }
                }
                
                Spacer()
                
                // Boot progress section
                VStack(spacing: 20) {
                    // Progress bar
                    VStack(spacing: 12) {
                        HStack {
                            Text("Booting Kernel...")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                            
                            Spacer()
                            
                            Text("\(Int(bootProgress * 100))%")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.blue)
                        }
                        
                        // Progress bar
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.white.opacity(0.1))
                                .frame(height: 6)
                            
                            RoundedRectangle(cornerRadius: 8)
                                .fill(
                                    LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: max(0, (NSScreen.main?.frame.width ?? 1920) * 0.6 * bootProgress), height: 6)
                                .shadow(color: .blue.opacity(0.5), radius: 4)
                        }
                        .frame(width: (NSScreen.main?.frame.width ?? 1920) * 0.6)
                    }
                    
                    // Boot stage text
                    if bootStage < bootStages.count {
                        Text(bootStages[bootStage])
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(.white.opacity(0.6))
                            .opacity(logoOpacity)
                            .animation(.easeInOut(duration: 0.3), value: bootStage)
                    }
                }
                .padding(.bottom, 60)
            }
            .padding(.horizontal, 40)
        }
        .onAppear {
            startBootSequence()
        }
        .onTapGesture(count: 3) {
            // Triple tap to skip boot sequence for development
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                bootProgress = 1.0
                bootStage = bootStages.count - 1
                kernelBooted = true
                isLaunching = false
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private func startBootSequence() {
        // Logo animation
        withAnimation(.spring(response: 1.0, dampingFraction: 0.6)) {
            logoScale = 1.0
            logoOpacity = 1.0
        }
        
        // Start particles after logo
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeInOut(duration: 1.0)) {
                particlesVisible = true
                glowIntensity = 1.0
            }
        }
        
        // Boot progress animation with proper stage management
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            bootToNextStage()
        }
    }
    
    private func bootToNextStage() {
        guard bootStage < bootStages.count - 1 else {
            // Boot complete
            withAnimation(.easeInOut(duration: 0.5)) {
                bootProgress = 1.0
                bootStage = bootStages.count - 1
            }
            
            // Mark kernel as booted and transition
            kernelBooted = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.spring(response: 0.8, dampingFraction: 0.8)) {
                    isLaunching = false
                }
            }
            return
        }
        
        // Progress to next stage
        withAnimation(.easeInOut(duration: 0.4)) {
            bootStage += 1
            bootProgress = Double(bootStage) / Double(bootStages.count - 1)
        }
        
        // Schedule next stage
        let nextDelay: TimeInterval = bootStage < 3 ? 0.6 : 0.4 // Slower start, faster later
        DispatchQueue.main.asyncAfter(deadline: .now() + nextDelay) {
            bootToNextStage()
        }
    }
}

struct AnimatedLaunchBackground: View {
    let particlesVisible: Bool
    let glowIntensity: Double
    @State private var animationOffset: CGFloat = 0
    
    var body: some View {
        ZStack {
            // Base gradient
            LinearGradient(
                colors: [
                    Color.black,
                    Color.blue.opacity(0.2),
                    Color.purple.opacity(0.1),
                    Color.black
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Animated grid pattern
            VStack(spacing: 20) {
                ForEach(0..<20, id: \.self) { row in
                    HStack(spacing: 20) {
                        ForEach(0..<10, id: \.self) { col in
                            Circle()
                                .fill(Color.blue.opacity(0.1))
                                .frame(width: 2, height: 2)
                                .opacity(particlesVisible ? Double.random(in: 0.1...0.6) : 0.0)
                                .scaleEffect(particlesVisible ? CGFloat.random(in: 0.5...1.5) : 0.1)
                                .animation(
                                    .easeInOut(duration: Double.random(in: 1.0...3.0))
                                    .repeatForever(autoreverses: true)
                                    .delay(Double.random(in: 0...2.0)),
                                    value: particlesVisible
                                )
                        }
                    }
                }
            }
            .offset(x: animationOffset)
            .onAppear {
                withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                    animationOffset = 100
                }
            }
            
            // Flowing light rays
            ForEach(0..<5, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.clear,
                                Color.blue.opacity(glowIntensity * 0.3),
                                Color.purple.opacity(glowIntensity * 0.2),
                                Color.clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 200, height: 1)
                    .rotationEffect(.degrees(Double(index) * 36))
                    .offset(x: particlesVisible ? 200 : -200)
                    .animation(
                        .easeInOut(duration: 3.0)
                        .repeatForever(autoreverses: false)
                        .delay(Double(index) * 0.5),
                        value: particlesVisible
                    )
            }
        }
        .ignoresSafeArea()
    }
}

#Preview {
    LaunchScreenView(isLaunching: .constant(true), kernelBooted: .constant(false))
}
