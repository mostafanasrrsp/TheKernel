import SwiftUI
import Combine

// MARK: - Circular Boot Animation with 43+147 Intervals
struct CircularBootLoader: View {
    @State private var bootProgress: Double = 0.0
    @State private var hourTickerAngle: Double = 0.0
    @State private var secondTickerAngle: Double = 0.0
    @State private var microIntervalAngle: Double = 0.0
    @State private var bootStartTime = Date()
    @State private var isBooting = true
    
    // Boot timing configuration
    let totalBootTime: TimeInterval = 60.0 // 1 minute boot time
    let hourIntervals = 43  // Primary counter-clockwise divisions
    let secondIntervals = 147 // Secondary fine-grain divisions
    
    // Calculated timing values
    private var hourTickDuration: TimeInterval {
        totalBootTime / Double(hourIntervals) // 60/43 ≈ 1.395 seconds per hour tick
    }
    
    private var secondTickDuration: TimeInterval {
        hourTickDuration / Double(secondIntervals) // 1.395/147 ≈ 0.00949 seconds per second tick
    }
    
    // Visual configuration
    let primaryRingSize: CGFloat = 300
    let secondaryRingSize: CGFloat = 250
    let tertiaryRingSize: CGFloat = 200
    
    // Colors with dynamic gradients
    private let bootColors = [
        Color(red: 0.2, green: 0.8, blue: 1.0), // Cyan
        Color(red: 0.5, green: 0.3, blue: 1.0), // Purple
        Color(red: 1.0, green: 0.3, blue: 0.5), // Pink
        Color(red: 0.3, green: 1.0, blue: 0.5)  // Green
    ]
    
