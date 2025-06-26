//
//  ChatView.swift
//  cerebral
//
//  Created by Justin Zweep on 26/06/2025.
//

import SwiftUI

struct ChatView: View {
    @StateObject private var chatManager = ChatManager()
    @EnvironmentObject var settingsManager: SettingsManager
    @State private var inputText = ""
    @State private var showingSettings = false
    @State private var selectedDocument: Document?
    @State private var isTestingConnection = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Chat Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("AI Assistant")
                        .font(.headline)
                    
                    HStack(spacing: 4) {
                        Circle()
                            .fill(connectionStatusColor)
                            .frame(width: 8, height: 8)
                        
                        Text(connectionStatusText)
                            .font(.caption)
                            .foregroundColor(connectionStatusColor)
                    }
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    if selectedDocument != nil {
                        Button {
                            selectedDocument = nil
                            chatManager.clearDocumentContext()
                        } label: {
                            Image(systemName: "doc.badge.minus")
                        }
                        .buttonStyle(.borderless)
                        .help("Clear document context")
                    }
                    
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gear")
                    }
                    .buttonStyle(.borderless)
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            
            // Document Context Banner
            if let document = selectedDocument {
                HStack {
                    Image(systemName: "doc.fill")
                        .foregroundColor(.blue)
                    
                    Text("Discussing: \(document.title)")
                        .font(.caption)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Button {
                        selectedDocument = nil
                        chatManager.clearDocumentContext()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.borderless)
                }
                .padding(.horizontal)
                .padding(.vertical, 6)
                .background(Color.blue.opacity(0.1))
            }
            
            Divider()
            
            if settingsManager.isAPIKeyValid {
                // Chat Messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            if chatManager.messages.isEmpty {
                                VStack(spacing: 16) {
                                    Image(systemName: "bubble.left.and.bubble.right")
                                        .font(.system(size: 48))
                                        .foregroundColor(.secondary)
                                    
                                    Text("Start a conversation")
                                        .font(.title3)
                                        .fontWeight(.medium)
                                    
                                    Text(selectedDocument == nil ? 
                                         "Ask me anything about your documents or any topic you'd like to discuss." :
                                         "Ask me questions about '\(selectedDocument!.title)' or anything else you'd like to know.")
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                }
                                .padding(.top, 50)
                            } else {
                                ForEach(chatManager.messages) { message in
                                    MessageView(message: message)
                                        .id(message.id)
                                }
                            }
                        }
                        .padding()
                    }
                    .onChange(of: chatManager.messages.count) { _, _ in
                        if let lastMessage = chatManager.messages.last {
                            withAnimation {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }
                
                Divider()
                
                // Chat Input
                ChatInputView(
                    text: $inputText,
                    isLoading: chatManager.isLoading
                ) {
                    Task {
                        await chatManager.sendMessage(
                            inputText, 
                            settingsManager: settingsManager,
                            documentContext: selectedDocument != nil ? [selectedDocument!] : []
                        )
                        inputText = ""
                    }
                }
                .disabled(!settingsManager.isAPIKeyValid)
            } else {
                // API Key Required State
                VStack(spacing: 16) {
                    Image(systemName: "key.slash")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    
                    Text("Claude API Key Required")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Configure your Claude API key in Settings to use AI chat functionality.")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                    
                    VStack(spacing: 8) {
                        Button("Open Settings") {
                            showingSettings = true
                        }
                        .buttonStyle(.borderedProminent)
                        
                        if isTestingConnection {
                            ProgressView("Testing connection...")
                                .font(.caption)
                        }
                    }
                }
                .padding()
                .frame(maxHeight: .infinity)
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
                .environmentObject(settingsManager)
        }
        .onReceive(NotificationCenter.default.publisher(for: .documentSelected)) { notification in
            if let document = notification.object as? Document {
                selectedDocument = document
                chatManager.startNewConversation(with: document)
            }
        }
        .onAppear {
            if settingsManager.isAPIKeyValid {
                Task {
                    isTestingConnection = true
                    _ = await chatManager.validateAPIConnection(settingsManager: settingsManager)
                    isTestingConnection = false
                }
            }
        }
    }
    
    private var connectionStatusColor: Color {
        if isTestingConnection {
            return .orange
        } else if settingsManager.isAPIKeyValid {
            return .green
        } else {
            return .red
        }
    }
    
    private var connectionStatusText: String {
        if isTestingConnection {
            return "Testing connection..."
        } else if settingsManager.isAPIKeyValid {
            return "Claude API Connected"
        } else {
            return "API Key Required"
        }
    }
}

// Notification for document selection
extension Notification.Name {
    static let documentSelected = Notification.Name("documentSelected")
}

#Preview {
    ChatView()
        .environmentObject(SettingsManager())
        .frame(width: 300, height: 600)
} 