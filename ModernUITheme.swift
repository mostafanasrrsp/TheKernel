import SwiftUI

/// Modern UI theme inspired by Elementary OS and KDE Plasma
/// Provides a clean, elegant interface with smooth animations and blur effects
public struct ModernUITheme {
    
    // MARK: - Theme Variants
    public enum ThemeVariant: String, CaseIterable {
        case elementary = "Elementary"  // Elementary OS inspired
        case plasma = "Plasma"          // KDE Plasma inspired
        case budgie = "Budgie"          // Ubuntu Budgie inspired
        case pantheon = "Pantheon"      // Pantheon desktop inspired
        case cupertino = "Cupertino"    // macOS-like (Elementary style)
    }
    
    // MARK: - Color Schemes
    public struct ColorScheme {
        let primary: Color
        let secondary: Color
        let accent: Color
        let background: Color
        let surface: Color
        let text: Color
        let textSecondary: Color
        let success: Color
        let warning: Color
        let error: Color
        let border: Color
        
        // Elementary OS inspired colors
        static let elementary = ColorScheme(
            primary: Color(hex: "#3689E6"),      // Elementary Blue
            secondary: Color(hex: "#667885"),     // Elementary Gray
            accent: Color(hex: "#F37329"),        // Elementary Orange
            background: Color(hex: "#FAFAFA"),    // Light background
            surface: Color.white,
            text: Color(hex: "#333333"),
            textSecondary: Color(hex: "#666666"),
            success: Color(hex: "#73E051"),
            warning: Color(hex: "#F9C440"),
            error: Color(hex: "#ED5353"),
            border: Color(hex: "#D4D4D4")
        )
        
        // KDE Plasma inspired colors
        static let plasma = ColorScheme(
            primary: Color(hex: "#3DAEE9"),      // Plasma Blue
            secondary: Color(hex: "#7F8C8D"),     // Breeze Gray
            accent: Color(hex: "#27AE60"),        // Plasma Green
            background: Color(hex: "#EFF0F1"),    // Breeze background
            surface: Color(hex: "#FCFCFC"),
            text: Color(hex: "#232627"),
            textSecondary: Color(hex: "#7F8C8D"),
            success: Color(hex: "#27AE60"),
            warning: Color(hex: "#FDBC4B"),
            error: Color(hex: "#ED1515"),
            border: Color(hex: "#BDC3C7")
        )
        
        // Dark mode variants
        static let elementaryDark = ColorScheme(
            primary: Color(hex: "#3689E6"),
            secondary: Color(hex: "#95A3AB"),
            accent: Color(hex: "#F37329"),
            background: Color(hex: "#1E1E1E"),
            surface: Color(hex: "#2B2B2B"),
            text: Color(hex: "#FAFAFA"),
            textSecondary: Color(hex: "#95A3AB"),
            success: Color(hex: "#73E051"),
            warning: Color(hex: "#F9C440"),
            error: Color(hex: "#ED5353"),
            border: Color(hex: "#3E3E3E")
        )
        
        static let plasmaDark = ColorScheme(
            primary: Color(hex: "#3DAEE9"),
            secondary: Color(hex: "#95A5A6"),
            accent: Color(hex: "#27AE60"),
            background: Color(hex: "#1E1E20"),
            surface: Color(hex: "#31363B"),
            text: Color(hex: "#EFF0F1"),
            textSecondary: Color(hex: "#95A5A6"),
            success: Color(hex: "#27AE60"),
            warning: Color(hex: "#FDBC4B"),
            error: Color(hex: "#ED1515"),
            border: Color(hex: "#4D4D4D")
        )
    }
    
    // MARK: - Typography
    public struct Typography {
        let largeTitle: Font
        let title1: Font
        let title2: Font
        let title3: Font
        let headline: Font
        let body: Font
        let callout: Font
        let subheadline: Font
        let footnote: Font
        let caption1: Font
        let caption2: Font
        
        static let elementary = Typography(
            largeTitle: .custom("Inter", size: 34).weight(.light),
            title1: .custom("Inter", size: 28).weight(.regular),
            title2: .custom("Inter", size: 22).weight(.regular),
            title3: .custom("Inter", size: 20).weight(.regular),
            headline: .custom("Inter", size: 17).weight(.semibold),
            body: .custom("Inter", size: 17).weight(.regular),
            callout: .custom("Inter", size: 16).weight(.regular),
            subheadline: .custom("Inter", size: 15).weight(.regular),
            footnote: .custom("Inter", size: 13).weight(.regular),
            caption1: .custom("Inter", size: 12).weight(.regular),
            caption2: .custom("Inter", size: 11).weight(.regular)
        )
        
