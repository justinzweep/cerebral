//
//  ContentView.swift
//  cerebral
//
//  Created by Justin Zweep on 26/06/2025.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var sidebarWidth: CGFloat = 280
    @State private var chatWidth: CGFloat = 320
    @State private var appState = ServiceContainer.shared.appState
    @State private var keyboardService: KeyboardShortcutService?
    
    @Environment(SettingsManager.self) var settingsManager: SettingsManager
    @Environment(\.modelContext) private var modelContext
    
    // Performance monitoring
    private let performanceMonitor = PerformanceMonitor.shared
    
    var body: some View {
        HStack(spacing: 0) {
            // Left Pane: Document Sidebar
            if appState.showingSidebar {
                DocumentSidebarPane(selectedDocument: $appState.selectedDocument)
                    .frame(width: sidebarWidth)
                    .background(DesignSystem.Colors.secondaryBackground)
                    .transition(.move(edge: .leading).combined(with: .opacity))
                    .id("sidebar") // Stable ID for animations
                    .trackPerformance("document_sidebar")
                
                // Resizable divider for sidebar
                ResizableDivider(
                    orientation: .vertical,
                    onDrag: { delta in
                        let newWidth = sidebarWidth + delta
                        sidebarWidth = max(200, min(400, newWidth))
                    }
                )
                .id("sidebar-divider") // Stable ID
            }
            
            // Middle Pane: PDF Viewer
            VStack(alignment: .leading, spacing: 0) {
                PDFViewerView(document: appState.selectedDocument)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .background(DesignSystem.Colors.secondaryBackground)
                    .id(appState.selectedDocument?.id.uuidString ?? "no-document") // Stable ID based on document
                    .trackPerformance("pdf_viewer")
            }
            .frame(minWidth: 300)
            .padding(.horizontal, DesignSystem.Spacing.sm)
            
            // Resizable divider for chat
            if appState.showingChat {
                ResizableDivider(
                    orientation: .vertical,
                    onDrag: { delta in
                        let newWidth = chatWidth - delta
                        chatWidth = max(250, min(500, newWidth))
                    }
                )
                .id("chat-divider") // Stable ID
                
                // Right Pane: Chat Panel
                ChatPane(selectedDocument: appState.selectedDocument)
                    .frame(width: chatWidth)
                    .background(DesignSystem.Colors.secondaryBackground)
                    .environment(settingsManager)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                    .id("chat-panel") // Stable ID for animations
                    .trackPerformance("chat_panel")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
        .background(DesignSystem.Colors.secondaryBackground)
        .onAppear {
            performanceMonitor.startMeasuring(identifier: "content_view_load")
            setupApplication()
        }
        .onDisappear {
            performanceMonitor.endMeasuring(identifier: "content_view_load")
            cleanupApplication()
        }
        .fileImporter(
            isPresented: $appState.showingImporter,
            allowedContentTypes: [.pdf],
            allowsMultipleSelection: true
        ) { result in
            Task { @MainActor in
                performanceMonitor.startMeasuring(identifier: "document_import")
                
                do {
                    try await ServiceContainer.shared.documentService.importDocuments(result, to: modelContext)
                } catch {
                    ServiceContainer.shared.errorManager.handle(error)
                }
                
                performanceMonitor.endMeasuring(identifier: "document_import")
            }
        }
        .trackPerformance("main_content_view")
    }
    
    // MARK: - Private Methods
    
    private func setupApplication() {
        if keyboardService == nil {
            keyboardService = KeyboardShortcutService(appState: appState)
        }
        keyboardService?.startMonitoring()
        setupServices()
        
        print("✅ Application setup completed")
    }
    
    private func cleanupApplication() {
        keyboardService?.stopMonitoring()
        ServiceContainer.shared.cleanup()
        
        print("🧹 Application cleanup completed")
    }
    
    private func setupServices() {
        ServiceContainer.shared.configureModelContext(modelContext)
    }
}

#Preview {
    ContentView()
        .environment(SettingsManager())
        .modelContainer(for: [Document.self, ChatSession.self], inMemory: true)
}
