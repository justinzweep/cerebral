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
    @StateObject private var settingsManager = SettingsManager()
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([Document.self, Annotation.self, ChatSession.self, Folder.self])
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
                .environmentObject(settingsManager)
        }
        .modelContainer(sharedModelContainer)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Import PDF...") {
                    NotificationCenter.default.post(name: .importPDF, object: nil)
                }
                .keyboardShortcut("o", modifiers: [.command])
            }
            
            CommandGroup(after: .toolbar) {
                Button("Toggle Chat Panel") {
                    NotificationCenter.default.post(name: .toggleChatPanel, object: nil)
                }
                .keyboardShortcut("c", modifiers: [.command])
                
                Divider()
                
                Button("Focus Search") {
                    NotificationCenter.default.post(name: .focusSearch, object: nil)
                }
                .keyboardShortcut("f", modifiers: [.command])
            }
        }
        
        Settings {
            SettingsView()
                .environmentObject(settingsManager)
        }
    }
}
