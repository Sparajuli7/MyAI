# MyAI UX - Interactive Knowledge Graph + LLM Interface

A privacy-first AI data hub with interactive knowledge graph visualization and local LLM integration, built with Flutter. MyAI provides an intuitive interface for exploring interconnected data and querying it with local AI models - your personal AI assistant that keeps everything private.

## Features

### 🕸️ Interactive Knowledge Graph
- **Node-Link Visualization**: Data appears as interconnected nodes showing relationships
- **Force-Directed Layout**: Dynamic positioning with real-time graph algorithms
- **Multi-Selection**: Click nodes to select multiple documents for AI analysis
- **Relationship Detection**: Automatic semantic, temporal, and entity-based connections
- **Constellation Clustering**: Data grouped by type (Personal, Work, Kairoz)
- **Smooth Animations**: Pulsating nodes, animated connections, and fluid interactions

### 🤖 Local LLM Integration
- **Ollama Support**: Built-in integration with local Ollama models
- **Document-Aware Queries**: Ask questions about selected documents with full context
- **Streaming Responses**: Real-time AI responses with progress indicators
- **Model Support**: Optimized for gemma3:270m and other small, fast models
- **Chat Interface**: Persistent conversation history with selected documents

### 🔍 Advanced Search & Discovery
- **Graph-Based Navigation**: Explore data through visual connections
- **Real-time Results**: Instant search with relevance scoring
- **Context-Aware**: Understanding document relationships and dependencies

### 🛡️ Privacy Features
- **On-Device Processing**: All data processing happens locally
- **Privacy Shield**: Visual indicator showing secure processing status
- **No Data Transmission**: Simulated local indexing and search

### 🎨 Customizable Themes
- **Dark Theme**: Default cosmic interface
- **Light Theme**: Clean, professional look
- **Nepal Sunset**: Warm orange/red gradient theme

### 📊 Fake Data (10 Items)
- **Files**: School schedule, budget spreadsheet, resume, project notes
- **Emails**: Kairoz MVP meeting, visa updates
- **Messages**: WhatsApp and SMS conversations
- **Images**: Vacation photos, team meeting photos

## Quick Setup

### Prerequisites
1. **Flutter SDK**: Download from https://flutter.dev/docs/get-started/install
2. **Ollama**: For local LLM support
   ```bash
   # Windows
   iwr -useb https://ollama.ai/install.ps1 | iex
   
   # Mac/Linux
   curl -fsSL https://ollama.ai/install.sh | sh
   ```
3. **LLM Model**: Pull recommended model
   ```bash
   ollama pull gemma3:270m
   ```

### Installation
1. Navigate to the project directory:
   ```bash
   cd myai_ux
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the app:
   ```bash
   flutter run -d chrome --web-port 8080
   ```

4. Access at: `http://localhost:8080`

### Platform Support
- **iOS**: `flutter run -d ios`
- **Android**: `flutter run -d android`
- **Web**: `flutter run -d chrome`
- **Desktop**: `flutter run -d macos` (macOS) or `flutter run -d windows` (Windows)

## Usage

### Knowledge Graph Interface
1. **Graph View**: Interactive node-link visualization of your data
2. **Node Selection**: Click nodes to select them (white ring appears)
3. **Multi-Selection**: Select multiple documents for AI analysis
4. **Info Panel**: View selected documents in bottom-left panel
5. **Theme Selector**: Switch between Dark, Light, and Nepal Sunset themes

### AI Assistant
1. **Activate AI Panel**: Click the brain/psychology icon to open
2. **Document Context**: AI has access to selected documents
3. **Natural Queries**: Ask questions about your data in plain language
4. **Streaming Responses**: Watch AI responses appear in real-time
5. **Chat History**: Previous conversations are preserved

### Example Queries
With demo data selected, try:
- "What is my visa status?"
- "Summarize the meeting notes"
- "When do I need to renew my documents?"
- "What are the key topics in these documents?"

### Graph Navigation
1. **Pan**: Click and drag to move around the graph
2. **Zoom**: Use mouse wheel to zoom in/out (future feature)
3. **Node Types**: Different colors represent different data types
4. **Connections**: Lines show relationships between documents

## Technical Details

### Dependencies
- `provider`: State management for reactive UI
- `uuid`: Unique data identifiers
- `http`: HTTP client for Ollama API communication
- `file_picker`: File upload simulation
- `flutter/gestures`: Touch and pointer event handling

### Architecture
- **State Management**: Provider pattern for reactive UI updates
- **Data Models**: `DataItem` and `Orb` classes for data representation
- **Animations**: Custom animation controllers for smooth transitions
- **Theming**: Dynamic theme system with color schemes

### Simulated Features
- **FAISS Indexing**: Console output showing "Indexing 10 items..."
- **RAG Search**: String-based search with relevance scoring
- **On-Device Processing**: Simulated local data processing
- **File Upload**: Mock file addition with fake data

## Development Notes

### Key Components
- `NexusDataProvider`: Main state management class
- `NexusDashboard`: Cosmic dashboard UI implementation
- `NexusTheme`: Theme configuration and color schemes
- `DataItem`: Data model for files, emails, messages, and images

### Animation System
- `_pulseController`: Central sun pulsing animation
- `_orbitController`: Data orb orbital movement
- `_shieldController`: Privacy shield pulsing effect

### Search Algorithm
- String-based search across title and content
- Relevance scoring based on word matches
- Title match boosting for better results
- Sorting by relevance score

## Future Enhancements

### Planned Features
- Real FAISS integration for vector search
- Phi-3 model integration for semantic search
- Cross-device synchronization
- Real file system integration
- Advanced clustering algorithms
- Export and sharing capabilities

### Performance Optimizations
- Lazy loading for large datasets
- Caching for search results
- Optimized animation rendering
- Memory management for large files

## Troubleshooting

### Common Issues
1. **Flutter not found**: Ensure Flutter is installed and in PATH
2. **Dependencies not found**: Run `flutter pub get`
3. **Voice input not working**: Check microphone permissions
4. **Animation lag**: Reduce animation complexity on low-end devices

### Debug Mode
Run with debug information:
```bash
flutter run --debug
```

## License

This project is created for demonstration purposes. All dependencies are free and open-source.

---

**Nexus AI Data Hub** - Where your data orbits in a secure, cosmic universe.
