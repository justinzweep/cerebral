//
//  cerebralApp.swift
//  cerebral
//
//  Created by Justin Zweep on 26/06/2025.
//

import SwiftUI
import SwiftData

@main
struct CerebralApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([Document.self, ChatSession.self])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(SettingsManager.shared)
        }
        .modelContainer(sharedModelContainer)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Import PDF...") {
                    ServiceContainer.shared.appState.requestDocumentImport()
                }
                .keyboardShortcut("o", modifiers: [.command])
            }
            
            CommandGroup(after: .toolbar) {
                Button("Toggle Chat Panel") {
                    ServiceContainer.shared.appState.toggleChatPanel()
                }
                .keyboardShortcut("c", modifiers: [.command])
            }
        }
        
        Settings {
            SettingsView()
                .environment(SettingsManager.shared)
        }
    }
}
