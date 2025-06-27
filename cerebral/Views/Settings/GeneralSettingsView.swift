//
//  GeneralSettingsView.swift
//  cerebral
//
//  Created by Justin Zweep on 26/06/2025.
//

import SwiftUI

struct GeneralSettingsView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @AppStorage("showWelcomeScreen") private var showWelcomeScreen = true
    @AppStorage("enableNotifications") private var enableNotifications = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                Text("General Settings")
                    .font(DesignSystem.Typography.title2)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Text("Configure general application behavior and preferences.")
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
            
            GroupBox("Startup") {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    Toggle("Launch Cerebral at login", isOn: $launchAtLogin)
                        .toggleStyle(SwitchToggleStyle())
                    
                    Toggle("Show welcome screen on startup", isOn: $showWelcomeScreen)
                        .toggleStyle(SwitchToggleStyle())
                }
                .padding(DesignSystem.Spacing.md)
            }
            
            GroupBox("Interface") {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    Toggle("Enable notifications", isOn: $enableNotifications)
                        .toggleStyle(SwitchToggleStyle())
                }
                .padding(DesignSystem.Spacing.md)
            }
            
            GroupBox("About") {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    HStack {
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                            Text("Cerebral")
                                .font(DesignSystem.Typography.title3)
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                            
                            Text("AI-powered PDF reader and chat assistant")
                                .font(DesignSystem.Typography.body)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                            
                            Text("Version 1.0.0")
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(DesignSystem.Colors.textTertiary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 40))
                            .foregroundColor(DesignSystem.Colors.accent)
                    }
                }
                .padding(DesignSystem.Spacing.md)
            }
            
            Spacer()
        }
        .padding(DesignSystem.Spacing.lg)
    }
}

#Preview {
    GeneralSettingsView()
        .environmentObject(SettingsManager())
        .frame(width: 500, height: 400)
}

//
//  PreferencesTabView.swift
//  cerebral
//
//  Created by Justin Zweep on 26/06/2025.
//

import SwiftUI

struct PreferencesTabView: View {
    var body: some View {
        VStack {
            // Empty preferences view
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    PreferencesTabView()
        .frame(width: 500, height: 400)
} 