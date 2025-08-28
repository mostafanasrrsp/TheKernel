import SwiftUI

// MARK: - RadiateOS Design System
// A rich, spectroscopic color palette inspired by light wavelengths and modern OS design

public struct RadiateDesign {
    
    // MARK: - Spectroscopic Color Palette
    public struct Colors {
        // Primary Spectrum Colors
        public static let ultraviolet = LinearGradient(
            colors: [Color(hex: "6B46C1"), Color(hex: "9333EA")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        public static let indigo = LinearGradient(
            colors: [Color(hex: "4C1D95"), Color(hex: "6366F1")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        public static let azure = LinearGradient(
            colors: [Color(hex: "0EA5E9"), Color(hex: "06B6D4")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        public static let emerald = LinearGradient(
            colors: [Color(hex: "10B981"), Color(hex: "34D399")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        public static let amber = LinearGradient(
            colors: [Color(hex: "F59E0B"), Color(hex: "FCD34D")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        public static let crimson = LinearGradient(
            colors: [Color(hex: "DC2626"), Color(hex: "EF4444")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        public static let infrared = LinearGradient(
            colors: [Color(hex: "991B1B"), Color(hex: "B91C1C")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        // Glass Morphism Colors
        public static let glassDark = Color.black.opacity(0.2)
        public static let glassLight = Color.white.opacity(0.1)
        public static let glassBorder = Color.white.opacity(0.2)
        
        // Semantic Colors
        public static let background = Color(hex: "0A0A0F")
        public static let surface = Color(hex: "151521")
        public static let surfaceLight = Color(hex: "1E1E2E")
        public static let text = Color(hex: "F8F8F2")
        public static let textSecondary = Color(hex: "A8A8B3")
        public static let textTertiary = Color(hex: "6C6C80")
        
        // Accent Colors
        public static let accentPrimary = Color(hex: "6366F1")
        public static let accentSecondary = Color(hex: "A855F7")
        public static let accentTertiary = Color(hex: "EC4899")
        
        // System Status Colors
        public static let success = Color(hex: "10B981")
        public static let warning = Color(hex: "F59E0B")
        public static let error = Color(hex: "EF4444")
        public static let info = Color(hex: "3B82F6")
        
        // Neon Glow Colors
        public static let neonBlue = Color(hex: "00D9FF")
        public static let neonPink = Color(hex: "FF006E")
        public static let neonGreen = Color(hex: "00FF88")
        public static let neonPurple = Color(hex: "BF00FF")
    }
    
    // MARK: - Typography
    public struct Typography {
        public static let largeTitle = Font.system(size: 34, weight: .bold, design: .rounded)
        public static let title1 = Font.system(size: 28, weight: .semibold, design: .rounded)
        public static let title2 = Font.system(size: 22, weight: .semibold, design: .rounded)
        public static let title3 = Font.system(size: 20, weight: .medium, design: .rounded)
        public static let headline = Font.system(size: 17, weight: .semibold, design: .rounded)
        public static let body = Font.system(size: 17, weight: .regular, design: .default)
        public static let callout = Font.system(size: 16, weight: .regular, design: .default)
        public static let subheadline = Font.system(size: 15, weight: .regular, design: .default)
        public static let footnote = Font.system(size: 13, weight: .regular, design: .default)
        public static let caption1 = Font.system(size: 12, weight: .regular, design: .default)
        public static let caption2 = Font.system(size: 11, weight: .regular, design: .default)
        public static let monospace = Font.system(size: 14, design: .monospaced)
    }
    
    // MARK: - Spacing
    public struct Spacing {
        public static let xs: CGFloat = 4
        public static let sm: CGFloat = 8
        public static let md: CGFloat = 16
        public static let lg: CGFloat = 24
        public static let xl: CGFloat = 32
        public static let xxl: CGFloat = 48
        public static let xxxl: CGFloat = 64
    }
    
    // MARK: - Corner Radius
    public struct CornerRadius {
        public static let xs: CGFloat = 4
        public static let sm: CGFloat = 8
        public static let md: CGFloat = 12
        public static let lg: CGFloat = 16
        public static let xl: CGFloat = 20
        public static let xxl: CGFloat = 24
        public static let full: CGFloat = 9999
    }
    
    // MARK: - Shadows
    public struct Shadows {
        public static let sm = Shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        public static let md = Shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
        public static let lg = Shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
        public static let xl = Shadow(color: .black.opacity(0.25), radius: 16, x: 0, y: 8)
        public static let neon = Shadow(color: Colors.neonBlue.opacity(0.5), radius: 20, x: 0, y: 0)
    }
    
    // MARK: - Animations
    public struct Animations {
        public static let fast = Animation.easeInOut(duration: 0.2)
        public static let normal = Animation.easeInOut(duration: 0.3)
        public static let slow = Animation.easeInOut(duration: 0.5)
        public static let spring = Animation.spring(response: 0.4, dampingFraction: 0.75)
        public static let bounce = Animation.interpolatingSpring(stiffness: 300, damping: 20)
    }
}

// MARK: - Glass Morphism View Modifier
public struct GlassMorphism: ViewModifier {
    let cornerRadius: CGFloat
    let shadowRadius: CGFloat
    
    public init(cornerRadius: CGFloat = RadiateDesign.CornerRadius.lg, shadowRadius: CGFloat = 10) {
        self.cornerRadius = cornerRadius
        self.shadowRadius = shadowRadius
    }
    
    public func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    RadiateDesign.Colors.glassLight
                    RadiateDesign.Colors.glassDark
                        .blur(radius: 20)
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(RadiateDesign.Colors.glassBorder, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .shadow(color: .black.opacity(0.2), radius: shadowRadius, x: 0, y: 5)
    }
}

// MARK: - Neon Glow View Modifier
public struct NeonGlow: ViewModifier {
    let color: Color
    let intensity: Double
    
    public init(color: Color = RadiateDesign.Colors.neonBlue, intensity: Double = 1.0) {
        self.color = color
        self.intensity = intensity
    }
    
    public func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(0.5 * intensity), radius: 5)
            .shadow(color: color.opacity(0.3 * intensity), radius: 10)
            .shadow(color: color.opacity(0.2 * intensity), radius: 20)
            .shadow(color: color.opacity(0.1 * intensity), radius: 40)
    }
}

// MARK: - Gradient Border View Modifier
public struct GradientBorder: ViewModifier {
    let gradient: LinearGradient
    let width: CGFloat
    let cornerRadius: CGFloat
    
    public init(gradient: LinearGradient, width: CGFloat = 2, cornerRadius: CGFloat = RadiateDesign.CornerRadius.md) {
        self.gradient = gradient
        self.width = width
        self.cornerRadius = cornerRadius
    }
    
    public func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(gradient, lineWidth: width)
            )
    }
}

// MARK: - Extensions
extension View {
    public func glassMorphism(cornerRadius: CGFloat = RadiateDesign.CornerRadius.lg, shadowRadius: CGFloat = 10) -> some View {
        modifier(GlassMorphism(cornerRadius: cornerRadius, shadowRadius: shadowRadius))
    }
    
    public func neonGlow(color: Color = RadiateDesign.Colors.neonBlue, intensity: Double = 1.0) -> some View {
        modifier(NeonGlow(color: color, intensity: intensity))
    }
    
    public func gradientBorder(_ gradient: LinearGradient, width: CGFloat = 2, cornerRadius: CGFloat = RadiateDesign.CornerRadius.md) -> some View {
        modifier(GradientBorder(gradient: gradient, width: width, cornerRadius: cornerRadius))
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}