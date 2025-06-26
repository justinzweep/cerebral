import SwiftUI
import SwiftData
import PDFKit
import Foundation

@MainActor
class AnnotationManager: ObservableObject {
    @Published var selectedAnnotationTool: AnnotationType = .highlight
    @Published var selectedColor: Color = .yellow
    @Published var isAnnotationMode: Bool = false
    @Published var annotations: [Annotation] = []
    @Published var selectedAnnotation: Annotation?
    
    private var modelContext: ModelContext?
    private var currentDocument: Document?
    
    // Available colors for annotations
    let annotationColors: [Color] = [.yellow, .green, .blue, .red, .orange, .purple, .pink]
    
    func setContext(_ context: ModelContext) {
        self.modelContext = context
    }
    
    func setCurrentDocument(_ document: Document?) {
        self.currentDocument = document
        loadAnnotations()
    }
    
    func loadAnnotations() {
        guard let document = currentDocument else {
            annotations = []
            return
        }
        
        annotations = document.annotations
    }
    
    func createHighlightAnnotation(at bounds: CGRect, on pageNumber: Int, selectedText: String? = nil) {
        guard let document = currentDocument,
              let context = modelContext else { return }
        
        let annotation = Annotation(
            type: .highlight,
            pageNumber: pageNumber,
            bounds: bounds,
            document: document
        )
        annotation.color = colorToString(selectedColor)
        annotation.text = selectedText
        
        context.insert(annotation)
        document.annotations.append(annotation)
        
        do {
            try context.save()
            loadAnnotations()
        } catch {
            print("Error saving highlight annotation: \(error)")
        }
    }
    
    func createNoteAnnotation(at point: CGPoint, on pageNumber: Int, text: String) {
        guard let document = currentDocument,
              let context = modelContext else { return }
        
        let bounds = CGRect(x: point.x - 10, y: point.y - 10, width: 20, height: 20)
        let annotation = Annotation(
            type: .note,
            pageNumber: pageNumber,
            bounds: bounds,
            document: document
        )
        annotation.color = colorToString(selectedColor)
        annotation.text = text
        
        context.insert(annotation)
        document.annotations.append(annotation)
        
        do {
            try context.save()
            loadAnnotations()
        } catch {
            print("Error saving note annotation: \(error)")
        }
    }
    
    func updateAnnotation(_ annotation: Annotation, text: String? = nil, color: Color? = nil) {
        guard let context = modelContext else { return }
        
        if let text = text {
            annotation.text = text
        }
        
        if let color = color {
            annotation.color = colorToString(color)
        }
        
        do {
            try context.save()
            loadAnnotations()
        } catch {
            print("Error updating annotation: \(error)")
        }
    }
    
    func deleteAnnotation(_ annotation: Annotation) {
        guard let context = modelContext,
              let document = currentDocument else { return }
        
        // Remove from document's annotations array
        if let index = document.annotations.firstIndex(where: { $0.id == annotation.id }) {
            document.annotations.remove(at: index)
        }
        
        context.delete(annotation)
        
        do {
            try context.save()
            loadAnnotations()
        } catch {
            print("Error deleting annotation: \(error)")
        }
    }
    
    func getAnnotationsForPage(_ pageNumber: Int) -> [Annotation] {
        return annotations.filter { $0.pageNumber == pageNumber }
    }
    
    func selectAnnotation(_ annotation: Annotation) {
        selectedAnnotation = annotation
    }
    
    func deselectAnnotation() {
        selectedAnnotation = nil
    }
    
    // Helper methods
    private func colorToString(_ color: Color) -> String {
        switch color {
        case .yellow: return "yellow"
        case .green: return "green"
        case .blue: return "blue"
        case .red: return "red"
        case .orange: return "orange"
        case .purple: return "purple"
        case .pink: return "pink"
        default: return "yellow"
        }
    }
    
    func stringToColor(_ string: String?) -> Color {
        guard let string = string else { return .yellow }
        
        switch string {
        case "yellow": return .yellow
        case "green": return .green
        case "blue": return .blue
        case "red": return .red
        case "orange": return .orange
        case "purple": return .purple
        case "pink": return .pink
        default: return .yellow
        }
    }
} 