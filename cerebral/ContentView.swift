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
    @State private var keyMonitor: Any?
    @State private var showingImporter = false
    @EnvironmentObject var settingsManager: SettingsManager
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 0) {
            // Left Pane: Document Sidebar (Fixed width, user-resizable only)
            if showingSidebar {
                DocumentSidebarPane(selectedDocument: $selectedDocument)
                    .frame(width: sidebarWidth)
                    .background(DesignSystem.Colors.surfaceSecondary)
                    .transition(.move(edge: .leading).combined(with: .opacity))
                
                // Resizable divider for sidebar
                DividerView(
                    orientation: .vertical,
                    onDrag: { delta in
                        let newWidth = sidebarWidth + delta
                        sidebarWidth = max(200, min(400, newWidth))
                    }
                )
            }
            
            // Middle Pane: PDF Viewer (Takes remaining space, constrained to screen)
            VStack(alignment: .leading, spacing: 0) {
                PDFViewerView(document: selectedDocument)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .background(DesignSystem.Colors.secondaryBackground)
            }
            .frame(minWidth: 300)
            .padding(.horizontal, DesignSystem.Spacing.sm)
            
            // Resizable divider for chat (only when chat is shown)
            if showingChat {
                DividerView(
                    orientation: .vertical,
                    onDrag: { delta in
                        let newWidth = chatWidth - delta
                        chatWidth = max(250, min(500, newWidth))
                    }
                )
                
                // Right Pane: Chat Panel (Fixed width, user-resizable only)
                ChatPane(selectedDocument: selectedDocument)
                    .frame(width: chatWidth)
                    .background(DesignSystem.Colors.surfaceSecondary)
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
            setupKeyboardMonitoring()
        }
        .onDisappear {
            removeKeyboardMonitoring()
        }
        .onChange(of: modelContext) { _, newContext in
            // Initialize DocumentLookupService with model context
            Task { @MainActor in
                DocumentLookupService.shared.setModelContext(newContext)
            }
        }
        .task {
            // Initialize DocumentLookupService on app launch
            DocumentLookupService.shared.setModelContext(modelContext)
        }
        .fileImporter(
            isPresented: $showingImporter,
            allowedContentTypes: [.pdf],
            allowsMultipleSelection: true
        ) { result in
            importDocuments(result)
        }
    }
    
    // MARK: - Import Methods
    
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
    
    // MARK: - Keyboard Monitoring
    
    private func setupKeyboardMonitoring() {
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { event in
            return handleKeyEvent(event)
        }
    }
    
    private func removeKeyboardMonitoring() {
        if let monitor = keyMonitor {
            NSEvent.removeMonitor(monitor)
            keyMonitor = nil
        }
    }
    
    private func handleKeyEvent(_ event: NSEvent) -> NSEvent? {
        let keyCode = event.keyCode
        let modifierFlags = event.modifierFlags
        
        // ESC key (keyCode 53)
        if keyCode == 53 {
            DispatchQueue.main.async {
                withAnimation(DesignSystem.Animation.smooth) {
                    selectedDocument = nil
                }
            }
            return nil // Consume the event
        }
        
        // Command + L (keyCode 37 for 'L')
        if keyCode == 37 && modifierFlags.contains(.command) {
            DispatchQueue.main.async {
                withAnimation(DesignSystem.Animation.smooth) {
                    showingChat.toggle()
                }
            }
            return nil // Consume the event
        }
        
        // Command + K (keyCode 40 for 'K')
        if keyCode == 40 && modifierFlags.contains(.command) {
            DispatchQueue.main.async {
                withAnimation(DesignSystem.Animation.smooth) {
                    showingSidebar.toggle()
                }
            }
            return nil // Consume the event
        }
        
        return event // Let the event continue
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
    let selectedDocument: Document?
    
    var body: some View {
        ChatView(selectedDocument: selectedDocument)
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

// MARK: - Custom Divider for Resizing

struct DividerView: View {
    enum Orientation {
        case vertical, horizontal
    }
    
    let orientation: Orientation
    let onDrag: (CGFloat) -> Void
    
    @State private var isDragging = false
    @State private var isHovered = false
    
    var body: some View {
        ZStack {
            // Invisible drag area (larger for easier targeting)
            Rectangle()
                .fill(Color.clear)
                .frame(
                    width: orientation == .vertical ? 16 : nil,
                    height: orientation == .horizontal ? 16 : nil
                )
                .contentShape(Rectangle())
                .cursor(orientation == .vertical ? .resizeLeftRight : .resizeUpDown)
                .onHover { hovering in
                    isHovered = hovering
                }
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            if !isDragging {
                                isDragging = true
                            }
                            let delta = orientation == .vertical ? value.translation.width : value.translation.height
                            onDrag(delta)
                        }
                        .onEnded { _ in
                            isDragging = false
                        }
                )
            
            // Visual divider line
            Rectangle()
                .fill(DesignSystem.Colors.border.opacity(0.3))
                .frame(
                    width: orientation == .vertical ? 1 : nil,
                    height: orientation == .horizontal ? 1 : nil
                )
            
            // Hover/drag indicator
            if isHovered || isDragging {
                Rectangle()
                    .fill(DesignSystem.Colors.accent.opacity(isDragging ? 0.4 : 0.2))
                    .frame(
                        width: orientation == .vertical ? 3 : nil,
                        height: orientation == .horizontal ? 3 : nil
                    )
                    .animation(DesignSystem.Animation.microInteraction, value: isDragging)
                    .animation(DesignSystem.Animation.microInteraction, value: isHovered)
            }
        }
    }
}

// MARK: - NSCursor Extension for Custom Cursors

extension View {
    func cursor(_ cursor: NSCursor) -> some View {
        self.onHover { hovering in
            if hovering {
                cursor.push()
            } else {
                NSCursor.pop()
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(SettingsManager())
        .modelContainer(for: [Document.self, ChatSession.self], inMemory: true)
}
