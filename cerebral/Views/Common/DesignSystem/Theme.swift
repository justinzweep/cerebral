//
//  Theme.swift
//  cerebral
//
//  Modern Conversational Color System
//  Inspired by ChatGPT and Airbnb's warm, approachable design language
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

// MARK: - Modern Conversational Color System

extension DesignSystem {
    struct Colors {
        
        // MARK: - Base Palette (Light Mode) - Warm & Inviting
        private struct Light {
            // Warm Neutrals (Airbnb-inspired)
            static let white = Color.white
            static let gray50 = Color(hex: "FAFBFC")      // Soft white
            static let gray100 = Color(hex: "F4F6F8")     // Warm light gray
            static let gray200 = Color(hex: "E8EAED")     // Light border
            static let gray300 = Color(hex: "DADCE0")     // Medium border
            static let gray400 = Color(hex: "BDC1C6")     // Subtle text
            static let gray500 = Color(hex: "9AA0A6")     // Muted text
            static let gray600 = Color(hex: "80868B")     // Secondary text
            static let gray700 = Color(hex: "5F6368")     // Primary text
            static let gray800 = Color(hex: "3C4043")     // Strong text
            static let gray900 = Color(hex: "202124")     // Emphasis text
            
            // ChatGPT-inspired Blues (Conversational & Trustworthy)
            static let blue50 = Color(hex: "F0F9FF")      // Lightest blue
            static let blue100 = Color(hex: "E0F2FE")     // Very light blue
            static let blue200 = Color(hex: "BAE6FD")     // Light blue
            static let blue300 = Color(hex: "7DD3FC")     // Medium light blue
            static let blue400 = Color(hex: "38BDF8")     // Bright blue
            static let blue500 = Color(hex: "0EA5E9")     // Primary blue
            static let blue600 = Color(hex: "0284C7")     // Strong blue
            static let blue700 = Color(hex: "0369A1")     // Deep blue
            static let blue800 = Color(hex: "075985")     // Darker blue
            static let blue900 = Color(hex: "0C4A6E")     // Deepest blue
            
            // Vibrant Purples (ChatGPT & Airbnb inspired)
            static let purple50 = Color(hex: "FAF5FF")    // Lightest purple
            static let purple100 = Color(hex: "F3E8FF")   // Very light purple
            static let purple200 = Color(hex: "E9D5FF")   // Light purple
            static let purple300 = Color(hex: "D8B4FE")   // Medium light purple
            static let purple400 = Color(hex: "C084FC")   // Bright purple
            static let purple500 = Color(hex: "A855F7")   // Primary purple
            static let purple600 = Color(hex: "9333EA")   // Strong purple
            static let purple700 = Color(hex: "7C3AED")   // Deep purple
            static let purple800 = Color(hex: "6B21A8")   // Darker purple
            static let purple900 = Color(hex: "581C87")   // Deepest purple
            
            // Complementary Teals (Fresh & Modern)
            static let teal50 = Color(hex: "F0FDFA")      // Lightest teal
            static let teal100 = Color(hex: "CCFBF1")     // Very light teal
            static let teal200 = Color(hex: "99F6E4")     // Light teal
            static let teal300 = Color(hex: "5EEAD4")     // Medium teal
            static let teal400 = Color(hex: "2DD4BF")     // Bright teal
            static let teal500 = Color(hex: "14B8A6")     // Primary teal
            static let teal600 = Color(hex: "0D9488")     // Strong teal
            
            // Warm Accent Colors
            static let coral50 = Color(hex: "FFF7ED")     // Light coral
            static let coral100 = Color(hex: "FFEDD5")    // Soft coral
            static let coral400 = Color(hex: "FB923C")    // Bright coral
            static let coral500 = Color(hex: "F97316")    // Primary coral
            
