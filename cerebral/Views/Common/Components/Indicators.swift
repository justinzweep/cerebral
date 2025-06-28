//
//  Indicators.swift
//  cerebral
//
//  Consolidated Indicator Components
//

import SwiftUI

// MARK: - Loading Spinner

struct LoadingSpinner: View {
    let size: SpinnerSize
    let color: Color
    
    enum SpinnerSize {
        case small, medium, large
        
        var diameter: CGFloat {
            switch self {
            case .small: return 16
            case .medium: return 24
            case .large: return 32
            }
        }
        
        var lineWidth: CGFloat {
            switch self {
            case .small: return 2
            case .medium: return 3
            case .large: return 4
            }
        }
    }
    
    init(size: SpinnerSize = .medium, color: Color = DesignSystem.Colors.accent) {
        self.size = size
        self.color = color
    }
    
    @State private var isAnimating = false
    
    var body: some View {
        Circle()
            .trim(from: 0, to: 0.7)
            .stroke(
                color,
                style: StrokeStyle(
                    lineWidth: size.lineWidth,
                    lineCap: .round
                )
            )
            .frame(width: size.diameter, height: size.diameter)
            .rotationEffect(.degrees(isAnimating ? 360 : 0))
            .animation(
                .linear(duration: 1)
                .repeatForever(autoreverses: false),
                value: isAnimating
            )
            .onAppear {
                isAnimating = true
            }
    }
}

// MARK: - Status Badge

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

// MARK: - Previews

#Preview {
    VStack(spacing: 20) {
        // Loading Spinners
        VStack(spacing: 20) {
            Text("Loading Spinners")
                .font(.headline)
            
            HStack(spacing: 20) {
                LoadingSpinner(size: .small)
                LoadingSpinner(size: .medium)
                LoadingSpinner(size: .large)
            }
            
            HStack(spacing: 20) {
                LoadingSpinner(size: .medium, color: .red)
                LoadingSpinner(size: .medium, color: .green)
                LoadingSpinner(size: .medium, color: .blue)
            }
        }
        
        Divider()
        
        // Status Badges
        VStack(spacing: 16) {
            Text("Status Badges")
                .font(.headline)
            
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
    }
    .padding()
} 