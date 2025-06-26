import SwiftUI

struct AnnotationToolbar: View {
    @ObservedObject var annotationManager: AnnotationManager
    @State private var showingNoteDialog = false
    @State private var noteText = ""
    
    var body: some View {
        HStack(spacing: 12) {
            // Annotation mode toggle
            Button(action: {
                annotationManager.isAnnotationMode.toggle()
                if !annotationManager.isAnnotationMode {
                    annotationManager.deselectAnnotation()
                }
            }) {
                Image(systemName: annotationManager.isAnnotationMode ? "pencil.circle.fill" : "pencil.circle")
                    .font(.title2)
                    .foregroundColor(annotationManager.isAnnotationMode ? .accentColor : .secondary)
            }
            .help("Toggle annotation mode")
            
            if annotationManager.isAnnotationMode {
                Divider()
                    .frame(height: 20)
                
                // Annotation tool selection
                HStack(spacing: 8) {
                    Button(action: {
                        annotationManager.selectedAnnotationTool = .highlight
                    }) {
                        Image(systemName: "highlighter")
                            .font(.title3)
                            .foregroundColor(annotationManager.selectedAnnotationTool == .highlight ? .accentColor : .secondary)
                    }
                    .help("Highlight tool")
                    
                    Button(action: {
                        annotationManager.selectedAnnotationTool = .note
                    }) {
                        Image(systemName: "note.text")
                            .font(.title3)
                            .foregroundColor(annotationManager.selectedAnnotationTool == .note ? .accentColor : .secondary)
                    }
                    .help("Note tool")
                }
                
                Divider()
                    .frame(height: 20)
                
                // Color selection
                HStack(spacing: 4) {
                    ForEach(Array(annotationManager.annotationColors.enumerated()), id: \.offset) { index, color in
                        Button(action: {
                            annotationManager.selectedColor = color
                        }) {
                            Circle()
                                .fill(color)
                                .frame(width: 20, height: 20)
                                .overlay(
                                    Circle()
                                        .stroke(annotationManager.selectedColor == color ? Color.primary : Color.clear, lineWidth: 2)
                                )
                        }
                        .buttonStyle(.plain)
                        .help("Select \(colorName(color)) color")
                    }
                }
            }
            
            Spacer()
            
            // Annotation count
            if !annotationManager.annotations.isEmpty {
                Text("\(annotationManager.annotations.count) annotations")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
    
    private func colorName(_ color: Color) -> String {
        switch color {
        case .yellow: return "yellow"
        case .green: return "green"
        case .blue: return "blue"
        case .red: return "red"
        case .orange: return "orange"
        case .purple: return "purple"
        case .pink: return "pink"
        default: return "color"
        }
    }
}

#Preview {
    AnnotationToolbar(annotationManager: AnnotationManager())
        .padding()
} 