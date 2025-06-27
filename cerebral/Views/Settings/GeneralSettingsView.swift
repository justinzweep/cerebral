// //
// //  GeneralSettingsView.swift
// //  cerebral
// //
// //  Created by Justin Zweep on 26/06/2025.
// //

// import SwiftUI

// struct GeneralSettingsView: View {
//     @EnvironmentObject var settingsManager: SettingsManager
//     @AppStorage("launchAtLogin") private var launchAtLogin = false
//     @AppStorage("showWelcomeScreen") private var showWelcomeScreen = true
//     @AppStorage("enableNotifications") private var enableNotifications = true
    
//     var body: some View {
//         VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
//             VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
//                 Text("General Settings")
//                     .font(DesignSystem.Typography.title2)
//                     .foregroundColor(DesignSystem.Colors.primaryText)
                
//                 Text("Configure general application behavior and preferences.")
//                     .font(DesignSystem.Typography.body)
//                     .foregroundColor(DesignSystem.Colors.secondaryText)
//             }
            
//             GroupBox("Startup") {
//                 VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
//                     Toggle("Launch Cerebral at login", isOn: $launchAtLogin)
//                         .toggleStyle(SwitchToggleStyle())
                    
//                     Toggle("Show welcome screen on startup", isOn: $showWelcomeScreen)
//                         .toggleStyle(SwitchToggleStyle())
//                 }
//                 .padding(DesignSystem.Spacing.md)
//             }
            
//             GroupBox("Interface") {
//                 VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
//                     Toggle("Enable notifications", isOn: $enableNotifications)
//                         .toggleStyle(SwitchToggleStyle())
//                 }
//                 .padding(DesignSystem.Spacing.md)
//             }
            
//             GroupBox("About") {
//                 VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
//                     HStack {
//                         VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
//                             Text("Cerebral")
//                                 .font(DesignSystem.Typography.title3)
//                                 .foregroundColor(DesignSystem.Colors.primaryText)
                            
//                             Text("AI-powered PDF reader and chat assistant")
//                                 .font(DesignSystem.Typography.body)
//                                 .foregroundColor(DesignSystem.Colors.secondaryText)
                            
//                             Text("Version 1.0.0")
//                                 .font(DesignSystem.Typography.caption)
//                                 .foregroundColor(DesignSystem.Colors.tertiaryText)
//                         }
                        
//                         Spacer()
                        
//                         Image(systemName: "brain.head.profile")
//                             .font(.system(size: 40))
//                             .foregroundColor(DesignSystem.Colors.accent)
//                     }
//                 }
//                 .padding(DesignSystem.Spacing.md)
//             }
            
//             Spacer()
//         }
//         .padding(DesignSystem.Spacing.lg)
//     }
// }

// #Preview {
//     GeneralSettingsView()
//         .environmentObject(SettingsManager())
//         .frame(width: 500, height: 400)
// }

// //
// //  PreferencesTabView.swift
// //  cerebral
// //
// //  Created by Justin Zweep on 26/06/2025.
// //

// import SwiftUI

// struct PreferencesTabView: View {
//     var body: some View {
//         VStack {
//             // Empty preferences view
//         }
//         .frame(maxWidth: .infinity, maxHeight: .infinity)
//     }
// }

// #Preview {
//     PreferencesTabView()
//         .frame(width: 500, height: 400)
// }

//
//  GeneralSettingsView.swift
//  cerebral
//
//  Created by Justin Zweep on 26/06/2025.
//

import SwiftUI

struct GeneralSettingsView: View {
    @Environment(SettingsManager.self) var settingsManager: SettingsManager
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @AppStorage("showWelcomeScreen") private var showWelcomeScreen = true
    @AppStorage("enableNotifications") private var enableNotifications = true
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    Text("General Settings")
                        .font(DesignSystem.Typography.headline)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                    
                    Text("Configure general application behavior and preferences.")
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
                
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                    Text("Startup")
                        .font(DesignSystem.Typography.body)
                        .fontWeight(.medium)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                    
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                        Toggle("Launch Cerebral at login", isOn: $launchAtLogin)
                            .toggleStyle(.switch)
                        
                        Toggle("Show welcome screen on startup", isOn: $showWelcomeScreen)
                            .toggleStyle(.switch)
                    }
                }
                .padding(DesignSystem.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                        .fill(DesignSystem.Colors.secondaryBackground)
                )
                
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                    Text("Interface")
                        .font(DesignSystem.Typography.body)
                        .fontWeight(.medium)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                    
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                        Toggle("Enable notifications", isOn: $enableNotifications)
                            .toggleStyle(.switch)
                    }
                }
                .padding(DesignSystem.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                        .fill(DesignSystem.Colors.secondaryBackground)
                )
                
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                    Text("About")
                        .font(DesignSystem.Typography.body)
                        .fontWeight(.medium)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                    
                    HStack {
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                            Text("Cerebral")
                                .font(DesignSystem.Typography.title3)
                                .foregroundColor(DesignSystem.Colors.primaryText)
                            
                            Text("AI-powered PDF reader and chat assistant")
                                .font(DesignSystem.Typography.body)
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                            
                            Text("Version 1.0.0")
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(DesignSystem.Colors.tertiaryText)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 40))
                            .foregroundColor(DesignSystem.Colors.accent)
                    }
                }
                .padding(DesignSystem.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                        .fill(DesignSystem.Colors.secondaryBackground)
                )
                
                Spacer()
            }
            .padding(DesignSystem.Spacing.lg)
        }
    }
}

#Preview {
    GeneralSettingsView()
        .environment(SettingsManager())
} 