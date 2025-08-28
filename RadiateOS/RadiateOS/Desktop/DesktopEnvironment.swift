//
//  DesktopEnvironment.swift
//  RadiateOS
//
//  Main desktop environment with window management
//

import SwiftUI

struct DesktopEnvironment: View {
    @StateObject private var osManager = OSManager.shared
    @State private var showApplicationLauncher = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Desktop background
                DesktopBackground()
                
                // Desktop icons and widgets (when desktop is visible)
                if osManager.showDesktop {
                    DesktopView()
                        .transition(.opacity)
                }
                
                // Windows
                ForEach(osManager.openWindows.filter { !$0.isMinimized }) { window in
                    WindowView(window: window)
                        .zIndex(window == osManager.activeWindow ? 1000 : Double(osManager.openWindows.firstIndex(of: window) ?? 0))
                }
                
                // Menu bar
                VStack {
                    MenuBarView(showApplicationLauncher: $showApplicationLauncher)
                    Spacer()
                }
                .zIndex(2000)
                
                // Dock
                VStack {
                    Spacer()
                    DockView()
                        .padding(.bottom, 10)
                }
                .zIndex(1500)
                
                // Application launcher
                if showApplicationLauncher {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .onTapGesture {
                            showApplicationLauncher = false
                        }
                        .zIndex(2500)
                    
                    ApplicationLauncherView(isPresented: $showApplicationLauncher)
                        .zIndex(3000)
                        .transition(.scale.combined(with: .opacity))
                }
                
                // System notifications
                VStack {
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            ForEach(osManager.systemNotifications.prefix(5)) { notification in
                                NotificationView(notification: notification)
                                    .transition(.asymmetric(
                                        insertion: .move(edge: .trailing).combined(with: .opacity),
                                        removal: .move(edge: .trailing).combined(with: .opacity)
                                    ))
                            }
                        }
                        .padding(.trailing, 20)
                    }
                    Spacer()
                }
                .zIndex(4000)
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: osManager.showDesktop)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: showApplicationLauncher)
        .animation(.spring(response: 0.3, dampingFraction: 0.9), value: osManager.systemNotifications.count)
        .onAppear {
            setupInitialState()
        }
    }
    
    private func setupInitialState() {
        // Welcome notification
        let welcomeNotification = OSNotification(
            title: "Welcome to RadiateOS",
            message: "Your optical computing system is ready!",
            type: .success,
            duration: 4.0
        )
        osManager.addNotification(welcomeNotification)
    }
}

struct DesktopBackground: View {
    @State private var animationOffset: CGFloat = 0
    
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
            ForEach(0..<30, id: \.self) { index in
                Circle()
                    .fill(Color.white.opacity(0.05))
                    .frame(width: CGFloat.random(in: 2...8))
                    .position(
                        x: CGFloat.random(in: 0...(NSScreen.main?.frame.width ?? 1920)),
                        y: CGFloat.random(in: 0...(NSScreen.main?.frame.height ?? 1080))
                    )
                    .offset(x: animationOffset)
                    .animation(.linear(duration: Double.random(in: 20...40)).repeatForever(autoreverses: false), value: animationOffset)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            animationOffset = NSScreen.main?.frame.width ?? 1920
        }
    }
}

struct DesktopView: View {
    @StateObject private var fileSystem = OSManager.shared.fileSystem
    // Show different apps on desktop than in dock - focus on productivity and utilities
    private let desktopApps = SystemAppRegistry.allSystemApps.filter { app in
        app.category == .productivity || app.category == .utilities || app.name == "Safari"
    }.prefix(6)
    
    var body: some View {
        VStack {
            // Quick access to common applications
            HStack {
                VStack(spacing: 20) {
                    ForEach(Array(desktopApps.enumerated()), id: \.element.id) { index, app in
                        DesktopIconView(application: app)
                            .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(Double(index) * 0.1), value: true)
                    }
                    Spacer()
                }
                .padding(.leading, 40)
                .padding(.top, 80)
                
                Spacer()
                
                // System status widget
                VStack {
                    SystemStatusWidget()
                        .padding(.trailing, 40)
                        .padding(.top, 80)
                    Spacer()
                }
            }
            
            Spacer()
        }
    }
}

struct DesktopIconView: View {
    let application: OSApplication
    @State private var isHovered = false
    
    var body: some View {
        VStack(spacing: 8) {
            Button(action: {
                OSManager.shared.launchApplication(application)
            }) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(isHovered ? 0.2 : 0.1))
                        .frame(width: 64, height: 64)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                    
                    Image(systemName: application.icon)
                        .font(.system(size: 28))
                        .foregroundColor(.white)
                }
                .scaleEffect(isHovered ? 1.1 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isHovered)
            }
            .buttonStyle(PlainButtonStyle())
            .onHover { hovering in
                isHovered = hovering
            }
            
            Text(application.name)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white)
                .shadow(color: .black, radius: 1)
        }
    }
}

struct SystemStatusWidget: View {
    @State private var cpuUsage: Double = 0.0
    @State private var memoryUsage: Double = 0.0
    @State private var currentTime = Date()
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 16) {
            // Time and date
            VStack(alignment: .trailing, spacing: 4) {
                Text(currentTime, style: .time)
                    .font(.system(size: 24, weight: .light, design: .rounded))
                    .foregroundColor(.white)
                
                Text(currentTime, style: .date)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
            
            // System stats
            VStack(alignment: .trailing, spacing: 12) {
                HStack(spacing: 8) {
                    Text("CPU")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                    
                    ProgressView(value: cpuUsage)
                        .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                        .frame(width: 80)
                    
                    Text("\(Int(cpuUsage * 100))%")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 30, alignment: .trailing)
                }
                
                HStack(spacing: 8) {
                    Text("RAM")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                    
                    ProgressView(value: memoryUsage)
                        .progressViewStyle(LinearProgressViewStyle(tint: .green))
                        .frame(width: 80)
                    
                    Text("\(Int(memoryUsage * 100))%")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 30, alignment: .trailing)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.black.opacity(0.3))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .onReceive(timer) { _ in
            currentTime = Date()
            updateSystemStats()
        }
    }
    
    private func updateSystemStats() {
        // Simulate system stats
        withAnimation(.easeInOut(duration: 0.5)) {
            cpuUsage = Double.random(in: 0.1...0.8)
            memoryUsage = Double.random(in: 0.3...0.7)
        }
    }
}

#Preview {
    DesktopEnvironment()
        .preferredColorScheme(.dark)
}
