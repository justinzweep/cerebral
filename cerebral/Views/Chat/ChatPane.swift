//
//  ChatPane.swift
//  cerebral
//
//  Created by Justin Zweep on 26/06/2025.
//

import SwiftUI

struct ChatPane: View {
    let selectedDocument: Document?
    
    var body: some View {
        ChatView(selectedDocument: selectedDocument)
    }
}

#Preview {
    ChatPane(selectedDocument: nil)
        .environmentObject(SettingsManager())
        .modelContainer(for: [Document.self, ChatSession.self], inMemory: true)
        .frame(width: 320, height: 600)
} 