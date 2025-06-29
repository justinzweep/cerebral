//
//  ContentView.swift
//  cerebral
//
//  Created by Justin Zweep on 26/06/2025.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var appState = ServiceContainer.shared.appState
    @State private var errorManager = ServiceContainer.shared.errorManager
    @State private var keyboardService: KeyboardShortcutService?
    
    @Environment(SettingsManager.self) var settingsManager: SettingsManager
    @Environment(\.modelContext) private var modelContext
    
    // Layout constraints
    private let sidebarWidthRange: ClosedRange<CGFloat> = 200...400
    private let chatWidthRange: ClosedRange<CGFloat> = 280...600
    private let centerMinWidth: CGFloat = 300
    
    var body: some View {
        VStack(spacing: 0) {
            // Subtle divider line at bottom of toolbar
            Rectangle()
                .fill(DesignSystem.Colors.border)
                .frame(height: 0.5)
                .opacity(0.6)
            
            HSplitView {
                // Left Pane: Document Sidebar
                if appState.showingSidebar {
                    DocumentSidebarPane(
                        selectedDocument: $appState.selectedDocument,
                        showingImporter: $appState.showingImporter
                    )
                    .frame(minWidth: sidebarWidthRange.lowerBound, maxWidth: sidebarWidthRange.upperBound)
                    .background(DesignSystem.Colors.secondaryBackground)
                    .transition(.asymmetric(
                        insertion: .move(edge: .leading).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                    .id("sidebar")
                }
                
                // Center and Right Panes in nested HSplitView
                HSplitView {
                    // Center Pane: PDF Viewer
                    PDFViewerView(document: appState.selectedDocument)
                        .frame(minWidth: centerMinWidth)
                        .background(DesignSystem.Colors.secondaryBackground)
                        .id(appState.selectedDocument?.id.uuidString ?? "no-document")
                        .padding(.horizontal, DesignSystem.Spacing.sm)
                    
                    // Right Pane: Chat Panel
                    if appState.showingChat {
                        ChatView(selectedDocument: appState.selectedDocument)
                            .frame(minWidth: chatWidthRange.lowerBound, maxWidth: chatWidthRange.upperBound)
                            .background(DesignSystem.Colors.secondaryBackground)
                            .environment(settingsManager)
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .trailing).combined(with: .opacity)
                            ))
                            .id("chat-panel")
                    }
                }
            }
        }
        .animation(DesignSystem.Animation.interface, value: appState.showingSidebar)
        .animation(DesignSystem.Animation.interface, value: appState.showingChat)
        .onChange(of: appState.showingSidebar) { _, _ in
            handlePanelToggle()
        }
        .onChange(of: appState.showingChat) { _, _ in
            handlePanelToggle()
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
        .toolbar {
            // Centered app title
            ToolbarItem(placement: .principal) {
                Text("Cerebral")
                    .font(DesignSystem.Typography.title3)
                    .foregroundColor(DesignSystem.Colors.primaryText)
            }
            
            // Panel toggle buttons on the right
            ToolbarItem(placement: .primaryAction) {
                HStack(spacing: 8) {
                    // Sidebar toggle button
                    Button(action: {
                        withAnimation(DesignSystem.Animation.smooth) {
                            appState.toggleSidebar()
                        }
                    }) {
                        Image(systemName: appState.showingSidebar ? "rectangle.lefthalf.filled" : "rectangle")
                            .foregroundColor(appState.showingSidebar ? DesignSystem.Colors.accent : DesignSystem.Colors.secondaryText)
                            .font(.system(size: 16, weight: .medium))
                    }
                    .buttonStyle(.plain)
                    .help(appState.showingSidebar ? "Hide Documents (⌘K)" : "Show Documents (⌘K)")
                    
                    // Chat panel toggle button  
                    Button(action: {
                        withAnimation(DesignSystem.Animation.smooth) {
                            appState.toggleChatPanel()
                        }
                    }) {
                        Image(systemName: appState.showingChat ? "rectangle.righthalf.filled" : "rectangle")
                            .foregroundColor(appState.showingChat ? DesignSystem.Colors.accent : DesignSystem.Colors.secondaryText)
                            .font(.system(size: 16, weight: .medium))
                    }
                    .buttonStyle(.plain)
                    .help(appState.showingChat ? "Hide Chat (⌘L)" : "Show Chat (⌘L)")
                }
            }
        }
        .toolbarBackground(DesignSystem.Colors.secondaryBackground, for: .windowToolbar)
    }
    
    // MARK: - Panel Management
    
    private func handlePanelToggle() {
        // HSplitView handles layout changes automatically, but we still notify PDF viewer
        // for any content adjustments that might be needed
        NotificationCenter.default.post(name: NSNotification.Name("PDFLayoutWillChange"), object: nil)
        
        // Schedule notification that layout changed after animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { // 0.3s to account for 0.25s animation + buffer
            NotificationCenter.default.post(name: NSNotification.Name("PDFLayoutDidChange"), object: nil)
        }
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
            // For network errors, just clear the current error since validation happens naturally when user sends messages
            ServiceContainer.shared.errorManager.clearError()
        case .chatError(.connectionFailed), .chatError(.requestFailed):
            // Similar retry logic for chat errors - clear and let natural validation occur
            ServiceContainer.shared.errorManager.clearError()
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
        .environment(SettingsManager.shared)
        .modelContainer(for: [Document.self, ChatSession.self], inMemory: true)
}
