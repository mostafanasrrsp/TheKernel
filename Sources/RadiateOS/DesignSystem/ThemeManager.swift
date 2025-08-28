import Foundation
#if canImport(SwiftUI)
import SwiftUI

/// Yaru-inspired theme manager with light/dark and accent palette
public final class ThemeManager: ObservableObject {
    public static let shared = ThemeManager()
    
    @Published public private(set) var theme: Theme = .yaruLight
    @Published public private(set) var accent: Color = YaruColors.accentOrange
    
    private init() {}
    
    public func setLight() { theme = .yaruLight }
    public func setDark() { theme = .yaruDark }
    public func setAccent(_ color: Color) { accent = color }
}

public struct YaruColors {
    // Canonical Yaru accents
    public static let accentOrange = Color(red: 233/255, green: 84/255, blue: 32/255)      // #E95420
    public static let aubergine    = Color(red: 119/255, green: 33/255, blue: 111/255)     // #77216F
    public static let warmGrey     = Color(red: 110/255, green: 112/255, blue: 114/255)    // #6E7072
    public static let teal         = Color(red: 44/255, green: 190/255, blue: 189/255)     // #2CBEBD
    public static let sage         = Color(red: 152/255, green: 202/255, blue: 70/255)     // #98CA46
    public static let sky          = Color(red: 45/255, green: 156/255, blue: 219/255)     // #2D9CDB
}

public struct Theme: Equatable {
    public let name: String
    public let isDark: Bool
    
    public let background: Color
    public let surface: Color
    public let textPrimary: Color
    public let textSecondary: Color
    public let border: Color
    public let success: Color
    public let warning: Color
    public let error: Color
    
    public static let yaruLight = Theme(
        name: "Yaru Light",
        isDark: false,
        background: Color(white: 0.98),
        surface: Color.white,
        textPrimary: Color.black,
        textSecondary: Color.gray,
        border: Color(white: 0.85),
        success: Color.green.opacity(0.85),
        warning: Color.yellow.opacity(0.85),
        error: Color.red.opacity(0.85)
    )
    
    public static let yaruDark = Theme(
        name: "Yaru Dark",
        isDark: true,
        background: Color(red: 0.10, green: 0.10, blue: 0.11),
        surface: Color(red: 0.15, green: 0.15, blue: 0.16),
        textPrimary: Color.white,
        textSecondary: Color(white: 0.8),
        border: Color(white: 0.25),
        success: Color.green.opacity(0.9),
        warning: Color.yellow.opacity(0.9),
        error: Color.red.opacity(0.9)
    )
}

// Convenience ViewModifier to apply theme surface and text colors
public struct ThemedSurface: ViewModifier {
    let theme: Theme
    let accent: Color
    
    public func body(content: Content) -> some View {
        content
            .accentColor(accent)
            .background(theme.surface)
            .foregroundColor(theme.textPrimary)
    }
}

public extension View {
    func themedSurface(theme: Theme, accent: Color) -> some View {
        self.modifier(ThemedSurface(theme: theme, accent: accent))
    }
}

#else

// Non-UI platforms: provide a minimal placeholder to avoid compile issues
public final class ThemeManager {
    public static let shared = ThemeManager()
    private init() {}
}

#endif

