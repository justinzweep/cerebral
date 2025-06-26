# Cerebral Setup Instructions

✅ **Native REST API Implementation Complete!** The chat interface now uses a native URLSession-based implementation with no external dependencies required.

## Quick Start

### 1. ✅ No Package Dependencies Required!
**The app now uses a native REST API implementation** - no external packages needed!

### 2. Get Claude API Key
1. Go to [Anthropic Console](https://console.anthropic.com/)
2. Create an account or sign in
3. Navigate to API Keys
4. Generate a new API key (starts with `sk-ant-`)

### 3. Configure API Key
1. Open Cerebral
2. Press `⌘,` to open Settings
3. Enter your Claude API key in the API Key tab
4. The key will be securely stored in your Keychain

### 4. Start Using
1. Import PDFs using the "Import" button
2. Select a document from the sidebar
3. Toggle the chat panel and start asking questions about your documents!

## Native API Integration

### Implementation Details
- ✅ **Native URLSession**: Direct HTTP requests to Claude API
- ✅ **Zero Dependencies**: No external packages required  
- ✅ **Proper Error Handling**: Network, API, and parsing error coverage
- ✅ **Request/Response Logging**: Detailed debugging information
- ✅ **Secure Storage**: API keys stored in macOS Keychain

## Features

### Core Functionality
- ✅ **PDF Import & Management**: Full document library with folders
- ✅ **Advanced PDF Viewer**: High-quality rendering with navigation  
- ✅ **Claude AI Chat**: Document-aware conversations using Claude 3.5 Sonnet
- ✅ **Annotation System**: Highlights, notes, editing, and persistence
- ✅ **Three-Panel Layout**: Documents | PDF Viewer | Chat+Annotations
- ✅ **Settings Management**: Secure API key configuration

### Document Integration
- ✅ **Document Context**: Chat conversations include PDF content
- ✅ **Text Extraction**: Automatic PDF text parsing for AI context
- ✅ **Metadata Support**: Document titles, authors, page counts
- ✅ **Conversation History**: Persistent chat sessions per document

## Architecture

### SwiftData Models
- `Document`: PDF document management
- `Annotation`: Highlight and note annotations  
- `ChatSession`: Conversation persistence
- `Folder`: Document organization

### Services
- `ClaudeAPIService`: Native REST API implementation
- `KeychainService`: Secure API key storage
- `SettingsManager`: App configuration
- `PDFTextExtractionService`: PDF content parsing

### Views
- Three-panel layout with resizable splits
- Document sidebar with folder organization
- PDF viewer with annotation support
- Chat interface with message history

## Troubleshooting

### API Connection Issues
1. **Verify API Key**: Ensure it starts with `sk-ant-` and is valid
2. **Check Network**: Disable iCloud Private Relay if connection fails
3. **Test Connection**: Use the validation feature in Settings

### PDF Import Issues  
1. **File Permissions**: Ensure Cerebral has file access permissions
2. **PDF Format**: Most standard PDF files are supported
3. **Large Files**: Very large PDFs may take time to process

### Chat Not Working
1. **API Key Required**: Configure your Claude API key in Settings
2. **Document Context**: Select a document for document-aware conversations
3. **Network Connection**: Ensure stable internet connection

## System Requirements
- macOS 14.0 or later
- Internet connection for Claude API
- Valid Anthropic Claude API key

## 🎉 Latest Update: Claude API Integration FIXED!

**All SwiftAnthropic integration issues have been resolved!** The chat interface now uses the correct API patterns and should work properly.

## Quick Setup

### 1. Add SwiftAnthropic Dependency
In Xcode:
1. Go to **File → Add Package Dependencies**
2. Enter: `https://github.com/jamesrochabrun/SwiftAnthropic`
3. Click **Add Package**

### 2. Get Claude API Key
1. Visit [console.anthropic.com](https://console.anthropic.com)
2. Create account or sign in
3. Go to **API Keys** section
4. Create a new API key
5. Copy the key (starts with `sk-ant-`)

### 3. Configure in App
1. Build and run the app
2. Press **⌘,** (Command-comma) to open Settings
3. Go to **API Key** tab
4. Paste your Claude API key
5. Click **Save**

### 4. Start Using
1. Import PDFs using the sidebar
2. Toggle chat panel with message icon
3. Ask questions about your documents!

## 🔧 Issues Fixed

### SwiftAnthropic Integration
- ✅ **Fixed service initialization**: Now using `AnthropicServiceFactory.service(apiKey:)`
- ✅ **Fixed message structure**: Proper `MessageParameter.Message` with correct content types
- ✅ **Fixed model names**: Using `.claude35Sonnet` instead of deprecated models
- ✅ **Fixed response handling**: Correct `MessageResponse.content` extraction
- ✅ **Fixed API patterns**: Following official SwiftAnthropic documentation

### Chat Interface
- ✅ **Proper error handling**: Better error messages and validation
- ✅ **Document context**: PDF text extraction working correctly
- ✅ **Conversation history**: Maintains context across messages
- ✅ **Loading states**: Visual feedback during API calls

## Project Structure

```
cerebral/
├── App/
│   ├── CerebralApp.swift
│   └── ContentView.swift
├── Models/
│   ├── Document.swift
│   ├── Annotation.swift
│   ├── ChatSession.swift
│   └── Folder.swift
├── Views/
│   ├── PDF/
│   ├── Sidebar/
│   ├── Chat/
│   └── Settings/
├── ViewModels/
│   └── ChatManager.swift
└── Services/
    ├── ClaudeAPIService.swift ← **FIXED!**
    ├── KeychainService.swift
    ├── PDFTextExtractionService.swift
    └── SettingsManager.swift
```

## Features Implemented

### ✅ Complete Features
- Three-panel layout (Documents | PDF Viewer | Chat)
- Document import and management
- PDF viewing with PDFKit
- Secure API key storage (Keychain)
- Settings interface (⌘, shortcut)
- **Claude API chat integration** (FIXED!)
- Document-aware conversations
- PDF text extraction for context
- Chat session management

### 🚧 Optional Features (Phase 5)
- Annotation system (highlighting, notes)
- Advanced PDF markup tools

## Troubleshooting

### API Key Issues
- Ensure key starts with `sk-ant-`
- Check key has proper permissions in Anthropic console
- Try removing and re-adding the key

### Build Issues
- Make sure SwiftAnthropic package is properly added
- Clean build folder (⌘+Shift+K)
- Restart Xcode if needed

### Chat Not Working
- Verify API key is valid and saved
- Check internet connection
- Look at console logs for detailed error messages

## Support

If you encounter any issues:
1. Check the troubleshooting section above
2. Verify all dependencies are properly installed
3. Ensure you're using the latest version of the code
4. Check that your Claude API key has sufficient credits

The app is now fully functional for PDF reading with AI chat assistance!

## Features

### 📚 **Document Management**
- Import multiple PDFs at once
- Organize with folders
- Search your document library
- Recent documents tracking

### 📄 **PDF Viewer**
- Native macOS PDF viewing
- Page-by-page navigation
- High-quality rendering
- Zoom and scroll support

### 💬 **AI Chat Integration**
- Full Claude 3.5 Sonnet integration
- Document-aware conversations
- PDF text extraction for context
- Conversation history
- Real-time API status indicator

### 🔐 **Security**
- API keys stored securely in macOS Keychain
- No data sent to third parties (only to Anthropic's Claude API)
- Local document storage

### ⚙️ **Settings**
- API key management with validation
- Real-time connection testing
- Professional settings interface

## Keyboard Shortcuts

- **⌘O**: Import PDF
- **⌘,**: Open Settings
- **⌘W**: Close window
- **⌘Q**: Quit app

## Requirements

- **macOS 14.0+** (Sonoma or later)
- **Xcode 15.0+** for building
- **Active internet connection** for Claude API
- **Anthropic Claude API account** (free tier available)

## Cost Information

Claude API usage is pay-per-use:
- **Claude 3.5 Sonnet**: ~$3 per million input tokens
- **Typical conversation**: $0.01-0.05 per exchange
- **Monitor usage** at console.anthropic.com

---

🎉 **Enjoy your AI-powered PDF reading experience!** 