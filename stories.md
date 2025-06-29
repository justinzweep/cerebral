# Cerebral macOS App - Sprint Stories & Epics

## 🎯 Epic Overview

### Epic 1: Document-Based App Foundation
**Goal**: Transform Cerebral into a native macOS document-based application with proper file management integration.

### Epic 2: Hybrid Vector Search Architecture  
**Goal**: Implement ObjectBox on-device vector storage and search while leveraging Python API for document processing and query embedding.

### Epic 3: Authentication & App Launch
**Goal**: Implement authentication gate where users must sign in/up via modal on first launch, then access the full app with subscription-based feature limitations.

### Epic 4: Enhanced PDF Integration
**Goal**: Implement native PDF viewing with intelligent highlighting and context navigation.

### Epic 5: Context-Aware AI Chat
**Goal**: Build intelligent chat system with precise document references and visual navigation.

## 🏗️ Hybrid Architecture Approach

### Python API Integration
The rebuild maintains a strategic dependency on Python API for two critical operations:

1. **Document Chunking & Embedding**: Python API processes PDF documents and returns structured JSON with:
   - `document_id`: Unique identifier for the source document
   - `chunk_id`: Unique identifier for each text chunk
   - `text`: Extracted text content of the chunk
   - `bounding_boxes`: Coordinate information for visual highlighting
   - `embeddings`: Vector embeddings for semantic search

2. **Query Embedding**: Python API converts user queries into vector embeddings for search operations

### On-Device ObjectBox Storage
- All processed chunks stored locally in ObjectBox vector database
- Fast similarity search operations (<100ms response time)
- Privacy-focused: search operations never leave the device
- Offline capability: search works without internet connectivity

### Authentication & Launch Requirements
- **Mandatory Authentication**: All users must have an account to access any app functionality
- **Authentication Modal**: First-time users see sign up/in modal, then app launches normally
- **Subscription Tiers**: Three access levels (Trial, Subscription, Purchased) with different feature limits
- **Clerk Integration**: Native iOS authentication using Clerk SDK for user management
- **Trial Access**: New users automatically get trial access after authentication
- **In-App Limitations**: Feature limits enforced throughout normal app usage
- **Upgrade Flows**: Paywall appears when users hit trial limitations

### Benefits of Hybrid Approach
- **Processing Power**: Leverage specialized Python ML libraries for document processing
- **Privacy**: Search operations and data storage remain on-device
- **Performance**: Fast local search with optimized ObjectBox vector operations
- **Scalability**: Python API can be scaled independently for processing workloads
- **User Management**: Clerk handles authentication, user profiles, and subscription state

---

## 📋 Phase 0: Layout Foundation (Sprint 0)

### Epic 0: Three-Pane App Layout Architecture
**Goal**: Establish the fundamental 3-pane layout structure that serves as the foundation for all app functionality.

#### Story 0.1: Basic 3-Pane Layout Structure
**As a** macOS user  
**I want** a familiar 3-pane interface layout  
**So that** I can efficiently navigate between documents, view content, and interact with AI  

**Acceptance Criteria:**
- [ ] Three-pane layout implemented using SwiftUI NavigationSplitView or custom HSplitView
- [ ] Left pane: Document manager/explorer (minimum 200px, maximum 400px width)
- [ ] Middle pane: Document reader/viewer (flexible width, minimum 400px)
- [ ] Right pane: Chat window (minimum 300px, maximum 500px width)
- [ ] Pane resize handles functional with proper constraints
- [ ] Layout state persists between app launches
- [ ] Responsive design adapts to different window sizes

**Technical Tasks:**
- [ ] Create MainContentView with NavigationSplitView structure
- [ ] Implement pane width constraints and resize logic
- [ ] Add layout state persistence to UserDefaults
- [ ] Create placeholder views for each pane
- [ ] Test layout behavior across different screen sizes

#### Story 0.2: Document Manager Pane Foundation
**As a** user  
**I want** a dedicated document management area  
**So that** I can organize and access my PDF library efficiently  

**Acceptance Criteria:**
- [ ] Left pane displays as document manager/explorer
- [ ] Sidebar-style design with native macOS appearance
- [ ] Empty state shows "No Documents" placeholder
- [ ] Basic list structure ready for document items
- [ ] Search/filter area allocated at top of pane
- [ ] Add document button/area clearly visible
- [ ] Proper scrolling behavior for large document lists

**Technical Tasks:**
- [ ] Create DocumentManagerView as left pane content
- [ ] Implement basic List or LazyVStack structure
- [ ] Add empty state placeholder design
- [ ] Create header area for search and add document controls
- [ ] Apply native macOS sidebar styling
- [ ] Add basic navigation and selection states

#### Story 0.3: PDFKit Viewer Pane Foundation  
**As a** user  
**I want** a dedicated PDF viewing area  
**So that** I can read and interact with my documents using native macOS capabilities  

