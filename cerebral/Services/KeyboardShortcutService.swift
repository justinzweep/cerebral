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
    private let errorManager: ErrorManager
    
    init(appState: AppState) {
        self.appState = appState
        self.errorManager = ServiceContainer.shared.errorManager
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
        
        // ESC key (keyCode 53) - Handle hierarchically from most specific to most general
        if keyCode == 53 {
            if handleEscapeHierarchy() {
                return nil // Consumed by escape handling
            }
        }
        
        // NEW: PDF-to-Chat typing detection
        // Only trigger if we have PDF selections and user types alphanumeric
        if appState.isReadyForChatTransition,
           !characters.isEmpty,
           !modifierFlags.contains(.command), // Ignore cmd shortcuts
           !modifierFlags.contains(.control),  // Ignore ctrl shortcuts
           !modifierFlags.contains(.option),   // Ignore option shortcuts
           isAlphanumericCharacter(characters.first!) {
            
            // Trigger chat focus with the typed character
            appState.triggerChatFocus(withCharacter: characters)
            
            // Ensure chat panel is visible
            if !appState.showingChat {
                appState.toggleChatPanel()
            }
            
            // Consume the event - we'll handle the character insertion ourselves
            return nil
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
    
    /// Handle escape key in hierarchical order from most specific to most general UI state
    /// Returns true if the escape key was handled and consumed
    private func handleEscapeHierarchy() -> Bool {
        // Send notifications for UI states that need to handle escape (in priority order)
        // Each view will check its own state and handle if applicable
        
        // 1. Autocomplete (most immediate UI state)
        NotificationCenter.default.post(name: .escapeKeyPressed, object: nil, userInfo: ["context": "autocomplete"])
        
        // 2. API key editing state (form state)
        NotificationCenter.default.post(name: .escapeKeyPressed, object: nil, userInfo: ["context": "apikey"])
        
        // 3. PDF Toolbar (immediate interaction state)
        if appState.toolbarState.isVisible {
            appState.hideToolbar()
            return true
        }
        
        // 4. Error dialogs (modal state)
        if errorManager.showingError {
            errorManager.clearError()
            return true
        }
        
        // 5. File importer (modal state)
        if appState.showingImporter {
            appState.showingImporter = false
            return true
        }
        
        // 6. PDF selections (component state)
        if !appState.pdfSelections.isEmpty {
            appState.clearAllPDFSelections()
            // Also clear the coordinator selections
            Task { @MainActor in
                if let coordinator = PDFViewCoordinator.sharedCoordinator {
                    coordinator.clearMultipleSelections()
                }
            }
            return true
        }
        
        // 7. Document selection (global state)
        if appState.selectedDocument != nil {
            appState.selectDocument(nil)
            return true
        }
        
        // If we get here, escape wasn't consumed by any specific UI state
        return false
    }
    
    // MARK: - Helper Methods for State Detection
    
    private func isAlphanumericCharacter(_ char: Character) -> Bool {
        return char.isLetter || char.isNumber || char.isWhitespace || char.isPunctuation
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let escapeKeyPressed = Notification.Name("escapeKeyPressed")
} 