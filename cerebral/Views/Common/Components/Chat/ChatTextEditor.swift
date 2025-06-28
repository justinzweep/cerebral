//
//  ChatTextEditor.swift
//  cerebral
//
//  Reusable Chat Text Editor Component
//

import SwiftUI

struct ChatTextEditor: View {
    @Binding var text: String
    @FocusState private var isFocused: Bool
    @State private var appState = ServiceContainer.shared.appState
    @Binding var shouldFocus: Bool
    let isDisabled: Bool
    let onSubmit: () -> Void
    let onTextChange: (String) -> Void
    
    private let minHeight: CGFloat = 66
    
    init(
        text: Binding<String>,
        isDisabled: Bool = false,
        shouldFocus: Binding<Bool> = .constant(false),
        onSubmit: @escaping () -> Void = {},
        onTextChange: @escaping (String) -> Void = { _ in }
    ) {
        self._text = text
        self.isDisabled = isDisabled
        self._shouldFocus = shouldFocus
        self.onSubmit = onSubmit
        self.onTextChange = onTextChange
    }
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            // Highlight overlay ONLY when text contains @ symbol
            if text.contains("@") {
                HighlightOverlay(text: text)
                    .allowsHitTesting(false)
                    .padding(.leading, 16)
                    .padding(.trailing, 48)
                    .padding(.vertical, 12)
            }
            
            // Actual text field (normal colors)
            TextField("Message...", text: $text, axis: .vertical)
                .textFieldStyle(.plain)
                .background(Color.clear)
                .font(.system(size: 16))
                .foregroundColor(DesignSystem.Colors.primaryText)
                .focused($isFocused)
                .padding(.leading, 16)
                .padding(.trailing, 48) // Make room for send button
                .padding(.vertical, 12)
                .onSubmit(onSubmit)
                .onChange(of: text) { _, newValue in
                    onTextChange(newValue)
                }
                .disabled(isDisabled)
        }
        .frame(minHeight: minHeight)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(DesignSystem.Colors.background)
                .stroke(
                    isFocused ? DesignSystem.Colors.accent.opacity(0.5) : DesignSystem.Colors.border.opacity(0.3),
                    lineWidth: 1
                )
        )
        .animation(.easeInOut(duration: 0.2), value: isFocused)
        .onAppear {
            // Auto-focus when the component appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isFocused = true
            }
        }
        .onChange(of: shouldFocus) { _, newValue in
            if newValue {
                isFocused = true
                shouldFocus = false
            }
        }
    }
}

#Preview {
    @State var text = "Hello @document.pdf"
    
    VStack {
        ChatTextEditor(
            text: $text
        ) {
            print("Submit")
        } onTextChange: { newText in
            print("Text changed: \(newText)")
        }
        .padding()
    }
} 