            // Semantic Colors (Friendly & Clear)
            static let emerald500 = Color(hex: "10B981")   // Success
            static let emerald600 = Color(hex: "059669")   // Success strong
            static let emerald100 = Color(hex: "D1FAE5")   // Success background
            
            static let amber500 = Color(hex: "F59E0B")     // Warning
            static let amber600 = Color(hex: "D97706")     // Warning strong
            static let amber100 = Color(hex: "FEF3C7")     // Warning background
            
            static let rose500 = Color(hex: "F43F5E")      // Error
            static let rose600 = Color(hex: "E11D48")      // Error strong
            static let rose100 = Color(hex: "FFE4E6")      // Error background
        }
        
        // MARK: - Base Palette (Dark Mode) - Rich & Sophisticated
        private struct Dark {
            // Rich Dark Neutrals (Modern & Approachable)
            static let gray900 = Color(hex: "0F0F23")     // Primary background (deep blue-black)
            static let gray800 = Color(hex: "1A1A2E")     // Secondary background
            static let gray750 = Color(hex: "16213E")     // Card background
            static let gray700 = Color(hex: "2A2D47")     // Surface background
            static let gray600 = Color(hex: "3E4258")     // Border
            static let gray500 = Color(hex: "6B6D7C")     // Muted elements
            static let gray400 = Color(hex: "9B9CA6")     // Secondary text
            static let gray300 = Color(hex: "C5C6D0")     // Primary text
            static let gray200 = Color(hex: "E2E3ED")     // High contrast text
            static let gray100 = Color(hex: "F1F2F7")     // Emphasis text
            static let white = Color.white
            
            // Enhanced Blues for Dark Mode (Brighter & More Vibrant)
            static let blue900 = Color(hex: "0F1629")     // Blue background
            static let blue800 = Color(hex: "1E3A8A")     // Deep blue surface
            static let blue600 = Color(hex: "2563EB")     // Primary blue
            static let blue500 = Color(hex: "3B82F6")     // Bright blue
            static let blue400 = Color(hex: "60A5FA")     // Light blue
            static let blue300 = Color(hex: "93C5FD")     // Very light blue
            
            // Enhanced Purples for Dark Mode (Vibrant & Beautiful)
            static let purple900 = Color(hex: "1A0B2E")   // Purple background
            static let purple800 = Color(hex: "581C87")   // Deep purple surface
            static let purple600 = Color(hex: "7C3AED")   // Primary purple
            static let purple500 = Color(hex: "8B5CF6")   // Bright purple
            static let purple400 = Color(hex: "A78BFA")   // Light purple
            static let purple300 = Color(hex: "C4B5FD")   // Very light purple
            
            // Enhanced Teals for Dark Mode
            static let teal600 = Color(hex: "0D9488")     // Primary teal
            static let teal500 = Color(hex: "14B8A6")     // Bright teal
            static let teal400 = Color(hex: "2DD4BF")     // Light teal
            
            // Semantic Colors (adjusted for dark)
            static let emerald500 = Color(hex: "10B981")  // Success
            static let emerald400 = Color(hex: "34D399")  // Success light
            static let emerald900 = Color(hex: "064E3B")  // Success background
            
            static let amber500 = Color(hex: "F59E0B")    // Warning
            static let amber400 = Color(hex: "FBBF24")    // Warning light
            static let amber900 = Color(hex: "78350F")    // Warning background
            
            static let rose500 = Color(hex: "F43F5E")     // Error
            static let rose400 = Color(hex: "FB7185")     // Error light
            static let rose900 = Color(hex: "881337")     // Error background
        }
        
        // MARK: - Semantic Colors (Modern & Approachable)
        
        // Text Hierarchy (Warm & Readable)
        static let primaryText = Color.adaptive(light: Light.gray800, dark: Dark.gray200)
        static let secondaryText = Color.adaptive(light: Light.gray600, dark: Dark.gray400)
        static let tertiaryText = Color.adaptive(light: Light.gray500, dark: Dark.gray500)
        static let placeholderText = Color.adaptive(light: Light.gray400, dark: Dark.gray500)
        static let mutedText = Color.adaptive(light: Light.gray400, dark: Dark.gray400)
        