**Acceptance Criteria:**
- [ ] Middle pane serves as primary PDF viewer
- [ ] PDFKit integration implemented with PDFView
- [ ] Empty state shows "Select a document" placeholder
- [ ] Basic PDF display functionality working
- [ ] Zoom and navigation controls accessible
- [ ] PDF loading states handled gracefully
- [ ] Error states for unsupported/corrupted files

**Technical Tasks:**
- [ ] Create PDFViewerPane using PDFKit's PDFView
- [ ] Implement PDFViewerRepresentable for SwiftUI integration
- [ ] Add empty state and loading state views
- [ ] Create basic PDF document loading mechanism
- [ ] Add error handling for PDF loading failures
- [ ] Implement basic zoom and navigation controls

#### Story 0.4: Chat Window Pane Foundation
**As a** user  
**I want** a dedicated chat interface  
**So that** I can interact with AI about my documents  

**Acceptance Criteria:**
- [ ] Right pane serves as chat interface
- [ ] Chat message area with proper scrolling
- [ ] Text input area at bottom of pane
- [ ] Empty state shows "Start a conversation" placeholder
- [ ] Basic message display structure implemented
- [ ] Input area properly sized and responsive
- [ ] Chat history scroll behavior functional

**Technical Tasks:**
- [ ] Create ChatWindowView as right pane content
- [ ] Implement ScrollView for message history
- [ ] Add text input area with TextField or TextEditor
- [ ] Create message list structure (ready for chat messages)
- [ ] Add empty state design for new conversations
- [ ] Implement basic keyboard shortcuts (Enter to send)
- [ ] Add proper focus management for chat input

#### Story 0.5: Pane Integration & Layout Management
**As a** user  
**I want** seamless interaction between the three panes  
**So that** I can efficiently work with documents and AI simultaneously  

**Acceptance Criteria:**
- [ ] Pane visibility can be toggled (show/hide each pane)
- [ ] Layout adapts gracefully when panes are hidden
- [ ] Keyboard shortcuts for pane navigation implemented
- [ ] Focus management works properly between panes
- [ ] Minimum window size enforced for usability
- [ ] Pane configurations saved and restored
- [ ] Proper toolbar/menu integration for pane controls

**Technical Tasks:**
- [ ] Add pane visibility state management
- [ ] Implement keyboard shortcuts for pane navigation (Cmd+1, Cmd+2, Cmd+3)
- [ ] Create toolbar buttons for pane visibility toggles
- [ ] Add focus management system between panes
- [ ] Implement window size constraints
- [ ] Add layout configuration persistence
- [ ] Create View menu items for pane controls

#### Story 0.6: Responsive Design & Accessibility
**As a** user with different needs and screen sizes  
**I want** the app layout to be accessible and responsive  
**So that** I can use the app effectively regardless of my setup  

**Acceptance Criteria:**
- [ ] Layout adapts to different screen sizes (13" to 32" displays)
- [ ] Proper keyboard navigation between all panes
- [ ] VoiceOver support for pane navigation
- [ ] High contrast mode compatibility
- [ ] Dynamic Type support throughout layout
- [ ] Proper focus indicators for keyboard navigation
- [ ] Layout works in both light and dark modes

**Technical Tasks:**
- [ ] Test layout across various screen sizes
- [ ] Implement accessibility labels and hints
- [ ] Add VoiceOver support for pane navigation
- [ ] Test keyboard navigation flow
- [ ] Verify Dynamic Type scaling
- [ ] Add proper focus ring implementations
- [ ] Test dark/light mode appearance

---

## 📋 Phase 1: Foundation (Sprints 1-3)

### Sprint 1: Core Architecture Setup

#### Story 1.1: Document-Based App Structure
**As a** macOS user  
**I want** Cerebral to behave like a native document-based app  
**So that** I can manage my document libraries using familiar macOS patterns  

**Acceptance Criteria:**
- [ ] Convert existing app to DocumentGroup architecture
- [ ] Implement CerebralDocument FileDocument conformance
- [ ] Add proper document lifecycle management
- [ ] Support .cerebral file extension registration
- [ ] Enable "Recent Documents" menu integration
- [ ] Support document creation/opening/saving workflows

**Technical Tasks:**
- [ ] Refactor cerebralApp.swift to use DocumentGroup
- [ ] Create CerebralDocument model with FileDocument protocol
- [ ] Update Info.plist with document type definitions
- [ ] Migrate existing data models to document-based structure

#### Story 1.2: ObjectBox Integration Setup
**As a** developer  
**I want** ObjectBox vector search configured for on-device storage and search  
**So that** we can have fast, private vector operations while using Python API for processing  

**Acceptance Criteria:**
- [ ] ObjectBox SDK integrated into Xcode project
- [ ] DocumentChunk entity defined with required fields (document_id, chunk_id, text, bounding_boxes, embeddings)
- [ ] VectorSearchService implemented with basic CRUD operations
- [ ] Python API integration service for chunking and embedding
- [ ] Performance benchmarks for on-device search established

