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
                                .padding(.leading, DesignSystem.Spacing.md)
            .padding(.trailing, DesignSystem.Spacing.xxl)
            .padding(.vertical, DesignSystem.Spacing.sm)
            }
            
            // Actual text field (single line behavior, no multiline)
            TextField("Message...", text: $text)
                .textFieldStyle(.plain)
                .background(Color.clear)
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.primaryText)
                .focused($isFocused)
                .padding(.leading, DesignSystem.Spacing.md)
                .padding(.trailing, DesignSystem.Spacing.xxl) // Make room for send button
                .padding(.vertical, DesignSystem.Spacing.sm)
                .onSubmit {
                    // Call the submit handler when Enter is pressed
                    print("🚨 TextField onSubmit TRIGGERED")
                    print("   - isFocused: \(isFocused)")
                    print("   - isDisabled: \(isDisabled)")
                    print("   - text: '\(text)'")
                    onSubmit()
                }
                .onChange(of: text) { _, newValue in
                    onTextChange(newValue)
                }
                .disabled(isDisabled)
                .onKeyPress(.return) { 
                    print("🔴 ENTER KEY DETECTED in TextField")
                    print("   - isFocused: \(isFocused)")
                    print("   - isDisabled: \(isDisabled)")
                    return .ignored  // Let TextField handle it normally
                }
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
                    .animation(DesignSystem.Animation.quick, value: isFocused)
        .onAppear {
            print("🎯 ChatTextEditor onAppear - auto-focusing")
            // Auto-focus when the component appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isFocused = true
                print("✅ ChatTextEditor focus set to true")
            }
        }
        .onChange(of: shouldFocus) { _, newValue in
            print("🔄 shouldFocus changed to: \(newValue)")
            if newValue {
                isFocused = true
                shouldFocus = false
                print("✅ Focus triggered externally")
            }
        }
        .onChange(of: isFocused) { _, newValue in
            print("🎯 TextField focus changed to: \(newValue)")
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
