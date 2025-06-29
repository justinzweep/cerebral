//
//  DocumentProcessorDemo.swift
//  cerebral  
//
//  Created on 27/11/2024.
//

import SwiftUI
import SwiftData

struct DocumentProcessorDemo: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var documents: [Document]  
    @Query private var chatSessions: [ChatSession]
    
    @State private var selectedDocuments: Set<UUID> = []
    @State private var selectedSession: ChatSession?
    @State private var isProcessing = false
    @State private var processingResults: [ProcessingResult] = []
    @State private var showingResults = false
    
    private let contextService = ContextManagementService.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "gearshape.2")
                    .foregroundColor(.blue)
                Text("Vector Search Demo")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            // Instructions
            Text("Add documents to a chat session for vector search context. Documents will be processed by the API to create searchable embeddings.")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding()
                .background(Color(.controlBackgroundColor))
                .cornerRadius(8)
            
            // Document Selection
            VStack(alignment: .leading, spacing: 8) {
                Text("Select Documents to Process:")
                    .font(.headline)
                
                if documents.isEmpty {
                    Text("No documents available. Import some PDFs first.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .italic()
                } else {
                    LazyVStack(alignment: .leading, spacing: 4) {
                        ForEach(documents, id: \.id) { document in
                            DocumentSelectionRow(
                                document: document,
                                isSelected: selectedDocuments.contains(document.id),
                                onToggle: { 
                                    if selectedDocuments.contains(document.id) {
                                        selectedDocuments.remove(document.id)
                                    } else {
                                        selectedDocuments.insert(document.id)
                                    }
                                }
                            )
                        }
                    }
                }
            }
            
            // Chat Session Selection
            VStack(alignment: .leading, spacing: 8) {
                Text("Select Chat Session:")
                    .font(.headline)
                
                if chatSessions.isEmpty {
                    HStack {
                        Text("No chat sessions available.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Button("Create New Session") {
                            createNewChatSession()
                        }
                        .font(.caption)
                    }
                } else {
                    Picker("Chat Session", selection: $selectedSession) {
                        Text("Select Session").tag(nil as ChatSession?)
                        ForEach(chatSessions, id: \.id) { session in
                            Text(session.title).tag(session as ChatSession?)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
            }
            
            // Action Buttons
            HStack {
                Button("Process Selected Documents") {
                    processSelectedDocuments()
                }
                .disabled(selectedDocuments.isEmpty || selectedSession == nil || isProcessing)
                
                if !processingResults.isEmpty {
                    Button("Show Results") {
                        showingResults = true
                    }
                }
                
                Spacer()
                
                if isProcessing {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            
            Spacer()
        }
        .padding()
        .sheet(isPresented: $showingResults) {
            ProcessingResultsView(results: processingResults)
        }
    }
    
    private func createNewChatSession() {
        let newSession = ChatSession(title: "Vector Search Demo \(Date().formatted(date: .abbreviated, time: .shortened))")
        modelContext.insert(newSession)
        selectedSession = newSession
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to create chat session: \(error)")
        }
    }
    
    private func processSelectedDocuments() {
        guard let session = selectedSession else { return }
        
        isProcessing = true
        processingResults.removeAll()
        
        Task {
            for documentId in selectedDocuments {
                guard let document = documents.first(where: { $0.id == documentId }) else { continue }
                
                do {
                    let startTime = Date()
                    try await contextService.addDocumentToContext(document, for: session)
                    let endTime = Date()
                    
                    let result = ProcessingResult(
                        documentTitle: document.title,
                        success: true,
                        processingTime: endTime.timeIntervalSince(startTime),
                        chunksCreated: document.totalChunks,
                        error: nil
                    )
                    await MainActor.run {
                        processingResults.append(result)
                    }
                    
                } catch {
                    let result = ProcessingResult(
                        documentTitle: document.title,
                        success: false,
                        processingTime: 0,
                        chunksCreated: 0,
                        error: error.localizedDescription
                    )
                    await MainActor.run {
                        processingResults.append(result)
                    }
                }
            }
            
            await MainActor.run {
                isProcessing = false
                showingResults = true
            }
        }
    }
}

struct DocumentSelectionRow: View {
    let document: Document
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        HStack {
            Button(action: onToggle) {
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .foregroundColor(isSelected ? .blue : .secondary)
            }
            .buttonStyle(PlainButtonStyle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text(document.title)
                    .font(.caption)
                    .fontWeight(.medium)
                
                HStack {
                    ProcessingStatusBadge(status: document.processingStatus)
                    
                    if document.totalChunks > 0 {
                        Text("\(document.totalChunks) chunks")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
            }
            
            Spacer()
        }
        .padding(4)
        .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
        .cornerRadius(4)
        .contentShape(Rectangle())
        .onTapGesture(perform: onToggle)
    }
}

struct ProcessingResult {
    let documentTitle: String
    let success: Bool
    let processingTime: TimeInterval
    let chunksCreated: Int
    let error: String?
}

struct ProcessingResultsView: View {
    let results: [ProcessingResult]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List(results.indices, id: \.self) { index in
                let result = results[index]
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(result.documentTitle)
                            .font(.headline)
                        
                        Spacer()
                        
                        Image(systemName: result.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(result.success ? .green : .red)
                    }
                    
                    if result.success {
                        Text("Processing Time: \(String(format: "%.2f", result.processingTime))s")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("Chunks Created: \(result.chunksCreated)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else if let error = result.error {
                        Text("Error: \(error)")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                .padding(.vertical, 4)
            }
            .navigationTitle("Processing Results")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
} 