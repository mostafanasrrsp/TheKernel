//
//  ColorPalette.swift
//  RadiateOS
//

import Foundation

#if canImport(SwiftUI)
import SwiftUI

public enum RadiateColors {
    // MARK: - Brand & Accents
    public static let brand = Color(hex: "#6D28D9") // Purple 700
    public static let brandAccent = Color(hex: "#22D3EE") // Cyan 400

    // MARK: - Semantic (Light)
    public static let backgroundLight = Color(hex: "#0B0F16") // Deep space navy
    public static let surfaceLight = Color(hex: "#121826")
    public static let surfaceSecondaryLight = Color(hex: "#0F1522")
    public static let textPrimaryLight = Color(hex: "#E6EAF2")
    public static let textSecondaryLight = Color(hex: "#A9B1C6")

    public static let success = Color(hex: "#22C55E")
    public static let warning = Color(hex: "#F59E0B")
    public static let error = Color(hex: "#EF4444")
    public static let info = Color(hex: "#3B82F6")

    // MARK: - Semantic (Dark)
    public static let backgroundDark = Color.black
    public static let surfaceDark = Color.black.opacity(0.7)
    public static let surfaceSecondaryDark = Color.black.opacity(0.5)
    public static let textPrimaryDark = Color.white
    public static let textSecondaryDark = Color.white.opacity(0.7)

    // MARK: - Spectrum
    // Rich spectroscopic colors approximated across visible wavelength
    public static let spectrum: [Color] = [
        Color(hex: "#9400D3"), // Violet
        Color(hex: "#6A00FF"), // Deep Indigo
        Color(hex: "#4C00FF"),
        Color(hex: "#0000FF"), // Blue
        Color(hex: "#0076FF"),
        Color(hex: "#00B3FF"),
        Color(hex: "#00FFFF"), // Cyan
        Color(hex: "#00FFB3"),
        Color(hex: "#00FF76"),
        Color(hex: "#00FF00"), // Green
        Color(hex: "#76FF00"),
        Color(hex: "#B3FF00"),
        Color(hex: "#FFFF00"), // Yellow
        Color(hex: "#FFC300"),
        Color(hex: "#FF9800"),
        Color(hex: "#FF6A00"),
        Color(hex: "#FF0000")  // Red
    ]

    public static var spectrumGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: spectrum),
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    public static func background(for scheme: ColorScheme) -> Color {
        scheme == .dark ? backgroundDark : backgroundLight
    }

    public static func surface(for scheme: ColorScheme) -> Color {
        scheme == .dark ? surfaceDark : surfaceLight
    }

    public static func surfaceSecondary(for scheme: ColorScheme) -> Color {
        scheme == .dark ? surfaceSecondaryDark : surfaceSecondaryLight
    }

    public static func textPrimary(for scheme: ColorScheme) -> Color {
        scheme == .dark ? textPrimaryDark : textPrimaryLight
    }

    public static func textSecondary(for scheme: ColorScheme) -> Color {
        scheme == .dark ? textSecondaryDark : textSecondaryLight
    }
}

public extension Color {
    init(hex: String, alpha: Double = 1.0) {
        let hexSanitized = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hexSanitized.count {
        case 3: // RGB (12-bit)
            (r, g, b) = ((int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (r, g, b) = (int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255.0,
            green: Double(g) / 255.0,
            blue: Double(b) / 255.0,
            opacity: alpha
        )
    }
}

#else
// Linux / no-SwiftUI fallback stubs to keep package buildable
public enum RadiateColors {
    public static let brandHex = "#6D28D9"
    public static let brandAccentHex = "#22D3EE"
    public static let spectrumHex: [String] = [
        "#9400D3", "#6A00FF", "#4C00FF", "#0000FF", "#0076FF", "#00B3FF",
        "#00FFFF", "#00FFB3", "#00FF76", "#00FF00", "#76FF00", "#B3FF00",
        "#FFFF00", "#FFC300", "#FF9800", "#FF6A00", "#FF0000"
    ]
}
#endif

