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
    
    // Layout constraints
    private let sidebarWidthRange: ClosedRange<CGFloat> = 200...400
    private let chatWidthRange: ClosedRange<CGFloat> = 250...500
    private let centerMinWidth: CGFloat = 300
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                // Left Pane: Document Sidebar
                if appState.showingSidebar {
                    DocumentSidebarPane(
                        selectedDocument: $appState.selectedDocument,
                        showingImporter: $appState.showingImporter
                    )
                    .frame(width: constrainedSidebarWidth(for: geometry.size.width))
                    .background(DesignSystem.Colors.secondaryBackground)
                    .transition(.asymmetric(
                        insertion: .move(edge: .leading).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                    .id("sidebar")
                    
                    // Resizable divider for sidebar
                    ResizableDivider(orientation: .vertical) { delta in
                        updateSidebarWidth(delta: delta, availableWidth: geometry.size.width)
                    }
                    .id("sidebar-divider")
                }
                
                // Center Pane: PDF Viewer
                PDFViewerView(document: appState.selectedDocument)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .frame(minWidth: centerMinWidth)
                    .background(DesignSystem.Colors.secondaryBackground)
                    .id(appState.selectedDocument?.id.uuidString ?? "no-document")
                    .padding(.horizontal, DesignSystem.Spacing.sm)
                
                // Right divider and pane
                if appState.showingChat {
                    ResizableDivider(orientation: .vertical) { delta in
                        updateChatWidth(delta: -delta, availableWidth: geometry.size.width)
                    }
                    .id("chat-divider")
                    
                    // Right Pane: Chat Panel
                    ChatView(selectedDocument: appState.selectedDocument)
                        .frame(width: constrainedChatWidth(for: geometry.size.width))
                        .background(DesignSystem.Colors.secondaryBackground)
                        .environment(settingsManager)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .trailing).combined(with: .opacity)
                        ))
                        .id("chat-panel")
                }
            }
            .animation(.easeInOut(duration: 0.25), value: appState.showingSidebar)
            .animation(.easeInOut(duration: 0.25), value: appState.showingChat)
            .onChange(of: appState.showingSidebar) { _, _ in
                handlePanelToggle()
            }
            .onChange(of: appState.showingChat) { _, _ in
                handlePanelToggle()
            }
            .onChange(of: geometry.size.width) { oldWidth, newWidth in
                // Handle significant window size changes that could affect PDF layout
                if abs(newWidth - (oldWidth ?? 0)) > 50 { // Only for significant changes
                    NotificationCenter.default.post(name: NSNotification.Name("PDFLayoutWillChange"), object: nil)
                    
                    // Validate pane sizes first
                    validatePaneSizes(for: newWidth)
                    
                    // Schedule layout change notification
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        NotificationCenter.default.post(name: NSNotification.Name("PDFLayoutDidChange"), object: nil)
                    }
                } else {
                    validatePaneSizes(for: newWidth)
                }
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
    
    // MARK: - Layout Helper Methods
    
    private func constrainedSidebarWidth(for totalWidth: CGFloat) -> CGFloat {
        let maxAllowed = totalWidth - centerMinWidth - (appState.showingChat ? chatWidthRange.lowerBound : 0) - 16 // divider space
        return min(max(sidebarWidth, sidebarWidthRange.lowerBound), min(sidebarWidthRange.upperBound, maxAllowed))
    }
    
    private func constrainedChatWidth(for totalWidth: CGFloat) -> CGFloat {
        let maxAllowed = totalWidth - centerMinWidth - (appState.showingSidebar ? sidebarWidthRange.lowerBound : 0) - 16 // divider space
        return min(max(chatWidth, chatWidthRange.lowerBound), min(chatWidthRange.upperBound, maxAllowed))
    }
    
    private func updateSidebarWidth(delta: CGFloat, availableWidth: CGFloat) {
        let newWidth = sidebarWidth + delta
        let maxAllowed = availableWidth - centerMinWidth - (appState.showingChat ? chatWidthRange.lowerBound : 0) - 16
        sidebarWidth = min(max(newWidth, sidebarWidthRange.lowerBound), min(sidebarWidthRange.upperBound, maxAllowed))
    }
    
    private func updateChatWidth(delta: CGFloat, availableWidth: CGFloat) {
        let newWidth = chatWidth + delta
        let maxAllowed = availableWidth - centerMinWidth - (appState.showingSidebar ? sidebarWidthRange.lowerBound : 0) - 16
        chatWidth = min(max(newWidth, chatWidthRange.lowerBound), min(chatWidthRange.upperBound, maxAllowed))
    }
    
    private func validatePaneSizes(for totalWidth: CGFloat) {
        // Ensure pane sizes are within bounds when window is resized
        sidebarWidth = constrainedSidebarWidth(for: totalWidth)
        chatWidth = constrainedChatWidth(for: totalWidth)
    }
    
    // MARK: - Panel Management
    
    private func handlePanelToggle() {
        // Notify that layout will change due to panel toggle
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
        .environment(SettingsManager.shared)
        .modelContainer(for: [Document.self, ChatSession.self], inMemory: true)
}
