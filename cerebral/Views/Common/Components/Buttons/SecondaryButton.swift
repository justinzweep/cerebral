//
//  SecondaryButton.swift
//  cerebral
//
//  Reusable Secondary Button Component
//

import SwiftUI

struct SecondaryButton: View {
    let title: String
    let action: () -> Void
    let isDisabled: Bool
    let isLoading: Bool
    
    init(
        _ title: String,
        isDisabled: Bool = false,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.isDisabled = isDisabled
        self.isLoading = isLoading
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignSystem.Spacing.xs) {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .progressViewStyle(CircularProgressViewStyle(tint: DesignSystem.Colors.accent))
                }
                
                Text(title)
                    .font(DesignSystem.Typography.button)
                    .foregroundColor(DesignSystem.Colors.accent)
            }
        }
        .buttonStyle(SecondaryButtonStyle())
        .disabled(isDisabled || isLoading)
    }
}

#Preview {
    VStack(spacing: 16) {
        SecondaryButton("Normal Button") { }
        SecondaryButton("Disabled Button", isDisabled: true) { }
        SecondaryButton("Loading Button", isLoading: true) { }
    }
    .padding()
} 