//
//  DocumentRowView.swift
//  cerebral
//
//  Created by Justin Zweep on 26/06/2025.
//

import SwiftUI

struct DocumentRowView: View {
    let document: Document
    
    var body: some View {
        HStack {
            Image(systemName: "doc.fill")
                .foregroundColor(.red)
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(document.title)
                    .font(.headline)
                    .lineLimit(1)
                
                Text(document.dateAdded, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 2)
        .contextMenu {
            Button("Chat about this document") {
                NotificationCenter.default.post(name: .documentSelected, object: document)
            }
            
            Divider()
            
            Button("Reveal in Finder") {
                NSWorkspace.shared.activateFileViewerSelecting([document.filePath])
            }
            
            Divider()
            
            Button("Delete", role: .destructive) {
                // This will be handled by the parent view
            }
        }
    }
}

#Preview {
    let sampleDocument = Document(
        title: "Sample Document",
        filePath: URL(fileURLWithPath: "/path/to/sample.pdf")
    )
    
    return DocumentRowView(document: sampleDocument)
        .padding()
} 