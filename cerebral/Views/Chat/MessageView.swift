//
//  MessageView.swift
//  cerebral
//
//  Created by Justin Zweep on 26/06/2025.
//

import SwiftUI

struct MessageView: View {
    let message: ChatMessage
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if message.isUser {
                Spacer(minLength: 40)
                
                VStack(alignment: .trailing, spacing: 4) {
                    HStack {
                        Text(message.text)
                            .font(.body)
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color.accentColor)
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                    }
                    
                    Text(message.timestamp, style: .time)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                // User Avatar
                Circle()
                    .fill(Color.blue)
                    .frame(width: 32, height: 32)
                    .overlay {
                        Image(systemName: "person.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 16))
                    }
            } else {
                // AI Avatar
                Circle()
                    .fill(Color.purple)
                    .frame(width: 32, height: 32)
                    .overlay {
                        Image(systemName: "brain.head.profile")
                            .foregroundColor(.white)
                            .font(.system(size: 16))
                    }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(message.text)
                            .font(.body)
                            .foregroundColor(.primary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color(NSColor.controlBackgroundColor))
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                    }
                    
                    HStack {
                        Text(message.timestamp, style: .time)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        if !message.documentReferences.isEmpty {
                            Image(systemName: "doc.text")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer(minLength: 40)
            }
        }
        .contextMenu {
            Button("Copy Message") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(message.text, forType: .string)
            }
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        MessageView(message: ChatMessage(
            text: "Hello, how can I help you with your documents today?",
            isUser: false
        ))
        
        MessageView(message: ChatMessage(
            text: "Can you help me understand this PDF?",
            isUser: true
        ))
    }
    .padding()
} 