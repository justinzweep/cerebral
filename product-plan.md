# Cerebral - Implementation Guide

## Project Overview
Build **Cerebral**, a native macOS application combining PDF reading with AI-powered chat using Claude API. Features: PDF viewing, annotations, document management, and AI chat assistance.

## Project Setup

### Xcode Configuration
```
- New macOS App project
- Target: macOS 14.0+
- Language: Swift
- UI Framework: SwiftUI
```

### Dependencies (Swift Package Manager)
```
✅ NO EXTERNAL DEPENDENCIES REQUIRED!
Native URLSession implementation for Claude API integration.
```

### Required Frameworks
- SwiftUI, SwiftData, PDFKit, Foundation, AppKit

## File Structure

```
Cerebral/
├── App/
│   ├── CerebralApp.swift
│   └── ContentView.swift
├── Models/
│   ├── Document.swift
│   ├── Annotation.swift
│   ├── ChatSession.swift
│   └── Folder.swift
├── Views/
│   ├── PDF/
│   │   ├── PDFViewerView.swift
│   │   ├── PDFViewerRepresentable.swift
│   │   └── AnnotationToolbar.swift
│   ├── Sidebar/
│   │   ├── DocumentSidebar.swift
│   │   └── FolderTreeView.swift
│   ├── Chat/
│   │   ├── ChatView.swift
│   │   ├── MessageView.swift
│   │   └── ChatInputView.swift
│   ├── Settings/
│   │   ├── SettingsView.swift
│   │   └── APIKeySettingsView.swift
│   └── Common/
│       ├── TabView.swift
│       └── SplitView.swift
├── ViewModels/
│   ├── DocumentManager.swift
│   ├── AnnotationManager.swift
│   └── ChatManager.swift
├── Services/
│   ├── ClaudeAPIService.swift
│   ├── DocumentService.swift
│   ├── KeychainService.swift
│   └── SettingsManager.swift
└── Resources/
    ├── SamplePDFs/
    └── Assets.xcassets
```

## SwiftData Models

```swift
// Models/Document.swift
import SwiftData
import Foundation

@Model
class Document {
    @Attribute(.unique) var id: UUID = UUID()
    var title: String = ""
    var filePath: URL
    var dateAdded: Date = Date()
    var lastOpened: Date?
    
    var folder: Folder?
    @Relationship(deleteRule: .cascade) var annotations: [Annotation] = []
    @Relationship var chatSessions: [ChatSession] = []
    
    init(title: String, filePath: URL, folder: Folder? = nil) {
        self.title = title
        self.filePath = filePath
        self.folder = folder
    }
}

// Models/Annotation.swift
@Model
class Annotation {
    @Attribute(.unique) var id: UUID = UUID()
    var type: AnnotationType = .highlight
    var color: String?
    var text: String?
    var pageNumber: Int = 0
    var boundsX: Double = 0
    var boundsY: Double = 0
    var boundsWidth: Double = 0
    var boundsHeight: Double = 0
    var document: Document?
    
    init(type: AnnotationType, pageNumber: Int, bounds: CGRect, document: Document) {
        self.type = type
        self.pageNumber = pageNumber
        self.boundsX = bounds.origin.x
        self.boundsY = bounds.origin.y
        self.boundsWidth = bounds.width
        self.boundsHeight = bounds.height
        self.document = document
    }
    
    var bounds: CGRect {
        CGRect(x: boundsX, y: boundsY, width: boundsWidth, height: boundsHeight)
    }
}

enum AnnotationType: String, Codable, CaseIterable {
    case highlight = "highlight"
    case note = "note"
}

// Models/ChatSession.swift
@Model
class ChatSession {
    @Attribute(.unique) var id: UUID = UUID()
    var title: String = ""
    var createdAt: Date = Date()
    @Attribute(.externalStorage) var messagesData: Data = Data()
    @Relationship var documentReferences: [Document] = []
    
    init(title: String) {
        self.title = title
    }
    
    var messages: [ChatMessage] {
        get {
            (try? JSONDecoder().decode([ChatMessage].self, from: messagesData)) ?? []
        }
        set {
            messagesData = (try? JSONEncoder().encode(newValue)) ?? Data()
        }
    }
}

struct ChatMessage: Codable, Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool
    let timestamp: Date
    let documentReferences: [UUID]
}

// Models/Folder.swift
@Model
class Folder {
    @Attribute(.unique) var id: UUID = UUID()
    var name: String = ""
    var createdAt: Date = Date()
    var parent: Folder?
    @Relationship(deleteRule: .cascade) var children: [Folder] = []
    @Relationship var documents: [Document] = []
    
    init(name: String, parent: Folder? = nil) {
        self.name = name
        self.parent = parent
    }
}
```

## Implementation Phases

### PHASE 1: Basic App Structure

