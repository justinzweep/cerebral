//
//  EmptyDocumentsView.swift
//  cerebral
//
//  Created by Justin Zweep on 26/06/2025.
//

import SwiftUI

struct EmptyDocumentsView: View {
    @Binding var showingImporter: Bool
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            // Image(systemName: "doc.text")
            //     .font(DesignSystem.Typography.largeTitle)
            //     .foregroundColor(DesignSystem.Colors.tertiaryText)
            
            // VStack(spacing: DesignSystem.Spacing.sm) {
            //     Text("No Documents")
            //         .font(DesignSystem.Typography.headline)
            //         .foregroundColor(DesignSystem.Colors.primaryText)
                
            //     Text("Import your first PDF to get started")
            //         .font(DesignSystem.Typography.body)
            //         .foregroundColor(DesignSystem.Colors.secondaryText)
            //         .multilineTextAlignment(.center)
            // }
            
            // Button("Import PDF") {
            //     showingImporter = true
            // }
            // .buttonStyle(PrimaryButtonStyle())
        }
        .padding(DesignSystem.Spacing.xl)
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    EmptyDocumentsView(showingImporter: .constant(false))
        .frame(width: DesignSystem.ComponentSizes.panelMaxWidth, height: DesignSystem.ComponentSizes.previewPanelHeight)
} 