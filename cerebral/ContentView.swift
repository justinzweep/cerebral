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
    @State private var showingSidebar = true
    @State private var selectedDocument: Document?
    @State private var sidebarWidth: CGFloat = 280
    @State private var chatWidth: CGFloat = 320
    @State private var showingImporter = false
    @StateObject private var keyboardService = KeyboardShortcutService()
    
    @EnvironmentObject var settingsManager: SettingsManager
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        HStack(spacing: 0) {
            // Left Pane: Document Sidebar
            if showingSidebar {
                DocumentSidebarPane(selectedDocument: $selectedDocument)
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
                PDFViewerView(document: selectedDocument)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .background(DesignSystem.Colors.secondaryBackground)
            }
            .frame(minWidth: 300)
            .padding(.horizontal, DesignSystem.Spacing.sm)
            
            // Resizable divider for chat
            if showingChat {
                ResizableDivider(
                    orientation: .vertical,
                    onDrag: { delta in
                        let newWidth = chatWidth - delta
                        chatWidth = max(250, min(500, newWidth))
                    }
                )
                
                // Right Pane: Chat Panel
                ChatPane(selectedDocument: selectedDocument)
                    .frame(width: chatWidth)
                    .background(DesignSystem.Colors.secondaryBackground)
                    .environmentObject(settingsManager)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
        .background(DesignSystem.Colors.secondaryBackground)
        .onReceive(NotificationCenter.default.publisher(for: .importPDF)) { _ in
            showingImporter = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .toggleChatPanel)) { _ in
            withAnimation(DesignSystem.Animation.smooth) {
                showingChat.toggle()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .documentSelected)) { notification in
            if let document = notification.object as? Document {
                withAnimation(DesignSystem.Animation.smooth) {
                    selectedDocument = document
                }
                print("🎯 ContentView: Document selected via notification: '\(document.title)'")
            }
        }
        .onAppear {
            setupKeyboardHandling()
            setupServices()
        }
        .onDisappear {
            keyboardService.stopMonitoring()
        }
        .fileImporter(
            isPresented: $showingImporter,
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
    
    private func setupKeyboardHandling() {
        keyboardService.onEscapePressed = {
            withAnimation(DesignSystem.Animation.smooth) {
                selectedDocument = nil
            }
        }
        
        keyboardService.onToggleChat = {
            withAnimation(DesignSystem.Animation.smooth) {
                showingChat.toggle()
            }
        }
        
        keyboardService.onToggleSidebar = {
            withAnimation(DesignSystem.Animation.smooth) {
                showingSidebar.toggle()
            }
        }
        
        keyboardService.startMonitoring()
    }
    
    private func setupServices() {
        ServiceContainer.shared.configureModelContext(modelContext)
    }
}

#Preview {
    ContentView()
        .environmentObject(SettingsManager())
        .modelContainer(for: [Document.self, ChatSession.self], inMemory: true)
}
