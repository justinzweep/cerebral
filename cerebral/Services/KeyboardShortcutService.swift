//
//  KeyboardShortcutService.swift
//  cerebral
//
//  Created by Justin Zweep on 26/06/2025.
//

import AppKit
import SwiftUI

// Non-isolated monitor wrapper to handle cleanup safely
final class KeyMonitorWrapper {
    private var monitor: Any?
    
    func start(handler: @escaping (NSEvent) -> NSEvent?) {
        guard monitor == nil else { return }
        monitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown], handler: handler)
    }
    
    func stop() {
        if let monitor = monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
    }
    
    deinit {
        stop()
    }
}

@MainActor
@Observable
final class KeyboardShortcutService {
    private let monitorWrapper = KeyMonitorWrapper()
    private let appState: AppState
    
    init(appState: AppState) {
        self.appState = appState
    }
    
    // MARK: - Public Methods
    
    func startMonitoring() {
        monitorWrapper.start { [weak self] event in
            return self?.handleKeyEvent(event)
        }
    }
    
    func stopMonitoring() {
        monitorWrapper.stop()
    }
    
    // MARK: - Private Methods
    
    private func handleKeyEvent(_ event: NSEvent) -> NSEvent? {
        let keyCode = event.keyCode
        let modifierFlags = event.modifierFlags
        let characters = event.characters ?? ""
        
        // ESC key (keyCode 53) - Clear document selection AND PDF selections
        if keyCode == 53 {
            appState.selectDocument(nil)
            appState.clearAllPDFSelections()
            return nil
        }
        
        // NEW: PDF-to-Chat typing detection
        // Only trigger if we have PDF selections and user types alphanumeric
        if appState.isReadyForChatTransition,
           !characters.isEmpty,
           !modifierFlags.contains(.command), // Ignore cmd shortcuts
           !modifierFlags.contains(.control),  // Ignore ctrl shortcuts
           !modifierFlags.contains(.option),   // Ignore option shortcuts
           isAlphanumericCharacter(characters.first!) {
            
            // Trigger chat focus
            appState.triggerChatFocus()
            
            // Ensure chat panel is visible
            if !appState.showingChat {
                appState.toggleChatPanel()
            }
            
            // Don't consume the event - let it go to the chat input
            return event
        }
        
        // Command + L (keyCode 37 for 'L') - Toggle chat panel
        if keyCode == 37 && modifierFlags.contains(.command) {
            appState.toggleChatPanel()
            return nil // Consume the event
        }
        
        // Command + K (keyCode 40 for 'K') - Toggle sidebar
        if keyCode == 40 && modifierFlags.contains(.command) {
            appState.toggleSidebar()
            return nil // Consume the event
        }
        
        return event // Let the event continue
    }
    
    private func isAlphanumericCharacter(_ char: Character) -> Bool {
        return char.isLetter || char.isNumber || char.isWhitespace || char.isPunctuation
    }
} 