//
//  Animations.swift
//  cerebral
//
//  Animation System for Cerebral macOS App
//  Responsive Elegance with 60fps smooth animations
//

import SwiftUI

// MARK: - Animation and Transition System

extension DesignSystem {
    // MARK: - Animation System (Responsive Elegance)
    struct Animation {
        // MARK: - Micro-interactions (60fps smooth)
        static let micro = SwiftUI.Animation.easeOut(duration: 0.15)           // Button presses, hovers
        static let quick = SwiftUI.Animation.easeInOut(duration: 0.2)          // State changes
        static let interface = SwiftUI.Animation.easeInOut(duration: 0.25)     // Interface updates
        static let smooth = SwiftUI.Animation.easeInOut(duration: 0.3)         // Content transitions
        
        // MARK: - Page & Modal Transitions
        static let pageTransition = SwiftUI.Animation.easeInOut(duration: 0.35)
        static let modalPresentation = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.8)
        static let modalDismissal = SwiftUI.Animation.easeIn(duration: 0.25)
        
        // MARK: - Spring Animations
        static let gentleSpring = SwiftUI.Animation.spring(response: 0.5, dampingFraction: 0.8)
        static let snappySpring = SwiftUI.Animation.spring(response: 0.3, dampingFraction: 0.9)
        
        // MARK: - Special Effects
        static let elasticScale = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.6)
        static let fadeInOut = SwiftUI.Animation.easeInOut(duration: 0.2)
        
        // MARK: - Legacy Support
        static let microInteraction = micro
        static let gentle = smooth
        static let spring = modalPresentation
        static let modal = modalPresentation
    }
}

// MARK: - Transition Extensions

extension AnyTransition {
    static var slideAndFade: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        )
    }
    
    static var scaleAndFade: AnyTransition {
        .scale(scale: 0.8).combined(with: .opacity)
    }
    
    static var modernSlide: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .bottom).combined(with: .opacity.animation(DesignSystem.Animation.quick)),
            removal: .move(edge: .top).combined(with: .opacity.animation(DesignSystem.Animation.micro))
        )
    }
} 