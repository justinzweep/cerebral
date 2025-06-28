// //
// //  ContextTestView.swift
// //  cerebral
// //
// //  Created on 26/06/2025.
// //

// import SwiftUI

// struct ContextTestView: View {
//     @State private var contextBundle = ChatContextBundle()
//     private let settingsManager = SettingsManager.shared
    
//     var body: some View {
//         VStack(spacing: 20) {
//             Text("Context Management Test")
//                 .font(.title)
            
//             // Show active context panel
//             ActiveContextPanel(
//                 contextBundle: $contextBundle,
//                 onRemoveContext: { context in
//                     contextBundle.removeContext(context)
//                 },
//                 onAddContext: {
//                     // Add a sample context
//                     addSampleContext()
//                 }
//             )
            
//             // Show sample message with context
//             if !contextBundle.contexts.isEmpty {
//                 MessageContextIndicator(contexts: contextBundle.contexts)
//                     .frame(maxWidth: 400)
//             }
            
//             Button("Add Sample Context") {
//                 addSampleContext()
//             }
            
//             Button("Clear All") {
//                 contextBundle.clearContexts()
//             }
//         }
//         .padding()
//     }
    
//     private func addSampleContext() {
//         let sampleContext = DocumentContext(
//             documentId: UUID(),
//             documentTitle: "Sample Document \(contextBundle.contexts.count + 1).pdf",
//             contextType: .fullDocument,
//             content: "This is sample content for testing the context management system.",
//             metadata: ContextMetadata(
//                 extractionMethod: "test",
//                 tokenCount: 50,
//                 checksum: "sample\(contextBundle.contexts.count)"
//             )
//         )
        
//         contextBundle.addContext(sampleContext)
//     }
// }

// #Preview {
//     ContextTestView()
// } 