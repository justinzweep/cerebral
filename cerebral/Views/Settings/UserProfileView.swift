//
//  UserProfileView.swift
//  cerebral
//
//  Created by Justin Zweep on 26/06/2025.
//

import SwiftUI

struct UserProfileView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @State private var userName: String = ""
    @State private var userEmail: String = ""
    @State private var isEditing: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                Text("User Profile")
                    .font(DesignSystem.Typography.title2)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .accessibleHeading(level: .h1)
                
                Text("Manage your personal information and preferences.")
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
            
            GroupBox {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                    // User Name
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                        Text("Name")
                            .font(DesignSystem.Typography.bodyMedium)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        
                        if isEditing {
                            TextField("Enter your name", text: $userName)
                                .textFieldStyle(CerebralTextFieldStyle())
                        } else {
                            Text(userName.isEmpty ? "Not set" : userName)
                                .font(DesignSystem.Typography.body)
                                .foregroundColor(userName.isEmpty ? DesignSystem.Colors.textTertiary : DesignSystem.Colors.textPrimary)
                        }
                    }
                    
                    // User Email
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                        Text("Email")
                            .font(DesignSystem.Typography.bodyMedium)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        
                        if isEditing {
                            TextField("Enter your email", text: $userEmail)
                                .textFieldStyle(CerebralTextFieldStyle())
                        } else {
                            Text(userEmail.isEmpty ? "Not set" : userEmail)
                                .font(DesignSystem.Typography.body)
                                .foregroundColor(userEmail.isEmpty ? DesignSystem.Colors.textTertiary : DesignSystem.Colors.textPrimary)
                        }
                    }
                    
                    // Action Buttons
                    HStack {
                        if isEditing {
                            Button("Save") {
                                // Save to settings manager
                                // TODO: Implement save functionality in SettingsManager
                                isEditing = false
                            }
                            .buttonStyle(PrimaryButtonStyle())
                            
                            Button("Cancel") {
                                // Restore original values
                                // TODO: Load from settings manager
                                isEditing = false
                            }
                            .buttonStyle(SecondaryButtonStyle())
                        } else {
                            Button("Edit") {
                                isEditing = true
                            }
                            .buttonStyle(SecondaryButtonStyle())
                        }
                        
                        Spacer()
                    }
                }
                .padding(DesignSystem.Spacing.md)
            }
            
            Spacer()
        }
        .padding(DesignSystem.Spacing.lg)
        .onAppear {
            // TODO: Load user profile from settings manager
            // userName = settingsManager.userName
            // userEmail = settingsManager.userEmail
        }
    }
}

#Preview {
    UserProfileView()
        .environmentObject(SettingsManager())
        .frame(width: 500, height: 400)
} 