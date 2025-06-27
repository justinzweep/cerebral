//
//  UserProfileView.swift
//  cerebral
//
//  Created by Justin Zweep on 26/06/2025.
//

import SwiftUI

struct UserProfileView: View {
    @Environment(SettingsManager.self) var settingsManager: SettingsManager
    @AppStorage("userName") private var userName: String = ""
    @State private var tempUserName: String = ""
    @State private var isEditingName: Bool = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                // Header
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    Text("User Profile")
                        .font(DesignSystem.Typography.headline)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                    
                    Text("Manage your user profile and preferences.")
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
                
                // Profile Information
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                    Text("Profile Information")
                        .font(DesignSystem.Typography.body)
                        .fontWeight(.medium)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                    
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                        HStack {
                            Text("Display Name")
                                .font(DesignSystem.Typography.body)
                                .foregroundColor(DesignSystem.Colors.primaryText)
                            
                            Spacer()
                        }
                        
                        if isEditingName {
                            TextField("Enter your name", text: $tempUserName)
                                .textFieldStyle(.roundedBorder)
                            
                            HStack {
                                Button("Save") {
                                    userName = tempUserName
                                    isEditingName = false
                                }
                                .disabled(tempUserName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                                
                                Button("Cancel") {
                                    tempUserName = userName
                                    isEditingName = false
                                }
                            }
                        } else {
                            HStack {
                                Text(userName.isEmpty ? "No name set" : userName)
                                    .foregroundColor(userName.isEmpty ? DesignSystem.Colors.secondaryText : DesignSystem.Colors.primaryText)
                                
                                Spacer()
                                
                                Button(userName.isEmpty ? "Add" : "Edit") {
                                    tempUserName = userName
                                    isEditingName = true
                                }
                            }
                        }
                    }
                }
                .padding(DesignSystem.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                        .fill(DesignSystem.Colors.secondaryBackground)
                )
                
                // API Status
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                    Text("API Status")
                        .font(DesignSystem.Typography.body)
                        .fontWeight(.medium)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Claude API")
                                .font(DesignSystem.Typography.body)
                                .foregroundColor(DesignSystem.Colors.primaryText)
                            
                            Text(settingsManager.isAPIKeyValid ? "Connected" : "Not configured")
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(settingsManager.isAPIKeyValid ? DesignSystem.Colors.success : DesignSystem.Colors.error)
                        }
                        
                        Spacer()
                        
                        if settingsManager.isAPIKeyValid {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(DesignSystem.Colors.success)
                        } else {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundColor(DesignSystem.Colors.error)
                        }
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
        .onAppear {
            tempUserName = userName
        }
    }
}

#Preview {
    UserProfileView()
        .environment(SettingsManager())
} 