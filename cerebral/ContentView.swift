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
    @State private var showingAnnotations = false
    @State private var selectedDocument: Document?
    @StateObject private var annotationManager = AnnotationManager()
    @EnvironmentObject var settingsManager: SettingsManager
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        HSplitView {
            // Document Sidebar
            DocumentSidebar(selectedDocument: $selectedDocument)
                .frame(minWidth: 200, idealWidth: 250, maxWidth: 300)
            
            // PDF Viewer Area
            PDFViewerView(document: selectedDocument, annotationManager: annotationManager)
                .frame(minWidth: 400)
            
            // Right Side Panels
            VStack(spacing: 0) {
                if showingAnnotations && showingChat {
                    // Both panels shown - use tabs
                    TabView {
                        AnnotationListView(annotationManager: annotationManager, document: selectedDocument)
                            .tabItem {
                                Label("Annotations", systemImage: "note.text")
                            }
                        
                        ChatView()
                            .environmentObject(settingsManager)
                            .tabItem {
                                Label("Chat", systemImage: "message")
                            }
                    }
                    .frame(minWidth: 250, idealWidth: 300, maxWidth: 400)
                } else if showingAnnotations {
                    // Just annotations
                    AnnotationListView(annotationManager: annotationManager, document: selectedDocument)
                        .frame(minWidth: 250, idealWidth: 300, maxWidth: 400)
                } else if showingChat {
                    // Just chat
                    ChatView()
                        .frame(minWidth: 250, idealWidth: 300, maxWidth: 400)
                        .environmentObject(settingsManager)
                }
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button(action: { showingAnnotations.toggle() }) {
                    Image(systemName: showingAnnotations ? "note.text.badge.plus" : "note.text")
                }
                .help(showingAnnotations ? "Hide Annotations" : "Show Annotations")
                
                Button(action: { showingChat.toggle() }) {
                    Image(systemName: showingChat ? "sidebar.right" : "message")
                }
                .help(showingChat ? "Hide Chat" : "Show Chat")
            }
        }
        .onChange(of: selectedDocument) { oldDocument, newDocument in
            setupAnnotationManager()
        }
        .onAppear {
            setupAnnotationManager()
        }
        .navigationTitle("Cerebral")
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
