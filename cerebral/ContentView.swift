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
    @State private var errorManager = ServiceContainer.shared.errorManager
    @State private var keyboardService: KeyboardShortcutService?
    
    @Environment(SettingsManager.self) var settingsManager: SettingsManager
    @Environment(\.modelContext) private var modelContext
    
    // Performance monitoring
    
    var body: some View {
        HStack(spacing: 0) {
            // Left Pane: Document Sidebar
            if appState.showingSidebar {
                DocumentSidebarPane(
                    selectedDocument: $appState.selectedDocument,
                    showingImporter: $appState.showingImporter
                )
                    .frame(width: sidebarWidth)
                    .background(DesignSystem.Colors.secondaryBackground)
                    .transition(.move(edge: .leading).combined(with: .opacity))
                    .id("sidebar") // Stable ID for animations
                
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
            PDFViewerView(document: appState.selectedDocument)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .background(DesignSystem.Colors.secondaryBackground)
                .id(appState.selectedDocument?.id.uuidString ?? "no-document") // Stable ID based on document
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
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
        .background(DesignSystem.Colors.secondaryBackground)
        .onAppear {
            setupApplication()
        }
        .onDisappear {
            cleanupApplication()
        }
        .fileImporter(
            isPresented: $appState.showingImporter,
            allowedContentTypes: [.pdf],
            allowsMultipleSelection: true
        ) { result in
            Task { @MainActor in
                
                do {
                    try await ServiceContainer.shared.documentService.importDocuments(result, to: modelContext)
                } catch {
                    ServiceContainer.shared.errorManager.handle(error, context: "document_import")
                }
                
            }
        }
        // Global Error Handling
        .errorAlert(
            isPresented: $errorManager.showingError,
            error: errorManager.currentError,
            onRetry: {
                // Retry action based on error type
                if let error = errorManager.currentError {
                    errorManager.attemptRetry(for: error)
                    handleRetryAction(for: error)
                }
            },
            onOpenSettings: {
                // Open settings action
                openSettingsWindow()
            }
        )
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
    
    private func handleRetryAction(for error: AppError) {
        switch error {
        case .networkFailure, .chatServiceUnavailable:
            // For network errors, we could trigger a connection test
            Task {
                do {
                    _ = try await ServiceContainer.shared.chatService().validateConnection()
                } catch {
                    ServiceContainer.shared.errorManager.handle(error)
                }
            }
        case .chatError(.connectionFailed), .chatError(.requestFailed):
            // Similar retry logic for chat errors
            break
        default:
            break
        }
    }
    
    private func openSettingsWindow() {
        // Open the Settings window
        NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
    }
}

#Preview {
    ContentView()
        .environment(SettingsManager())
        .modelContainer(for: [Document.self, ChatSession.self], inMemory: true)
}