**Technical Tasks:**
- [ ] Add ObjectBox Swift package dependency
- [ ] Create DocumentChunk @Entity model with fields: document_id, chunk_id, text, bounding_boxes, embeddings
- [ ] Implement VectorSearchService class for on-device operations
- [ ] Create PythonAPIService for chunking and embedding operations
- [ ] Add data migration utilities from existing storage

#### Story 1.3: Python API Integration Service
**As a** developer  
**I want** a service to communicate with the Python API for document processing  
**So that** we can leverage the existing chunking and embedding capabilities  

**Acceptance Criteria:**
- [ ] PythonAPIService implemented with proper error handling
- [ ] Document chunking API integration (returns document_id, chunk_id, text, bounding_boxes, embeddings)
- [ ] Query embedding API integration (returns embedded query vector)
- [ ] Async/await patterns for non-blocking operations
- [ ] Network connectivity and timeout handling
- [ ] API response validation and error states

**Technical Tasks:**
- [ ] Create PythonAPIService class with URLSession
- [ ] Define API request/response models matching Python API
- [ ] Implement document chunking API call
- [ ] Implement query embedding API call
- [ ] Add comprehensive error handling and retry logic
- [ ] Create unit tests for API service

#### Story 1.4: Clerk Authentication Integration
**As a** developer  
**I want** Clerk authentication SDK integrated into the app  
**So that** all users must authenticate before accessing any functionality  

**Acceptance Criteria:**
- [ ] Clerk iOS SDK integrated via Swift Package Manager
- [ ] App launches with authentication gate - no access without login
- [ ] Sign up and sign in flows functional
- [ ] Email verification process working
- [ ] User session management implemented
- [ ] Sign out functionality working

