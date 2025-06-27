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
    
    var body: some View {
        HStack(spacing: 0) {
            // Left Pane: Document Sidebar
            if appState.showingSidebar {
                DocumentSidebarPane(selectedDocument: $appState.selectedDocument)
                    .frame(width: sidebarWidth)
                    .background(DesignSystem.Colors.secondaryBackground)
                    .transition(.move(edge: .leading).combined(with: .opacity))
                
                // Resizable divider for sidebar
                ResizableDivider(
                    orientation: .vertical,
                    onDrag: { delta in
                        let newWidth = sidebarWidth + delta
                        sidebarWidth = max(200, min(400, newWidth))
                    }
                )
            }
            
            // Middle Pane: PDF Viewer
            VStack(alignment: .leading, spacing: 0) {
                PDFViewerView(document: appState.selectedDocument)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .background(DesignSystem.Colors.secondaryBackground)
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
                
                // Right Pane: Chat Panel
                ChatPane(selectedDocument: appState.selectedDocument)
                    .frame(width: chatWidth)
                    .background(DesignSystem.Colors.secondaryBackground)
                    .environment(settingsManager)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
        .background(DesignSystem.Colors.secondaryBackground)
        .onAppear {
            if keyboardService == nil {
                keyboardService = KeyboardShortcutService(appState: appState)
            }
            keyboardService?.startMonitoring()
            setupServices()
        }
        .onDisappear {
            keyboardService?.stopMonitoring()
        }
        .fileImporter(
            isPresented: $appState.showingImporter,
            allowedContentTypes: [.pdf],
            allowsMultipleSelection: true
        ) { result in
            Task {
                do {
                    try await ServiceContainer.shared.documentService.importDocuments(result, to: modelContext)
                } catch {
                    ServiceContainer.shared.errorManager.handle(error)
                }
            }
        }
    }
    
    // MARK: - Private Methods
    

    
    private func setupServices() {
        ServiceContainer.shared.configureModelContext(modelContext)
    }
}

#Preview {
    ContentView()
        .environment(SettingsManager())
        .modelContainer(for: [Document.self, ChatSession.self], inMemory: true)
}
