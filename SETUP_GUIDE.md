# MyAI Development Setup Guide

A simple copy-paste guide to get MyAI running on Mac or Windows for development.

## Prerequisites

### Windows
```bash
# Install Flutter (if not already installed)
winget install -e --id Google.Flutter

# Install Ollama for local AI
winget install -e --id Ollama.Ollama

# Add Flutter to PATH (restart terminal after this)
setx PATH "%PATH%;C:\Users\%USERNAME%\flutter\bin"
```

### Mac
```bash
# Install Flutter (if not already installed)
curl -fsSL https://flutter.dev/docs/get-started/install/macos | sh

# Install Ollama for local AI  
curl -fsSL https://ollama.ai/install.sh | sh

# Add Flutter to PATH
echo 'export PATH="$PATH:`pwd`/flutter/bin"' >> ~/.zshrc
source ~/.zshrc
```

## Setup Commands (Copy & Paste)

### 1. Clone and Setup Project
```bash
# Clone the repository
git clone <your-repo-url>
cd MyAI

# Navigate to Flutter project
cd myai_ux

# Get Flutter dependencies
flutter pub get

# Enable web and desktop platforms
flutter config --enable-web
flutter config --enable-windows-desktop  # Windows only
flutter config --enable-macos-desktop    # Mac only
```

### 2. Setup Ollama AI Model
```bash
# Start Ollama server
ollama serve

# In a new terminal, pull a lightweight AI model
ollama pull qwen2:0.5b

# Verify the model is installed
ollama list
```

### 3. Run the Application

#### For Web Development (Recommended)
```bash
# Run on web browser
flutter run -d chrome --web-port 8080

# Or build for production
flutter build web --release
```

#### For Desktop Development

**Windows:**
```bash
flutter run -d windows
```

**Mac:**
```bash
flutter run -d macos
```

### 4. Verify Everything Works

1. Open your browser to `http://localhost:8080` (if using web)
2. You should see the MyAI interface
3. Check that "Ollama" shows as available in the UI
4. Try uploading some documents and asking questions about them

## Troubleshooting

### If Ollama shows as "Not Available"
```bash
# Check if Ollama is running
curl http://localhost:11434/api/tags

# If not running, start it
ollama serve

# Pull a model if none exist
ollama pull qwen2:0.5b
```

### If Flutter build fails
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter run -d chrome --web-port 8080
```

### Port Issues
```bash
# Use different port if 8080 is busy
flutter run -d chrome --web-port 3000
```

## Development Workflow

1. **Start Ollama**: `ollama serve`
2. **Run Flutter**: `flutter run -d chrome --web-port 8080`
3. **Make changes** to code files
4. **Hot reload** with `r` in the terminal or save files in your editor

## Available AI Models

- `qwen2:0.5b` - Fast, lightweight (352MB) - Recommended for development
- `tinyllama:1.1b` - Slightly larger but more capable (637MB)
- `phi3.5:3.8b` - Larger, more powerful (2.2GB) - For production use

To switch models:
```bash
ollama pull <model-name>
```

## Project Structure

```
MyAI/
├── myai_ux/           # Flutter web/desktop app
│   ├── lib/
│   │   ├── main.dart           # Main app entry
│   │   ├── services/           # AI and data services
│   │   ├── screens/            # UI screens
│   │   ├── widgets/            # Reusable components
│   │   └── models/             # Data models
│   └── pubspec.yaml           # Flutter dependencies
├── myai-mvp/          # Rust backend (optional)
└── SETUP_GUIDE.md     # This guide
```

## Key Features

- **Document Upload & Analysis**: Upload PDFs, text files, images
- **AI-Powered Insights**: Ask questions about your documents
- **Knowledge Graph**: Visual representation of document relationships
- **Local AI**: All AI processing happens locally via Ollama
- **Cross-Platform**: Runs on Web, Windows, and macOS

---

**Ready to develop!** Start with `ollama serve` and `flutter run -d chrome --web-port 8080`