**Technical Tasks:**
- [ ] Add Clerk iOS SDK package dependency (https://github.com/clerk/clerk-ios)
- [ ] Update cerebralApp.swift to configure Clerk with publishable key
- [ ] Create authentication state management in app loading
- [ ] Add environment injection for Clerk instance
- [ ] Implement loading state while Clerk initializes
- [ ] Create error handling for authentication failures

#### Story 1.5: Authentication Views Implementation
**As a** user  
**I want** streamlined sign up and sign in flows  
**So that** I can quickly get authenticated and start using the app  

**Acceptance Criteria:**
- [ ] SignUpView with email/password registration
- [ ] Email verification code entry flow
- [ ] SignInView with email/password authentication
- [ ] SignUpOrSignInView container with toggle between modes
- [ ] Native macOS design consistent with app aesthetic
- [ ] Clear error messaging for authentication failures

**Technical Tasks:**
- [ ] Create SignUpView with email verification flow
- [ ] Create SignInView with credential authentication
- [ ] Create SignUpOrSignInView container
- [ ] Implement proper async error handling
- [ ] Design authentication UI consistent with macOS guidelines
- [ ] Add accessibility support for authentication forms

#### Story 1.6: Core Data Models Refactoring
**As a** developer  
**I want** simplified data models aligned with document-based architecture  
**So that** the codebase is maintainable and performant  

**Acceptance Criteria:**
- [ ] DocumentLibrary model created for document collections
- [ ] ChatSession model updated for document association
- [ ] PDFDocument model aligned with new architecture
- [ ] User-specific data isolation implemented
- [ ] Existing models preserved/migrated appropriately
- [ ] SwiftData integration planned for future phases

**Technical Tasks:**
- [ ] Audit existing models in Models/ directory
- [ ] Create new document-centric models with user association
- [ ] Plan migration strategy for existing data
- [ ] Update ViewModels to work with new models
- [ ] Add user ID tracking to all data models

### Sprint 2: Service Architecture Simplification

#### Story 2.1: Service Container Refactoring
**As a** developer  
**I want** simplified service architecture with clear responsibilities  
**So that** the code is easier to maintain and test  

**Acceptance Criteria:**
- [ ] ServiceContainer complexity reduced
- [ ] Core managers (DocumentManager, ChatManager, etc.) defined
- [ ] Service dependencies clarified and minimized  
- [ ] Existing service functionality preserved
- [ ] Testing strategy updated for new architecture

**Technical Tasks:**
- [ ] Audit existing Services/ directory (20+ services)
- [ ] Identify services to consolidate vs preserve
- [ ] Create DocumentManager, ChatManager, SearchManager
- [ ] Refactor ServiceContainer to be lightweight
- [ ] Update dependency injection patterns

#### Story 2.2: AppModel State Management  
**As a** developer  
**I want** centralized app state using SwiftUI @Observable  
**So that** UI updates are efficient and predictable  

**Acceptance Criteria:**
- [ ] AppModel created with @Observable macro
- [ ] Core managers integrated into AppModel
- [ ] View state management simplified
- [ ] Existing ViewModels updated or deprecated
- [ ] Performance impact assessed and optimized

**Technical Tasks:**
- [ ] Create AppModel with core managers
- [ ] Update existing ViewModels (ChatManager.swift)
- [ ] Refactor Views to use new state management
- [ ] Remove redundant state management code

### Sprint 3: Basic PDF Viewer Integration

#### Story 3.1: Native PDF Viewer Foundation
**As a** user  
**I want** to view PDF documents natively within Cerebral  
**So that** I can read and reference documents without external apps  

**Acceptance Criteria:**
- [ ] PDFKit integration working with existing PDFViewerRepresentable
- [ ] Basic navigation (zoom, pan, page selection) functional
- [ ] PDF loading from document library implemented
- [ ] Performance optimized for large PDFs
- [ ] Error handling for corrupted/unsupported files

**Technical Tasks:**
- [ ] Enhance existing PDFViewerRepresentable.swift
- [ ] Integrate with new DocumentManager
- [ ] Optimize PDF rendering performance
- [ ] Add error states and loading indicators

#### Story 3.2: Document Import & Processing
**As a** user  
**I want** to easily import PDF documents into my library  
**So that** I can build my document collection for AI interaction  

**Acceptance Criteria:**
- [ ] Drag & drop PDF import functional
- [ ] File picker integration working
- [ ] Folder import for bulk operations
- [ ] Processing status indicators shown
- [ ] Text extraction and chunking background processing

**Technical Tasks:**
- [ ] Implement drag & drop handlers
- [ ] Update DocumentService for new architecture
- [ ] Create background processing queue
- [ ] Add progress indicators to UI
- [ ] Integrate with vector search preparation

### Sprint 4: Authentication Modal & Subscription System

#### Story 4.1: Authentication Modal Implementation
**As a** first-time user  
**I want** to see a clear authentication modal when opening the app  
**So that** I can sign in or sign up to access the application  

**Acceptance Criteria:**
- [ ] Modal appears on first app launch blocking all other functionality
- [ ] Clean, native macOS design with SignUpOrSignInView
- [ ] Email/password sign up with verification flow
- [ ] Email/password sign in functionality
- [ ] Toggle between sign up and sign in modes
- [ ] Modal dismisses after successful authentication
- [ ] App launches to main interface after authentication
- [ ] Loading states during authentication process

**Technical Tasks:**
- [ ] Create authentication modal overlay in cerebralApp.swift
- [ ] Implement SignUpView, SignInView, and SignUpOrSignInView
- [ ] Add modal presentation logic based on authentication state
- [ ] Integrate with Clerk authentication flows
- [ ] Add proper error handling and loading states
- [ ] Test modal behavior and app launch sequence

#### Story 4.2: Subscription Tier Management
**As a** newly authenticated user  
**I want** automatic trial access with clear tier limitations  
**So that** I can start using the app and understand upgrade benefits  

**Acceptance Criteria:**
- [ ] New users automatically assigned to Trial tier after authentication
- [ ] Three subscription tiers defined: Trial, Subscription, Purchased
- [ ] Trial tier: Limited document import (3 documents), limited chat messages (50)
- [ ] Subscription tier: Unlimited access with monthly/yearly billing
- [ ] Purchased tier: One-time purchase for lifetime access
- [ ] Tier limitations enforced throughout app
- [ ] Clear messaging about current tier and limitations in UI

**Technical Tasks:**
- [ ] Create SubscriptionManager service
- [ ] Define tier limits and feature gates
- [ ] Integrate with Clerk user metadata for tier tracking
- [ ] Add subscription state monitoring
- [ ] Create tier validation helpers throughout app
- [ ] Add usage tracking for trial limitations

#### Story 4.3: In-App Paywall & Upgrade Flow
**As a** trial user who hits limitations  
**I want** a compelling upgrade experience within the app  
**So that** I can easily purchase more features when I need them  

**Acceptance Criteria:**
- [ ] Paywall triggers when trial limits are reached (documents, messages)
- [ ] Clear value proposition for upgrading displayed
- [ ] Pricing display for subscription and purchase options
- [ ] Integration with App Store for payment processing
- [ ] Smooth upgrade flow with immediate access after purchase
- [ ] Paywall can be dismissed with continued trial limitations
- [ ] Account settings page for subscription management

**Technical Tasks:**
- [ ] Create PaywallView with pricing options and value props
- [ ] Integrate StoreKit for in-app purchases and subscriptions
- [ ] Add subscription management UI in settings
- [ ] Implement upgrade flow with Clerk metadata updates
- [ ] Add purchase restoration functionality
- [ ] Create paywall trigger logic throughout app features

---

## 📋 Phase 2: Core Features (Sprints 5-7)

### Sprint 5: Core App Experience with Trial Limitations

#### Story 5.1: Trial-Limited Document Management
**As a** trial user  
**I want** to import and manage documents within my tier limits  
**So that** I can experience the app value while understanding upgrade benefits  

**Acceptance Criteria:**
- [ ] Document import respects trial limit (3 documents maximum)
- [ ] Clear messaging when approaching/hitting document limit
- [ ] Document library shows usage progress (e.g., "2 of 3 documents")
- [ ] Upgrade prompts appear when limits are reached
- [ ] Full document management functionality within limits
- [ ] Document processing works normally for trial users

**Technical Tasks:**
- [ ] Integrate SubscriptionManager with document import flow
- [ ] Add trial limit checking in DocumentService
- [ ] Update DocumentSidebar to show usage indicators
- [ ] Add upgrade prompts to document management UI
- [ ] Test document limit enforcement across all import methods

#### Story 5.2: Trial-Limited Chat Experience
**As a** trial user  
**I want** to have AI conversations within my message limits  
**So that** I can experience the core app value while understanding the full potential  

**Acceptance Criteria:**
- [ ] Chat messages respect trial limit (50 messages maximum)
- [ ] Message counter visible in chat interface
- [ ] Warning when approaching message limit (e.g., 5 messages remaining)
- [ ] Paywall appears when message limit is reached
- [ ] Full chat functionality available within limits
- [ ] Context-aware responses work normally for trial users

**Technical Tasks:**
- [ ] Integrate SubscriptionManager with chat message tracking
- [ ] Add message limit checking in ChatManager
- [ ] Update ChatView to show message counter
- [ ] Add limit warnings and upgrade prompts to chat UI
- [ ] Test message limit enforcement across all chat features

#### Story 5.3: Settings & Account Management
**As a** user  
**I want** to manage my account, API settings, and subscription  
**So that** I can control my app experience and upgrade when ready  

**Acceptance Criteria:**
- [ ] Settings view accessible from main app interface
- [ ] API configuration (Claude API key, Python endpoint) manageable
- [ ] Current subscription tier and usage clearly displayed
- [ ] Account information and sign out functionality
- [ ] Subscription upgrade options easily accessible
- [ ] Privacy and data management options available

**Technical Tasks:**
- [ ] Create comprehensive SettingsView
- [ ] Integrate API configuration management
- [ ] Add subscription status and usage displays
- [ ] Implement account management functionality
- [ ] Add direct links to upgrade flows
- [ ] Include privacy and data export options

### Sprint 6: Enhanced Document Management

#### Story 6.1: Document Library Interface
**As a** user  
**I want** an organized view of all my imported documents  
**So that** I can easily find and manage my document collection  

**Acceptance Criteria:**
- [ ] Sidebar document list with thumbnails
- [ ] Document metadata display (title, page count, etc.)
- [ ] Search and filter capabilities
- [ ] Document selection and preview
- [ ] Processing status indicators
- [ ] Document count limits enforced by subscription tier

**Technical Tasks:**
- [ ] Enhance existing DocumentSidebar.swift
- [ ] Update DocumentRowView with new design
- [ ] Integrate with new DocumentManager
- [ ] Add thumbnail generation service
- [ ] Implement search functionality
- [ ] Add tier-based document limit enforcement

#### Story 6.2: Document Organization Features
**As a** user  
**I want** to organize my documents into collections  
**So that** I can group related documents for better workflow  

**Acceptance Criteria:**
- [ ] Collection creation and management
- [ ] Drag & drop documents between collections
- [ ] Collection-based filtering
- [ ] Document tagging system
- [ ] Bulk operations (move, delete, tag)
- [ ] Collection limits based on subscription tier

**Technical Tasks:**
- [ ] Extend DocumentLibrary model with collections
- [ ] Create collection management UI
- [ ] Implement drag & drop between collections
- [ ] Add bulk operation capabilities
- [ ] Integrate subscription tier limits for collections

### Sprint 7: Vector Search Migration

#### Story 7.1: ObjectBox Vector Search Implementation
**As a** user  
**I want** fast, accurate document search capabilities  
**So that** I can quickly find relevant information across my library  

**Acceptance Criteria:**
- [ ] Vector search functional with ObjectBox on-device storage
- [ ] Query embedding via Python API integration
- [ ] Search results include relevance scoring and bounding box information
- [ ] Sub-100ms response time for on-device search operations
- [ ] Integration with existing UI components
- [ ] Fallback for API connectivity issues
- [ ] Search functionality respects subscription tier limits

**Technical Tasks:**
- [ ] Complete VectorSearchService implementation for on-device search
- [ ] Integrate PythonAPIService for query embedding
- [ ] Add search result ranking with relevance scores
- [ ] Implement bounding box result processing
- [ ] Performance optimization and caching for search results
- [ ] Add offline fallback mechanisms
- [ ] Integrate subscription tier validation for search operations

#### Story 7.2: Document Indexing Pipeline
**As a** user  
**I want** my documents automatically processed for search  
**So that** I can immediately start finding information  

**Acceptance Criteria:**
- [ ] Automatic document processing via Python API on import
- [ ] Background processing with progress indicators
- [ ] Batch processing for large libraries with API rate limiting
- [ ] Error handling for API failures and network issues
- [ ] Re-indexing capabilities and status tracking
- [ ] Processing respects subscription tier document limits

**Technical Tasks:**
- [ ] Create background processing queue for API calls
- [ ] Integrate PythonAPIService for document chunking and embedding
- [ ] Implement API response processing and ObjectBox storage
- [ ] Add rate limiting and retry logic for API calls
- [ ] Create processing status tracking with detailed error reporting
- [ ] Add batch processing optimization for large document sets
- [ ] Integrate tier limit checking before processing

---

## 📋 Phase 3: Polish & Optimization (Sprints 8-9)

### Sprint 8: UI/UX Refinements

#### Story 8.1: Native macOS Design Implementation
**As a** macOS user  
**I want** Cerebral to feel like a native Mac application  
**So that** it integrates seamlessly with my workflow  

**Acceptance Criteria:**
- [ ] SF Symbols used consistently throughout app
- [ ] Dynamic Type support for accessibility  
- [ ] Dark/Light mode adaptive colors
- [ ] Native materials (sidebar, toolbar, etc.)
- [ ] Proper focus management and keyboard navigation
- [ ] Consistent design with authentication and paywall flows

**Technical Tasks:**
- [ ] Audit existing Views/ directory for design consistency
- [ ] Update DesignSystem.swift with native patterns
- [ ] Implement accessibility features
- [ ] Add keyboard shortcut support
- [ ] Test across different macOS versions
- [ ] Ensure design consistency with authentication screens

#### Story 8.2: Performance Optimization
**As a** user  
**I want** Cerebral to be fast and responsive  
**So that** I can work efficiently without waiting  

**Acceptance Criteria:**
- [ ] App launch time < 2 seconds (including authentication)
- [ ] Vector search response < 100ms
- [ ] Smooth PDF scrolling and zoom
- [ ] Memory usage < 500MB with 100 documents
- [ ] No blocking UI operations
- [ ] Efficient subscription tier checking

**Technical Tasks:**
- [ ] Profile app performance with Instruments
- [ ] Optimize PDF rendering and caching
- [ ] Implement lazy loading for large datasets
- [ ] Add background processing for heavy operations
- [ ] Memory management optimization
- [ ] Optimize authentication and subscription checking

### Sprint 9: Chat System Enhancement

#### Story 9.1: Context-Aware Chat Interface
**As a** user  
**I want** AI conversations that reference specific document content  
**So that** I get precise answers with clear sources  

**Acceptance Criteria:**
- [ ] Chat interface shows document context indicators
- [ ] Clickable references navigate to PDF locations using bounding box coordinates
- [ ] Context selection from multiple documents
- [ ] Visual highlighting of referenced content using stored bounding boxes
- [ ] Chat history with context preservation and visual reference links
- [ ] Chat message limits enforced based on subscription tier

**Technical Tasks:**
- [ ] Enhance existing ChatView.swift
- [ ] Integrate with new vector search results including bounding box data
- [ ] Add document reference navigation using coordinate-based highlighting
- [ ] Update MessageView with context indicators and clickable references
- [ ] Implement chat session persistence with reference link preservation
- [ ] Add tier-based chat message limit enforcement

#### Story 9.2: Streaming Chat Implementation
**As a** user  
**I want** to see AI responses appear in real-time  
**So that** I get immediate feedback and can interrupt if needed  

**Acceptance Criteria:**
- [ ] Streaming responses with token-by-token display
- [ ] Ability to stop generation mid-stream
- [ ] Error handling for connection issues
- [ ] Typing indicators and response status
- [ ] Message editing and regeneration
- [ ] Subscription tier validation before message sending

**Technical Tasks:**
- [ ] Update existing StreamingChatService
- [ ] Implement proper async/await patterns
- [ ] Add response cancellation capability
- [ ] Error state management
- [ ] Integration with new ChatManager
- [ ] Add subscription tier checking before API calls

---

## 📋 Phase 4: Advanced Features (Sprints 10-13)

### Sprint 10: Smart Collections & Auto-Organization

#### Story 10.1: Automatic Document Categorization
**As a** user  
**I want** documents automatically organized by topic/type  
**So that** I can find related content without manual organization  

**Acceptance Criteria:**
- [ ] ML-based document classification
- [ ] Automatic collection suggestions
- [ ] Topic extraction and tagging
- [ ] Similar document grouping
- [ ] User review and override capabilities

**Technical Tasks:**
- [ ] Integrate Create ML for classification
- [ ] Build topic extraction pipeline
- [ ] Create smart collection algorithms
- [ ] Add user feedback mechanisms
- [ ] Performance optimization for large libraries

#### Story 10.2: Related Document Discovery
**As a** user  
**I want** to discover documents related to my current reading  
**So that** I can explore connected topics and information  

**Acceptance Criteria:**
- [ ] "Related Documents" panel in PDF viewer
- [ ] Similarity scoring and ranking
- [ ] Cross-document topic connections
- [ ] Visual relationship indicators
- [ ] Integration with chat context

**Technical Tasks:**
- [ ] Implement document similarity algorithms
- [ ] Create related content UI components
- [ ] Add cross-document relationship tracking
- [ ] Integration with vector search results

### Sprint 11: Multi-Modal Search & Analysis

#### Story 11.1: Advanced Search Capabilities
**As a** user  
**I want** to search across different types of content (text, images, tables)  
**So that** I can find information regardless of format  

**Acceptance Criteria:**
- [ ] Image search within documents
- [ ] Table content extraction and search
- [ ] Formula/equation recognition
- [ ] Combined multi-modal search results
- [ ] Advanced filtering options

**Technical Tasks:**
- [ ] Integrate Vision framework for image analysis
- [ ] Add table extraction capabilities
- [ ] Implement formula recognition
- [ ] Create unified search interface
- [ ] Performance optimization for complex queries

#### Story 11.2: Document Summarization
**As a** user  
**I want** automatic summaries of my documents  
**So that** I can quickly understand content without reading everything  

**Acceptance Criteria:**
- [ ] Chapter/section automatic summaries
- [ ] Key points extraction
- [ ] Executive summary generation
- [ ] Multi-document comparative summaries
- [ ] Summary accuracy and relevance

**Technical Tasks:**
- [ ] Implement summarization algorithms
- [ ] Create summary UI components
- [ ] Add summary caching and management
- [ ] Integration with chat system
- [ ] Quality assessment metrics

### Sprint 12: Collaboration Features

#### Story 12.1: Shared Collections
**As a** team member  
**I want** to share document collections with colleagues  
**So that** we can collaborate on research and analysis  

**Acceptance Criteria:**
- [ ] Collection sharing with permissions
- [ ] Real-time sync of shared documents
- [ ] Access control and user management
- [ ] Shared annotation capabilities
- [ ] Activity tracking and notifications

**Technical Tasks:**
- [ ] Design collaboration data model
- [ ] Implement sharing infrastructure
- [ ] Add user management system
- [ ] Create sync mechanisms
- [ ] Security and privacy controls

#### Story 12.2: Annotation Synchronization
**As a** collaborator  
**I want** to see and contribute to shared annotations  
**So that** team insights are preserved and accessible  

**Acceptance Criteria:**
- [ ] Real-time annotation sync
- [ ] Author attribution for annotations
- [ ] Annotation commenting and discussion
- [ ] Conflict resolution for overlapping annotations
- [ ] Export capabilities for annotations

**Technical Tasks:**
- [ ] Extend existing PDFAnnotationService
- [ ] Add collaborative annotation model
- [ ] Implement real-time sync
- [ ] Create annotation management UI
- [ ] Export/import functionality

### Sprint 13: Advanced AI Features

#### Story 13.1: Question Generation
**As a** user  
**I want** the AI to suggest relevant questions about my documents  
**So that** I can discover insights I might not have thought to ask about  

**Acceptance Criteria:**
- [ ] Context-relevant question suggestions
- [ ] Questions based on document content analysis
- [ ] Interactive question exploration
- [ ] Question quality and relevance
- [ ] Integration with chat interface

**Technical Tasks:**
- [ ] Implement question generation algorithms
- [ ] Create question suggestion UI
- [ ] Add question ranking and filtering
- [ ] Integration with document analysis
- [ ] User feedback collection

#### Story 13.2: Comparative Document Analysis
**As a** researcher  
**I want** to compare insights across multiple documents  
**So that** I can identify patterns and contradictions  

**Acceptance Criteria:**
- [ ] Multi-document comparison interface
- [ ] Contradiction detection
- [ ] Pattern identification across documents
- [ ] Comparative summary generation
- [ ] Visual comparison tools

**Technical Tasks:**
- [ ] Build document comparison algorithms
- [ ] Create comparison visualization components
- [ ] Add pattern detection capabilities
- [ ] Integration with existing search and chat
- [ ] Performance optimization for multiple documents

---

## 🧪 Testing & Quality Assurance Stories

### Automated Testing Epic

#### Story T.1: Unit Test Coverage
**As a** developer  
**I want** comprehensive unit test coverage  
**So that** code changes don't break existing functionality  

**Acceptance Criteria:**
- [ ] >80% code coverage across core services
- [ ] Test cases for all major user workflows
- [ ] Mock services for external dependencies
- [ ] Automated test running in CI/CD
- [ ] Performance regression testing

#### Story T.2: UI Test Automation
**As a** developer  
**I want** automated UI testing for critical user journeys  
**So that** UI changes don't break user workflows  

**Acceptance Criteria:**
- [ ] Onboarding flow automated tests
- [ ] Document import/export test scenarios
- [ ] Chat interaction testing
- [ ] PDF viewer navigation tests
- [ ] Accessibility testing automation

### Manual Testing Epic

#### Story T.3: Device & OS Compatibility
**As a** user  
**I want** Cerebral to work reliably across different Mac models  
**So that** I can use it regardless of my hardware  

**Acceptance Criteria:**
- [ ] Testing on Intel and Apple Silicon Macs
- [ ] macOS 14.0+ compatibility verified
- [ ] Performance testing on older hardware
- [ ] Memory usage testing across devices
- [ ] Graphics compatibility testing

#### Story T.4: Document Format Testing
**As a** user  
**I want** Cerebral to handle various PDF types reliably  
**So that** I can work with any document in my collection  

**Acceptance Criteria:**
- [ ] Password-protected PDF handling
- [ ] Scanned document OCR testing
- [ ] Large file performance testing
- [ ] Corrupted file error handling
- [ ] Various PDF version compatibility

---

## 📊 Definition of Done

### Story Completion Criteria
- [ ] Feature functionality complete per acceptance criteria
- [ ] Unit tests written and passing
- [ ] UI tests for user-facing features
- [ ] Code review completed
- [ ] Documentation updated
- [ ] Accessibility considerations addressed
- [ ] Performance impact assessed
- [ ] Integration testing completed

### Sprint Completion Criteria  
- [ ] All stories meet Definition of Done
- [ ] Sprint demo prepared and delivered
- [ ] Retrospective completed with action items
- [ ] Next sprint backlog refined
- [ ] Technical debt items identified and prioritized

### Release Criteria
- [ ] All acceptance criteria met for phase stories
- [ ] Performance benchmarks achieved
- [ ] Security review completed
- [ ] User acceptance testing passed
- [ ] Documentation and help content complete
- [ ] App Store submission requirements met (for public release)

---

## 🎯 Success Metrics per Epic

### Epic 1: Document-Based App Foundation
- App launches as document-based app with proper file associations
- Document creation/opening workflows work seamlessly
- iCloud integration functional (if implemented)
- User can import and organize documents effectively

### Epic 2: Hybrid Vector Search Architecture
- On-device search response time <100ms achieved
- Python API integration reliable with <2s processing time
- Search accuracy maintained or improved with bounding box precision
- Memory usage within acceptable limits for on-device storage

### Epic 3: Authentication & App Launch
- 100% user authentication requirement enforced via modal gate
- >90% authentication completion rate (users who see modal complete sign up/in)
- App launches successfully after authentication for 100% of users
- Trial users can immediately access limited features after authentication
- Trial-to-paid conversion rate >15%
- Clear subscription tier limitations communicated within app interface

### Epic 4: Enhanced PDF Integration
- PDF viewing performance matches or exceeds native Preview app
- Document navigation smooth and intuitive
- Highlighting and annotation features functional
- Large document handling optimized

### Epic 5: Context-Aware AI Chat
- Document references clickable and accurate
- Context building includes relevant document sections
- Chat response quality maintained or improved
- Streaming responses functional with <2s initial response time
- Chat message limits enforced based on subscription tier

---

---

## 🔐 Authentication & Subscription Implementation Details

### Clerk iOS SDK Integration
Following the provided Clerk quickstart guide:

```swift
// App entry point with authentication gate
@main
struct CerebralApp: App {
    @State private var clerk = Clerk.shared
    
    var body: some Scene {
        DocumentGroup(newDocument: CerebralDocument()) { file in
            ZStack {
                if clerk.isLoaded {
                    if let user = clerk.user {
                        ContentView(document: file.$document)
                    } else {
                        SignUpOrSignInView()
                    }
                } else {
                    ProgressView("Loading...")
                }
            }
            .environment(clerk)
            .task {
                clerk.configure(publishableKey: "YOUR_PUBLISHABLE_KEY")
                try? await clerk.load()
            }
        }
    }
}
```

### Subscription Tier Structure
- **Trial**: 3 documents, 50 chat messages, 7-day limit
- **Subscription**: Unlimited access, $9.99/month or $99/year
- **Purchased**: One-time $199 purchase, lifetime access

### Key Dependencies
- **SwiftUI for MacOS**
- **PDFKit**
- **Clerk iOS SDK**: User authentication and management
- **StoreKit 2**: In-app purchases and subscription management
- **ObjectBox**: On-device vector storage
- **Python API**: Document processing and embedding services

---

*This backlog provides a comprehensive roadmap for rebuilding Cerebral into a production-ready, authenticated macOS application with subscription-based revenue model while leveraging existing code where beneficial and implementing the architectural improvements outlined in the specification.*
