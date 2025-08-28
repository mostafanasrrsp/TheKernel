//
//  SetupWizardView.swift
//  RadiateOS
//
//  Professional setup wizard showcasing OS features
//

import SwiftUI

struct SetupWizardView: View {
    @State private var currentPage = 0
    @State private var animationProgress: Double = 0
    @State private var isAnimating = false
    @Binding var isPresented: Bool
    
    private let pages: [WizardPage] = [
        WizardPage(
            title: "Welcome to RadiateOS",
            subtitle: "The Future of Optical Computing",
            systemImage: "sparkles",
            color: .blue,
            description: "Experience lightning-fast processing with our revolutionary optical kernel technology.",
            features: ["Photonic Processing", "Quantum Speed", "Zero Latency"]
        ),
        WizardPage(
            title: "Optical CPU",
            subtitle: "Light-Speed Processing Power",
            systemImage: "cpu",
            color: .purple,
            description: "Our custom optical CPU processes data at the speed of light, delivering unprecedented performance.",
            features: ["THz Frequencies", "Parallel Execution", "Ultra Low Power"]
        ),
        WizardPage(
            title: "Smart Memory",
            subtitle: "Dynamic Resource Management",
            systemImage: "memorychip",
            color: .green,
            description: "Intelligent memory allocation with free-form bandwidth distribution for optimal performance.",
            features: ["Auto-Scaling", "Bandwidth Optimization", "Real-time Allocation"]
        ),
        WizardPage(
            title: "Ejectable ROM",
            subtitle: "Modular System Architecture",
            systemImage: "opticaldiscdrive",
            color: .orange,
            description: "Hot-swappable ROM modules for instant system configuration and feature expansion.",
            features: ["Hot-Swap Capable", "Instant Updates", "Modular Design"]
        ),
        WizardPage(
            title: "Universal Compatibility",
            subtitle: "x86/x64 Translation Layer",
            systemImage: "arrow.triangle.2.circlepath",
            color: .indigo,
            description: "Seamless backwards compatibility with existing software through our advanced translation layer.",
            features: ["Legacy Support", "Real-time Translation", "Zero Migration"]
        ),
        WizardPage(
            title: "You're All Set!",
            subtitle: "Ready to Experience the Future",
            systemImage: "checkmark.circle.fill",
            color: .mint,
            description: "RadiateOS is now configured and ready to revolutionize your computing experience.",
            features: ["Kernel Initialized", "Systems Online", "Ready to Launch"]
        )
    ]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Animated background
                AnimatedBackground(page: currentPage, animationProgress: animationProgress)
                
                VStack(spacing: 0) {
                    // Progress indicator
                    ProgressIndicator(currentPage: currentPage, totalPages: pages.count)
                        .padding(.top, 20)
                    
                    // Main content
                    TabView(selection: $currentPage) {
                        ForEach(pages.indices, id: \.self) { index in
                            WizardPageView(
                                page: pages[index],
                                isAnimating: $isAnimating,
                                animationProgress: $animationProgress
                            )
                            .tag(index)
                        }
                    }
                    #if os(iOS)
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    #endif
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: currentPage)
                    
                    // Navigation buttons
                    HStack {
                        if currentPage > 0 {
                            Button("Previous") {
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                    currentPage -= 1
                                    triggerAnimation()
                                }
                            }
                            .buttonStyle(SecondaryWizardButtonStyle())
                        }
                        
                        Spacer()
                        
                        Button(currentPage == pages.count - 1 ? "Get Started" : "Next") {
                            if currentPage == pages.count - 1 {
                                // Complete setup
                                UserDefaults.standard.set(true, forKey: "hasCompletedSetup")
                                withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                                    isPresented = false
                                }
                            } else {
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                    currentPage += 1
                                    triggerAnimation()
                                }
                            }
                        }
                        .buttonStyle(PrimaryWizardButtonStyle(isComplete: currentPage == pages.count - 1))
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 40)
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            triggerAnimation()
        }
    }
    
    private func triggerAnimation() {
        isAnimating = true
        withAnimation(.easeInOut(duration: 1.5)) {
            animationProgress = Double(currentPage + 1) / Double(pages.count)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isAnimating = false
        }
    }
}

struct WizardPage {
    let title: String
    let subtitle: String
    let systemImage: String
    let color: Color
    let description: String
    let features: [String]
}

struct WizardPageView: View {
    let page: WizardPage
    @Binding var isAnimating: Bool
    @Binding var animationProgress: Double
    @State private var featuresVisible = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                Spacer(minLength: 40)
                