        static let plasma = Typography(
            largeTitle: .custom("Noto Sans", size: 32).weight(.light),
            title1: .custom("Noto Sans", size: 26).weight(.regular),
            title2: .custom("Noto Sans", size: 22).weight(.regular),
            title3: .custom("Noto Sans", size: 20).weight(.regular),
            headline: .custom("Noto Sans", size: 16).weight(.semibold),
            body: .custom("Noto Sans", size: 16).weight(.regular),
            callout: .custom("Noto Sans", size: 15).weight(.regular),
            subheadline: .custom("Noto Sans", size: 14).weight(.regular),
            footnote: .custom("Noto Sans", size: 13).weight(.regular),
            caption1: .custom("Noto Sans", size: 12).weight(.regular),
            caption2: .custom("Noto Sans", size: 11).weight(.regular)
        )
    }
    
    // MARK: - Spacing
    public struct Spacing {
        static let xxSmall: CGFloat = 2
        static let xSmall: CGFloat = 4
        static let small: CGFloat = 8
        static let medium: CGFloat = 16
        static let large: CGFloat = 24
        static let xLarge: CGFloat = 32
        static let xxLarge: CGFloat = 48
    }
    
    // MARK: - Corner Radius
    public struct CornerRadius {
        static let small: CGFloat = 4
        static let medium: CGFloat = 8
        static let large: CGFloat = 12
        static let xLarge: CGFloat = 16
        static let round: CGFloat = 999
    }
    
    // MARK: - Shadows
    public struct Shadow {
        static let small = ShadowStyle(
            color: Color.black.opacity(0.1),
            radius: 4,
            x: 0,
            y: 2
        )
        
        static let medium = ShadowStyle(
            color: Color.black.opacity(0.15),
            radius: 8,
            x: 0,
            y: 4
        )
        
        static let large = ShadowStyle(
            color: Color.black.opacity(0.2),
            radius: 16,
            x: 0,
            y: 8
        )
        
        static let elevation1 = ShadowStyle(
            color: Color.black.opacity(0.05),
            radius: 2,
            x: 0,
            y: 1
        )
        
        static let elevation2 = ShadowStyle(
            color: Color.black.opacity(0.08),
            radius: 4,
            x: 0,
            y: 2
        )
        
        static let elevation3 = ShadowStyle(
            color: Color.black.opacity(0.12),
            radius: 8,
            x: 0,
            y: 4
        )
    }
    
    public struct ShadowStyle {
        let color: Color
        let radius: CGFloat
        let x: CGFloat
        let y: CGFloat
    }
    
    // MARK: - Animation
    public struct Animation {
        static let fast = SwiftUI.Animation.easeInOut(duration: 0.15)
        static let normal = SwiftUI.Animation.easeInOut(duration: 0.25)
        static let slow = SwiftUI.Animation.easeInOut(duration: 0.35)
        static let spring = SwiftUI.Animation.spring(response: 0.3, dampingFraction: 0.7)
        static let bounce = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.6)
    }
}

// MARK: - Theme Manager

public class ThemeManager: ObservableObject {
    
    @Published public var currentTheme: ModernUITheme.ThemeVariant = .elementary
    @Published public var isDarkMode: Bool = false
    @Published public var accentColor: Color = ModernUITheme.ColorScheme.elementary.accent
    @Published public var useBlurEffects: Bool = true
    @Published public var useAnimations: Bool = true
    @Published public var transparencyLevel: Double = 0.95
    
    public static let shared = ThemeManager()
    
    public var colorScheme: ModernUITheme.ColorScheme {
        switch (currentTheme, isDarkMode) {
        case (.elementary, false):
            return ModernUITheme.ColorScheme.elementary
        case (.elementary, true):
            return ModernUITheme.ColorScheme.elementaryDark
        case (.plasma, false):
            return ModernUITheme.ColorScheme.plasma
        case (.plasma, true):
            return ModernUITheme.ColorScheme.plasmaDark
        default:
            return ModernUITheme.ColorScheme.elementary
        }
    }
    
    public var typography: ModernUITheme.Typography {
        switch currentTheme {
        case .elementary, .pantheon, .cupertino:
            return ModernUITheme.Typography.elementary
        case .plasma, .budgie:
            return ModernUITheme.Typography.plasma
        }
    }
    
