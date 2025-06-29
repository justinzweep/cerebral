# Cerebral Design Principles

## Executive Summary
This document outlines comprehensive UI/UX improvements for Cerebral, focusing on creating a modern, conversational, and approachable macOS application inspired by leading contemporary applications like ChatGPT, Airbnb, Linear, Notion, Claude, Msty, Things, and Arc. The design follows Apple Human Interface Guidelines while incorporating the warm, human-centered aesthetic and interaction patterns that define premium consumer-focused applications.

## Overall Design Philosophy

### Core Design Values
- **Human-Centered Simplicity**: Every element feels approachable and intuitive, prioritizing user comfort over complexity
- **Conversational Flow**: Interface elements guide users through natural, dialogue-like interactions
- **Warm Minimalism**: Clean design with subtle warmth through rounded corners, gentle shadows, and inviting colors
- **Contextual Intelligence**: Smart, adaptive interfaces that anticipate user needs and provide helpful suggestions
- **Trustworthy Transparency**: Clear visual feedback and honest communication about system status and capabilities
- **Delightful Interactions**: Thoughtful micro-interactions and animations that feel responsive and engaging

### Visual Hierarchy & Layout

#### Three-Pane Architecture
- **Left Sidebar**: Document library with card-based design, warm hover states, and friendly iconography
- **Center Panel**: Conversational interface, generous padding, and comfortable reading zones
- **Right Panel**: Contextual assistance with helpful tips, document insights, and smart suggestions
- **Visual Separation**: Use soft shadows, subtle borders, and gentle background tints for natural content separation

#### Spacing System
```swift
// Consistent spacing scale
enum Spacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}
```

#### Grid & Alignment
- **8pt grid system** for consistent spacing and alignment
- **Content max-width**: 800px for optimal reading experience
- **Responsive breakpoints** for different window sizes
- **Optical alignment** over mathematical centering for visual balance

### Typography & Content

#### Type Scale
```swift
// Following SF Pro Display/Text guidelines
.largeTitle      // 34pt - Page headers
.title          // 28pt - Section headers  
.title2         // 22pt - Subsection headers
.title3         // 20pt - Card headers
.headline       // 17pt - Emphasized body text
.body           // 17pt - Primary body text
.callout        // 16pt - Secondary text
.subheadline    // 15pt - Metadata
.footnote       // 13pt - Fine print
.caption        // 12pt - Labels
```

#### Content Strategy
- **Scannable content** with clear headings and bullet points
- **Progressive disclosure** - show essential information first
- **Contextual help** integrated inline rather than separate help sections
- **Smart defaults** that reduce cognitive load

### Color & Materials

#### Color Philosophy
**Clean Professional Minimalism**: Inspired by McKinsey & Company's sophisticated design language, our color system prioritizes clarity, cleanliness, and professional elegance. We use mostly whites and light grays with carefully chosen blue and purple accents that convey intelligence and trustworthiness.

**Key Principles:**
- **Clean Foundation**: Pure whites and light grays create a clean, uncluttered foundation
- **Sophisticated Accents**: McKinsey-inspired blue and purple colors used sparingly for maximum impact
- **High Contrast**: Clear distinction between text and backgrounds for optimal readability
- **Professional Restraint**: Minimal color usage that lets content take center stage

#### Primary Color Palette
```swift
// Clean Professional Color System
struct Colors {
    // MARK: - Base Neutrals (Clean & Minimal)
    static let white = Color.white                // Pure white primary background
    static let gray50 = Color(hex: "FAFAFA")      // Subtle background
    static let gray100 = Color(hex: "F5F5F5")     // Light background
    static let gray200 = Color(hex: "EEEEEE")     // Border light
    static let gray300 = Color(hex: "E0E0E0")     // Border
    static let gray500 = Color(hex: "9E9E9E")     // Text muted
    static let gray600 = Color(hex: "757575")     // Text secondary
    static let gray700 = Color(hex: "616161")     // Text primary
    static let gray900 = Color(hex: "212121")     // Text emphasis
    
    // MARK: - McKinsey Blue (Professional & Confident)
    static let blue700 = Color(hex: "1E40AF")     // Primary brand (deeper)
    static let blue600 = Color(hex: "2563EB")     // Primary brand
    static let blue500 = Color(hex: "3B82F6")     // Brand accent
    static let blue100 = Color(hex: "DBEAFE")     // Background tint
    static let blue50 = Color(hex: "EFF6FF")      // Subtle background
    
    // MARK: - Sophisticated Purple (McKinsey Secondary)
    static let purple700 = Color(hex: "6B46C1")   // Deep purple
    static let purple600 = Color(hex: "7C3AED")   // Primary purple
    static let purple500 = Color(hex: "8B5CF6")   // Purple accent
    static let purple100 = Color(hex: "EDE9FE")   // Background tint
    static let purple50 = Color(hex: "F5F3FF")    // Subtle background
    
    // MARK: - Semantic Colors (Professional Status)
    static let green600 = Color(hex: "059669")    // Success primary
    static let green500 = Color(hex: "10B981")    // Success light
    static let green100 = Color(hex: "D1FAE5")    // Success background
    
    static let amber600 = Color(hex: "D97706")    // Warning primary
    static let amber500 = Color(hex: "F59E0B")    // Warning light
    static let amber100 = Color(hex: "FEF3C7")    // Warning background
    
    static let red600 = Color(hex: "DC2626")      // Error primary
    static let red500 = Color(hex: "EF4444")      // Error light
    static let red100 = Color(hex: "FEE2E2")      // Error background
    
    static let indigo600 = Color(hex: "4F46E5")   // Info primary
    static let indigo500 = Color(hex: "6366F1")   // Info light
    static let indigo100 = Color(hex: "E0E7FF")   // Info background
}
```

