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
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search documents...", text: $searchText)
                        .textFieldStyle(.plain)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
                .padding(.horizontal)
                .padding(.bottom)
                
                // Document list
                List(selection: $selectedDocument) {
                    if !folders.isEmpty {
                        Section("Folders") {
                            ForEach(folders.filter { $0.parent == nil }) { folder in
                                FolderRowView(folder: folder, selectedDocument: $selectedDocument)
                            }
                        }
                    }
                    
                    Section("Documents") {
                        ForEach(filteredDocuments.filter { $0.folder == nil }) { document in
                            DocumentRowView(document: document)
                                .tag(document)
                        }
                        .onDelete(perform: deleteDocuments)
                    }
                }
                .listStyle(.sidebar)
            }
            .navigationTitle("Library")
            .toolbar {
                ToolbarItemGroup {
                    Menu {
                        Button("Import PDF...") {
                            showingImporter = true
                        }
                        
                        Button("New Folder...") {
                            showingNewFolderAlert = true
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        } detail: {
            if selectedDocument == nil {
                VStack(spacing: 16) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    
                    Text("Select a document to view")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    
                    Button("Import PDF") {
                        showingImporter = true
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .fileImporter(
            isPresented: $showingImporter,
            allowedContentTypes: [UTType.pdf],
            allowsMultipleSelection: true
        ) { result in
            Task {
                await importDocuments(result)
            }
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

#Preview {
    DocumentSidebar(selectedDocument: .constant(nil))
        .modelContainer(for: [Document.self, Folder.self], inMemory: true)
} 