//
//  VectorSearchDemo.swift  
//  cerebral
//
//  Created on 27/11/2024.
//

import SwiftUI
import SwiftData

struct VectorSearchDemo: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var documents: [Document]
    @Query private var chatSessions: [ChatSession]
    
    @State private var selectedSession: ChatSession?
    @State private var searchQuery = ""
    @State private var searchResults: [DocumentChunk] = []
    @State private var isSearching = false
    @State private var selectedTab = 0
    @State private var testMessage = "What are the main topics discussed in the document?"
    @State private var contextMessage = ""
    @State private var isBuilding = false
    
    private let contextService = ContextManagementService.shared
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "magnifyingglass.circle.fill")
                        .font(.title)
                        .foregroundColor(DesignSystem.Colors.accent)
                    Text("Vector Search Demo")
                        .font(.title)
                        .fontWeight(.bold)
                    Spacer()
                }
                
                Text("Demonstrate context-aware vector search functionality")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.controlBackgroundColor))
            
            // Tab Picker
            Picker("Demo Sections", selection: $selectedTab) {
                Text("Process Documents").tag(0)
                Text("Search Context").tag(1)
                Text("Test Chat").tag(2)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            
            // Tab Content
            TabView(selection: $selectedTab) {
                // Tab 1: Document Processing
                DocumentProcessorDemo()
                    .tag(0)
                
                // Tab 2: Vector Search
                vectorSearchTab()
                    .tag(1)
                
                // Tab 3: Context Testing
                contextTestTab()
                    .tag(2)
            }
        }
    }
    
    @ViewBuilder
    private func vectorSearchTab() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Search Interface
            VStack(alignment: .leading, spacing: 8) {
                Text("Vector Search")
                    .font(.headline)
                
                Text("Search across all processed document chunks using semantic similarity")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack {
                    TextField("Enter search query...", text: $searchQuery)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button("Search") {
                        performVectorSearch()
                    }
                    .disabled(searchQuery.isEmpty || isSearching)
                    
                    if isSearching {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
            }
            
            // Search Results
            if !searchResults.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Search Results (\(searchResults.count))")
                        .font(.headline)
                    
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 8) {
                            ForEach(searchResults.indices, id: \.self) { index in
                                SearchResultCard(chunk: searchResults[index], rank: index + 1)
                            }
                        }
                    }
                }
            } else if searchQuery.isEmpty {
                Text("Enter a search query to find relevant document chunks")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            }
            
            Spacer()
        }
        .padding()
    }
    
    @ViewBuilder
    private func contextTestTab() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Session Selection
            VStack(alignment: .leading, spacing: 8) {
                Text("Test Context Building")
                    .font(.headline)
                
                Text("Test how context is built for chat messages using vector search")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if chatSessions.isEmpty {
                    Text("No chat sessions available. Create one in the first tab.")
                        .font(.caption)
                        .foregroundColor(DesignSystem.Colors.warning)
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
            
            if let session = selectedSession {
                // Context Panel
                VectorContextPanel(chatSession: session)
                
                // Test Message Input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Test Message")
                        .font(.headline)
                    
                    TextField("Enter a test message...", text: $testMessage, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(3)
                    
                    Button("Build Context") {
                        buildTestContext()
                    }
                    .disabled(testMessage.isEmpty || isBuilding)
                    
                    if isBuilding {
                        ProgressView("Building context...")
                            .font(.caption)
                    }
                }
                
                // Context Preview
                if !contextMessage.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Generated Context")
                            .font(.headline)
                        
                        ScrollView {
                            Text(contextMessage)
                                .font(.caption)
                                .textSelection(.enabled)
                                .padding()
                                .background(Color(.controlBackgroundColor))
                                .cornerRadius(8)
                        }
                        .frame(maxHeight: 200)
                    }
                }
            }
            
            Spacer()
        }
        .padding()
    }
    
    private func performVectorSearch() {
        guard !searchQuery.isEmpty else { return }
        
        isSearching = true
        
        Task {
            do {
                if let vectorService = contextService.currentVectorSearchService {
                    let results = try await vectorService.searchSimilar(to: searchQuery, limit: 10)
                    await MainActor.run {
                        searchResults = results
                        isSearching = false
                    }
                }
            } catch {
                await MainActor.run {
                    print("Search failed: \(error)")
                    isSearching = false
                }
            }
        }
    }
    
    private func buildTestContext() {
        guard let session = selectedSession else { return }
        
        isBuilding = true
        
        Task {
            do {
                let context = try await contextService.buildContextForMessage(
                    session: session,
                    userMessage: testMessage
                )
                await MainActor.run {
                    contextMessage = context
                    isBuilding = false
                }
            } catch {
                await MainActor.run {
                    contextMessage = "Error building context: \(error.localizedDescription)"
                    isBuilding = false
                }
            }
        }
    }
}

struct SearchResultCard: View {
    let chunk: DocumentChunk
    let rank: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Text("#\(rank)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(DesignSystem.Colors.accent)
                    .padding(4)
                    .background(DesignSystem.Colors.accentSecondary)
                    .cornerRadius(4)
                
                Text(chunk.document?.title ?? "Unknown Document")
                    .font(.caption)
                    .fontWeight(.medium)
                
                Spacer()
                
                if let pageNumber = chunk.primaryPageNumber {
                    Text("Page \(pageNumber)")
                        .font(.caption2)
                        .padding(2)
                        .background(DesignSystem.Colors.tertiaryBackground)
                        .cornerRadius(4)
                }
            }
            
            // Content
            Text(chunk.text)
                .font(.caption)
                .lineLimit(4)
                .multilineTextAlignment(.leading)
            
            // Metadata
            HStack {
                Text("Chunk: \(chunk.chunkId)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if !chunk.boundingBoxes.isEmpty {
                    Text("\(chunk.boundingBoxes.count) locations")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.controlColor))
        .cornerRadius(8)
    }
}

// Preview
struct VectorSearchDemo_Previews: PreviewProvider {
    static var previews: some View {
        VectorSearchDemo()
            .modelContainer(for: [Document.self, ChatSession.self, DocumentChunk.self])
    }
} 