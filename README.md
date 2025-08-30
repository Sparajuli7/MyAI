# MyAI - Privacy-First Personal AGI System

A complete privacy-first AI data hub combining knowledge graph visualization with local LLM integration. MyAI provides an intuitive interface for exploring interconnected data and querying it with local AI models - your personal AI assistant that keeps everything private.

## 🚀 Quick Start

### One-Command Setup (Windows)

```powershell
# Install Ollama for local LLM support
iwr -useb https://ollama.ai/install.ps1 | iex

# Pull the gemma3:270m model (small, fast model for testing)
ollama pull gemma3:270m

# Install Flutter (if not already installed)
# Download from: https://flutter.dev/docs/get-started/install/windows

# Clone and run MyAI
git clone https://github.com/your-repo/myai
cd myai/myai_ux
flutter pub get
flutter run -d chrome --web-port 8080
```

### One-Command Setup (Mac/Linux)

```bash
# Install Ollama
curl -fsSL https://ollama.ai/install.sh | sh

# Pull the gemma3:270m model
ollama pull gemma3:270m

# Install Flutter (if not already installed)
# Download from: https://flutter.dev/docs/get-started/install

# Clone and run MyAI
git clone https://github.com/your-repo/myai
cd myai/myai_ux
flutter pub get
flutter run -d chrome --web-port 8080
```

**That's it!** Your MyAI system will be running at `http://localhost:8080` with:
- ✅ Interactive knowledge graph visualization
- ✅ Local LLM integration (gemma3:270m)
- ✅ Privacy-first architecture (all processing local)
- ✅ Rich demo data for immediate exploration

---

## 🌟 Features

### 🕸️ Interactive Knowledge Graph
- **Visual Node-Link Visualization**: See your data as interconnected nodes with relationship detection
- **Dynamic Layout**: Force-directed graph layout with real-time positioning
- **Multi-Selection**: Click nodes to select multiple documents for AI analysis
- **Relationship Detection**: Automatic detection of semantic, temporal, and entity-based connections
- **Constellation Clustering**: Data grouped by type (personal, work, projects)

### 🤖 Local LLM Integration
- **Ollama Integration**: Built-in support for local Ollama models
- **Document-Aware Queries**: Ask questions about selected documents with full context
- **Streaming Responses**: Real-time AI responses with progress indicators
- **Privacy-First**: All AI processing happens locally on your machine
- **Model Support**: Optimized for small, fast models like gemma3:270m

### 🔍 Advanced Search & Discovery
- **Hybrid Search**: BM25 + HNSW vector search with reranking
- **Real-time Results**: Instant search with relevance scoring
- **Semantic Understanding**: Vector embeddings for meaning-based search
- **Temporal Filtering**: Search by date ranges and time periods

### 🎨 Modern Interface
- **Responsive Design**: Works on desktop, tablet, and mobile
- **Dark/Light Themes**: Multiple theme options including Nepal Sunset
- **Smooth Animations**: Fluid transitions and interactive feedback
- **Accessibility**: Screen reader support and keyboard navigation

### 🛡️ Privacy & Security
- **Local-Only Processing**: No data leaves your device
- **Optional Encryption**: SQLCipher support for encrypted storage
- **On-Device Models**: All AI inference runs locally
- **No Telemetry**: Zero data collection or tracking

---

## 📋 System Requirements

### Minimum Requirements
- **OS**: Windows 10+, macOS 10.14+, or Linux Ubuntu 18.04+
- **RAM**: 8GB (recommended for LLM models)
- **Storage**: 2GB free space
- **Network**: Internet connection for initial setup only

### Recommended Setup
- **OS**: Windows 11, macOS 12+, or Linux Ubuntu 20.04+
- **RAM**: 16GB+ (for larger LLM models)
- **CPU**: 8+ cores (for faster AI inference)
- **Storage**: 10GB+ (for multiple models and data)

---

## 🛠️ Detailed Installation

### Step 1: Install Dependencies

