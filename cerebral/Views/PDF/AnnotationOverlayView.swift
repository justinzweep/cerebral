import SwiftUI
import PDFKit

struct AnnotationOverlayView: View {
    @ObservedObject var annotationManager: AnnotationManager
    let pdfView: PDFView
    let pageNumber: Int
    @State private var showingNoteEditor = false
    @State private var notePosition: CGPoint = .zero
    @State private var editingAnnotation: Annotation?
    @State private var noteText = ""
    
    var annotations: [Annotation] {
        annotationManager.getAnnotationsForPage(pageNumber)
    }
    
    var body: some View {
        ZStack {
            // Transparent background to capture taps
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture { location in
                    if annotationManager.isAnnotationMode {
                        handleTap(at: location)
                    } else {
                        annotationManager.deselectAnnotation()
                    }
                }
            
            // Annotation overlays
            ForEach(annotations, id: \.id) { annotation in
                AnnotationView(
                    annotation: annotation,
                    annotationManager: annotationManager,
                    pdfView: pdfView,
                    onEdit: { editAnnotation(annotation) },
                    onDelete: { annotationManager.deleteAnnotation(annotation) }
                )
            }
        }
        .sheet(isPresented: $showingNoteEditor) {
            NoteEditorSheet(
                text: $noteText,
                isPresented: $showingNoteEditor,
                onSave: { saveNote() }
            )
        }
    }
    
    private func handleTap(at location: CGPoint) {
        switch annotationManager.selectedAnnotationTool {
        case .note:
            notePosition = location
            noteText = ""
            editingAnnotation = nil
            showingNoteEditor = true
            
        case .highlight:
            // For highlights, we need text selection
            if let selection = pdfView.currentSelection,
               let currentPage = pdfView.currentPage {
                let bounds = selection.bounds(for: currentPage)
                let convertedBounds = pdfView.convert(bounds, from: currentPage)
                annotationManager.createHighlightAnnotation(
                    at: convertedBounds,
                    on: pageNumber,
                    selectedText: selection.string
                )
                pdfView.clearSelection()
            }
        }
    }
    
    private func editAnnotation(_ annotation: Annotation) {
        if annotation.type == .note {
            noteText = annotation.text ?? ""
            editingAnnotation = annotation
            showingNoteEditor = true
        }
    }
    
    private func saveNote() {
        if let editingAnnotation = editingAnnotation {
            annotationManager.updateAnnotation(editingAnnotation, text: noteText)
        } else {
            annotationManager.createNoteAnnotation(at: notePosition, on: pageNumber, text: noteText)
        }
        editingAnnotation = nil
    }
}

struct AnnotationView: View {
    let annotation: Annotation
    @ObservedObject var annotationManager: AnnotationManager
    let pdfView: PDFView
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    @State private var showingContextMenu = false
    
    var body: some View {
        Group {
            switch annotation.type {
            case .highlight:
                Rectangle()
                    .fill(annotationManager.stringToColor(annotation.color).opacity(0.3))
                    .frame(width: annotation.bounds.width, height: annotation.bounds.height)
                    .position(x: annotation.bounds.midX, y: annotation.bounds.midY)
                    .onTapGesture {
                        if !annotationManager.isAnnotationMode {
                            annotationManager.selectAnnotation(annotation)
                        }
                    }
                    .contextMenu {
                        Button("Delete Highlight") {
                            onDelete()
                        }
                    }
                
            case .note:
                Button(action: {
                    if annotationManager.isAnnotationMode {
                        onEdit()
                    } else {
                        annotationManager.selectAnnotation(annotation)
                    }
                }) {
                    Image(systemName: "note.text")
                        .font(.title2)
                        .foregroundColor(annotationManager.stringToColor(annotation.color))
                        .background(
                            Circle()
                                .fill(Color.white)
                                .frame(width: 24, height: 24)
                        )
                }
                .buttonStyle(.plain)
                .position(x: annotation.bounds.midX, y: annotation.bounds.midY)
                .contextMenu {
                    Button("Edit Note") {
                        onEdit()
                    }
                    Button("Delete Note") {
                        onDelete()
                    }
                }
            }
        }
        .opacity(annotationManager.selectedAnnotation?.id == annotation.id ? 0.8 : 1.0)
        .scaleEffect(annotationManager.selectedAnnotation?.id == annotation.id ? 1.1 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: annotationManager.selectedAnnotation?.id)
    }
}

struct NoteEditorSheet: View {
    @Binding var text: String
    @Binding var isPresented: Bool
    let onSave: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Add Note")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                TextEditor(text: $text)
                    .font(.body)
                    .scrollContentBackground(.hidden)
                    .background(Color(NSColor.textBackgroundColor))
                    .cornerRadius(8)
                    .frame(minHeight: 150)
                
                Spacer()
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave()
                        isPresented = false
                    }
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .frame(width: 400, height: 300)
    }
}

#Preview {
    AnnotationOverlayView(
        annotationManager: AnnotationManager(),
        pdfView: PDFView(),
        pageNumber: 0
    )
} 