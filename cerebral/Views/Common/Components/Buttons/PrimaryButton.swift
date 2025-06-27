//
//  PrimaryButton.swift
//  cerebral
//
//  Reusable Primary Button Component
//

import SwiftUI

struct PrimaryButton: View {
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
                        .progressViewStyle(CircularProgressViewStyle(tint: DesignSystem.Colors.textOnAccent))
                }
                
                Text(title)
                    .font(DesignSystem.Typography.button)
                    .foregroundColor(DesignSystem.Colors.textOnAccent)
            }
        }
        .buttonStyle(PrimaryButtonStyle())
        .disabled(isDisabled || isLoading)
    }
}

#Preview {
    VStack(spacing: 16) {
        PrimaryButton("Normal Button") { }
        PrimaryButton("Disabled Button", isDisabled: true) { }
        PrimaryButton("Loading Button", isLoading: true) { }
    }
    .padding()
} 