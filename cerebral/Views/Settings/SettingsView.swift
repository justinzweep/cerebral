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
        case performance = "Performance"
        case userProfile = "Profile"
        
        var icon: String {
            switch self {
            case .general: return "gearshape"
            case .apiKey: return "key"
            case .performance: return "speedometer"
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
                        .font(.system(size: 14, weight: .medium))
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
                                .font(.system(size: 12, weight: .medium))
                            
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
                case .performance:
                    PerformanceSettingsView()
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

struct PerformanceSettingsView: View {
    @State private var performanceMonitor = PerformanceMonitor.shared
    @State private var isMonitoring = false
    @State private var refreshTimer: Timer?
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                // Performance Monitoring Controls
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                    HStack {
                        Text("Performance Monitoring")
                            .font(DesignSystem.Typography.headline)
                            .foregroundColor(DesignSystem.Colors.primaryText)
                        
                        Spacer()
                        
                        Toggle("Enable", isOn: $isMonitoring)
                            .toggleStyle(.switch)
                    }
                    
                    Text("Monitor app performance and identify bottlenecks in real-time.")
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
                .padding(DesignSystem.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                        .fill(DesignSystem.Colors.secondaryBackground)
                )
                
                // Performance Metrics
                if isMonitoring {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                        Text("Current Performance Metrics")
                            .font(DesignSystem.Typography.headline)
                            .foregroundColor(DesignSystem.Colors.primaryText)
                        
                        LazyVStack(spacing: DesignSystem.Spacing.sm) {
                            PerformanceMetricRow(identifier: "main_content_view", label: "Main Content View")
                            PerformanceMetricRow(identifier: "document_sidebar", label: "Document Sidebar")
                            PerformanceMetricRow(identifier: "pdf_viewer", label: "PDF Viewer")
                            PerformanceMetricRow(identifier: "chat_panel", label: "Chat Panel")
                            PerformanceMetricRow(identifier: "streaming_message", label: "Message Streaming")
                        }
                    }
                    .padding(DesignSystem.Spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                            .fill(DesignSystem.Colors.secondaryBackground)
                    )
                }
                
                // Performance Tips
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                    Text("Performance Tips")
                        .font(DesignSystem.Typography.headline)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                    
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                        PerformanceTip(
                            icon: "doc.text.below.ecg",
                            title: "Large Documents",
                            description: "Large PDF files may impact performance. Consider splitting very large documents."
                        )
                        
                        PerformanceTip(
                            icon: "message.badge",
                            title: "Chat History",
                            description: "Chat history is automatically limited to maintain performance."
                        )
                        
                        PerformanceTip(
                            icon: "photo.on.rectangle.angled",
                            title: "Thumbnails",
                            description: "PDF thumbnails are cached for better performance."
                        )
                    }
                }
                .padding(DesignSystem.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                        .fill(DesignSystem.Colors.secondaryBackground)
                )
            }
            .padding(DesignSystem.Spacing.lg)
        }
        .onAppear {
            if isMonitoring {
                startPerformanceMonitoring()
            }
        }
        .onDisappear {
            stopPerformanceMonitoring()
        }
        .onChange(of: isMonitoring) { _, monitoring in
            if monitoring {
                startPerformanceMonitoring()
            } else {
                stopPerformanceMonitoring()
            }
        }
    }
    
    private func startPerformanceMonitoring() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            // This will trigger UI updates for performance metrics
        }
    }
    
    private func stopPerformanceMonitoring() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
}

struct PerformanceMetricRow: View {
    let identifier: String
    let label: String
    @State private var performanceMonitor = PerformanceMonitor.shared
    
    var body: some View {
        HStack {
            Text(label)
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.primaryText)
            
            Spacer()
            
            if let renderTime = performanceMonitor.getAverageRenderTime(for: identifier) {
                Text("\(String(format: "%.2f", renderTime * 1000))ms")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(renderTime > 0.016 ? DesignSystem.Colors.error : DesignSystem.Colors.success)
                    .padding(.horizontal, DesignSystem.Spacing.xs)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(renderTime > 0.016 ? 
                                  DesignSystem.Colors.error.opacity(0.1) : 
                                  DesignSystem.Colors.success.opacity(0.1))
                    )
            } else {
                Text("N/A")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.tertiaryText)
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.sm)
        .padding(.vertical, DesignSystem.Spacing.xs)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                .fill(DesignSystem.Colors.background)
        )
    }
}

struct PerformanceTip: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: DesignSystem.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(DesignSystem.Colors.accent)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(DesignSystem.Typography.caption)
                    .fontWeight(.medium)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                
                Text(description)
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.sm)
        .padding(.vertical, DesignSystem.Spacing.xs)
    }
}

#Preview {
    SettingsView()
        .environment(SettingsManager())
} 