                // Icon with animation
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [page.color.opacity(0.3), page.color.opacity(0.1)],
                                center: .center,
                                startRadius: 20,
                                endRadius: 80
                            )
                        )
                        .frame(width: 160, height: 160)
                        .scaleEffect(isAnimating ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: isAnimating)
                    
                    Image(systemName: page.systemImage)
                        .font(.system(size: 60, weight: .light))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [page.color, page.color.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .scaleEffect(featuresVisible ? 1.0 : 0.5)
                        .opacity(featuresVisible ? 1.0 : 0.0)
                        .animation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.2), value: featuresVisible)
                }
                .padding(.bottom, 20)
                
                // Title and subtitle
                VStack(spacing: 12) {
                    Text(page.title)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, .white.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .multilineTextAlignment(.center)
                        .opacity(featuresVisible ? 1.0 : 0.0)
                        .offset(y: featuresVisible ? 0 : 20)
                        .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.4), value: featuresVisible)
                    
                    Text(page.subtitle)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .opacity(featuresVisible ? 1.0 : 0.0)
                        .offset(y: featuresVisible ? 0 : 20)
                        .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.5), value: featuresVisible)
                }
                .padding(.horizontal, 40)
                
                // Description
                Text(page.description)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .padding(.horizontal, 40)
                    .opacity(featuresVisible ? 1.0 : 0.0)
                    .offset(y: featuresVisible ? 0 : 20)
                    .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.6), value: featuresVisible)
                
                // Features
                VStack(spacing: 16) {
                    ForEach(Array(page.features.enumerated()), id: \.offset) { index, feature in
                        FeatureRow(
                            feature: feature,
                            color: page.color,
                            isVisible: featuresVisible,
                            delay: 0.7 + (Double(index) * 0.1)
                        )
                    }
                }
                .padding(.horizontal, 40)
                .padding(.top, 20)
                
                Spacer(minLength: 40)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                featuresVisible = true
            }
        }
        .onChange(of: isAnimating) { _, newValue in
            if newValue {
                featuresVisible = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    featuresVisible = true
                }
            }
        }
    }
}

struct FeatureRow: View {
    let feature: String
    let color: Color
    let isVisible: Bool
    let delay: Double
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 20))
                .foregroundColor(color)
                .scaleEffect(isVisible ? 1.0 : 0.5)
                .opacity(isVisible ? 1.0 : 0.0)
                .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(delay), value: isVisible)
            
            Text(feature)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
                .opacity(isVisible ? 1.0 : 0.0)
                .offset(x: isVisible ? 0 : -20)
                .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(delay), value: isVisible)
            
            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
        .scaleEffect(isVisible ? 1.0 : 0.9)
        .opacity(isVisible ? 1.0 : 0.0)
        .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(delay), value: isVisible)
    }
}

struct AnimatedBackground: View {
    let page: Int
    let animationProgress: Double
    
    var body: some View {
        ZStack {
            // Base gradient
            LinearGradient(
                colors: [
                    Color.black,
                    Color.blue.opacity(0.3),
                    Color.purple.opacity(0.2),
                    Color.black
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Animated particles
            ForEach(0..<50, id: \.self) { index in
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: CGFloat.random(in: 2...6))
                    .position(
                        x: CGFloat.random(in: 0...400),
                        y: CGFloat.random(in: 0...800)
                    )
                    .scaleEffect(0.5 + animationProgress * 0.5)
                    .opacity(0.3 + animationProgress * 0.7)
                    .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true).delay(Double(index) * 0.1), value: animationProgress)
            }
            
            // Gradient overlay based on current page
            if page < 6 {
                let colors = [Color.blue, Color.purple, Color.green, Color.orange, Color.indigo, Color.mint]
                LinearGradient(
                    colors: [colors[page].opacity(0.2), Color.clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }
        .ignoresSafeArea()
    }
}

struct ProgressIndicator: View {
    let currentPage: Int
    let totalPages: Int
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalPages, id: \.self) { index in
                RoundedRectangle(cornerRadius: 4)
                    .fill(index <= currentPage ? Color.white : Color.white.opacity(0.3))
                    .frame(width: index == currentPage ? 24 : 8, height: 4)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: currentPage)
            }
        }
        .padding(.vertical, 20)
    }
}

struct PrimaryWizardButtonStyle: ButtonStyle {
    let isComplete: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 18, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 32)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .fill(
                        LinearGradient(
                            colors: isComplete ? [.green, .mint] : [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: (isComplete ? Color.green : Color.blue).opacity(0.3), radius: 8, x: 0, y: 4)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

struct SecondaryWizardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 18, weight: .medium))
            .foregroundColor(.white.opacity(0.8))
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    .background(
                        RoundedRectangle(cornerRadius: 25)
                            .fill(Color.white.opacity(0.05))
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

#Preview {
    SetupWizardView(isPresented: .constant(true))
}