        // Backgrounds (Clean & Inviting)
        static let background = Color.adaptive(light: Light.white, dark: Dark.gray900)
        static let secondaryBackground = Color.adaptive(light: Light.gray50, dark: Dark.gray800)
        static let tertiaryBackground = Color.adaptive(light: Light.gray100, dark: Dark.gray750)
        static let surfaceBackground = Color.adaptive(light: Light.white, dark: Dark.gray750)
        static let cardBackground = Color.adaptive(light: Light.white, dark: Dark.gray750)
        
        // Brand Colors (ChatGPT & Airbnb Inspired)
        static let accent = Color.adaptive(light: Light.blue600, dark: Dark.blue500)
        static let accentSecondary = Color.adaptive(light: Light.blue50, dark: Dark.blue900)
        static let accentHover = Color.adaptive(light: Light.blue700, dark: Dark.blue400)
        static let accentPressed = Color.adaptive(light: Light.blue800, dark: Dark.blue600)
        
        // Purple Accent (Secondary Brand)
        static let secondaryAccent = Color.adaptive(light: Light.purple600, dark: Dark.purple500)
        static let secondaryAccentHover = Color.adaptive(light: Light.purple700, dark: Dark.purple400)
        static let secondaryAccentBackground = Color.adaptive(light: Light.purple50, dark: Dark.purple900)
        
        // Teal Accent (Fresh & Modern)
        static let tertiaryAccent = Color.adaptive(light: Light.teal500, dark: Dark.teal500)
        static let tertiaryAccentHover = Color.adaptive(light: Light.teal600, dark: Dark.teal400)
        static let tertiaryAccentBackground = Color.adaptive(light: Light.teal50, dark: Dark.gray700)
        
        // Interactive States (Smooth & Responsive)
        static let hoverBackground = Color.adaptive(light: Light.gray50, dark: Dark.gray700)
        static let selectedBackground = Color.adaptive(light: Light.blue50, dark: Dark.blue900.opacity(0.4))
        static let pressedBackground = Color.adaptive(light: Light.gray100, dark: Dark.gray600)
        static let focusBackground = Color.adaptive(light: Light.blue50, dark: Dark.blue900.opacity(0.3))
        
        // Borders & Separators (Subtle & Clean)
        static let border = Color.adaptive(light: Light.gray200, dark: Dark.gray600)
        static let borderSecondary = Color.adaptive(light: Light.gray100, dark: Dark.gray700)
        static let borderStrong = Color.adaptive(light: Light.gray300, dark: Dark.gray500)
        static let borderFocus = accent
        static let borderError = Color.adaptive(light: Light.rose500, dark: Dark.rose500)
        
        // Status Colors (Friendly & Clear)
        static let success = Color.adaptive(light: Light.emerald600, dark: Dark.emerald500)
        static let successBackground = Color.adaptive(light: Light.emerald100, dark: Dark.emerald900)
        static let warning = Color.adaptive(light: Light.amber600, dark: Dark.amber500)
        static let warningBackground = Color.adaptive(light: Light.amber100, dark: Dark.amber900)
        static let error = Color.adaptive(light: Light.rose600, dark: Dark.rose500)
        static let errorBackground = Color.adaptive(light: Light.rose100, dark: Dark.rose900)
        
        // Special Purpose Colors
        static let textOnAccent = Color.white
        static let textOnSecondaryAccent = Color.white
        static let overlayBackground = Color.black.opacity(0.5)
        static let glassMorphism = Color.white.opacity(0.1)
        
        // MARK: - Legacy Support (for gradual migration)
        static let primary = primaryText
        static let secondary = secondaryText
        static let info = accent
        static let infoBackground = accentSecondary
    }
    
