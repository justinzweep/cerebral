import SwiftUI

struct AnnotationListView: View {
    @ObservedObject var annotationManager: AnnotationManager
    let document: Document?
    @State private var showingEditSheet = false
    @State private var editingAnnotation: Annotation?
    @State private var editText = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("Annotations")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if !annotationManager.annotations.isEmpty {
                    Text("\(annotationManager.annotations.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.secondary.opacity(0.2))
                        .cornerRadius(10)
                }
            }
            .padding()
            
            Divider()
            
            // Annotations list
            if annotationManager.annotations.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "note.text")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    
                    Text("No Annotations")
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    Text("Add highlights and notes to your PDF using the annotation toolbar.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(annotationManager.annotations.sorted(by: { $0.pageNumber < $1.pageNumber }), id: \.id) { annotation in
                            AnnotationRowView(
                                annotation: annotation,
                                annotationManager: annotationManager,
                                onEdit: { editAnnotation(annotation) },
                                onDelete: { annotationManager.deleteAnnotation(annotation) }
                            )
                            
                            if annotation.id != annotationManager.annotations.last?.id {
                                Divider()
                                    .padding(.horizontal)
                            }
                        }
                    }
                }
            }
        }
        .background(Color(NSColor.controlBackgroundColor))
        .sheet(isPresented: $showingEditSheet) {
            AnnotationEditSheet(
                annotation: editingAnnotation,
                text: $editText,
                isPresented: $showingEditSheet,
                onSave: { saveEdit() }
            )
        }
    }
    
    private func editAnnotation(_ annotation: Annotation) {
        editingAnnotation = annotation
        editText = annotation.text ?? ""
        showingEditSheet = true
    }
    
    private func saveEdit() {
        guard let annotation = editingAnnotation else { return }
        annotationManager.updateAnnotation(annotation, text: editText)
        editingAnnotation = nil
    }
}

struct AnnotationRowView: View {
    let annotation: Annotation
    @ObservedObject var annotationManager: AnnotationManager
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // Annotation type icon
                Image(systemName: annotation.type == .highlight ? "highlighter" : "note.text")
                    .font(.caption)
                    .foregroundColor(annotationManager.stringToColor(annotation.color))
                    .frame(width: 16, height: 16)
                
                Text("Page \(annotation.pageNumber + 1)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // Action buttons
                HStack(spacing: 4) {
                    if annotation.type == .note {
                        Button(action: onEdit) {
                            Image(systemName: "pencil")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                        .help("Edit note")
                    }
                    
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.plain)
                    .help("Delete annotation")
                }
            }
            
            // Annotation content
            if let text = annotation.text, !text.isEmpty {
                Text(text)
                    .font(.body)
                    .foregroundColor(.primary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
            }
        }
        .padding()
        .background(annotationManager.selectedAnnotation?.id == annotation.id ? 
                   Color.accentColor.opacity(0.1) : Color.clear)
        .contentShape(Rectangle())
        .onTapGesture {
            annotationManager.selectAnnotation(annotation)
        }
    }
}

struct AnnotationEditSheet: View {
    let annotation: Annotation?
    @Binding var text: String
    @Binding var isPresented: Bool
    let onSave: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Edit Note")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                if let annotation = annotation {
                    HStack {
                        Image(systemName: "doc.text")
                            .foregroundColor(.secondary)
                        Text("Page \(annotation.pageNumber + 1)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
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
    AnnotationListView(
        annotationManager: AnnotationManager(),
        document: nil
    )
} 