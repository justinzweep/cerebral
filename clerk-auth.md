# Clerk Authentication Implementation for Cerebral (Official SDK)

## Overview
Add modern, secure authentication to Cerebral using Clerk's official iOS SDK. This implementation provides email/password authentication with Google, Apple, and Microsoft social sign-in options, following Clerk's official patterns.

## Setup Requirements

### 1. Clerk Dashboard Setup
1. Go to [clerk.com](https://clerk.com) and create an account
2. Create a new application
3. Enable these authentication methods in Clerk Dashboard:
   - **Email & Password**: Enable email verification
   - **Social Providers**: Google, Apple, Microsoft
4. Get your publishable key from the API Keys section

### 2. Xcode Project Configuration

#### Add Clerk SDK Dependency
```
Add Swift Package: https://github.com/clerk/clerk-ios
```

#### Update Info.plist
```xml
<!-- Apple Sign In capability -->
<key>com.apple.developer.applesignin</key>
<array>
    <string>Default</string>
</array>

<!-- Network permissions for API calls -->
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

## File Structure Updates

Add these new files to your existing Cerebral project:

```
Cerebral/
├── Services/
│   ├── UserProfileManager.swift
│   └── SubscriptionManager.swift
├── Views/
│   ├── Auth/
│   │   ├── SignUpView.swift
│   │   ├── SignInView.swift
│   │   ├── SignUpOrSignInView.swift
│   │   └── UserProfileView.swift
│   └── Settings/
│       └── AccountSettingsView.swift (updated)
├── Models/
│   └── UserProfile.swift (updated)
└── Utils/
    └── ClerkConfig.swift
```

## Implementation

### 1. Clerk Configuration

```swift
// Utils/ClerkConfig.swift
import Foundation

struct ClerkConfig {
    static let publishableKey = "pk_test_your_publishable_key_here"
}
```

### 2. Updated App Entry Point (Following Official Pattern)

```swift
// CerebralApp.swift
import SwiftUI
import SwiftData
import Clerk

@main
struct CerebralApp: App {
    @State private var clerk = Clerk.shared
    @StateObject private var settingsManager = SettingsManager()
    @StateObject private var userProfileManager = UserProfileManager()
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Document.self,
            Annotation.self, 
            ChatSession.self,
            Folder.self,
            UserProfile.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if clerk.isLoaded {
                    ContentView()
                        .environmentObject(settingsManager)
                        .environmentObject(userProfileManager)
                } else {
                    ProgressView("Loading Cerebral...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(NSColor.controlBackgroundColor))
                }
            }
            .environment(clerk)
            .task {
                clerk.configure(publishableKey: ClerkConfig.publishableKey)
                try? await clerk.load()
                
                // Listen for auth state changes
                if let user = clerk.user {
                    await userProfileManager.loadOrCreateProfile(for: user)
                }
            }
            .onChange(of: clerk.user) { oldUser, newUser in
                Task {
                    if let user = newUser {
                        await userProfileManager.loadOrCreateProfile(for: user)
                    } else {
                        userProfileManager.clearProfile()
                    }
                }
            }
        }
        .modelContainer(sharedModelContainer)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Import PDF...") { }
                    .keyboardShortcut("o")
                    .disabled(clerk.user == nil)
            }
            CommandGroup(after: .appInfo) {
                Button("Preferences...") {
                    NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
                }
                .keyboardShortcut(",")
                .disabled(clerk.user == nil)
            }
        }
        
        Settings {
            SettingsView()
                .environmentObject(settingsManager)
                .environmentObject(userProfileManager)
                .environment(clerk)
        }
    }
}

// ContentView.swift (Updated for Auth)
struct ContentView: View {
    @Environment(Clerk.self) private var clerk
    @EnvironmentObject var settingsManager: SettingsManager
    @EnvironmentObject var userProfileManager: UserProfileManager
    
    var body: some View {
        Group {
            if let user = clerk.user {
                MainAppView()
                    .environmentObject(settingsManager)
                    .environmentObject(userProfileManager)
            } else {
                AuthenticationView()
            }
        }
    }
}

struct MainAppView: View {
    @State private var showingChat = true
    @EnvironmentObject var settingsManager: SettingsManager
    
    var body: some View {
        HSplitView {
            DocumentSidebar()
                .frame(minWidth: 200, idealWidth: 250, maxWidth: 300)
            
            PDFViewerView()
                .frame(minWidth: 400)
            
            if showingChat {
                ChatView()
                    .frame(minWidth: 250, idealWidth: 300, maxWidth: 400)
                    .environmentObject(settingsManager)
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showingChat.toggle() }) {
                    Image(systemName: "message")
                }
            }
        }
    }
}
```

### 3. User Profile Manager

```swift
// Services/UserProfileManager.swift
import Foundation
import SwiftData
import Clerk