```swift
// CerebralApp.swift
import SwiftUI
import SwiftData

@main
struct CerebralApp: App {
    @StateObject private var settingsManager = SettingsManager()
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([Document.self, Annotation.self, ChatSession.self, Folder.self])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(settingsManager)
        }
        .modelContainer(sharedModelContainer)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Import PDF...") { }
                    .keyboardShortcut("o")
            }
            CommandGroup(after: .appInfo) {
                Button("Preferences...") {
                    NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
                }
                .keyboardShortcut(",")
            }
        }
        
        Settings {
            SettingsView()
                .environmentObject(settingsManager)
        }
    }
}

// ContentView.swift
struct ContentView: View {
    @State private var showingChat = true
    @EnvironmentObject var settingsManager: SettingsManager
    
    var body: some View {
        HSplitView {
            DocumentSidebar()
                .frame(minWidth: 200, idealWidth: 250, maxWidth: 300)
            
            PDFViewerView()
                .frame(minWidth: 400)
            
            if showingChat {
                ChatView()
                    .frame(minWidth: 250, idealWidth: 300, maxWidth: 400)
                    .environmentObject(settingsManager)
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showingChat.toggle() }) {
                    Image(systemName: "message")
                }
            }
        }
    }
}
```

### PHASE 2: Settings & API Key Management

```swift
// Services/KeychainService.swift
import Foundation
import Security

class KeychainService {
    static let shared = KeychainService()
    private let service = "com.yourcompany.cerebral"
    
    private init() {}
    
    func saveAPIKey(_ key: String) throws {
        let data = key.data(using: .utf8)!
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: "claude_api_key",
            kSecValueData as String: data
        ]
        
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else { throw KeychainError.unableToSave }
    }
    
    func getAPIKey() throws -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: "claude_api_key",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess else {
            return status == errSecItemNotFound ? nil : nil
        }
        
        guard let data = result as? Data,
              let key = String(data: data, encoding: .utf8) else {
            throw KeychainError.invalidData
        }
        
        return key
    }
}

enum KeychainError: LocalizedError {
    case unableToSave, unableToRetrieve, invalidData
    
    var errorDescription: String? {
        switch self {
        case .unableToSave: return "Unable to save API key"
        case .unableToRetrieve: return "Unable to retrieve API key"
        case .invalidData: return "Invalid data retrieved"
        }
    }
}

// Services/SettingsManager.swift
import Foundation

@MainActor
class SettingsManager: ObservableObject {
    @Published var apiKey: String = ""
    @Published var isAPIKeyValid: Bool = false
    private let keychainService = KeychainService.shared
    
    init() {
        loadAPIKey()
    }
    
    func loadAPIKey() {
        do {
            if let key = try keychainService.getAPIKey() {
                apiKey = key
                isAPIKeyValid = !key.isEmpty
            }
        } catch {
            print("Error loading API key: \(error)")
        }
    }
    
    func saveAPIKey(_ key: String) {
        do {
            try keychainService.saveAPIKey(key)
            apiKey = key
            isAPIKeyValid = !key.isEmpty
        } catch {
            print("Error saving API key: \(error)")
        }
    }
    
    func validateAPIKey(_ key: String) -> Bool {
        return key.hasPrefix("sk-ant-") && key.count > 20
    }
}

// Views/Settings/SettingsView.swift
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    
    var body: some View {
        TabView {
            APIKeySettingsView()
                .tabItem {
                    Label("API Key", systemImage: "key.fill")
                }
                .environmentObject(settingsManager)
        }
        .frame(width: 500, height: 400)
    }
}

// Views/Settings/APIKeySettingsView.swift
struct APIKeySettingsView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @State private var tempAPIKey: String = ""
    @State private var isEditing: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Claude API Configuration")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Enter your Anthropic Claude API key to enable AI chat functionality.")
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("API Key").fontWeight(.medium)
                
                HStack {
                    if isEditing {
                        SecureField("sk-ant-...", text: $tempAPIKey)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(.body, design: .monospaced))
                    } else {
                        HStack {
                            Text(settingsManager.apiKey.isEmpty ? "No API key set" : "••••••••••••••••••••")
                                .foregroundColor(settingsManager.apiKey.isEmpty ? .secondary : .primary)
                                .font(.system(.body, design: .monospaced))
                            Spacer()
                            if settingsManager.isAPIKeyValid {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(6)
                    }
                    
                    if isEditing {
                        Button("Save") {
                            if settingsManager.validateAPIKey(tempAPIKey) {
                                settingsManager.saveAPIKey(tempAPIKey)
                                isEditing = false
                            }
                        }
                        .disabled(!settingsManager.validateAPIKey(tempAPIKey))
                        
                        Button("Cancel") {
                            tempAPIKey = settingsManager.apiKey
                            isEditing = false
                        }
                    } else {
                        Button(settingsManager.apiKey.isEmpty ? "Add" : "Edit") {
                            tempAPIKey = settingsManager.apiKey
                            isEditing = true
                        }
                    }
                }
            }
            
            if isEditing && !settingsManager.validateAPIKey(tempAPIKey) && !tempAPIKey.isEmpty {
                Text("Invalid API key format. Claude API keys should start with 'sk-ant-'")
                    .foregroundColor(.red)
                    .font(.caption)
            }
            
            Spacer()
        }
        .padding(20)
        .onAppear {
            tempAPIKey = settingsManager.apiKey
        }
    }
}
```

