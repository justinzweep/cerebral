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
    @StateObject private var annotationManager = AnnotationManager()
    @EnvironmentObject var settingsManager: SettingsManager
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HSplitView {
            // Document Sidebar
            DocumentSidebarContent(selectedDocument: $selectedDocument)
                .frame(minWidth: 200, idealWidth: 250, maxWidth: 300)
                .accessibilityLabel("Document library sidebar")
            
            // PDF Viewer Area
            PDFViewerView(document: selectedDocument, annotationManager: annotationManager)
                .frame(minWidth: 400)
                .accessibilityLabel("PDF viewer")
            
            // Chat Panel (conditionally shown)
            if showingChat {
                ChatView()
                    .frame(minWidth: 250, idealWidth: 300, maxWidth: 400)
                    .environmentObject(settingsManager)
                    .accessibilityLabel("AI chat assistant panel")
            }
        }
        .background(DesignSystem.Colors.secondaryBackground)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button(action: { 
                    withAnimation(DesignSystem.Animation.smooth) {
                        showingChat.toggle()
                    }
                }) {
                    Image(systemName: showingChat ? "sidebar.trailing" : "message")
                        .foregroundColor(DesignSystem.Colors.accent)
                }
                .buttonStyle(.borderless)
                .minimumTouchTarget()
                .accessibleButton(
                    label: showingChat ? "Hide chat panel" : "Show chat panel",
                    hint: "Toggle the visibility of the AI chat panel"
                )
                .keyboardShortcut("c", modifiers: [.command])
            }
        }
        .onChange(of: selectedDocument) { oldDocument, newDocument in
            setupAnnotationManager()
        }
        .onAppear {
            setupAnnotationManager()
        }
        .onReceive(NotificationCenter.default.publisher(for: .toggleChatPanel)) { _ in
            withAnimation(DesignSystem.Animation.smooth) {
                showingChat.toggle()
            }
        }
        .navigationTitle("Cerebral")
        .focusable()
        .focusEffectDisabled()
    }
    
    private func setupAnnotationManager() {
        annotationManager.setContext(modelContext)
        annotationManager.setCurrentDocument(selectedDocument)
    }
}

#Preview {
    ContentView()
        .environmentObject(SettingsManager())
        .modelContainer(for: [Document.self, Annotation.self, ChatSession.self, Folder.self], inMemory: true)
}