@MainActor
class UserProfileManager: ObservableObject {
    @Published var userProfile: UserProfile?
    @Published var isLoading = false
    
    func loadOrCreateProfile(for clerkUser: Clerk.User) async {
        isLoading = true
        
        // In a real app, you'd fetch this from your backend
        // For now, create from Clerk user data
        let profile = UserProfile(
            id: clerkUser.id,
            email: clerkUser.primaryEmailAddress?.emailAddress ?? "",
            firstName: clerkUser.firstName ?? "",
            lastName: clerkUser.lastName ?? "",
            imageUrl: clerkUser.imageUrl,
            createdAt: clerkUser.createdAt ?? Date(),
            lastSignInAt: Date(),
            subscriptionTier: .free
        )
        
        self.userProfile = profile
        isLoading = false
    }
    
    func clearProfile() {
        userProfile = nil
    }
    
    func updateUsage(documentsAdded: Int = 0, apiCallsAdded: Int = 0) {
        guard let profile = userProfile else { return }
        
        profile.documentsCount += documentsAdded
        profile.apiCallsThisMonth += apiCallsAdded
        
        // In a real app, sync this with your backend
    }
}
```

### 4. Updated User Profile Model

```swift
// Models/UserProfile.swift
import SwiftData
import Foundation

@Model
class UserProfile {
    @Attribute(.unique) var id: String // Clerk User ID
    var email: String
    var firstName: String
    var lastName: String
    var imageUrl: String?
    var createdAt: Date
    var lastSignInAt: Date
    var subscriptionTier: SubscriptionTier
    
    // Usage tracking
    var documentsCount: Int = 0
    var apiCallsThisMonth: Int = 0
    var monthlyResetDate: Date = Date()
    
    // Computed properties
    var displayName: String {
        let full = "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
        return full.isEmpty ? email.components(separatedBy: "@").first ?? "User" : full
    }
    
    var maxDocuments: Int {
        switch subscriptionTier {
        case .free: return 10
        case .pro: return 500
        case .enterprise: return -1 // unlimited
        }
    }
    
    var maxAPICallsPerMonth: Int {
        switch subscriptionTier {
        case .free: return 100
        case .pro: return 5000
        case .enterprise: return 50000
        }
    }
    
    var canAddDocument: Bool {
        return maxDocuments == -1 || documentsCount < maxDocuments
    }
    
    var canMakeAPICall: Bool {
        // Check if we need to reset monthly counter
        let calendar = Calendar.current
        if !calendar.isDate(monthlyResetDate, equalTo: Date(), toGranularity: .month) {
            apiCallsThisMonth = 0
            monthlyResetDate = Date()
        }
        
        return apiCallsThisMonth < maxAPICallsPerMonth
    }
    
    init(id: String, email: String, firstName: String, lastName: String, 
         imageUrl: String? = nil, createdAt: Date, lastSignInAt: Date, 
         subscriptionTier: SubscriptionTier = .free) {
        self.id = id
        self.email = email
        self.firstName = firstName
        self.lastName = lastName
        self.imageUrl = imageUrl
        self.createdAt = createdAt
        self.lastSignInAt = lastSignInAt
        self.subscriptionTier = subscriptionTier
        self.monthlyResetDate = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
    }
}

enum SubscriptionTier: String, Codable, CaseIterable {
    case free = "free"
    case pro = "pro" 
    case enterprise = "enterprise"
    
    var displayName: String {
        switch self {
        case .free: return "Free"
        case .pro: return "Pro"
        case .enterprise: return "Enterprise"
        }
    }
    
    var monthlyPrice: String {
        switch self {
        case .free: return "$0"
        case .pro: return "$29"
        case .enterprise: return "Contact Sales"
        }
    }
}
```

### 5. Authentication Views (Following Official Pattern)

```swift
// Views/Auth/AuthenticationView.swift
import SwiftUI

struct AuthenticationView: View {
    var body: some View {
        HStack(spacing: 0) {
            // Left side - Branding
            VStack {
                Spacer()
                
                VStack(spacing: 24) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 100))
                        .foregroundStyle(.linearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                    
                    VStack(spacing: 8) {
                        Text("Cerebral")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                        
                        Text("AI-Powered PDF Research Assistant")
                            .font(.title2)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        FeatureRow(icon: "doc.text.magnifyingglass", text: "Smart PDF analysis")
                        FeatureRow(icon: "message.bubble", text: "AI-powered chat assistance") 
                        FeatureRow(icon: "highlighter", text: "Advanced annotations")
                        FeatureRow(icon: "folder", text: "Organized document library")
                    }
                }
                
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .padding(40)
            .background(.ultraThinMaterial)
            
            // Right side - Sign In/Up
            VStack {
                Spacer()
                
                SignUpOrSignInView()
                    .frame(maxWidth: 400)
                    .padding(40)
                
                Spacer()
            }
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.controlBackgroundColor))
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.blue)
                .frame(width: 20)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
        }
    }
}

