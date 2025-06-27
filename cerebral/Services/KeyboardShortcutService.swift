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
        
        // ESC key (keyCode 53) - Clear document selection
        if keyCode == 53 {
            appState.selectDocument(nil)
            return nil // Consume the event
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
} 