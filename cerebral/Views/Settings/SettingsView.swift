//
//  SettingsView.swift
//  cerebral
//
//  Created by Justin Zweep on 26/06/2025.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab: SettingsTab = .apiKey
    
    enum SettingsTab: String, CaseIterable, Identifiable {
        case apiKey = "API Key"
        
        var id: String { rawValue }
        
        var icon: String {
            switch self {
            case .apiKey: return "key.fill"
            }
        }
        
        var description: String {
            switch self {
            case .apiKey: return "Configure Claude API integration"
            }
        }
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // Left Sidebar Navigation
            VStack(alignment: .leading, spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text("Settings")
                        .font(DesignSystem.Typography.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                    
                    Text("Configure Cerebral")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.tertiaryText)
                }
                .padding(.horizontal, DesignSystem.Spacing.lg)
                .padding(.top, DesignSystem.Spacing.xl)
                .padding(.bottom, DesignSystem.Spacing.lg)
                
                // Navigation List
                ScrollView {
                    LazyVStack(spacing: DesignSystem.Spacing.xxxs) {
                        ForEach(SettingsTab.allCases) { tab in
                            SettingsTabRow(
                                tab: tab,
                                isSelected: selectedTab == tab,
                                onSelect: { selectedTab = tab }
                            )
                        }
                    }
                    .padding(.horizontal, DesignSystem.Spacing.md)
                }
                
                Spacer()
                
                // Footer Actions
                VStack(spacing: DesignSystem.Spacing.sm) {
                    Divider()
                        .foregroundColor(DesignSystem.Colors.borderSecondary)
                    
                    HStack {
                        Button {
                            dismiss()
                        } label: {
                            HStack(spacing: DesignSystem.Spacing.xs) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(DesignSystem.Typography.caption)
                                Text("Close")
                                    .font(DesignSystem.Typography.caption)
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                        }
                        .buttonStyle(TertiaryButtonStyle())
                        
                        Spacer()
                    }
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    .padding(.bottom, DesignSystem.Spacing.lg)
                }
            }
            .frame(width: DesignSystem.ComponentSizes.settingsSidebarWidth)
            .background(DesignSystem.Colors.secondaryBackground)
            
            // Divider
            Rectangle()
                .fill(DesignSystem.Colors.border)
                .frame(width: DesignSystem.ComponentSizes.dividerWidth)
            
            // Right Content Area
            Group {
                switch selectedTab {
                case .apiKey:
                    APIKeySettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(DesignSystem.Colors.background)
        }
        .frame(width: DesignSystem.ComponentSizes.settingsWindowWidth, height: DesignSystem.ComponentSizes.settingsWindowHeight)
        .background(DesignSystem.Colors.background)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl))
    }
}

// MARK: - Settings Tab Row Component

struct SettingsTabRow: View {
    let tab: SettingsView.SettingsTab
    let isSelected: Bool
    let onSelect: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: DesignSystem.Spacing.sm) {
                Image(systemName: tab.icon)
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(iconColor)
                    .frame(width: DesignSystem.ComponentSizes.standardIconFrame.width, height: DesignSystem.ComponentSizes.standardIconFrame.height)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(tab.rawValue)
                        .font(DesignSystem.Typography.body)
                        .fontWeight(isSelected ? .medium : .regular)
                        .foregroundColor(textColor)
                    
                    Text(tab.description)
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.tertiaryText)
                        .lineLimit(1)
                }
                
                Spacer()
                
                if isSelected {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(DesignSystem.Colors.accent)
                        .frame(width: DesignSystem.ComponentSizes.statusIndicator, height: DesignSystem.ComponentSizes.iconXL)
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.vertical, DesignSystem.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                    .fill(backgroundColor)
            )
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .animation(DesignSystem.Animation.micro, value: isHovered)
        .animation(DesignSystem.Animation.micro, value: isSelected)
    }
    
    private var backgroundColor: Color {
        if isSelected {
            return DesignSystem.Colors.selectedBackground
        } else if isHovered {
            return DesignSystem.Colors.hoverBackground
        } else {
            return Color.clear
        }
    }
    
    private var textColor: Color {
        isSelected ? DesignSystem.Colors.accent : DesignSystem.Colors.primaryText
    }
    
    private var iconColor: Color {
        isSelected ? DesignSystem.Colors.accent : DesignSystem.Colors.secondaryText
    }
}

// MARK: - Reusable Settings Content Layout

struct SettingsContentView<Content: View>: View {
    let title: String
    let subtitle: String
    let icon: String
    @ViewBuilder let content: Content
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xl) {
                // Header
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    HStack(spacing: DesignSystem.Spacing.md) {
                        Image(systemName: icon)
                            .font(DesignSystem.Typography.title3)
                            .foregroundColor(DesignSystem.Colors.accent)
                            .frame(width: DesignSystem.ComponentSizes.largeIconFrame.width, height: DesignSystem.ComponentSizes.largeIconFrame.height)
                            .background(
                                Circle()
                                    .fill(DesignSystem.Colors.accentSecondary)
                            )
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(title)
                                .font(DesignSystem.Typography.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(DesignSystem.Colors.primaryText)
                            
                            Text(subtitle)
                                .font(DesignSystem.Typography.body)
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                        }
                        
                        Spacer()
                    }
                }
                .padding(.top, DesignSystem.Spacing.xl)
                
                // Content
                content
                
                Spacer(minLength: DesignSystem.Spacing.xl)
            }
            .padding(.horizontal, DesignSystem.Spacing.xl)
        }
        .background(DesignSystem.Colors.background)
    }
}

// MARK: - Settings Section Component

struct SettingsSection<Content: View>: View {
    let title: String
    let subtitle: String?
    @ViewBuilder let content: Content
    
    init(title: String, subtitle: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text(title)
                    .font(DesignSystem.Typography.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
            }
            
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                content
            }
            .padding(DesignSystem.Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                    .fill(DesignSystem.Colors.cardBackground)
                    .stroke(DesignSystem.Colors.borderSecondary, lineWidth: 0.5)
            )
        }
    }
}

#Preview {
    SettingsView()
        .environment(SettingsManager.shared)
}