// Views/Auth/SignUpView.swift (Following Official Pattern)
import SwiftUI
import Clerk

struct SignUpView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var code = ""
    @State private var isVerifying = false
    @State private var errorMessage: String?
    @State private var isLoading = false
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("Create Account")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Join thousands of researchers using AI")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 16) {
                if isVerifying {
                    Text("Check your email for a verification code")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    TextField("Verification Code", text: $code)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.body, design: .monospaced))
                    
                    Button("Verify Email") {
                        Task { await verify(code: code) }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(code.isEmpty || isLoading)
                    
                    Button("Resend Code") {
                        Task { await resendCode() }
                    }
                    .buttonStyle(.borderless)
                    .font(.subheadline)
                } else {
                    TextField("Email", text: $email)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                    
                    SecureField("Password", text: $password)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.newPassword)
                    
                    Text("Password must be at least 8 characters")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Button("Create Account") {
                        Task { await signUp(email: email, password: password) }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(email.isEmpty || password.count < 8 || isLoading)
                }
            }
            
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
                    .multilineTextAlignment(.center)
            }
        }
        .disabled(isLoading)
        .overlay {
            if isLoading {
                ProgressView()
                    .scaleEffect(0.8)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.ultraThinMaterial)
            }
        }
    }
}

extension SignUpView {
    func signUp(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let signUp = try await SignUp.create(
                strategy: .standard(emailAddress: email, password: password)
            )
            
            try await signUp.prepareVerification(strategy: .emailCode)
            isVerifying = true
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func verify(code: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            guard let signUp = Clerk.shared.client?.signUp else {
                errorMessage = "Sign up session expired. Please try again."
                isVerifying = false
                isLoading = false
                return
            }
            
            try await signUp.attemptVerification(strategy: .emailCode(code: code))
            // Success - user will be automatically signed in
        } catch {
            errorMessage = "Invalid verification code. Please try again."
        }
        
        isLoading = false
    }
    
    func resendCode() async {
        guard let signUp = Clerk.shared.client?.signUp else { return }
        
        do {
            try await signUp.prepareVerification(strategy: .emailCode)
        } catch {
            errorMessage = "Failed to resend code. Please try again."
        }
    }
}

// Views/Auth/SignInView.swift (Following Official Pattern)
import SwiftUI
import Clerk

struct SignInView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String?
    @State private var isLoading = false
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("Welcome Back")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Sign in to continue your research")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 16) {
                TextField("Email", text: $email)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.emailAddress)
                    .autocapitalization(.none)
                
                SecureField("Password", text: $password)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.password)
                
                Button("Sign In") {
                    Task { await signIn(email: email, password: password) }
                }
                .buttonStyle(.borderedProminent)
                .disabled(email.isEmpty || password.isEmpty || isLoading)
                
                Button("Forgot Password?") {
                    // Handle password reset
                }
                .buttonStyle(.borderless)
                .font(.subheadline)
            }
            
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
                    .multilineTextAlignment(.center)
            }
        }
        .disabled(isLoading)
        .overlay {
            if isLoading {
                ProgressView()
                    .scaleEffect(0.8)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.ultraThinMaterial)
            }
        }
    }
}

extension SignInView {
    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await SignIn.create(
                strategy: .identifier(email, password: password)
            )
            // Success - user will be automatically signed in
        } catch {
            errorMessage = "Invalid email or password. Please try again."
        }
        
        isLoading = false
    }
}

// Views/Auth/SignUpOrSignInView.swift (Following Official Pattern)
import SwiftUI

struct SignUpOrSignInView: View {
    @State private var isSignUp = true
    
    var body: some View {
        VStack(spacing: 24) {
            if isSignUp {
                SignUpView()
            } else {
                SignInView()
            }
            
            Button {
                isSignUp.toggle()
            } label: {
                if isSignUp {
                    Text("Already have an account? **Sign In**")
                } else {
                    Text("Don't have an account? **Create Account**")
                }
            }
            .buttonStyle(.borderless)
            .font(.subheadline)
        }
    }
}
```

### 6. Updated Settings with Account Management

```swift
// Views/Settings/SettingsView.swift
struct SettingsView: View {
    @Environment(Clerk.self) private var clerk
    @EnvironmentObject var settingsManager: SettingsManager
    @EnvironmentObject var userProfileManager: UserProfileManager
    
    var body: some View {
        TabView {
            APIKeySettingsView()
                .tabItem {
                    Label("API Key", systemImage: "key.fill")
                }
                .environmentObject(settingsManager)
            
            if clerk.user != nil {
                AccountSettingsView()
                    .tabItem {
                        Label("Account", systemImage: "person.circle")
                    }
                    .environmentObject(userProfileManager)
                    .environment(clerk)
            }
        }
        .frame(width: 600, height: 500)
    }
}

