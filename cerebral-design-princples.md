# Cerebral Design Principles

## Executive Summary
This document outlines comprehensive UI/UX improvements for Cerebral, focusing on creating a modern, sleek, and minimalistic macOS application inspired by leading contemporary applications like Linear, Notion, ChatGPT, Claude, Msty, Things, and Arc. The design follows Apple Human Interface Guidelines while incorporating the sophisticated aesthetic and interaction patterns that define premium macOS applications.

## Overall Design Philosophy

### Core Design Values
- **Clarity Over Decoration**: Every element serves a purpose, removing visual noise to focus on content
- **Spatial Intelligence**: Strategic use of whitespace to create breathing room and visual hierarchy
- **Material Sophistication**: Leverage macOS materials and vibrancy effects for depth without heaviness
- **Typographic Excellence**: Clear, readable typography that guides users naturally through information
- **Intentional Color**: Restrained color palette with purposeful accent usage
- **Responsive Elegance**: Smooth animations and transitions that feel natural and performant

### Visual Hierarchy & Layout

#### Three-Pane Architecture
- **Left Sidebar**: Document library with clean list design, subtle hover states
- **Center Panel**: Main content area (PDF viewer/chat interface) with generous margins
- **Right Panel**: Contextual tools and information with collapsible sections
- **Visual Separation**: Use `Material.thin` dividers and subtle background variations

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

#### Color Palette
```swift
// Semantic color system
struct Colors {
    // Neutrals (inspired by Linear/Notion)
    static let background = Color(.systemBackground)
    static let secondaryBackground = Color(.controlBackgroundColor)
    static let tertiaryBackground = Color(.tertiarySystemBackground)
    
    // Text hierarchy
    static let primaryText = Color(.labelColor)
    static let secondaryText = Color(.secondaryLabelColor)
    static let tertiaryText = Color(.tertiaryLabelColor)
    
    // Accent colors (inspired by Claude/ChatGPT)
    static let accent = Color(.controlAccentColor)
    static let accentSecondary = Color(.controlAccentColor).opacity(0.1)
    
    // Status colors
    static let success = Color(.systemGreen)
    static let warning = Color(.systemOrange)
    static let error = Color(.systemRed)
}
```

#### Material Usage
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
