//
//  ChatInputView.swift
//  cerebral
//
//  Created by Justin Zweep on 26/06/2025.
//

import SwiftUI

struct ChatInputView: View {
    @Binding var text: String
    let isLoading: Bool
    let onSend: () -> Void
    
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .bottom, spacing: 12) {
                // Text Input
                TextField("Ask anything...", text: $text, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .focused($isTextFieldFocused)
                    .lineLimit(1...6)
                    .onSubmit {
                        if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isLoading {
                            onSend()
                        }
                    }
                    .disabled(isLoading)
                
                // Send Button
                Button(action: onSend) {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                            .frame(width: 20, height: 20)
                    } else {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                            .foregroundColor(canSend ? .accentColor : .secondary)
                    }
                }
                .buttonStyle(.borderless)
                .disabled(!canSend || isLoading)
            }
            .padding()
        }
        .onAppear {
            isTextFieldFocused = true
        }
    }
    
    private var canSend: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

#Preview {
    VStack {
        Spacer()
        
        ChatInputView(
            text: .constant(""),
            isLoading: false
        ) {
            print("Send message")
        }
    }
    .frame(width: 300, height: 200)
} 