#### Install Flutter
```bash
# Windows (using winget)
winget install Google.Flutter

# macOS (using brew)
brew install flutter

# Linux
snap install flutter --classic

# Verify installation
flutter doctor
```

#### Install Ollama
```bash
# Windows
iwr -useb https://ollama.ai/install.ps1 | iex

# macOS
brew install ollama

# Linux
curl -fsSL https://ollama.ai/install.sh | sh
```

### Step 2: Setup LLM Models

```bash
# Start Ollama service (if not auto-started)
ollama serve

# Pull recommended models
ollama pull gemma3:270m        # Small, fast model (291MB)
ollama pull qwen2.5:0.5b       # Alternative small model (397MB)

# Optional: Larger models (if you have 16GB+ RAM)
ollama pull llama3.2:3b        # Better quality, larger (2GB)
```

### Step 3: Setup MyAI

```bash
# Clone the repository
git clone https://github.com/your-repo/myai
cd myai/myai_ux

# Install Flutter dependencies
flutter pub get

# Enable web support (if not already enabled)
flutter config --enable-web

# Run the application
flutter run -d chrome --web-port 8080
```

### Step 4: Verify Installation

Open `http://localhost:8080` and you should see:
- Interactive knowledge graph with demo data
- AI assistant panel (click the brain icon to activate)
- Ability to select nodes and ask AI questions about them

---

## 🎯 Usage Guide

