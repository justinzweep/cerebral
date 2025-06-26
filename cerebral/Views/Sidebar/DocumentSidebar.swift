//
//  DocumentSidebar.swift
//  cerebral
//
//  Created by Justin Zweep on 26/06/2025.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct DocumentSidebar: View {
    @Binding var selectedDocument: Document?
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Document.dateAdded, order: .reverse) private var documents: [Document]
    @Query(sort: \Folder.name) private var folders: [Folder]
    
    @State private var showingImporter = false
    @State private var showingNewFolderAlert = false
    @State private var newFolderName = ""
    @State private var searchText = ""
    
    var filteredDocuments: [Document] {
        if searchText.isEmpty {
            return documents
        } else {
            return documents.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        NavigationSplitView {
            DocumentSidebarContent(selectedDocument: $selectedDocument)
        } detail: {
            if selectedDocument == nil {
                EmptyDocumentSelectionView(showingImporter: $showingImporter)
            }
        }
    }
}

struct DocumentSidebarContent: View {
    @Binding var selectedDocument: Document?
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Document.dateAdded, order: .reverse) private var documents: [Document]
    @Query(sort: \Folder.name) private var folders: [Folder]
    
    @State private var showingImporter = false
    @State private var showingNewFolderAlert = false
    @State private var newFolderName = ""
    @State private var searchText = ""
    @FocusState private var isSearchFocused: Bool
    
    var filteredDocuments: [Document] {
        if searchText.isEmpty {
            return documents
        } else {
            return documents.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
            VStack(spacing: 0) {
                // Search bar
                HStack(spacing: DesignSystem.Spacing.xs) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(DesignSystem.Colors.textTertiary)
                        .font(DesignSystem.Typography.caption)
                    TextField("Search documents...", text: $searchText)
                        .textFieldStyle(.plain)
                        .font(DesignSystem.Typography.body)
                        .accessibilityLabel("Search documents")
                        .accessibilityHint("Type to search through your document library")
                        .focused($isSearchFocused)
                }
                .padding(.horizontal, DesignSystem.Spacing.sm)
                .padding(.vertical, DesignSystem.Spacing.xs)
                .background(DesignSystem.Colors.background)
                .cornerRadius(DesignSystem.CornerRadius.sm)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                        .stroke(DesignSystem.Colors.border, lineWidth: 1)
                )
                .padding(.horizontal, DesignSystem.Spacing.md)
                .padding(.bottom, DesignSystem.Spacing.md)
                
                // Document list
                List(selection: $selectedDocument) {
                    if !folders.isEmpty {
                        Section {
                            ForEach(folders.filter { $0.parent == nil }) { folder in
                                FolderRowView(folder: folder, selectedDocument: $selectedDocument)
                                    .listRowSeparator(.hidden)
                            }
                        } header: {
                            Text("Folders")
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                                .textCase(.uppercase)
                                .accessibleHeading(level: .h3)
                        }
                    }
                    
                    Section {
                        ForEach(filteredDocuments.filter { $0.folder == nil }) { document in
                            DocumentRowView(document: document)
                                .tag(document)
                                .listRowSeparator(.hidden)
                                .accessibilityAddTraits(.isButton)
                        }
                        .onDelete(perform: deleteDocuments)
                    } header: {
                        Text("Documents")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                            .textCase(.uppercase)
                            .accessibleHeading(level: .h3)
                    }
                }
                .listStyle(.sidebar)
                .scrollContentBackground(.hidden)
                .background(DesignSystem.Colors.secondaryBackground)
            }
            .navigationTitle("Library")
            .toolbar {
                ToolbarItemGroup {
                    Menu {
                        Button {
                            showingImporter = true
                        } label: {
                            Label("Import PDF...", systemImage: "doc.badge.plus")
                        }
                        .accessibleButton(
                            label: "Import PDF documents",
                            hint: "Open file picker to import PDF files"
                        )
                        
                        Divider()
                        
                        Button {
                            showingNewFolderAlert = true
                        } label: {
                            Label("New Folder...", systemImage: "folder.badge.plus")
                        }
                        .accessibleButton(
                            label: "Create new folder",
                            hint: "Create a new folder to organize documents"
                        )
                    } label: {
                        Image(systemName: "plus")
                            .foregroundColor(DesignSystem.Colors.accent)
                    }
                    .menuStyle(.borderlessButton)
                    .minimumTouchTarget()
                    .accessibleButton(
                        label: "Add documents or folders",
                        hint: "Menu with options to import documents or create folders"
                    )
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .focusSearch)) { _ in
                isSearchFocused = true
            }
            .onReceive(NotificationCenter.default.publisher(for: .importPDF)) { _ in
                showingImporter = true
            }
        .fileImporter(
            isPresented: $showingImporter,
            allowedContentTypes: [UTType.pdf],
            allowsMultipleSelection: true
        ) { result in
            importDocuments(result)
        }
        .alert("New Folder", isPresented: $showingNewFolderAlert) {
            TextField("Folder Name", text: $newFolderName)
            Button("Create") {
                createFolder()
            }
            .disabled(newFolderName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Enter a name for the new folder:")
        }
    }
    
    private func createFolder() {
        let folderName = newFolderName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !folderName.isEmpty else { return }
        
        let folder = Folder(name: folderName)
        modelContext.insert(folder)
        
        try? modelContext.save()
        newFolderName = ""
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
    
    private func deleteDocuments(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                let document = filteredDocuments[index]
                
                // Delete the actual file
                try? FileManager.default.removeItem(at: document.filePath)
                
                // Delete from SwiftData
                modelContext.delete(document)
            }
            
            try? modelContext.save()
        }
    }
}

// MARK: - Empty State Component

struct EmptyDocumentSelectionView: View {
    @Binding var showingImporter: Bool
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            // Icon
            Image(systemName: "doc.text")
                .font(.system(size: DesignSystem.Spacing.huge))
                .foregroundColor(DesignSystem.Colors.accent)
                .accessibilityHidden(true)
            
            VStack(spacing: DesignSystem.Spacing.sm) {
                // Title
                Text("Select a document to view")
                    .font(DesignSystem.Typography.title2)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .accessibleHeading(level: .h2)
                
                // Description
                Text("Choose a PDF from your library or import new documents to get started.")
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            // Action Button
            Button("Import PDF") {
                showingImporter = true
            }
            .buttonStyle(PrimaryButtonStyle())
            .accessibleButton(
                label: "Import PDF document",
                hint: "Opens file picker to select and import PDF files"
            )
        }
        .frame(maxWidth: 350)
        .padding(DesignSystem.Spacing.xl)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    DocumentSidebar(selectedDocument: .constant(nil))
        .modelContainer(for: [Document.self, Folder.self], inMemory: true)
}
