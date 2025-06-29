//
//  Animations.swift
//  cerebral
//
//  Modern Conversational Animation System
//  Delightful, responsive animations inspired by ChatGPT and Airbnb
//

import SwiftUI

// MARK: - Animation and Transition System

extension DesignSystem {
    // MARK: - Modern Animation System (60fps Smooth & Delightful)
    struct Animation {
        // MARK: - Micro-interactions (Buttery Smooth)
        static let delightful = SwiftUI.Animation.spring(response: 0.3, dampingFraction: 0.8)    // Main interaction animation
        static let micro = SwiftUI.Animation.easeOut(duration: 0.15)                              // Button presses, hovers
        static let quick = SwiftUI.Animation.easeInOut(duration: 0.2)                             // State changes
        static let interface = SwiftUI.Animation.easeInOut(duration: 0.25)                        // Interface updates
        static let smooth = SwiftUI.Animation.easeInOut(duration: 0.3)                            // Content transitions
        
        // MARK: - ChatGPT-Inspired Conversational Animations
        static let conversational = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.75)  // Chat bubbles, messages
        static let thinking = SwiftUI.Animation.easeInOut(duration: 0.6).repeatForever(autoreverses: true)  // Thinking indicators
        static let typing = SwiftUI.Animation.linear(duration: 0.5)                                // Typing indicators
        static let messageAppear = SwiftUI.Animation.spring(response: 0.5, dampingFraction: 0.8)  // Message appearance
        
        // MARK: - Airbnb-Inspired Warm Animations
        static let warmEntry = SwiftUI.Animation.spring(response: 0.6, dampingFraction: 0.8)     // Card entries, modals
        static let gentleFloat = SwiftUI.Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true)  // Floating elements
        static let welcomeScale = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.6)  // Welcome animations
        static let cozyHover = SwiftUI.Animation.spring(response: 0.2, dampingFraction: 0.9)     // Cozy hover effects
        
        // MARK: - Page & Modal Transitions
        static let pageTransition = SwiftUI.Animation.easeInOut(duration: 0.35)
        static let modalPresentation = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.8)
        static let modalDismissal = SwiftUI.Animation.easeIn(duration: 0.25)
        
        // MARK: - Beautiful Spring Animations
        static let gentleSpring = SwiftUI.Animation.spring(response: 0.5, dampingFraction: 0.8)
        static let snappySpring = SwiftUI.Animation.spring(response: 0.3, dampingFraction: 0.9)
        static let bouncySpring = SwiftUI.Animation.spring(response: 0.35, dampingFraction: 0.65)  // For fun interactions
        static let elasticSpring = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.6)   // Elastic feel
        
        // MARK: - Gradient & Color Transitions
        static let colorShift = SwiftUI.Animation.easeInOut(duration: 0.4)                      // Color transitions
        static let gradientFlow = SwiftUI.Animation.easeInOut(duration: 0.8)                    // Gradient animations
        static let shimmer = SwiftUI.Animation.linear(duration: 1.5).repeatForever(autoreverses: false)  // Shimmer effects
        
        // MARK: - Special Effects
        static let elasticScale = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.6)
        static let fadeInOut = SwiftUI.Animation.easeInOut(duration: 0.2)
        static let breathe = SwiftUI.Animation.easeInOut(duration: 3.0).repeatForever(autoreverses: true)  // Breathing effect
        static let pulse = SwiftUI.Animation.easeInOut(duration: 1.2).repeatForever(autoreverses: true)    // Pulse effect
        
        // MARK: - Loading & Progress Animations
        static let progressFill = SwiftUI.Animation.easeInOut(duration: 0.3)                    // Progress bars
        static let spinnerRotation = SwiftUI.Animation.linear(duration: 1.0).repeatForever(autoreverses: false)  // Spinners
        static let dotsLoading = SwiftUI.Animation.easeInOut(duration: 0.6).repeatForever(autoreverses: true)     // Loading dots
        
        // MARK: - Legacy Support
        @available(*, deprecated, message: "Use delightful for modern interactions")
        static let microInteraction = micro
        @available(*, deprecated, message: "Use delightful or conversational")
        static let gentle = smooth
        @available(*, deprecated, message: "Use warmEntry or modalPresentation")
        static let spring = modalPresentation
        @available(*, deprecated, message: "Use modalPresentation")
        static let modal = modalPresentation
    }
}

// MARK: - Modern Transition Extensions

extension AnyTransition {
    // MARK: - Conversational Transitions (ChatGPT-inspired)
    static var messageSlide: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .bottom).combined(with: .opacity).combined(with: .scale(scale: 0.95)),
            removal: .move(edge: .top).combined(with: .opacity)
        )
    }
    
    static var chatBubble: AnyTransition {
        .scale(scale: 0.8, anchor: .bottomLeading).combined(with: .opacity)
    }
    
    static var conversationalSlide: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        )
    }
    
    // MARK: - Airbnb-inspired Warm Transitions
    static var warmEntry: AnyTransition {
        .scale(scale: 0.9).combined(with: .opacity).combined(with: .move(edge: .bottom))
    }
    
    static var cardFlip: AnyTransition {
        .asymmetric(
            insertion: .scale(scale: 0.8).combined(with: .opacity),
            removal: .scale(scale: 1.1).combined(with: .opacity)
        )
    }
    
    static var gentleSlide: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .bottom).combined(with: .opacity.animation(DesignSystem.Animation.warmEntry)),
            removal: .move(edge: .top).combined(with: .opacity.animation(DesignSystem.Animation.quick))
        )
    }
    
    // MARK: - Legacy Transitions (Updated)
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
            insertion: .move(edge: .bottom).combined(with: .opacity.animation(DesignSystem.Animation.delightful)),
            removal: .move(edge: .top).combined(with: .opacity.animation(DesignSystem.Animation.quick))
        )
    }
}

// MARK: - Animation Helpers

extension View {
    /// Apply a delightful spring animation with custom values
    func delightfulSpring(response: Double = 0.3, dampingFraction: Double = 0.8) -> some View {
        self.animation(.spring(response: response, dampingFraction: dampingFraction), value: true)
    }
    
    /// Apply a breathing animation effect
    func breathingEffect(duration: Double = 3.0, scale: CGFloat = 1.05) -> some View {
        self.scaleEffect(scale)
            .animation(
                .easeInOut(duration: duration).repeatForever(autoreverses: true),
                value: true
            )
    }
    
    /// Apply a gentle pulse animation
    func gentlePulse(duration: Double = 1.2, opacity: Double = 0.7) -> some View {
        self.opacity(opacity)
            .animation(
                .easeInOut(duration: duration).repeatForever(autoreverses: true),
                value: true
            )
    }
    
    /// Apply a shimmer effect
    func shimmerEffect() -> some View {
        self.overlay(
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.clear, .white.opacity(0.3), .clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .rotationEffect(.degrees(30))
                .animation(DesignSystem.Animation.shimmer, value: true)
        )
        .clipped()
    }
} 