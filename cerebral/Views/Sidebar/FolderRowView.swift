//
//  FolderRowView.swift
//  cerebral
//
//  Created by Justin Zweep on 26/06/2025.
//

import SwiftUI

struct FolderRowView: View {
    let folder: Folder
    @Binding var selectedDocument: Document?
    @State private var isExpanded: Bool = false
    
    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            // Child folders
            ForEach(folder.children) { childFolder in
                FolderRowView(folder: childFolder, selectedDocument: $selectedDocument)
                    .padding(.leading, 16)
            }
            
            // Documents in this folder
            ForEach(folder.documents) { document in
                DocumentRowView(document: document)
                    .tag(document)
                    .padding(.leading, 16)
                    .onTapGesture {
                        selectedDocument = document
                    }
            }
        } label: {
            HStack {
                Image(systemName: isExpanded ? "folder.fill" : "folder")
                    .foregroundColor(.blue)
                    .font(.title2)
                
                Text(folder.name)
                    .font(.headline)
                
                Spacer()
                
                if !folder.documents.isEmpty || !folder.children.isEmpty {
                    Text("\(folder.documents.count + folder.children.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(8)
                }
            }
        }
        .contextMenu {
            Button("New Subfolder...") {
                // TODO: Implement subfolder creation
            }
            
            Divider()
            
            Button("Delete Folder", role: .destructive) {
                // TODO: Implement folder deletion
            }
        }
    }
}

#Preview {
    let sampleFolder = Folder(name: "Sample Folder")
    
    return FolderRowView(folder: sampleFolder, selectedDocument: .constant(nil))
        .padding()
} 