//
//  Theme.swift
//  cerebral
//
//  Clean Professional Color System
//  Inspired by McKinsey & Company's sophisticated design language
//

import SwiftUI

// MARK: - Color Extension for Hex Support

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
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    // Helper for adaptive colors
    static func adaptive(light: Color, dark: Color) -> Color {
        return Color(NSColor(name: nil) { appearance in
            switch appearance.name {
            case .darkAqua, .vibrantDark, .accessibilityHighContrastDarkAqua, .accessibilityHighContrastVibrantDark:
                return NSColor(dark)
            default:
                return NSColor(light)
            }
        })
    }
}

// MARK: - Clean Professional Color System

extension DesignSystem {
    struct Colors {
        
        // MARK: - Base Palette (Light Mode) - Clean & Minimal
        private struct Light {
            // Pure & Clean Neutrals
            static let white = Color.white
            static let gray50 = Color(hex: "FAFAFA")      // Subtle background
            static let gray100 = Color(hex: "F5F5F5")     // Light background
            static let gray200 = Color(hex: "EEEEEE")     // Border light
            static let gray300 = Color(hex: "E0E0E0")     // Border
            static let gray400 = Color(hex: "BDBDBD")     // Border strong
            static let gray500 = Color(hex: "9E9E9E")     // Text muted
            static let gray600 = Color(hex: "757575")     // Text secondary
            static let gray700 = Color(hex: "616161")     // Text primary
            static let gray800 = Color(hex: "424242")     // Text strong
            static let gray900 = Color(hex: "212121")     // Text emphasis
            
            // McKinsey-Inspired Professional Blue (Deep & Sophisticated)
            static let navy900 = Color(hex: "0A1628")     // Deep navy for emphasis
            static let navy800 = Color(hex: "1A202C")     // Primary text alternative
            static let navy700 = Color(hex: "2D3748")     // Secondary text
            static let navy600 = Color(hex: "4A5568")     // Muted text
            static let navy500 = Color(hex: "718096")     // Subtle accent
            static let navy400 = Color(hex: "A0AEC0")     // Light accent
            static let navy300 = Color(hex: "CBD5E0")     // Very light accent
            static let navy200 = Color(hex: "E2E8F0")     // Background tint
            static let navy100 = Color(hex: "F7FAFC")     // Subtle background
            
            // McKinsey Blue (Professional & Confident)
            static let blue700 = Color(hex: "1E40AF")     // Primary brand (deeper)
            static let blue600 = Color(hex: "2563EB")     // Primary brand
            static let blue500 = Color(hex: "3B82F6")     // Brand accent
            static let blue400 = Color(hex: "60A5FA")     // Light accent
            static let blue300 = Color(hex: "93C5FD")     // Very light
            static let blue100 = Color(hex: "DBEAFE")     // Background tint
            static let blue50 = Color(hex: "EFF6FF")      // Subtle background
            
            // Sophisticated Purple (McKinsey Secondary)
            static let purple700 = Color(hex: "6B46C1")   // Deep purple
            static let purple600 = Color(hex: "7C3AED")   // Primary purple
            static let purple500 = Color(hex: "8B5CF6")   // Purple accent
            static let purple400 = Color(hex: "A78BFA")   // Light purple
            static let purple300 = Color(hex: "C4B5FD")   // Very light
            static let purple100 = Color(hex: "EDE9FE")   // Background tint
            static let purple50 = Color(hex: "F5F3FF")    // Subtle background
            
            // Semantic Colors (Professional)
            static let green600 = Color(hex: "059669")    // Success
            static let green500 = Color(hex: "10B981")    // Success light
            static let green100 = Color(hex: "D1FAE5")    // Success background
            
            static let amber600 = Color(hex: "D97706")    // Warning
            static let amber500 = Color(hex: "F59E0B")    // Warning light
            static let amber100 = Color(hex: "FEF3C7")    // Warning background
            
            static let red600 = Color(hex: "DC2626")      // Error
            static let red500 = Color(hex: "EF4444")      // Error light
            static let red100 = Color(hex: "FEE2E2")      // Error background
        }
        