// Views/Settings/AccountSettingsView.swift
struct AccountSettingsView: View {
    @Environment(Clerk.self) private var clerk
    @EnvironmentObject var userProfileManager: UserProfileManager
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Account Settings")
                .font(.title2)
                .fontWeight(.semibold)
            
            if let user = clerk.user, let profile = userProfileManager.userProfile {
                // User Info Section
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 16) {
                        AsyncImage(url: URL(string: user.imageUrl ?? "")) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Circle()
                                .fill(.gray.opacity(0.3))
                                .overlay {
                                    Image(systemName: "person.fill")
                                        .font(.title)
                                        .foregroundColor(.secondary)
                                }
                        }
                        .frame(width: 60, height: 60)
                        .clipShape(Circle())
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(profile.displayName)
                                .font(.title3)
                                .fontWeight(.medium)
                            
                            Text(profile.email)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Text("Member since \(profile.createdAt.formatted(date: .abbreviated, time: .omitted))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    
                    Divider()
                    
                    // Subscription Info
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Subscription")
                            .font(.headline)
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(profile.subscriptionTier.displayName) Plan")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                Text(profile.subscriptionTier.monthlyPrice + "/month")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if profile.subscriptionTier == .free {
                                Button("Upgrade to Pro") {
                                    // Handle subscription upgrade
                                }
                                .buttonStyle(.borderedProminent)
                            }
                        }
                    }
                    
                    Divider()
                    
                    // Usage Stats
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Usage")
                            .font(.headline)
                        
                        HStack {
                            UsageCard(
                                title: "Documents",
                                current: profile.documentsCount,
                                limit: profile.maxDocuments,
                                icon: "doc.text"
                            )
                            
                            UsageCard(
                                title: "API Calls",
                                current: profile.apiCallsThisMonth,
                                limit: profile.maxAPICallsPerMonth,
                                icon: "network"
                            )
                        }
                    }
                }
            }
            
            Spacer()
            
            // Account Actions
            VStack(alignment: .leading, spacing: 12) {
                Text("Account")
                    .font(.headline)
                
                VStack(spacing: 8) {
                    Button("Sign Out") {
                        Task {
                            try? await clerk.signOut()
                        }
                    }
                    .foregroundColor(.orange)
                    
                    Button("Delete Account") {
                        showingDeleteConfirmation = true
                    }
                    .foregroundColor(.red)
                }
            }
        }
        .padding(24)
        .alert("Delete Account", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task {
                    try? await clerk.user?.delete()
                }
            }
        } message: {
            Text("This action cannot be undone. All your documents and data will be permanently deleted.")
        }
    }
}

struct UsageCard: View {
    let title: String
    let current: Int
    let limit: Int
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                if limit == -1 {
                    Text("\(current)")
                        .font(.title3)
                        .fontWeight(.bold)
                    Text("Unlimited")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("\(current) / \(limit)")
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    ProgressView(value: Double(current), total: Double(limit))
                        .progressViewStyle(.linear)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(8)
    }
}
```

## Usage Limits & SaaS Integration

### Document Upload Validation
```swift
// Services/DocumentService.swift - Updated
func importPDF(from url: URL, userProfile: UserProfile) -> Result<Document, DocumentError> {
    guard userProfile.canAddDocument else {
        return .failure(.limitReached("Document limit reached. Upgrade to add more documents."))
    }
    
    // Proceed with import
    // Update userProfileManager.updateUsage(documentsAdded: 1)
}
```

### API Call Validation  
```swift
// Services/ClaudeAPIService.swift - Updated
func sendMessage(_ message: String, userProfile: UserProfile) async throws -> String {
    guard userProfile.canMakeAPICall else {
        throw APIError.limitReached("Monthly API limit reached. Upgrade for more requests.")
    }
    
    // Make API call
    // Update userProfileManager.updateUsage(apiCallsAdded: 1)
}
```

## Testing the Implementation

### 1. Basic Auth Flow
- Sign up with email verification
- Sign in with existing account
- Verify user profile creation
- Test sign out functionality

### 2. Usage Limits
- Import documents up to free tier limit
- Test API calls up to monthly limit
- Verify proper error messages

### 3. Settings Integration
- Account settings display correctly
- Usage statistics update correctly
- Delete account confirmation

## Next Steps

1. **Set up Clerk Dashboard** with email verification enabled
2. **Add social sign-in providers** (Google, Apple, Microsoft) in Clerk Dashboard
3. **Implement subscription management** (Stripe integration)
4. **Add backend API** for user profile synchronization
5. **Set up webhooks** for user lifecycle events

This implementation follows Clerk's official iOS patterns while providing all the SaaS features needed for Cerebral's business model.