    public func applyTheme(_ theme: ModernUITheme.ThemeVariant) {
        withAnimation(ModernUITheme.Animation.normal) {
            currentTheme = theme
        }
    }
    
    public func toggleDarkMode() {
        withAnimation(ModernUITheme.Animation.normal) {
            isDarkMode.toggle()
        }
    }
}

// MARK: - Custom UI Components

/// Elementary OS style button
public struct ElementaryButton: View {
    let title: String
    let action: () -> Void
    let style: ButtonStyle
    
    public enum ButtonStyle {
        case primary
        case secondary
        case destructive
        case text
    }
    
    @StateObject private var theme = ThemeManager.shared
    @State private var isHovered = false
    @State private var isPressed = false
    
    public init(_ title: String, style: ButtonStyle = .primary, action: @escaping () -> Void) {
        self.title = title
        self.style = style
        self.action = action
    }
    
    public var body: some View {
        Button(action: action) {
            Text(title)
                .font(theme.typography.callout)
                .foregroundColor(foregroundColor)
                .padding(.horizontal, ModernUITheme.Spacing.medium)
                .padding(.vertical, ModernUITheme.Spacing.small)
                .background(
                    RoundedRectangle(cornerRadius: ModernUITheme.CornerRadius.medium)
                        .fill(backgroundColor)
                        .shadow(
                            color: shadowColor,
                            radius: isPressed ? 2 : 4,
                            x: 0,
                            y: isPressed ? 1 : 2
                        )
                )
                .scaleEffect(isPressed ? 0.98 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            withAnimation(ModernUITheme.Animation.fast) {
                isHovered = hovering
            }
        }
    }
    
    private var backgroundColor: Color {
        switch style {
        case .primary:
            return isHovered ? theme.colorScheme.primary.opacity(0.9) : theme.colorScheme.primary
        case .secondary:
            return isHovered ? theme.colorScheme.secondary.opacity(0.9) : theme.colorScheme.secondary
        case .destructive:
            return isHovered ? theme.colorScheme.error.opacity(0.9) : theme.colorScheme.error
        case .text:
            return Color.clear
        }
    }
    
    private var foregroundColor: Color {
        switch style {
        case .primary, .destructive:
            return .white
        case .secondary:
            return theme.colorScheme.text
        case .text:
            return theme.colorScheme.primary
        }
    }
    
    private var shadowColor: Color {
        style == .text ? Color.clear : Color.black.opacity(0.2)
    }
}

/// KDE Plasma style panel
public struct PlasmaPanel: View {
    let content: AnyView
    let elevation: Int
    
    @StateObject private var theme = ThemeManager.shared
    
    public init<Content: View>(elevation: Int = 1, @ViewBuilder content: () -> Content) {
        self.content = AnyView(content())
        self.elevation = elevation
    }
    
    public var body: some View {
        content
            .padding(ModernUITheme.Spacing.medium)
            .background(
                RoundedRectangle(cornerRadius: ModernUITheme.CornerRadius.large)
                    .fill(theme.colorScheme.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: ModernUITheme.CornerRadius.large)
                            .stroke(theme.colorScheme.border, lineWidth: 1)
                    )
                    .shadow(
                        color: shadowStyle.color,
                        radius: shadowStyle.radius,
                        x: shadowStyle.x,
                        y: shadowStyle.y
                    )
            )
    }
    
    private var shadowStyle: ModernUITheme.ShadowStyle {
        switch elevation {
        case 1:
            return ModernUITheme.Shadow.elevation1
        case 2:
            return ModernUITheme.Shadow.elevation2
        case 3:
            return ModernUITheme.Shadow.elevation3
        default:
            return ModernUITheme.Shadow.small
        }
    }
}

/// Blur background view (Elementary OS / KDE style)
public struct BlurBackground: View {
    let style: BlurStyle
    
    public enum BlurStyle {
        case light
        case dark
        case adaptive
    }
    
    @StateObject private var theme = ThemeManager.shared
    
    public var body: some View {
        Rectangle()
            .fill(backgroundColor)
            .blur(radius: theme.useBlurEffects ? 20 : 0)
            .opacity(theme.transparencyLevel)
    }
    
    private var backgroundColor: Color {
        switch style {
        case .light:
            return Color.white
        case .dark:
            return Color.black
        case .adaptive:
            return theme.isDarkMode ? Color.black : Color.white
        }
    }
}

// MARK: - Color Extension

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
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}