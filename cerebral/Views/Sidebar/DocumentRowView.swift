//
//  DocumentRowView.swift
//  cerebral
//
//  Created by Justin Zweep on 26/06/2025.
//

import SwiftUI

struct DocumentRowView: View {
    let document: Document
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            // PDF Icon with subtle styling
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xs)
                .fill(DesignSystem.Colors.accent.opacity(0.1))
                .frame(width: 36, height: 44)
                .overlay(
                    Image(systemName: "doc.text.fill")
                        .foregroundColor(DesignSystem.Colors.accent)
                        .font(.system(size: 16, weight: .medium))
                )
            
            // Document info
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxxs) {
                Text(document.title)
                    .font(DesignSystem.Typography.body)
                    .fontWeight(.medium)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .lineLimit(2)
                    .truncationMode(.tail)
                
                HStack(spacing: DesignSystem.Spacing.xs) {
                    if let lastOpened = document.lastOpened {
                        Text(relativeDateString(from: lastOpened))
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.textTertiary)
                    } else {
                        Text(relativeDateString(from: document.dateAdded))
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.textTertiary)
                    }
                    
                    if document.lastOpened != nil {
                        Circle()
                            .fill(DesignSystem.Colors.textTertiary)
                            .frame(width: 2, height: 2)
                        
                        Text("Recent")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.accent)
                    }
                }
            }
            
            Spacer()
            
            // Add to Chat button (subtle, only shown on hover)
            if isHovered {
                Button {
                    NotificationCenter.default.post(
                        name: .documentAddedToChat,
                        object: document
                    )
                } label: {
                    Image(systemName: "message")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(DesignSystem.Colors.accent)
                }
                .buttonStyle(.plain)
                .frame(width: 24, height: 24)
                .background(
                    Circle()
                        .fill(DesignSystem.Colors.accent.opacity(0.1))
                )
                .contentShape(Circle())
                .accessibilityLabel("Add to chat")
                .accessibilityHint("Add this document to the chat context")
                .transition(.opacity.combined(with: .scale(scale: 0.8)))
            }
            
            // Subtle indicator
            if isHovered {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(DesignSystem.Colors.textTertiary)
                    .transition(.opacity.combined(with: .scale(scale: 0.8)))
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.sm)
        .padding(.vertical, DesignSystem.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                .fill(isHovered ? DesignSystem.Colors.hoverBackground.opacity(0.5) : Color.clear)
        )
        .onHover { hovering in
            withAnimation(DesignSystem.Animation.microInteraction) {
                isHovered = hovering
            }
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("PDF document: \(document.title)")
        .accessibilityHint("Tap to open document")
    }
    
    private func relativeDateString(from date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        
        // Check if it's today
        if calendar.isDate(date, inSameDayAs: now) {
            return "Today"
        }
        
        // Check if it's yesterday
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: now),
           calendar.isDate(date, inSameDayAs: yesterday) {
            return "Yesterday"
        }
        
        // Check if it's in the same week
        if calendar.isDate(date, equalTo: now, toGranularity: .weekOfYear) {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            return formatter.string(from: date)
        }
        
        // Check if it's in the same year
        if calendar.isDate(date, equalTo: now, toGranularity: .year) {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: date)
        }
        
        // Different year
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
} 
