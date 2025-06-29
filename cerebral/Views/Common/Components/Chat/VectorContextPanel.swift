//
//  VectorContextPanel.swift
//  cerebral
//
//  Created on 27/11/2024.
//

import SwiftUI
import SwiftData

struct VectorContextPanel: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var chatSession: ChatSession
    @State private var isExpanded = true
    @State private var processingStatus: (total: Int, processed: Int, pending: Int, failed: Int) = (0, 0, 0, 0)
    
    private let contextService = ContextManagementService.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(.blue)
                Text("Vector Context")
                    .font(.headline)
                Spacer()
                Button(action: { isExpanded.toggle() }) {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.caption)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { isExpanded.toggle() }
            
            if isExpanded {
                // Processing Status
                if processingStatus.total > 0 {
                    ProcessingStatusView(status: processingStatus)
                        .padding(.bottom, 8)
                }
                
                // Context Items
                if !chatSession.contextItems.isEmpty {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        ForEach(chatSession.contextItems, id: \.id) { contextItem in
                            ContextItemRow(
                                contextItem: contextItem,
                                onRemove: { 
                                    contextService.removeContextItem(contextItem, from: chatSession)
                                }
                            )
                        }
                    }
                } else {
                    Text("No context items added")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .italic()
                }
                
                // Actions
                HStack {
                    Button("Clear All") {
                        contextService.clearAllContext(for: chatSession)
                    }
                    .disabled(chatSession.contextItems.isEmpty)
                    
                    Spacer()
                    
                    Button("Refresh Status") {
                        updateProcessingStatus()
                    }
                    .font(.caption)
                }
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
        .onAppear {
            updateProcessingStatus()
        }
    }
    
    private func updateProcessingStatus() {
        do {
            if let vectorService = contextService.currentVectorSearchService {
                processingStatus = try vectorService.getProcessingStats()
            }
        } catch {
            print("Failed to get processing status: \(error)")
        }
    }
}

struct ContextItemRow: View {
    let contextItem: ContextItem
    let onRemove: () -> Void
    
    @Query private var documents: [Document]
    
    var document: Document? {
        documents.first { $0.id == contextItem.documentId }
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            // Type Icon
            Image(systemName: contextItem.type == .document ? "doc.text" : "text.quote")
                .foregroundColor(contextItem.type == .document ? .blue : .green)
                .font(.caption)
            
            VStack(alignment: .leading, spacing: 4) {
                // Title
                Text(contextItem.type == .document ? 
                    (document?.title ?? "Unknown Document") : 
                    "Selected Text")
                    .font(.caption)
                    .fontWeight(.medium)
                
                // Content Preview
                Text(String(contextItem.content.prefix(50)) + (contextItem.content.count > 50 ? "..." : ""))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                // Additional Info
                HStack {
                    if let pageNumber = contextItem.pageNumber {
                        Text("Page \(pageNumber)")
                            .font(.caption2)
                            .padding(2)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(4)
                    }
                    
                    if contextItem.type == .document, let doc = document {
                        ProcessingStatusBadge(status: doc.processingStatus)
                    }
                    
                    Spacer()
                    
                    Text(contextItem.dateAdded, format: .relative(presentation: .named))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Remove Button
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(8)
        .background(Color(.controlColor))
        .cornerRadius(6)
    }
}

struct ProcessingStatusView: View {
    let status: (total: Int, processed: Int, pending: Int, failed: Int)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Document Processing Status")
                .font(.caption)
                .fontWeight(.medium)
            
            HStack(spacing: 12) {
                StatusItem(label: "Total", count: status.total, color: .primary)
                StatusItem(label: "Processed", count: status.processed, color: .green)
                StatusItem(label: "Pending", count: status.pending, color: .orange)
                StatusItem(label: "Failed", count: status.failed, color: .red)
            }
            
            // Progress Bar
            if status.total > 0 {
                let progress = Double(status.processed) / Double(status.total)
                ProgressView(value: progress)
                    .progressViewStyle(LinearProgressViewStyle())
            }
        }
        .padding(8)
        .background(Color(.controlColor))
        .cornerRadius(6)
    }
}

struct StatusItem: View {
    let label: String
    let count: Int
    let color: Color
    
    var body: some View {
        VStack(spacing: 2) {
            Text("\(count)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(color)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

struct ProcessingStatusBadge: View {
    let status: ProcessingStatus
    
    var body: some View {
        Text(status.rawValue.capitalized)
            .font(.caption2)
            .padding(2)
            .background(backgroundColor)
            .foregroundColor(foregroundColor)
            .cornerRadius(4)
    }
    
    private var backgroundColor: Color {
        switch status {
        case .pending: return .orange.opacity(0.1)
        case .processing: return .blue.opacity(0.1)
        case .completed: return .green.opacity(0.1)
        case .failed: return .red.opacity(0.1)
        }
    }
    
    private var foregroundColor: Color {
        switch status {
        case .pending: return .orange
        case .processing: return .blue
        case .completed: return .green
        case .failed: return .red
        }
    }
}

 