    // MARK: - Beautiful Gradient System (ChatGPT & Airbnb Inspired)
    struct Gradients {
        // MARK: - Primary Brand Gradients (Blue to Purple Magic)
        static let oceanSunset = LinearGradient(
            colors: [
                Color.adaptive(light: Color(hex: "667eea"), dark: Color(hex: "4f46e5")),
                Color.adaptive(light: Color(hex: "764ba2"), dark: Color(hex: "7c3aed"))
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let electricBlue = LinearGradient(
            colors: [
                Color.adaptive(light: Color(hex: "0ea5e9"), dark: Color(hex: "3b82f6")),
                Color.adaptive(light: Color(hex: "3b82f6"), dark: Color(hex: "60a5fa"))
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let purpleDream = LinearGradient(
            colors: [
                Color.adaptive(light: Color(hex: "a855f7"), dark: Color(hex: "8b5cf6")),
                Color.adaptive(light: Color(hex: "7c3aed"), dark: Color(hex: "a78bfa"))
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        // MARK: - Magical Multi-Color Gradients
        static let conversational = LinearGradient(
            colors: [
                Color.adaptive(light: Color(hex: "667eea"), dark: Color(hex: "4f46e5")),
                Color.adaptive(light: Color(hex: "764ba2"), dark: Color(hex: "7c3aed")),
                Color.adaptive(light: Color(hex: "f093fb"), dark: Color(hex: "c084fc"))
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let aiAssistant = LinearGradient(
            colors: [
                Color.adaptive(light: Color(hex: "4facfe"), dark: Color(hex: "3b82f6")),
                Color.adaptive(light: Color(hex: "00f2fe"), dark: Color(hex: "06b6d4"))
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        // MARK: - Airbnb-Inspired Warm Gradients
        static let warmWelcome = LinearGradient(
            colors: [
                Color.adaptive(light: Color(hex: "fa709a"), dark: Color(hex: "ec4899")),
                Color.adaptive(light: Color(hex: "fee140"), dark: Color(hex: "f59e0b"))
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let tealMagic = LinearGradient(
            colors: [
                Color.adaptive(light: Color(hex: "21d4fd"), dark: Color(hex: "06b6d4")),
                Color.adaptive(light: Color(hex: "b721ff"), dark: Color(hex: "8b5cf6"))
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        // MARK: - Subtle Surface Gradients
        static let cardSurface = LinearGradient(
            colors: [
                Color.adaptive(light: .white, dark: Color(hex: "16213E")),
                Color.adaptive(light: Color(hex: "FAFBFC"), dark: Color(hex: "1A1A2E"))
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        
        static let glassSurface = LinearGradient(
            colors: [
                Color.white.opacity(0.15),
                Color.white.opacity(0.05)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        
        // MARK: - Status Gradients (Friendly & Clear)
        static let success = LinearGradient(
            colors: [
                Color.adaptive(light: Color(hex: "34d399"), dark: Color(hex: "10b981")),
                Color.adaptive(light: Color(hex: "059669"), dark: Color(hex: "34d399"))
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let warning = LinearGradient(
            colors: [
                Color.adaptive(light: Color(hex: "fbbf24"), dark: Color(hex: "f59e0b")),
                Color.adaptive(light: Color(hex: "d97706"), dark: Color(hex: "fbbf24"))
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let error = LinearGradient(
            colors: [
                Color.adaptive(light: Color(hex: "fb7185"), dark: Color(hex: "f43f5e")),
                Color.adaptive(light: Color(hex: "e11d48"), dark: Color(hex: "fb7185"))
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        // MARK: - Legacy Support
        static let brandPrimary = oceanSunset
        static let brandSecondary = conversational
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
        static let subtle = Color.black.opacity(0.04)
        static let light = Color.black.opacity(0.08)
        static let medium = Color.black.opacity(0.12)
        static let strong = Color.black.opacity(0.20)
        
        // MARK: - Shadow Configurations
        static let micro = (radius: 1.0, x: 0.0, y: 0.5, opacity: 0.04)
        static let small = (radius: 3.0, x: 0.0, y: 1.0, opacity: 0.08)
        static let mediumShadow = (radius: 6.0, x: 0.0, y: 3.0, opacity: 0.12)
        static let large = (radius: 12.0, x: 0.0, y: 6.0, opacity: 0.20)
        static let floating = (radius: 20.0, x: 0.0, y: 10.0, opacity: 0.25)
        
        // MARK: - Legacy Support
        static let cardShadow = mediumShadow
        static let floatingShadow = large
        static let deepShadow = floating
    }
}

// MARK: - Typography Extensions (Apple Best Practices)

extension View {
    /// Apply proper line spacing based on Apple's typography guidelines
    func appleLineSpacing(for textStyle: DesignSystem.Typography.LineHeightType = .body) -> some View {
        let baseSize: CGFloat
        switch textStyle {
        case .body:
            baseSize = DesignSystem.Typography.FontSize.body
        case .headline:
            baseSize = DesignSystem.Typography.FontSize.headline
        case .interface:
            baseSize = DesignSystem.Typography.FontSize.button
        case .compact:
            baseSize = DesignSystem.Typography.FontSize.caption
        }
        
        let spacing = DesignSystem.Typography.lineSpacing(for: baseSize, type: textStyle)
        return self.lineSpacing(spacing)
    }
    
    /// Apply accessibility-compliant font with minimum size enforcement
    func accessibleFont(_ font: Font, minimumSize: CGFloat = 11) -> some View {
        self.font(font)
    }
    
    /// Modern text style with proper Apple typography
    func appleTextStyle(_ style: AppleTextStyle) -> some View {
        Group {
            switch style {
            case .largeTitle:
                self.font(DesignSystem.Typography.largeTitle)
                    .appleLineSpacing(for: .headline)
            case .title:
                self.font(DesignSystem.Typography.title)
                    .appleLineSpacing(for: .headline)
            case .title2:
                self.font(DesignSystem.Typography.title2)
                    .appleLineSpacing(for: .headline)
            case .title3:
                self.font(DesignSystem.Typography.title3)
                    .appleLineSpacing(for: .headline)
            case .headline:
                self.font(DesignSystem.Typography.headline)
                    .appleLineSpacing(for: .headline)
            case .body:
                self.font(DesignSystem.Typography.body)
                    .appleLineSpacing(for: .body)
            case .bodySecondary:
                self.font(DesignSystem.Typography.bodySecondary)
                    .appleLineSpacing(for: .body)
            case .callout:
                self.font(DesignSystem.Typography.callout)
                    .appleLineSpacing(for: .body)
            case .subheadline:
                self.font(DesignSystem.Typography.subheadline)
                    .appleLineSpacing(for: .interface)
            case .footnote:
                self.font(DesignSystem.Typography.footnote)
                    .appleLineSpacing(for: .interface)
            case .caption:
                self.font(DesignSystem.Typography.caption)
                    .appleLineSpacing(for: .compact)
            case .caption2:
                self.font(DesignSystem.Typography.caption2)
                    .appleLineSpacing(for: .compact)
            case .button:
                self.font(DesignSystem.Typography.button)
                    .appleLineSpacing(for: .interface)
            case .menuItem:
                self.font(DesignSystem.Typography.menuItem)
                    .appleLineSpacing(for: .interface)
            case .tabBar:
                self.font(DesignSystem.Typography.tabBar)
                    .appleLineSpacing(for: .interface)
            }
        }
    }
}

enum AppleTextStyle {
    case largeTitle, title, title2, title3, headline
    case body, bodySecondary, callout, subheadline, footnote, caption, caption2
    case button, menuItem, tabBar
} 