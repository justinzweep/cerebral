//
//  ContentView.swift
//  cerebral
//
//  Created by Justin Zweep on 26/06/2025.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var showingChat = true
    @State private var selectedDocument: Document?
    @EnvironmentObject var settingsManager: SettingsManager
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                // Left Pane: Document Sidebar
                DocumentSidebarPane(selectedDocument: $selectedDocument)
                    .frame(width: 280)
                    .background(DesignSystem.Colors.surfaceSecondary)
                
                // Subtle divider
                Rectangle()
                    .fill(DesignSystem.Colors.border.opacity(0.3))
                    .frame(width: 1)
                
                // Middle Pane: PDF Viewer
                PDFViewerView(document: selectedDocument)
                    .frame(minWidth: 400)
                    .background(DesignSystem.Colors.secondaryBackground)
                
                // Subtle divider (only when chat is shown)
                if showingChat {
                    Rectangle()
                        .fill(DesignSystem.Colors.border.opacity(0.3))
                        .frame(width: 1)
                }
                
                // Right Pane: Chat Panel
                if showingChat {
                    ChatPane()
                        .frame(width: 320)
                        .background(DesignSystem.Colors.surfaceSecondary)
                        .environmentObject(settingsManager)
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                }
            }
        }
        .background(DesignSystem.Colors.secondaryBackground)
        .onReceive(NotificationCenter.default.publisher(for: .toggleChatPanel)) { _ in
            withAnimation(DesignSystem.Animation.smooth) {
                showingChat.toggle()
            }
        }
        .focusable()
        .focusEffectDisabled()
    }
}

// MARK: - Document Sidebar Pane (Clean Version)

struct DocumentSidebarPane: View {
    @Binding var selectedDocument: Document?
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Document.dateAdded, order: .reverse) private var documents: [Document]
    
    @State private var showingImporter = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with add button
            HStack {
                Text("Documents")
                    .font(DesignSystem.Typography.title3)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Spacer()
                
                Button {
                    showingImporter = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(DesignSystem.Colors.accent)
                }
                .buttonStyle(.plain)
                .frame(width: 32, height: 32)
                .background(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                        .fill(DesignSystem.Colors.hoverBackground.opacity(0))
                )
                .onHover { isHovered in
                    withAnimation(DesignSystem.Animation.microInteraction) {
                        // Hover effect handled by button style
                    }
                }
            }
            .padding(DesignSystem.Spacing.md)
            
            // Document list
            ScrollView {
                LazyVStack(spacing: DesignSystem.Spacing.xs) {
                    if documents.isEmpty {
                        EmptyDocumentsView(showingImporter: $showingImporter)
                    } else {
                        ForEach(documents) { document in
                            DocumentRowView(document: document)
                                .onTapGesture {
                                    selectedDocument = document
                                }
                                .background(
                                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                                        .fill(selectedDocument?.id == document.id ? 
                                              DesignSystem.Colors.selectedBackground : 
                                              Color.clear)
                                )
                        }
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.md)
                .padding(.bottom, DesignSystem.Spacing.lg)
            }
            .scrollIndicators(.never)
        }
        .fileImporter(
            isPresented: $showingImporter,
            allowedContentTypes: [.pdf],
            allowsMultipleSelection: true
        ) { result in
            importDocuments(result)
        }
    }
    
    private func importDocuments(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            for url in urls {
                importDocument(from: url)
            }
        case .failure(let error):
            print("Error importing documents: \(error)")
        }
    }
    
    private func importDocument(from url: URL) {
        guard url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }
        
        // Create documents directory if it doesn't exist
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let cerebralDocsPath = documentsPath.appendingPathComponent("Cerebral Documents")
        try? FileManager.default.createDirectory(at: cerebralDocsPath, withIntermediateDirectories: true)
        
        // Copy file to app's documents directory
        let fileName = url.lastPathComponent
        let destinationURL = cerebralDocsPath.appendingPathComponent(fileName)
        
        // Handle duplicates by appending a number
        var finalURL = destinationURL
        var counter = 1
        while FileManager.default.fileExists(atPath: finalURL.path) {
            let nameWithoutExt = (fileName as NSString).deletingPathExtension
            let ext = (fileName as NSString).pathExtension
            finalURL = cerebralDocsPath.appendingPathComponent("\(nameWithoutExt) \(counter).\(ext)")
            counter += 1
        }
        
        do {
            try FileManager.default.copyItem(at: url, to: finalURL)
            
            // Create document model
            let title = finalURL.deletingPathExtension().lastPathComponent
            let document = Document(title: title, filePath: finalURL)
            modelContext.insert(document)
            
            try modelContext.save()
        } catch {
            print("Error importing document: \(error)")
        }
    }
}

// MARK: - Chat Pane (Clean Version)

struct ChatPane: View {
    var body: some View {
        ChatView()
    }
}

// MARK: - Supporting Views

struct EmptyDocumentsView: View {
    @Binding var showingImporter: Bool
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            Image(systemName: "doc.text")
                .font(.system(size: 48))
                .foregroundColor(DesignSystem.Colors.textTertiary)
            
            VStack(spacing: DesignSystem.Spacing.sm) {
                Text("No Documents")
                    .font(DesignSystem.Typography.headline)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Text("Import your first PDF to get started")
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            Button("Import PDF") {
                showingImporter = true
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .padding(DesignSystem.Spacing.xl)
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    ContentView()
        .environmentObject(SettingsManager())
        .modelContainer(for: [Document.self, ChatSession.self], inMemory: true)
}