    var body: some View {
        ZStack {
            // Background gradient
            RadialGradient(
                colors: [Color.black, Color.blue.opacity(0.2)],
                center: .center,
                startRadius: 50,
                endRadius: 400
            )
            .ignoresSafeArea()
            
            // Main circular boot animation
            ZStack {
                // Outer ring - Hour ticker (43 intervals)
                CircularProgressRing(
                    progress: hourTickerAngle / 360.0,
                    ringSize: primaryRingSize,
                    strokeWidth: 15,
                    isCounterClockwise: true,
                    intervals: hourIntervals,
                    color: bootColors[0]
                )
                .overlay(
                    HourTickerMarkers(
                        intervals: hourIntervals,
                        radius: primaryRingSize / 2,
                        currentInterval: Int(hourTickerAngle / (360.0 / Double(hourIntervals)))
                    )
                )
                
                // Middle ring - Second ticker (147 intervals)
                CircularProgressRing(
                    progress: secondTickerAngle / 360.0,
                    ringSize: secondaryRingSize,
                    strokeWidth: 10,
                    isCounterClockwise: true,
                    intervals: secondIntervals,
                    color: bootColors[1]
                )
                .overlay(
                    SecondTickerMarkers(
                        intervals: secondIntervals,
                        radius: secondaryRingSize / 2,
                        currentInterval: Int(secondTickerAngle / (360.0 / Double(secondIntervals)))
                    )
                )
                
                // Inner ring - Micro intervals (147 * 43 subdivisions)
                CircularProgressRing(
                    progress: microIntervalAngle / 360.0,
                    ringSize: tertiaryRingSize,
                    strokeWidth: 5,
                    isCounterClockwise: true,
                    intervals: hourIntervals * secondIntervals,
                    color: bootColors[2]
                )
                
                // Center display
                VStack(spacing: 10) {
                    // Boot progress percentage
                    Text("\(Int(bootProgress * 100))%")
                        .font(.system(size: 48, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                    
                    // Hour ticker display
                    Text("H: \(Int(hourTickerAngle / (360.0 / Double(hourIntervals))))/\(hourIntervals)")
                        .font(.system(size: 16, weight: .medium, design: .monospaced))
                        .foregroundColor(bootColors[0])
                    
                    // Second ticker display
                    Text("S: \(Int(secondTickerAngle / (360.0 / Double(secondIntervals))))/\(secondIntervals)")
                        .font(.system(size: 16, weight: .medium, design: .monospaced))
                        .foregroundColor(bootColors[1])
                    
                    // Time remaining
                    Text(timeRemainingString())
                        .font(.system(size: 14, weight: .light, design: .monospaced))
                        .foregroundColor(.white.opacity(0.8))
                }
                
                // Quantum particle effects
                ForEach(0..<20, id: \.self) { index in
                    QuantumParticle(
                        angle: .degrees(Double(index) * 18),
                        radius: primaryRingSize / 2 + 30,
                        delay: Double(index) * 0.1
                    )
                }
            }
            .onAppear {
                startBootAnimation()
            }
            
            // Boot status messages
            VStack {
                Spacer()
                BootStatusMessage(progress: bootProgress)
                    .padding(.bottom, 50)
            }
        }
    }
    
    // MARK: - Animation Logic
    private func startBootAnimation() {
        bootStartTime = Date()
        
        // Main animation timer
        Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { timer in
            guard isBooting else {
                timer.invalidate()
                return
            }
            
            let elapsed = Date().timeIntervalSince(bootStartTime)
            let progress = min(elapsed / totalBootTime, 1.0)
            
            withAnimation(.linear(duration: 0.01)) {
                // Update boot progress
                bootProgress = progress
                
                // Calculate hour ticker angle (counter-clockwise)
                let hourTicksCompleted = elapsed / hourTickDuration
                hourTickerAngle = -hourTicksCompleted * (360.0 / Double(hourIntervals))
                
                // Calculate second ticker angle (counter-clockwise, faster)
                let secondTicksCompleted = elapsed / secondTickDuration
                secondTickerAngle = -secondTicksCompleted * (360.0 / Double(secondIntervals))
                
                // Calculate micro interval angle (fastest)
                microIntervalAngle = -elapsed * 6.0 // Full rotation every 60 seconds
            }
            
            // Check if boot is complete
            if progress >= 1.0 {
                isBooting = false
                timer.invalidate()
                onBootComplete()
            }
        }
    }
    
    private func timeRemainingString() -> String {
        let elapsed = Date().timeIntervalSince(bootStartTime)
        let remaining = max(totalBootTime - elapsed, 0)
        let minutes = Int(remaining) / 60
        let seconds = Int(remaining) % 60
        let milliseconds = Int((remaining.truncatingRemainder(dividingBy: 1)) * 1000)
        return String(format: "%02d:%02d.%03d", minutes, seconds, milliseconds)
    }
    
    private func onBootComplete() {
        // Boot completion handler
        print("Boot completed!")
    }
}

// MARK: - Circular Progress Ring Component
struct CircularProgressRing: View {
    let progress: Double
    let ringSize: CGFloat
    let strokeWidth: CGFloat
    let isCounterClockwise: Bool
    let intervals: Int
    let color: Color
    
    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(
                    color.opacity(0.2),
                    lineWidth: strokeWidth
                )
                .frame(width: ringSize, height: ringSize)
            
            // Progress ring
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    LinearGradient(
                        colors: [color, color.opacity(0.5)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(
                        lineWidth: strokeWidth,
                        lineCap: .round
                    )
                )
                .frame(width: ringSize, height: ringSize)
                .rotationEffect(.degrees(isCounterClockwise ? 90 : -90))
                .scaleEffect(x: isCounterClockwise ? -1 : 1, y: 1)
            
            // Interval markers
            ForEach(0..<intervals, id: \.self) { index in
                IntervalMarker(
                    angle: Double(index) * (360.0 / Double(intervals)),
                    radius: ringSize / 2,
                    isActive: Double(index) <= progress * Double(intervals),
                    color: color
                )
            }
        }
    }
}

// MARK: - Hour Ticker Markers
struct HourTickerMarkers: View {
    let intervals: Int
    let radius: CGFloat
    let currentInterval: Int
    
    var body: some View {
        ForEach(0..<intervals, id: \.self) { index in
            let angle = Double(index) * (360.0 / Double(intervals))
            let isActive = index <= currentInterval
            
            Circle()
                .fill(isActive ? Color.cyan : Color.gray.opacity(0.3))
                .frame(width: isActive ? 8 : 4, height: isActive ? 8 : 4)
                .offset(x: radius * cos(angle * .pi / 180),
                       y: radius * sin(angle * .pi / 180))
                .animation(.easeInOut(duration: 0.2), value: isActive)
        }
    }
}

// MARK: - Second Ticker Markers
struct SecondTickerMarkers: View {
    let intervals: Int
    let radius: CGFloat
    let currentInterval: Int
    
