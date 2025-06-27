# Cerebral Codebase Simplification & Cleanup Plan

## Overview
This plan outlines steps to refactor the Cerebral codebase to follow SwiftUI best practices while maintaining all existing functionality. The focus is on improving code organization, reducing complexity, and enhancing maintainability.

## Current Architecture Analysis

### Strengths
- Well-organized MVVM architecture with clear separation of concerns
- Comprehensive Design System with consistent spacing, colors, and typography
- Good use of SwiftData for data persistence
- Proper service layer abstraction
- Streaming chat implementation

### Areas for Improvement
1. **Large, monolithic view files** (ContentView.swift - 464 lines)
2. **Mixed responsibilities** in some views
3. **Duplicated code** patterns across components
4. **Complex state management** in some areas
5. **Missing view composition** opportunities
6. **Inconsistent error handling** patterns

## Detailed Cleanup Plan

### 5. Service Layer Improvements (Priority: MEDIUM)

**Current Issues:**
- Some services mixing concerns
- Inconsistent error handling patterns
- Missing dependency injection

**Refactoring Plan:**

#### A. Service Protocol Definitions
```swift
protocol ChatServiceProtocol {
    func sendMessage(_ text: String) async throws -> String
    func sendStreamingMessage(_ text: String) -> AsyncThrowingStream<ChatResponse, Error>
}

protocol DocumentServiceProtocol {
    func importDocument(from url: URL) async throws -> Document
    func searchDocuments(_ query: String) -> [Document]
}

protocol SettingsServiceProtocol {
    var apiKey: String { get set }
    var isAPIKeyValid: Bool { get }
    func validateSettings() async -> Bool
}
```

#### B. Service Consolidation
- Merge related services where appropriate
- Add proper error types instead of strings
- Implement consistent async/await patterns

**Actions:**
1. Define service protocols for better testability
2. Consolidate `PDFTextExtractionService` and `PDFThumbnailService` into `PDFService`
3. Create `DocumentImportService` from extracted ContentView logic
4. Add proper error types: `ChatError`, `DocumentError`, `APIError`
5. Implement dependency injection container

### 6. State Management Simplification (Priority: MEDIUM)

**Current Issues:**
- Mixed use of `@State`, `@StateObject`, and `@ObservedObject`
- Some state could be simplified with `@Observable`
- Notification-based communication could be improved

**Refactoring Plan:**

#### A. Adopt iOS 17+ Patterns
```swift
// Replace @StateObject with @State for new observable types
@State private var chatManager = ChatManager()

// Use @Observable for simpler state management
@Observable
final class DocumentManager {
    var selectedDocument: Document?
    var documents: [Document] = []
}
```

#### B. Reduce NotificationCenter Usage
- Replace notifications with proper data flow where possible
- Keep notifications only for system-level events
- Use proper parent-child view communication

**Actions:**
1. Audit current state management patterns
2. Replace `@StateObject` with `@State` where appropriate
3. Convert compatible classes to use `@Observable` macro
4. Reduce notification dependencies with proper data flow
5. Implement proper view data passing

### 7. Error Handling Standardization (Priority: MEDIUM)

**Current Issues:**
- Inconsistent error handling across the app
- String-based errors instead of proper error types
- Missing user-friendly error messages

**Refactoring Plan:**

#### A. Define Error Types
```swift
enum AppError: LocalizedError {
    case apiKeyInvalid
    case networkFailure(String)
    case documentImportFailed(String)
    case chatServiceUnavailable
    
    var errorDescription: String? {
        // User-friendly messages
    }
}
```

#### B. Centralized Error Handling
```swift
@Observable
final class ErrorManager {
    var currentError: AppError?
    var showingError: Bool = false
    
    func handle(_ error: Error) {
        // Convert and display errors consistently
    }
}
```

**Actions:**
1. Define comprehensive error types
2. Create centralized error handling service
3. Implement consistent error UI components
4. Add proper error recovery mechanisms
5. Replace string errors with typed errors

### 8. Performance Optimizations (Priority: LOW)

**Current Issues:**
- Some views might re-render unnecessarily
- Large lists without optimization
- Potential memory leaks in streaming

**Refactoring Plan:**

#### A. View Performance
- Add `@ViewBuilder` where beneficial
- Use `LazyVStack` and `LazyHStack` appropriately
- Implement proper view identity for animations

#### B. Memory Management
- Audit streaming task cancellation
- Review SwiftData query efficiency
- Optimize PDF rendering

**Actions:**
1. Profile app performance to identify bottlenecks
2. Add `@ViewBuilder` to custom view builders
3. Optimize SwiftData queries with proper predicates
4. Review and fix potential memory leaks
5. Add performance monitoring