        // MARK: - Base Palette (Dark Mode) - Sophisticated Dark
        private struct Dark {
            // Rich Dark Neutrals
            static let gray900 = Color(hex: "111111")     // Primary background
            static let gray800 = Color(hex: "1F1F1F")     // Secondary background
            static let gray700 = Color(hex: "2E2E2E")     // Surface background
            static let gray600 = Color(hex: "404040")     // Border
            static let gray500 = Color(hex: "6B6B6B")     // Border light
            static let gray400 = Color(hex: "9CA3AF")     // Text muted
            static let gray300 = Color(hex: "D1D5DB")     // Text secondary
            static let gray200 = Color(hex: "E5E7EB")     // Text primary
            static let gray100 = Color(hex: "F3F4F6")     // Text emphasis
            static let gray50 = Color(hex: "F9FAFB")      // Highest contrast
            static let white = Color.white
            
            // Dark Navy Tones
            static let navy900 = Color(hex: "0F1419")     // Deep background
            static let navy800 = Color(hex: "1A1F2E")     // Surface
            static let navy700 = Color(hex: "2A3441")     // Border
            static let navy600 = Color(hex: "374151")     // Text muted
            static let navy500 = Color(hex: "6B7280")     // Text secondary
            
            // Enhanced Blues for Dark Mode
            static let blue600 = Color(hex: "2563EB")     // Primary brand
            static let blue500 = Color(hex: "3B82F6")     // Brand accent (brighter)
            static let blue400 = Color(hex: "60A5FA")     // Light accent
            static let blue300 = Color(hex: "93C5FD")     // Very light
            static let blue900 = Color(hex: "1E3A8A")     // Background
            
            // Enhanced Purples for Dark Mode
            static let purple600 = Color(hex: "7C3AED")   // Primary purple
            static let purple500 = Color(hex: "8B5CF6")   // Purple accent (brighter)
            static let purple400 = Color(hex: "A78BFA")   // Light accent
            static let purple900 = Color(hex: "581C87")   // Background
            
            // Semantic Colors (adjusted for dark)
            static let green500 = Color(hex: "10B981")    // Success
            static let green400 = Color(hex: "34D399")    // Success light
            static let green900 = Color(hex: "064E3B")    // Success background
            
            static let amber500 = Color(hex: "F59E0B")    // Warning
            static let amber400 = Color(hex: "FBBF24")    // Warning light
            static let amber900 = Color(hex: "78350F")    // Warning background
            
            static let red500 = Color(hex: "EF4444")      // Error
            static let red400 = Color(hex: "F87171")      // Error light
            static let red900 = Color(hex: "7F1D1D")      // Error background
        }
        
        // MARK: - Semantic Colors (Clean & Professional)
        
        // Text Hierarchy (High Contrast & Clean)
        static let primaryText = Color.adaptive(light: Light.gray900, dark: Dark.gray100)
        static let secondaryText = Color.adaptive(light: Light.gray700, dark: Dark.gray300)
        static let tertiaryText = Color.adaptive(light: Light.gray600, dark: Dark.gray400)
        static let placeholderText = Color.adaptive(light: Light.gray500, dark: Dark.gray500)
        static let mutedText = Color.adaptive(light: Light.gray500, dark: Dark.gray400)
        
        // Backgrounds (Clean & Minimal)
        static let background = Color.adaptive(light: Light.white, dark: Dark.gray900)
        static let secondaryBackground = Color.adaptive(light: Light.gray50, dark: Dark.gray800)
        static let tertiaryBackground = Color.adaptive(light: Light.gray100, dark: Dark.gray700)
        static let surfaceBackground = Color.adaptive(light: Light.white, dark: Dark.gray800)
        static let cardBackground = Color.adaptive(light: Light.white, dark: Dark.gray800)
        
        // Professional Brand Colors (McKinsey-Inspired)
        static let accent = Color.adaptive(light: Light.blue600, dark: Dark.blue500)
        static let accentSecondary = Color.adaptive(light: Light.blue50, dark: Dark.blue900)
        static let accentHover = Color.adaptive(light: Light.blue700, dark: Dark.blue400)
        static let accentPressed = Color.adaptive(light: Light.navy900, dark: Dark.blue600)
        
        // Sophisticated Purple Accent
        static let secondaryAccent = Color.adaptive(light: Light.purple600, dark: Dark.purple500)
        static let secondaryAccentHover = Color.adaptive(light: Light.purple700, dark: Dark.purple400)
        static let secondaryAccentBackground = Color.adaptive(light: Light.purple50, dark: Dark.purple900)
        
        // Interactive States (Subtle & Clean)
        static let hoverBackground = Color.adaptive(light: Light.gray50, dark: Dark.gray700)
        static let selectedBackground = Color.adaptive(light: Light.blue50, dark: Dark.blue900.opacity(0.3))
        static let pressedBackground = Color.adaptive(light: Light.gray100, dark: Dark.gray600)
        static let focusBackground = Color.adaptive(light: Light.blue50, dark: Dark.blue900.opacity(0.2))
        