#### Dark Mode Palette
```swift
// Dark Mode Professional Colors
struct DarkColors {
    // MARK: - Base Neutrals (Rich Darks)
    static let slate900 = Color(hex: "0F172A")    // Primary background
    static let slate800 = Color(hex: "1E293B")    // Secondary background
    static let slate700 = Color(hex: "334155")    // Tertiary background
    static let slate600 = Color(hex: "475569")    // Surface background
    static let slate500 = Color(hex: "64748B")    // Border/divider
    static let slate400 = Color(hex: "94A3B8")    // Muted text
    static let slate300 = Color(hex: "CBD5E1")    // Secondary text
    static let slate200 = Color(hex: "E2E8F0")    // Primary text
    static let slate100 = Color(hex: "F1F5F9")    // High contrast text
    
    // MARK: - Enhanced Accents for Dark Mode
    static let blue500 = Color(hex: "3B82F6")     // Primary brand (brighter)
    static let blue400 = Color(hex: "60A5FA")     // Hover state
    static let blue600 = Color(hex: "2563EB")     // Pressed state
    
    // Semantic colors remain largely the same but slightly adjusted for dark backgrounds
}
```

#### Semantic Color System
```swift
// Semantic Usage
struct SemanticColors {
    // MARK: - Text Hierarchy
    static let primaryText = Color.adaptive(light: .slate900, dark: .slate100)
    static let secondaryText = Color.adaptive(light: .slate700, dark: .slate300)
    static let tertiaryText = Color.adaptive(light: .slate500, dark: .slate400)
    static let placeholderText = Color.adaptive(light: .slate400, dark: .slate500)
    
    // MARK: - Backgrounds
    static let primaryBackground = Color.adaptive(light: .slate50, dark: .slate900)
    static let secondaryBackground = Color.adaptive(light: .slate100, dark: .slate800)
    static let tertiaryBackground = Color.adaptive(light: .slate200, dark: .slate700)
    static let surfaceBackground = Color.adaptive(light: .white, dark: .slate800)
    
    // MARK: - Interactive Elements
    static let accent = Color.adaptive(light: .blue600, dark: .blue500)
    static let accentHover = Color.adaptive(light: .blue700, dark: .blue400)
    static let accentPressed = Color.adaptive(light: .blue800, dark: .blue600)
    static let accentSubtle = Color.adaptive(light: .blue50, dark: .blue900.opacity(0.3))
    
    // MARK: - Borders & Separators
    static let border = Color.adaptive(light: .slate300, dark: .slate600)
    static let borderSubtle = Color.adaptive(light: .slate200, dark: .slate700)
    static let borderFocus = accent
    
    // MARK: - Status Colors
    static let success = Color.adaptive(light: .green600, dark: .green500)
    static let warning = Color.adaptive(light: .amber600, dark: .amber500)
    static let error = Color.adaptive(light: .red600, dark: .red500)
    static let info = Color.adaptive(light: .indigo600, dark: .indigo500)
}
```

#### Gradient System
```swift
// Professional Gradients for Visual Interest
struct Gradients {
    // MARK: - Brand Gradients
    static let brandPrimary = LinearGradient(
        colors: [.blue600, .blue500],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let brandSecondary = LinearGradient(
        colors: [.purple600, .blue600],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // MARK: - Surface Gradients (Subtle Depth)
    static let cardSurface = LinearGradient(
        colors: [.white, .slate50],
        startPoint: .top,
        endPoint: .bottom
    )
    
    static let glassSurface = LinearGradient(
        colors: [.white.opacity(0.8), .white.opacity(0.4)],
        startPoint: .top,
        endPoint: .bottom
    )
    
    // MARK: - Status Gradients
    static let success = LinearGradient(
        colors: [.green500, .green600],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let warning = LinearGradient(
        colors: [.amber500, .amber600],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}
```

#### Color Usage Guidelines

**Primary Actions**: Use `blue600` for primary buttons, links, and key interactive elements
**Secondary Actions**: Use `purple600` for secondary brand actions and creative features
**Tertiary Actions**: Use `gray600` with subtle backgrounds for supporting actions
**Destructive Actions**: Use `red600` for delete, remove, or destructive operations
**Success States**: Use `green600` for confirmations, completed states
**Warning States**: Use `amber600` for caution, temporary states

