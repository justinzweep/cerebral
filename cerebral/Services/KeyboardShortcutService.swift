//
//  KeyboardShortcutService.swift
//  cerebral
//
//  Created by Justin Zweep on 26/06/2025.
//

import AppKit
import SwiftUI

final class KeyboardShortcutService: ObservableObject {
    private var keyMonitor: Any?
    
    // Closures for handling different keyboard shortcuts
    var onEscapePressed: (() -> Void)?
    var onToggleChat: (() -> Void)?
    var onToggleSidebar: (() -> Void)?
    
    // MARK: - Public Methods
    
    @MainActor
    func startMonitoring() {
        guard keyMonitor == nil else { return }
        
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { [weak self] event in
            return self?.handleKeyEvent(event)
        }
    }
    
    func stopMonitoring() {
        if let monitor = keyMonitor {
            NSEvent.removeMonitor(monitor)
            keyMonitor = nil
        }
    }
    
    // MARK: - Private Methods
    
    private func handleKeyEvent(_ event: NSEvent) -> NSEvent? {
        let keyCode = event.keyCode
        let modifierFlags = event.modifierFlags
        
        // ESC key (keyCode 53)
        if keyCode == 53 {
            Task { @MainActor [weak self] in
                self?.onEscapePressed?()
            }
            return nil // Consume the event
        }
        
        // Command + L (keyCode 37 for 'L')
        if keyCode == 37 && modifierFlags.contains(.command) {
            Task { @MainActor [weak self] in
                self?.onToggleChat?()
            }
            return nil // Consume the event
        }
        
        // Command + K (keyCode 40 for 'K')
        if keyCode == 40 && modifierFlags.contains(.command) {
            Task { @MainActor [weak self] in
                self?.onToggleSidebar?()
            }
            return nil // Consume the event
        }
        
        return event // Let the event continue
    }
    
    deinit {
        stopMonitoring()
    }
} 