### Basic Workflow
1. **Explore the Graph**: The main view shows your data as interconnected nodes
2. **Select Documents**: Click nodes to select them (they'll highlight with a white ring)
3. **Activate AI Panel**: Click the brain/psychology icon to open the AI assistant
4. **Ask Questions**: Type questions about your selected documents
5. **Get AI Responses**: The local LLM will analyze your documents and respond

### Example Queries
With demo data selected, try asking:
- "What is my visa status?"
- "Summarize the meeting notes"
- "When do I need to renew my documents?"
- "What are the key topics in these documents?"

### Graph Navigation
- **Pan**: Click and drag to move around the graph
- **Zoom**: Use mouse wheel to zoom in/out
- **Select**: Click nodes to select/deselect them
- **Info Panel**: Selected documents appear in the bottom-left panel

### AI Assistant Features
- **Document Context**: AI has full access to selected document content
- **Streaming**: Watch responses appear in real-time
- **Chat History**: Previous questions and answers are preserved
- **Status Indicators**: See when AI is thinking vs. responding

---

## 🔧 Configuration

### Model Configuration
Edit `lib/services/ollama_client.dart` to change default model:
```dart
class LLMService {
  String? preferredModel = 'gemma3:270m';  // Change this
  // ...
}
```

### Graph Layout
Modify graph appearance in `lib/widgets/simple_graph_widget.dart`:
```dart
// Adjust node spacing
final x = (i % 5) * 120.0 + 100;  // Change spacing here
final y = (i ~/ 5) * 120.0 + 100;
```

### Demo Data
Customize demo data in `lib/services/demo_data.dart`:
```dart
static List<DataItem> get richDemoData => [
  // Add your own demo data here
];
```

---

## 🏗️ Architecture

### Frontend (Flutter)
- **Framework**: Flutter Web with responsive design
- **State Management**: Provider pattern for reactive updates
- **UI Components**: Custom widgets for graph and AI panels
- **Animations**: Smooth transitions and real-time updates

### LLM Integration
- **API**: Ollama REST API for local model inference
- **Models**: Support for any Ollama-compatible model
- **Context**: Document content passed as context to LLM
- **Streaming**: Real-time response streaming

### Knowledge Graph
- **Layout**: Force-directed graph algorithm
- **Relationships**: Semantic, temporal, and entity-based connections
- **Rendering**: Custom Canvas painting for performance
- **Interaction**: Touch/click handling for node selection

### Data Processing
- **Search**: Hybrid BM25 + vector search (backend)
- **Embeddings**: MiniLM-L6-v2 for semantic understanding
- **Storage**: SQLite with optional encryption
- **Privacy**: All processing local, no external APIs

---

## 🧪 Testing

### Run Integration Tests
```bash
# Test system components
python test_simple.py
```

### Manual Testing Checklist
- [ ] Flutter app loads at http://localhost:8080
- [ ] Graph displays with demo data nodes
- [ ] Nodes can be selected (white ring appears)
- [ ] AI panel opens when brain icon clicked
- [ ] AI responds to questions about selected documents
- [ ] Ollama service running (`ollama list` shows models)

### Performance Testing
```bash
# Test LLM response time
curl -X POST "http://localhost:11434/api/generate" \
  -H "Content-Type: application/json" \
  -d '{"model": "gemma3:270m", "prompt": "Hello", "stream": false}'
```

---

## 🐛 Troubleshooting

### Common Issues

#### "Ollama not available" in AI panel
```bash
# Check if Ollama is running
ollama list

# If not running, start it
ollama serve

# Verify models are installed
ollama pull gemma3:270m
```

#### Flutter build errors
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter build web --release
```

#### White/blank page after loading
```bash
# Check browser console for errors
# Try running in development mode
flutter run -d chrome --debug
```

#### AI responses are slow
- Try smaller models: `ollama pull gemma3:270m`
- Ensure sufficient RAM (8GB+ recommended)
- Close other memory-intensive applications

### Debug Mode
```bash
# Run with verbose output
flutter run -d chrome --debug --verbose

# Check Ollama logs
ollama logs
```

---

## 🤝 Contributing

### Development Setup
```bash
git clone https://github.com/your-repo/myai
cd myai/myai_ux
flutter pub get
flutter analyze  # Check for issues
flutter test     # Run tests
```

### Project Structure
```
myai/
├── myai-mvp/                  # Rust backend (future integration)
├── myai_ux/                   # Flutter frontend
│   ├── lib/
│   │   ├── main.dart         # Main app entry point
│   │   ├── services/         # API and data services
│   │   │   ├── ollama_client.dart    # LLM integration
│   │   │   └── demo_data.dart        # Sample data
│   │   └── widgets/          # UI components
│   │       ├── simple_graph_widget.dart    # Knowledge graph
│   │       └── simple_llm_panel.dart       # AI assistant
│   └── pubspec.yaml          # Flutter dependencies
└── README.md                 # This file
```

### Adding New Features
1. Create feature branch: `git checkout -b feature/your-feature`
2. Implement changes with tests
3. Run: `flutter analyze && flutter test`
4. Submit pull request with description

---

## 📖 Additional Documentation

- **[Backend Architecture](FOR_WILDER.md)**: Detailed Rust backend analysis
- **[Demo Guide](DEMO_GUIDE.md)**: Step-by-step demo walkthrough
- **[UX README](myai_ux/README.md)**: Frontend-specific documentation

---

## 🚀 What's Next

### Short Term (v1.1)
- [ ] Backend integration with Rust search engine
- [ ] Real document ingestion (PDFs, Word, etc.)
- [ ] Advanced graph layout algorithms
- [ ] Model switching in UI

### Medium Term (v2.0)
- [ ] Multi-user support
- [ ] Synchronization across devices
- [ ] Plugin system for new data sources
- [ ] Advanced visualization options

### Long Term (v3.0+)
- [ ] Graph-RAG implementation
- [ ] Entity extraction and linking
- [ ] Real-time collaboration features
- [ ] Mobile app versions

---

## 📄 License

This project is open-source software. See individual component licenses for details.

---

## 🙏 Acknowledgments

- **Ollama Team**: For making local LLM inference accessible
- **Flutter Team**: For the excellent cross-platform framework
- **HuggingFace**: For open-source AI models and embeddings
- **Community**: For feedback and contributions

---

**MyAI** - Your Personal AGI, Privately Powered ✨

Access your running instance at: `http://localhost:8080`