        // Borders & Separators (Clean Lines)
        static let border = Color.adaptive(light: Light.gray200, dark: Dark.gray600)
        static let borderSecondary = Color.adaptive(light: Light.gray100, dark: Dark.gray700)
        static let borderStrong = Color.adaptive(light: Light.gray300, dark: Dark.gray500)
        static let borderFocus = accent
        static let borderError = Color.adaptive(light: Light.red600, dark: Dark.red500)
        
        // Status Colors (Professional)
        static let success = Color.adaptive(light: Light.green600, dark: Dark.green500)
        static let successBackground = Color.adaptive(light: Light.green100, dark: Dark.green900)
        static let warning = Color.adaptive(light: Light.amber600, dark: Dark.amber500)
        static let warningBackground = Color.adaptive(light: Light.amber100, dark: Dark.amber900)
        static let error = Color.adaptive(light: Light.red600, dark: Dark.red500)
        static let errorBackground = Color.adaptive(light: Light.red100, dark: Dark.red900)
        
        // Special Purpose Colors
        static let textOnAccent = Color.white
        static let textOnSecondaryAccent = Color.white
        static let overlayBackground = Color.black.opacity(0.4)
        static let glassMorphism = Color.white.opacity(0.1)
        
        // MARK: - Legacy Support (for gradual migration)
        static let primary = primaryText
        static let secondary = secondaryText
        static let info = accent
        static let infoBackground = accentSecondary
    }
    
    // MARK: - Gradient System (Clean & Sophisticated)
    struct Gradients {
        // Professional Brand Gradients
        static let brandPrimary = LinearGradient(
            colors: [Colors.accent, Colors.accent.opacity(0.8)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let brandSecondary = LinearGradient(
            colors: [Colors.secondaryAccent, Colors.accent],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        // Subtle Surface Gradients
        static let cardSurface = LinearGradient(
            colors: [
                Color.adaptive(light: .white, dark: Color(hex: "1F1F1F")),
                Color.adaptive(light: Color(hex: "FAFAFA"), dark: Color(hex: "111111"))
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        
        static let glassSurface = LinearGradient(
            colors: [
                Color.white.opacity(0.1),
                Color.white.opacity(0.05)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        
        // Status Gradients
        static let success = LinearGradient(
            colors: [Colors.success, Colors.success.opacity(0.8)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let warning = LinearGradient(
            colors: [Colors.warning, Colors.warning.opacity(0.8)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // MARK: - Enhanced Material System
    struct Materials {
        // MARK: - Primary Materials
        static let windowBackground = Material.regular
        static let sidebar = Material.bar
        static let contentBackground = Material.thin
        static let overlayBackground = Material.ultraThin
        
        // MARK: - Surface Materials
        static let cardSurface = Material.thin
        static let panelSurface = Material.regular
        static let modalSurface = Material.thick
        
        // MARK: - Interactive Materials
        static let hoverSurface = Material.ultraThin
        static let pressedSurface = Material.thin
        
        // MARK: - Legacy Color Support (for gradual migration)
        static let primarySurface = Material.thick
        static let secondarySurface = Material.regular
        static let tertiarySurface = Material.thin
        static let ultraThinSurface = Material.ultraThin
    }
    
    // MARK: - Shadow System (Subtle & Modern)
    struct Shadows {
        // MARK: - Shadow Colors
        static let subtle = Color.black.opacity(0.03)
        static let light = Color.black.opacity(0.06)
        static let medium = Color.black.opacity(0.10)
        static let strong = Color.black.opacity(0.15)
        
        // MARK: - Shadow Configurations
        static let micro = (radius: 1.0, x: 0.0, y: 0.5, opacity: 0.03)
        static let small = (radius: 2.0, x: 0.0, y: 1.0, opacity: 0.06)
        static let mediumShadow = (radius: 4.0, x: 0.0, y: 2.0, opacity: 0.10)
        static let large = (radius: 8.0, x: 0.0, y: 4.0, opacity: 0.15)
        static let floating = (radius: 12.0, x: 0.0, y: 6.0, opacity: 0.20)
        
        // MARK: - Legacy Support
        static let cardShadow = mediumShadow
        static let floatingShadow = large
        static let deepShadow = floating
    }
} 