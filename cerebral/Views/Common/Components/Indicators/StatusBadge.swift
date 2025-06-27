//
//  StatusBadge.swift
//  cerebral
//
//  Reusable Status Badge Component
//

import SwiftUI

struct StatusBadge: View {
    let status: BadgeStatus
    let showIcon: Bool
    let showText: Bool
    
    enum BadgeStatus {
        case online, offline, loading, error, warning, success
        
        var color: Color {
            switch self {
            case .online, .success: return DesignSystem.Colors.success
            case .offline: return DesignSystem.Colors.secondaryText
            case .loading: return DesignSystem.Colors.accent
            case .error: return DesignSystem.Colors.error
            case .warning: return DesignSystem.Colors.warning
            }
        }
        
        var icon: String {
            switch self {
            case .online: return "circle.fill"
            case .offline: return "circle"
            case .loading: return "arrow.clockwise"
            case .error: return "exclamationmark.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .success: return "checkmark.circle.fill"
            }
        }
        
        var text: String {
            switch self {
            case .online: return "Online"
            case .offline: return "Offline"
            case .loading: return "Loading"
            case .error: return "Error"
            case .warning: return "Warning"
            case .success: return "Success"
            }
        }
    }
    
    init(_ status: BadgeStatus, showIcon: Bool = true, showText: Bool = false) {
        self.status = status
        self.showIcon = showIcon
        self.showText = showText
    }
    
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.xxs) {
            if showIcon {
                Image(systemName: status.icon)
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundColor(status.color)
                    .rotationEffect(.degrees(status == .loading && isAnimating ? 360 : 0))
                    .animation(
                        status == .loading ? 
                        .linear(duration: 1).repeatForever(autoreverses: false) : 
                        .default,
                        value: isAnimating
                    )
            }
            
            if showText {
                Text(status.text)
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(status.color)
            }
        }
        .onAppear {
            if status == .loading {
                isAnimating = true
            }
        }
        .onChange(of: status) { _, newStatus in
            isAnimating = newStatus == .loading
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        // Icon only
        HStack(spacing: 16) {
            StatusBadge(.online)
            StatusBadge(.offline)
            StatusBadge(.loading)
            StatusBadge(.error)
            StatusBadge(.warning)
            StatusBadge(.success)
        }
        
        // With text
        VStack(alignment: .leading, spacing: 8) {
            StatusBadge(.online, showText: true)
            StatusBadge(.offline, showText: true)
            StatusBadge(.loading, showText: true)
            StatusBadge(.error, showText: true)
            StatusBadge(.warning, showText: true)
            StatusBadge(.success, showText: true)
        }
    }
    .padding()
} 