**Text Hierarchy**:
- Headers: `gray900` (light) / `gray100` (dark) - High contrast for maximum readability
- Body text: `gray700` (light) / `gray300` (dark) - Primary reading text
- Secondary text: `gray600` (light) / `gray400` (dark) - Supporting information
- Muted text: `gray500` both modes - Placeholder and metadata

**Backgrounds**:
- Primary: `white` (light) / `gray900` (dark) - Clean, pure foundation
- Secondary: `gray50` (light) / `gray800` (dark) - Subtle background variation
- Cards/Panels: `white` (light) / `gray800` (dark) - Elevated surfaces
- Hover states: `gray50` (light) / `gray700` (dark) - Minimal, clean interactions

### Material Usage
- **Window backgrounds**: `Material.regular` for depth
- **Sidebar**: `Material.sidebar` for native feel
- **Cards/panels**: `Material.thin` for subtle elevation
- **Overlays**: `Material.ultraThin` for focus without obstruction

### Component Design

#### Cards & Containers
- **Rounded corners**: 8-12px radius for modern feel
- **Subtle shadows**: Use materials instead of heavy drop shadows
- **Hover states**: Gentle scale (1.02x) and material changes
- **Content padding**: Minimum 16px, 24px for comfort

#### Interactive Elements

##### Buttons
```swift
// Primary button (inspired by Linear's clean style)
.buttonStyle(.borderedProminent)
.controlSize(.large)
.cornerRadius(8)

// Secondary button
.buttonStyle(.bordered)
.foregroundColor(.secondary)
```

##### Input Fields
- **Clean borders**: 1px subtle border with focus states
- **Generous padding**: 12px vertical, 16px horizontal
- **Placeholder text**: Helpful, not redundant
- **Clear affordances**: Obvious interactive states

#### Navigation & Structure

##### Sidebar Design (inspired by Things/Arc)
- **Section headers**: Small caps, letter-spaced for elegance
- **List items**: Clean rows with proper touch targets (44pt minimum)
- **Icons**: SF Symbols with consistent sizing (16-20pt)
- **Badges**: Rounded, subtle background colors

##### Content Areas
- **Reading width**: Optimal line length (45-75 characters)
- **Paragraph spacing**: 1.5x line height for readability
- **Code blocks**: Subtle background, syntax highlighting
- **Images**: Rounded corners, proper aspect ratios

### Animation & Interaction

#### Motion Principles
- **Meaningful motion**: Animations guide attention and provide feedback
- **Performance first**: 60fps smooth animations using SwiftUI's native capabilities
- **Reduced motion**: Respect accessibility preferences
- **Spatial awareness**: Elements move logically in 3D space

#### Transition Patterns
```swift
// Smooth page transitions
.transition(.asymmetric(
    insertion: .move(edge: .trailing).combined(with: .opacity),
    removal: .move(edge: .leading).combined(with: .opacity)
))

// Gentle hover effects
.scaleEffect(isHovered ? 1.02 : 1.0)
.animation(.easeOut(duration: 0.2), value: isHovered)
```

### Accessibility & Inclusion

#### Universal Design
- **High contrast modes**: Ensure 4.5:1 contrast ratio minimum
- **Dynamic Type**: Support all text sizes gracefully
- **Keyboard navigation**: Full keyboard accessibility
- **Screen readers**: Meaningful labels and hints
- **Reduced motion**: Alternative interaction patterns

#### Progressive Enhancement
- **Core functionality first**: Works without advanced features
- **Enhanced experience**: Additional features for capable devices
- **Graceful degradation**: Fallbacks for older systems

### Platform Integration

#### macOS Native Patterns
- **Menu bar integration**: Standard menu items and shortcuts
- **Toolbar design**: Native controls with proper spacing
- **Window management**: Proper restoration and state saving
- **Drag & drop**: System-level integration for file handling
- **Contextual menus**: Right-click functionality throughout

#### SwiftUI Best Practices
- **State management**: Clean, predictable data flow
- **View composition**: Small, focused, reusable components
- **Performance**: Lazy loading and efficient view updates
- **Testing**: Accessible UI elements for automated testing

### Content Strategy

#### Information Architecture
- **Progressive disclosure**: Surface most important information first
- **Contextual relevance**: Show information when and where it's needed
- **Search & discovery**: Quick access to all functionality
- **Personalization**: Adapt to user preferences and usage patterns

#### Microcopy & Voice
- **Conversational tone**: Friendly but professional
- **Action-oriented**: Clear calls to action
- **Error handling**: Helpful, not judgmental messaging
- **Empty states**: Encouraging and instructive

## Implementation Guidelines

### Development Workflow
1. **Design tokens first**: Establish spacing, colors, and typography
2. **Component library**: Build reusable components
3. **Dark mode**: Design with both light and dark themes
4. **Responsive testing**: Test across different window sizes
5. **Accessibility audit**: Regular testing with assistive technologies

### Performance Considerations
- **Smooth scrolling**: Optimize list performance with lazy loading
- **Image optimization**: Proper sizing and caching
- **Animation performance**: Use transform properties for smooth motion
- **Memory management**: Efficient view lifecycle management

This design system creates a cohesive, modern experience that feels both familiar to macOS users and innovative in its approach to PDF annotation and AI assistance.