### PHASE 3: PDF Viewer

```swift
// Views/PDF/PDFViewerRepresentable.swift
import SwiftUI
import PDFKit

struct PDFViewerRepresentable: NSViewRepresentable {
    let document: PDFDocument?
    @Binding var currentPage: Int
    @Binding var selectedText: String?
    
    func makeNSView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displaysPageBreaks = true
        return pdfView
    }
    
    func updateNSView(_ nsView: PDFView, context: Context) {
        if nsView.document !== document {
            nsView.document = document
        }
    }
}

// Views/Sidebar/DocumentSidebar.swift
import SwiftData

struct DocumentSidebar: View {
    @Query(sort: \Document.title) private var documents: [Document]
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        NavigationView {
            List {
                Section("Library") {
                    ForEach(documents) { document in
                        DocumentRowView(document: document)
                    }
                }
            }
            .navigationTitle("Documents")
            .toolbar {
                ToolbarItem {
                    Button("Import") {
                        // Show file picker
                    }
                }
            }
        }
    }
}
```

### PHASE 4: Claude API Integration

```swift
// Services/ClaudeAPIService.swift
import Foundation

@MainActor
class ClaudeAPIService: ObservableObject {
    private let settingsManager: SettingsManager
    private let baseURL = "https://api.anthropic.com"
    private let apiVersion = "2023-06-01"
    
    init(settingsManager: SettingsManager) {
        self.settingsManager = settingsManager
    }
    
    func sendMessage(_ message: String, context: [Document] = []) async throws -> String {
        guard !settingsManager.apiKey.isEmpty else {
            throw APIError.noAPIKey
        }
        
        let requestBody = ClaudeRequest(
            model: "claude-3-5-sonnet-20241022",
            maxTokens: 1000,
            messages: [ClaudeMessage(role: "user", content: message)]
        )
        
        let response = try await performAPIRequest(requestBody)
        return extractTextFromResponse(response)
    }
    
    private func performAPIRequest(_ requestBody: ClaudeRequest) async throws -> ClaudeResponse {
        // Native URLSession implementation for Claude API
        // See full implementation in actual ClaudeAPIService.swift file
        guard let url = URL(string: "\(baseURL)/v1/messages") else {
            throw APIError.requestFailed("Invalid API URL")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(settingsManager.apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue(apiVersion, forHTTPHeaderField: "anthropic-version")
        
        let jsonData = try JSONEncoder().encode(requestBody)
        request.httpBody = jsonData
        
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(ClaudeResponse.self, from: data)
    }
}

enum APIError: LocalizedError {
    case noAPIKey, invalidResponse
    
    var errorDescription: String? {
        switch self {
        case .noAPIKey: return "No API key configured. Please add your Claude API key in Settings."
        case .invalidResponse: return "Invalid response from Claude API"
        }
    }
}

// Views/Chat/ChatView.swift
struct ChatView: View {
    @StateObject private var chatManager = ChatManager()
    @EnvironmentObject var settingsManager: SettingsManager
    @State private var inputText = ""
    @State private var showingSettings = false
    
    var body: some View {
        VStack {
            if settingsManager.isAPIKeyValid {
                ScrollView {
                    LazyVStack {
                        ForEach(chatManager.messages) { message in
                            MessageView(message: message)
                        }
                    }
                }
                
                ChatInputView(text: $inputText) {
                    Task {
                        await chatManager.sendMessage(inputText, apiService: ClaudeAPIService(settingsManager: settingsManager))
                        inputText = ""
                    }
                }
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "key.slash")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    
                    Text("Claude API Key Required")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Configure your Claude API key in Settings to use AI chat.")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                    
                    Button("Open Settings") {
                        showingSettings = true
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            }
        }
        .navigationTitle("Chat")
        .sheet(isPresented: $showingSettings) {
            SettingsView()
                .environmentObject(settingsManager)
        }
    }
}
```

## Implementation Order

1. **Phase 1**: Basic app structure and three-panel layout
2. **Phase 2**: Settings page with secure API key management
3. **Phase 3**: PDF viewer and document management
4. **Phase 4**: Claude API integration and chat interface
5. **Phase 5**: Annotation system (highlighting and notes)

## Key Requirements

- **macOS 14.0+** target
- **SwiftData** for all data persistence
- **Native Security framework** for Keychain (no third-party dependencies)
- **Three-panel layout**: Documents | PDF Viewer | Chat
- **Settings accessible** via ⌘, shortcut
- **API key validation** with real-time feedback