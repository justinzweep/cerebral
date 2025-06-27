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
    let attachedDocuments: [Document]
    let onSend: () -> Void
    let onRemoveDocument: (Document) -> Void
    
    @FocusState private var isTextFieldFocused: Bool
    @State private var isHovered = false
    
    private let maxHeight: CGFloat = 120
    private let minHeight: CGFloat = 66 // Height for 2 lines of text
    
    init(
        text: Binding<String>,
        isLoading: Bool,
        attachedDocuments: [Document] = [],
        onSend: @escaping () -> Void,
        onRemoveDocument: @escaping (Document) -> Void = { _ in }
    ) {
        self._text = text
        self.isLoading = isLoading
        self.attachedDocuments = attachedDocuments
        self.onSend = onSend
        self.onRemoveDocument = onRemoveDocument
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // Attachment preview area
            if !attachedDocuments.isEmpty {
                AttachmentPreviewView(
                    documents: attachedDocuments,
                    onRemove: onRemoveDocument
                )
                .padding(.horizontal, 16)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
            
            // Input container with integrated send button
            HStack(spacing: 0) {
                // Integrated text field with send button
                ZStack(alignment: .trailing) {
                    // Text input
                    TextField("Message...", text: $text, axis: .vertical)
                        .textFieldStyle(.plain)
                        .background(Color.clear)
                        .font(.system(size: 16))
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                        .focused($isTextFieldFocused)
                        .padding(.leading, 16)
                        .padding(.trailing, 48) // Make room for send button
                        .padding(.vertical, 12)
                        .frame(minHeight: minHeight)
                        .background(
                            RoundedRectangle(cornerRadius: 22)
                                .fill(DesignSystem.Colors.background)
                                .stroke(
                                    isTextFieldFocused ? DesignSystem.Colors.accent.opacity(0.5) : DesignSystem.Colors.border.opacity(0.3),
                                    lineWidth: 1
                                )
                        )
                        .animation(.easeInOut(duration: 0.2), value: isTextFieldFocused)
                        .onSubmit {
                            if canSend && !isLoading {
                                onSend()
                            }
                        }
                        .disabled(isLoading)
                        .accessibilityLabel("Message input")
                    
                    // Send button positioned inside text field
                    Button(action: onSend) {
                        ZStack {
                            if isLoading {
                                ProgressView()
                                    .scaleEffect(0.7)
                                    .tint(DesignSystem.Colors.accent)
                            } else {
                                Image(systemName: "arrow.up")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(canSend && !isLoading ? DesignSystem.Colors.accent : DesignSystem.Colors.textTertiary.opacity(0.3))
                        )
                        .scaleEffect(canSend && !isLoading ? 1.0 : 0.9)
                        .animation(.easeInOut(duration: 0.15), value: canSend)
                        .animation(.easeInOut(duration: 0.15), value: isLoading)
                    }
                    .buttonStyle(.plain)
                    .disabled(!canSend || isLoading)
                    .accessibilityLabel(isLoading ? "Sending" : "Send message")
                    .keyboardShortcut(.return, modifiers: [])
                    .padding(.trailing, 8) // Position inside the text field
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
//        .background(Color.clear) // Ensure transparent background
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isTextFieldFocused = true
            }
        }
        .animation(.easeInOut(duration: 0.2), value: attachedDocuments.count)
    }
    
    private var canSend: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

// MARK: - Attachment Preview

struct AttachmentPreviewView: View {
    let documents: [Document]
    let onRemove: (Document) -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(documents, id: \.id) { document in
                    AttachmentPillView(document: document) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            onRemove(document)
                        }
                    }
                }
            }
            .padding(.horizontal, 4)
        }
        .frame(height: 32)
    }
}

struct AttachmentPillView: View {
    let document: Document
    let onRemove: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 6) {
            // Document icon
            Image(systemName: "doc.text")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(DesignSystem.Colors.accent)
            
            // Document title
            Text(document.title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(DesignSystem.Colors.textPrimary)
                .lineLimit(1)
                .truncationMode(.middle)
            
            // Remove button
            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
            .buttonStyle(.plain)
            .frame(width: 14, height: 14)
            .contentShape(Circle())
            .accessibilityLabel("Remove \(document.title)")
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(DesignSystem.Colors.background)
                .stroke(DesignSystem.Colors.border.opacity(0.3), lineWidth: 1)
        )
        .scaleEffect(isHovered ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isHovered)
        .onHover { isHovered = $0 }
    }
}

#Preview {
    VStack {
        Spacer()
        
        ChatInputView(
            text: .constant(""),
            isLoading: false,
            attachedDocuments: [
                Document(title: "Sample Document.pdf", filePath: URL(fileURLWithPath: "/path/to/document.pdf")),
                Document(title: "Research Paper.pdf", filePath: URL(fileURLWithPath: "/path/to/research.pdf"))
            ]
        ) {
            print("Send message")
        } onRemoveDocument: { document in
            print("Remove document: \(document.title)")
        }
    }
    .frame(width: 600, height: 400)
    .background(Color(NSColor.windowBackgroundColor))
}
