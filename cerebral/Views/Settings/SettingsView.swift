//
//  SettingsView.swift
//  cerebral
//
//  Created by Justin Zweep on 26/06/2025.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab: SettingsTab = .general
    
    enum SettingsTab: String, CaseIterable {
        case general = "General"
        case apiKey = "API Key"
        case userProfile = "Profile"
        
        var icon: String {
            switch self {
            case .general: return "gearshape"
            case .apiKey: return "key"
            case .userProfile: return "person"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Settings")
                    .font(DesignSystem.Typography.title2)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                
                Spacer()
                
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(DesignSystem.Typography.button)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
                .buttonStyle(.plain)
                .frame(width: 24, height: 24)
            }
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .padding(.top, DesignSystem.Spacing.lg)
            .padding(.bottom, DesignSystem.Spacing.md)
            
            // Tab Navigation
            HStack(spacing: 0) {
                ForEach(SettingsTab.allCases, id: \.self) { tab in
                    Button {
                        selectedTab = tab
                    } label: {
                        HStack(spacing: DesignSystem.Spacing.xs) {
                            Image(systemName: tab.icon)
                                .font(DesignSystem.Typography.caption)
                            
                            Text(tab.rawValue)
                                .font(DesignSystem.Typography.caption)
                        }
                        .foregroundColor(selectedTab == tab ? 
                                       DesignSystem.Colors.accent : 
                                       DesignSystem.Colors.secondaryText)
                        .padding(.horizontal, DesignSystem.Spacing.sm)
                        .padding(.vertical, DesignSystem.Spacing.xs)
                        .background(
                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                                .fill(selectedTab == tab ? 
                                      DesignSystem.Colors.accent.opacity(0.1) : 
                                      Color.clear)
                        )
                    }
                    .buttonStyle(.plain)
                    .animation(DesignSystem.Animation.micro, value: selectedTab)
                }
                
                Spacer()
            }
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .padding(.bottom, DesignSystem.Spacing.md)
            
            Divider()
                .foregroundColor(DesignSystem.Colors.border)
            
            // Content
            Group {
                switch selectedTab {
                case .general:
                    GeneralSettingsView()
                case .apiKey:
                    APIKeySettingsView()
                case .userProfile:
                    UserProfileView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: 600, height: 500)
        .background(DesignSystem.Colors.background)
    }
}