    var body: some View {
        ForEach(0..<min(intervals, 147), id: \.self) { index in
            let angle = Double(index) * (360.0 / Double(intervals))
            let isActive = index <= currentInterval
            
            Rectangle()
                .fill(isActive ? Color.purple.opacity(0.8) : Color.gray.opacity(0.2))
                .frame(width: 2, height: isActive ? 12 : 6)
                .offset(x: radius * cos(angle * .pi / 180),
                       y: radius * sin(angle * .pi / 180))
                .rotationEffect(.degrees(angle))
                .animation(.easeInOut(duration: 0.1), value: isActive)
        }
    }
}

// MARK: - Interval Marker
struct IntervalMarker: View {
    let angle: Double
    let radius: CGFloat
    let isActive: Bool
    let color: Color
    
    var body: some View {
        Circle()
            .fill(isActive ? color : Color.gray.opacity(0.3))
            .frame(width: 3, height: 3)
            .offset(x: radius * cos(angle * .pi / 180),
                   y: radius * sin(angle * .pi / 180))
    }
}

// MARK: - Quantum Particle Effect
struct QuantumParticle: View {
    let angle: Angle
    let radius: CGFloat
    let delay: Double
    
    @State private var opacity: Double = 0.0
    @State private var scale: CGFloat = 0.5
    
    var body: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [Color.cyan, Color.blue.opacity(0.3)],
                    center: .center,
                    startRadius: 1,
                    endRadius: 5
                )
            )
            .frame(width: 10, height: 10)
            .scaleEffect(scale)
            .opacity(opacity)
            .offset(
                x: radius * cos(angle.radians),
                y: radius * sin(angle.radians)
            )
            .onAppear {
                withAnimation(
                    Animation.easeInOut(duration: 2.0)
                        .repeatForever(autoreverses: true)
                        .delay(delay)
                ) {
                    opacity = 1.0
                    scale = 1.5
                }
            }
    }
}

// MARK: - Boot Status Messages
struct BootStatusMessage: View {
    let progress: Double
    
    private var statusMessage: String {
        switch progress {
        case 0..<0.1: return "Initializing Quantum Core..."
        case 0.1..<0.2: return "Loading Virtual GPUs..."
        case 0.2..<0.3: return "Establishing Neural Networks..."
        case 0.3..<0.4: return "Configuring Photonic Circuits..."
        case 0.4..<0.5: return "Optimizing Power Efficiency..."
        case 0.5..<0.6: return "Mounting Tensor Cores..."
        case 0.6..<0.7: return "Synchronizing Memory Banks..."
        case 0.7..<0.8: return "Activating PCIe 7.0 Interface..."
        case 0.8..<0.9: return "Finalizing System Configuration..."
        case 0.9..<1.0: return "Starting RadiateOS..."
        default: return "Boot Complete!"
        }
    }
    
    var body: some View {
        Text(statusMessage)
            .font(.system(size: 16, weight: .medium, design: .monospaced))
            .foregroundColor(.white.opacity(0.9))
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.black.opacity(0.7))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.cyan.opacity(0.5), lineWidth: 1)
                    )
            )
    }
}

// MARK: - Boot Animation Mathematics
struct BootTimingCalculator {
    let totalBootTime: TimeInterval = 60.0
    let hourIntervals = 43
    let secondIntervals = 147
    
    // Calculate precise timing intervals
    var hourTickDuration: TimeInterval {
        // Each hour tick represents 1/43 of the total boot time
        // 60 seconds / 43 intervals = 1.3953488372 seconds per hour tick
        return totalBootTime / Double(hourIntervals)
    }
    
    var secondTickDuration: TimeInterval {
        // Each second tick represents 1/147 of each hour tick
        // 1.3953488372 / 147 = 0.00949081517 seconds per second tick
        return hourTickDuration / Double(secondIntervals)
    }
    
    var totalMicroIntervals: Int {
        // Total micro-intervals = 43 * 147 = 6,321 intervals
        return hourIntervals * secondIntervals
    }
    
    var microIntervalDuration: TimeInterval {
        // Each micro-interval = 60 / 6321 = 0.00949081517 seconds
        return totalBootTime / Double(totalMicroIntervals)
    }
    
    func angleForProgress(_ progress: Double, intervals: Int, counterClockwise: Bool) -> Double {
        let angle = progress * 360.0
        return counterClockwise ? -angle : angle
    }
    
    func intervalForAngle(_ angle: Double, intervals: Int) -> Int {
        let normalizedAngle = abs(angle).truncatingRemainder(dividingBy: 360.0)
        return Int(normalizedAngle / (360.0 / Double(intervals)))
    }
}