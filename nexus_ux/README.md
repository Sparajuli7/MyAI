# Nexus AI Data Hub

A privacy-first AI data hub with a cosmic dashboard design, built with Flutter. Nexus provides a futuristic interface for querying user data across devices with on-device processing.

## Features

### 🌌 Cosmic Dashboard
- **3D Orbital Interface**: Data appears as glowing orbs orbiting a central query "sun"
- **Constellation Clustering**: Data grouped into thematic clusters (Work, Personal, Kairoz)
- **Smooth Animations**: Pulsating central sun, orbiting data orbs, and animated transitions

### 🔍 Search & Query
- **Text & Voice Input**: Natural language queries with speech-to-text support
- **Simulated RAG**: String-based search with relevance scoring (placeholder for FAISS/Phi-3)
- **Real-time Results**: Instant search results with relevance percentages

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

## Setup Instructions

### Prerequisites
1. Install Flutter SDK (https://flutter.dev/docs/get-started/install)
2. Ensure Flutter is in your PATH
3. Run `flutter doctor` to verify installation

### Installation
1. Navigate to the project directory:
   ```bash
   cd nexus_ux
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the app:
   ```bash
   flutter run
   ```

### Platform Support
- **iOS**: `flutter run -d ios`
- **Android**: `flutter run -d android`
- **Web**: `flutter run -d chrome`
- **Desktop**: `flutter run -d macos` (macOS) or `flutter run -d windows` (Windows)

## Usage

### Main Interface
1. **Home Button**: Returns to the cosmic dashboard view
2. **Query Bar**: Type or use voice input to search your data
3. **Privacy Shield**: Pulsing indicator showing secure processing
4. **Theme Selector**: Switch between Dark, Light, and Nepal Sunset themes

### Search Functionality
1. **Text Search**: Type queries like "find my visa email" or "Kairoz demo"
2. **Voice Search**: Tap the microphone icon and speak your query
3. **Results**: View search results with relevance scores and content snippets
4. **Clear**: Reset search and return to dashboard

### Data Interaction
1. **Orb Tapping**: Tap any glowing orb to view detailed information
2. **Constellation Labels**: See data grouped by category (Work, Personal, Kairoz)
3. **Add Files**: Use the floating action button to simulate file uploads

## Technical Details

### Dependencies
- `provider`: State management
- `file_picker`: File upload simulation
- `uuid`: Unique data identifiers
- `speech_to_text`: Voice input functionality
- `flare_flutter`: 3D animations (optional)

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
