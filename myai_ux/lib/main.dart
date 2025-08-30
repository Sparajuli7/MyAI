import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'dart:math' as math;
import 'dart:async';
import 'widgets/demo_controls.dart';
import 'widgets/simple_graph_widget.dart';
import 'widgets/simple_llm_panel.dart';
import 'widgets/enhanced_graph_widget.dart';
import 'widgets/enhanced_llm_panel.dart';
// import 'widgets/knowledge_graph_widget.dart';
// import 'widgets/llm_export_panel.dart';
import 'services/demo_data.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => MyAIDataProvider(),
      child: const MyAIApp(),
    ),
  );
}

// ============================================================================
// DATA MODELS
// ============================================================================

class DataItem {
  final String id;
  final String title;
  final String content;
  final String type; // 'file', 'email', 'message', 'image'
  final String constellation; // 'work', 'personal', 'kairoz'
  final DateTime createdAt;
  final String path;
  final double relevance; // 0.0 to 1.0 for search relevance

  DataItem({
    required this.id,
    required this.title,
    required this.content,
    required this.type,
    required this.constellation,
    required this.createdAt,
    required this.path,
    this.relevance = 0.0,
  });
}

class Orb {
  final DataItem data;
  final Offset position;
  final double radius;
  final Color color;
  final double pulsePhase;

  Orb({
    required this.data,
    required this.position,
    required this.radius,
    required this.color,
    this.pulsePhase = 0.0,
  });
}

// ============================================================================
// STATE MANAGEMENT
// ============================================================================

class MyAIDataProvider extends ChangeNotifier {
  List<DataItem> _dataItems = [];
  final List<Orb> _orbs = [];
  String _currentQuery = '';
  List<DataItem> _searchResults = [];
  bool _isSearching = false;
  bool _isIndexing = false;
  bool _isProcessing = false;
  String _selectedTheme = 'dark';
  bool _isVoiceListening = false;
  bool _speechEnabled = false; // Placeholder - speech disabled for demo
  bool _isDemoMode = true; // Start in demo mode
  bool _backendConnected = false;

  List<DataItem> get dataItems => _dataItems;
  List<Orb> get orbs => _orbs;
  String get currentQuery => _currentQuery;
  List<DataItem> get searchResults => _searchResults;
  bool get isSearching => _isSearching;
  bool get isIndexing => _isIndexing;
  bool get isProcessing => _isProcessing;
  String get selectedTheme => _selectedTheme;
  bool get isVoiceListening => _isVoiceListening;
  bool get speechEnabled => _speechEnabled;
  bool get isDemoMode => _isDemoMode;
  bool get backendConnected => _backendConnected;

  MyAIDataProvider() {
    _initializeSpeech();
    _loadInitialData();
  }

  void _loadInitialData() {
    if (_isDemoMode) {
      _loadDemoData();
    } else {
      _loadRealData();
    }
  }

  void _loadDemoData() {
    // Load rich interconnected demo data
    _dataItems = DemoData.richDemoData;
    _generateOrbs();
    _simulateIndexing();
    notifyListeners();
  }

  void _loadRealData() {
    // This will be populated from the real backend
    _dataItems = [];
    _generateOrbs();
    notifyListeners();
  }

  void toggleDemoMode() {
    _isDemoMode = !_isDemoMode;
    _loadInitialData();
    _clearSearch();
    notifyListeners();
  }

  void _initializeSpeech() async {
    // Speech functionality disabled for demo
    _speechEnabled = false;
    notifyListeners();
  }

  // Seed fake data on startup
  void _seedFakeData() {
    _dataItems = [
      // Files
      DataItem(
        id: const Uuid().v4(),
        title: 'School_Schedule_2025.pdf',
        content: 'Son\'s class schedule for 2025 semester. Math at 9 AM, Science at 11 AM.',
        type: 'file',
        constellation: 'personal',
        createdAt: DateTime(2025, 7, 15),
        path: '~/Documents/School_Schedule_2025.pdf',
      ),
      DataItem(
        id: const Uuid().v4(),
        title: 'Budget_2025.xlsx',
        content: 'Annual budget spreadsheet. Cursor Pro subscription \$500, groceries \$2000.',
        type: 'file',
        constellation: 'personal',
        createdAt: DateTime(2025, 7, 20),
        path: '~/Documents/Budget_2025.xlsx',
      ),
      
      // Emails
      DataItem(
        id: const Uuid().v4(),
        title: 'Kairoz MVP Meeting',
        content: 'Demo presentation due November 1st. Need to prepare pitch deck and technical overview.',
        type: 'email',
        constellation: 'kairoz',
        createdAt: DateTime(2025, 8, 10),
        path: '~/Mail/Kairoz_MVP_Meeting.eml',
      ),
      DataItem(
        id: const Uuid().v4(),
        title: 'Visa Update',
        content: 'OPT extension approved until December 2025. Status: Approved. Next steps: biometrics.',
        type: 'email',
        constellation: 'personal',
        createdAt: DateTime(2025, 8, 15),
        path: '~/Mail/Visa_Update.eml',
      ),
      
      // Messages
      DataItem(
        id: const Uuid().v4(),
        title: 'Send Nexus pitch deck',
        content: 'Can you send the Nexus pitch deck? Need it for investor meeting tomorrow.',
        type: 'message',
        constellation: 'kairoz',
        createdAt: DateTime(2025, 8, 20),
        path: '~/Messages/WhatsApp/nexus_pitch.txt',
      ),
      DataItem(
        id: const Uuid().v4(),
        title: 'Kairoz demo link',
        content: 'Here\'s the demo link: https://kairoz.ai/demo. Password: nexus2025',
        type: 'message',
        constellation: 'kairoz',
        createdAt: DateTime(2025, 8, 22),
        path: '~/Messages/SMS/kairoz_demo.txt',
      ),
      
      // Images
      DataItem(
        id: const Uuid().v4(),
        title: 'vacation_photo.jpg',
        content: 'Beautiful sunset at Maldives resort. Taken August 2025. Crystal clear water.',
        type: 'image',
        constellation: 'personal',
        createdAt: DateTime(2025, 8, 27),
        path: '~/Pictures/vacation_photo.jpg',
      ),
      DataItem(
        id: const Uuid().v4(),
        title: 'team_meeting.jpg',
        content: 'Kairoz team meeting photo. Whiteboard with architecture diagrams.',
        type: 'image',
        constellation: 'kairoz',
        createdAt: DateTime(2025, 8, 25),
        path: '~/Pictures/team_meeting.jpg',
      ),
      DataItem(
        id: const Uuid().v4(),
        title: 'resume_2025.pdf',
        content: 'Updated resume with latest experience. Kairoz co-founder, Flutter developer.',
        type: 'file',
        constellation: 'work',
        createdAt: DateTime(2025, 8, 1),
        path: '~/Documents/resume_2025.pdf',
      ),
      DataItem(
        id: const Uuid().v4(),
        title: 'project_notes.txt',
        content: 'Nexus project notes. Privacy-first AI, cosmic UI, on-device processing.',
        type: 'file',
        constellation: 'kairoz',
        createdAt: DateTime(2025, 8, 5),
        path: '~/Documents/project_notes.txt',
      ),
    ];
    
    _generateOrbs();
    notifyListeners();
  }

  void _generateOrbs() {
    _orbs.clear();
    final random = math.Random(42); // Fixed seed for consistent layout
    
    for (int i = 0; i < _dataItems.length; i++) {
      final item = _dataItems[i];
      final angle = (i * 2 * math.pi / _dataItems.length) + random.nextDouble() * 0.5;
      final radius = 150.0 + random.nextDouble() * 100.0;
      
      _orbs.add(Orb(
        data: item,
        position: Offset(
          math.cos(angle) * radius,
          math.sin(angle) * radius,
        ),
        radius: 20.0 + random.nextDouble() * 15.0,
        color: _getOrbColor(item.constellation),
        pulsePhase: random.nextDouble() * 2 * math.pi,
      ));
    }
  }

  Color _getOrbColor(String constellation) {
    switch (constellation) {
      case 'work':
        return Colors.blue;
      case 'personal':
        return Colors.green;
      case 'kairoz':
        return Colors.purple;
      default:
        return Colors.orange;
    }
  }

  // Simulate FAISS indexing
  void _simulateIndexing() async {
    _isIndexing = true;
    notifyListeners();
    
    await Future.delayed(const Duration(seconds: 2));
    print('Indexing ${_dataItems.length} items...');
    print('FAISS index created successfully');
    print('Embeddings generated for all data items');
    
    _isIndexing = false;
    notifyListeners();
  }

  // Search functionality (simulated RAG)
  void search(String query) async {
    if (query.trim().isEmpty) {
      _searchResults.clear();
      _isSearching = false;
      notifyListeners();
      return;
    }

    _currentQuery = query;
    _isSearching = true;
    _isProcessing = true;
    notifyListeners();

    // Simulate on-device processing delay
    await Future.delayed(const Duration(milliseconds: 800));

    // Simple string search (placeholder for FAISS/Phi-3)
    final results = _dataItems.where((item) {
      final searchText = '${item.title} ${item.content}'.toLowerCase();
      final queryLower = query.toLowerCase();
      return searchText.contains(queryLower);
    }).toList();

    // Calculate relevance scores and create new items with relevance
    final resultsWithRelevance = results.map((item) {
      final searchText = '${item.title} ${item.content}'.toLowerCase();
      final queryLower = query.toLowerCase();
      final words = queryLower.split(' ');
      double relevance = 0.0;
      
      for (final word in words) {
        if (searchText.contains(word)) {
          relevance += 0.2;
        }
      }
      
      // Boost title matches
      if (item.title.toLowerCase().contains(queryLower)) {
        relevance += 0.3;
      }
      
      return DataItem(
        id: item.id,
        title: item.title,
        content: item.content,
        type: item.type,
        constellation: item.constellation,
        createdAt: item.createdAt,
        path: item.path,
        relevance: relevance.clamp(0.0, 1.0),
      );
    }).toList();

    // Sort by relevance
    resultsWithRelevance.sort((a, b) => b.relevance.compareTo(a.relevance));
    
    _searchResults = resultsWithRelevance;
    _isSearching = false;
    _isProcessing = false;
    notifyListeners();
  }

  void clearSearch() {
    _clearSearch();
  }

  void _clearSearch() {
    _currentQuery = '';
    _searchResults.clear();
    _isSearching = false;
    notifyListeners();
  }

  void setTheme(String theme) {
    _selectedTheme = theme;
    notifyListeners();
  }

  // Voice input (disabled for demo)
  void startVoiceInput() async {
    if (!_speechEnabled) return;
    // Voice functionality disabled for web demo
  }

  void stopVoiceInput() {
    _isVoiceListening = false;
    notifyListeners();
  }

  // File upload simulation
  void addFakeFile() async {
    _isProcessing = true;
    notifyListeners();
    
    await Future.delayed(const Duration(seconds: 1));
    
    final newItem = DataItem(
      id: const Uuid().v4(),
      title: 'uploaded_file_${DateTime.now().millisecondsSinceEpoch}.pdf',
      content: 'Newly uploaded file with AI-generated content analysis.',
      type: 'file',
      constellation: 'personal',
      createdAt: DateTime.now(),
      path: '~/Documents/uploaded_file.pdf',
    );
    
    _dataItems.add(newItem);
    _generateOrbs();
    _isProcessing = false;
    notifyListeners();
  }
}

// ============================================================================
// THEME DATA
// ============================================================================

class MyAITheme {
  static const Map<String, Map<String, Color>> themes = {
    'dark': {
      'background': Color(0xFF0A0A0A),
      'surface': Color(0xFF1A1A1A),
      'primary': Color(0xFF00D4FF),
      'secondary': Color(0xFF6C63FF),
      'text': Color(0xFFFFFFFF),
      'textSecondary': Color(0xFFB0B0B0),
    },
    'light': {
      'background': Color(0xFFF5F5F5),
      'surface': Color(0xFFFFFFFF),
      'primary': Color(0xFF2196F3),
      'secondary': Color(0xFF673AB7),
      'text': Color(0xFF000000),
      'textSecondary': Color(0xFF666666),
    },
    'nepal_sunset': {
      'background': Color(0xFF2C1810),
      'surface': Color(0xFF3D2418),
      'primary': Color(0xFFFF6B35),
      'secondary': Color(0xFFFF8E53),
      'text': Color(0xFFFFF8E1),
      'textSecondary': Color(0xFFFFCC80),
    },
  };
}

// ============================================================================
// MAIN APP
// ============================================================================

class MyAIApp extends StatelessWidget {
  const MyAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MyAIDataProvider>(
      builder: (context, provider, child) {
        final themeColors = MyAITheme.themes[provider.selectedTheme]!;
        
        return MaterialApp(
          title: 'MyAI - Personal AGI with Privacy',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            brightness: provider.selectedTheme == 'dark' ? Brightness.dark : Brightness.light,
            primarySwatch: Colors.blue,
            scaffoldBackgroundColor: themeColors['background'],
            appBarTheme: AppBarTheme(
              backgroundColor: themeColors['surface'],
              elevation: 0,
              titleTextStyle: TextStyle(
                color: themeColors['text'],
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          home: const MyAIDashboard(),
        );
      },
    );
  }
}

// ============================================================================
// COSMIC DASHBOARD
// ============================================================================

class MyAIDashboard extends StatefulWidget {
  const MyAIDashboard({super.key});

  @override
  State<MyAIDashboard> createState() => _MyAIDashboardState();
}

class _MyAIDashboardState extends State<MyAIDashboard>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _orbitController;
  late AnimationController _shieldController;
  final TextEditingController _queryController = TextEditingController();
  Set<String> _selectedDocuments = {};
  bool _showKnowledgeGraph = true;
  bool _showLLMPanel = true;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    
    _orbitController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
    
    _shieldController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _orbitController.dispose();
    _shieldController.dispose();
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MyAIDataProvider>(
      builder: (context, provider, child) {
        final themeColors = MyAITheme.themes[provider.selectedTheme]!;
        
        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  themeColors['background']!,
                  themeColors['background']!.withOpacity(0.8),
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  _buildHeader(provider, themeColors),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: provider.isSearching || provider.searchResults.isNotEmpty
                              ? _buildSearchResults(provider, themeColors)
                              : _showKnowledgeGraph
                                  ? SimpleGraphWidget(
                                      onSelectionChanged: (selectedIds) {
                                        setState(() {
                                          _selectedDocuments = selectedIds;
                                        });
                                      },
                                    )
                                  : _buildCosmicDashboard(provider, themeColors),
                        ),
                        // Enhanced LLM Panel
                        if (_showLLMPanel)
                          EnhancedLLMPanel(
                            selectedDocumentIds: _selectedDocuments,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(MyAIDataProvider provider, Map<String, Color> themeColors) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.home,
                color: themeColors['primary'],
                size: 28,
              ),
              const SizedBox(width: 12),
              
              // Simple graph toggle
              IconButton(
                icon: Icon(
                  _showKnowledgeGraph ? Icons.account_tree : Icons.bubble_chart,
                  color: themeColors['primary'],
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _showKnowledgeGraph = !_showKnowledgeGraph;
                  });
                },
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MyAI',
                    style: TextStyle(
                      color: themeColors['text'],
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Personal AGI with Privacy',
                    style: TextStyle(
                      color: themeColors['textSecondary'],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              _buildPrivacyShield(provider, themeColors),
              const SizedBox(width: 16),
              _buildThemeSelector(provider, themeColors),
            ],
          ),
          const SizedBox(height: 16),
          _buildQueryBar(provider, themeColors),
        ],
      ),
    );
  }

  Widget _buildPrivacyShield(MyAIDataProvider provider, Map<String, Color> themeColors) {
    return AnimatedBuilder(
      animation: _shieldController,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: themeColors['primary']!.withOpacity(0.1 + _shieldController.value * 0.2),
          ),
          child: Icon(
            Icons.shield,
            color: themeColors['primary'],
            size: 20,
          ),
        );
      },
    );
  }

  Widget _buildThemeSelector(MyAIDataProvider provider, Map<String, Color> themeColors) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.palette, color: themeColors['text']),
      onSelected: provider.setTheme,
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'dark', child: Text('Dark')),
        const PopupMenuItem(value: 'light', child: Text('Light')),
        const PopupMenuItem(value: 'nepal_sunset', child: Text('Nepal Sunset')),
      ],
    );
  }

  Widget _buildQueryBar(MyAIDataProvider provider, Map<String, Color> themeColors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: themeColors['surface'],
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: provider.isVoiceListening 
              ? themeColors['primary']! 
              : themeColors['textSecondary']!.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: themeColors['primary']!.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: provider.isVoiceListening ? 2 : 0,
          ),
        ],
      ),
                child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _queryController,
                  style: TextStyle(color: themeColors['text']),
                  decoration: InputDecoration(
                    hintText: 'Search your data...',
                    hintStyle: TextStyle(color: themeColors['textSecondary']),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onSubmitted: (query) {
                    provider.search(query);
                    _queryController.clear();
                  },
                ),
              ),
              if (provider.isProcessing)
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(themeColors['primary']!),
                  ),
                )
              else ...[
                IconButton(
                  icon: Icon(
                    Icons.search,
                    color: themeColors['primary'],
                  ),
                  onPressed: () {
                    if (_queryController.text.isNotEmpty) {
                      provider.search(_queryController.text);
                      _queryController.clear();
                    }
                  },
                ),
                IconButton(
                  icon: Icon(
                    provider.isVoiceListening ? Icons.mic : Icons.mic_none,
                    color: provider.isVoiceListening 
                        ? themeColors['primary']! 
                        : themeColors['textSecondary'],
                  ),
                  onPressed: provider.isVoiceListening 
                      ? provider.stopVoiceInput 
                      : provider.startVoiceInput,
                ),
              ],
            ],
          ),
    );
  }

  Widget _buildCosmicDashboard(MyAIDataProvider provider, Map<String, Color> themeColors) {
    return Stack(
      children: [
        // Welcome message (only show when no search results)
        if (provider.searchResults.isEmpty && provider.currentQuery.isEmpty)
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: themeColors['surface']!.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: themeColors['primary']!.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.psychology,
                        color: themeColors['primary'],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Welcome to MyAI',
                        style: TextStyle(
                          color: themeColors['text'],
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your personal AGI with privacy. Search across all your data instantly - nothing leaves your device.',
                    style: TextStyle(
                      color: themeColors['textSecondary'],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        // Central sun
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    width: 80 + _pulseController.value * 20,
                    height: 80 + _pulseController.value * 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          themeColors['primary']!,
                          themeColors['primary']!.withOpacity(0.3),
                          Colors.transparent,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: themeColors['primary']!.withOpacity(0.5),
                          blurRadius: 20 + _pulseController.value * 10,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.search,
                      color: Colors.white,
                      size: 40,
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: themeColors['surface']!.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: themeColors['primary']!.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  'Your AI, Your Data',
                  style: TextStyle(
                    color: themeColors['text'],
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Orbiting data orbs
        ...provider.orbs.map((orb) => _buildOrb(orb, provider, themeColors)),
        
        // Constellation labels
        Positioned(
          top: 50,
          left: 20,
          child: _buildConstellationLabel('Work', Colors.blue, themeColors),
        ),
        Positioned(
          top: 50,
          right: 20,
          child: _buildConstellationLabel('Personal', Colors.green, themeColors),
        ),
        Positioned(
          bottom: 50,
          left: 20,
          child: _buildConstellationLabel('Kairoz', Colors.purple, themeColors),
        ),
        
        // Demo controls (top left)
        Positioned(
          top: 20,
          left: 20,
          child: DemoControls(),
        ),

        // Privacy message
        Positioned(
          bottom: 50,
          right: 20,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.2),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.green.withOpacity(0.5)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.shield,
                  color: Colors.green,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  '100% Private',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Add file button
        Positioned(
          bottom: 20,
          right: 20,
          child: FloatingActionButton(
            onPressed: provider.addFakeFile,
            backgroundColor: themeColors['primary'],
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildOrb(Orb orb, MyAIDataProvider provider, Map<String, Color> themeColors) {
    return AnimatedBuilder(
      animation: _orbitController,
      builder: (context, child) {
        final angle = _orbitController.value * 2 * math.pi;
        final offset = Offset(
          orb.position.dx * math.cos(angle * 0.1) + MediaQuery.of(context).size.width / 2,
          orb.position.dy * math.sin(angle * 0.1) + MediaQuery.of(context).size.height / 2,
        );
        
        return Positioned(
          left: offset.dx - orb.radius,
          top: offset.dy - orb.radius,
          child: GestureDetector(
            onTap: () => _showDataDetails(orb.data, themeColors),
            child: Container(
              width: orb.radius * 2,
              height: orb.radius * 2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    orb.color,
                    orb.color.withOpacity(0.7),
                    orb.color.withOpacity(0.3),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: orb.color.withOpacity(0.5),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                _getDataIcon(orb.data.type),
                color: Colors.white,
                size: orb.radius * 0.8,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildConstellationLabel(String name, Color color, Map<String, Color> themeColors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        name,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSearchResults(MyAIDataProvider provider, Map<String, Color> themeColors) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.search,
                color: themeColors['primary'],
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Search Results',
                style: TextStyle(
                  color: themeColors['text'],
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: themeColors['primary']!.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${provider.searchResults.length} found',
                  style: TextStyle(
                    color: themeColors['primary'],
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: provider.clearSearch,
                icon: Icon(
                  Icons.clear,
                  color: themeColors['textSecondary'],
                  size: 18,
                ),
                label: Text(
                  'Clear',
                  style: TextStyle(
                    color: themeColors['textSecondary'],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: provider.searchResults.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          color: themeColors['textSecondary'],
                          size: 64,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No results found',
                          style: TextStyle(
                            color: themeColors['text'],
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try different keywords or check your spelling',
                          style: TextStyle(
                            color: themeColors['textSecondary'],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: provider.searchResults.length,
                    itemBuilder: (context, index) {
                      final item = provider.searchResults[index];
                      return AnimatedOpacity(
                        opacity: 1.0,
                        duration: Duration(milliseconds: 300 + (index * 100)),
                        child: _buildSearchResultItem(item, themeColors),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResultItem(DataItem item, Map<String, Color> themeColors) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _showDataDetails(item, themeColors),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: themeColors['surface'],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _getOrbColor(item.constellation).withOpacity(0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      _getOrbColor(item.constellation),
                      _getOrbColor(item.constellation).withOpacity(0.7),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _getOrbColor(item.constellation).withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Icon(
                  _getDataIcon(item.type),
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: TextStyle(
                              color: themeColors['text'],
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (item.relevance > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: themeColors['primary']!.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: themeColors['primary']!.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              '${(item.relevance * 100).toInt()}%',
                              style: TextStyle(
                                color: themeColors['primary'],
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.content,
                      style: TextStyle(
                        color: themeColors['textSecondary'],
                        fontSize: 14,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _getOrbColor(item.constellation).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            item.type.toUpperCase(),
                            style: TextStyle(
                              color: _getOrbColor(item.constellation),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: themeColors['textSecondary']!.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            item.constellation,
                            style: TextStyle(
                              color: themeColors['textSecondary'],
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _formatDate(item.createdAt),
                          style: TextStyle(
                            color: themeColors['textSecondary'],
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getDataIcon(String type) {
    switch (type) {
      case 'file':
        return Icons.description;
      case 'email':
        return Icons.email;
      case 'message':
        return Icons.message;
      case 'image':
        return Icons.image;
      default:
        return Icons.file_present;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  Color _getOrbColor(String constellation) {
    switch (constellation) {
      case 'work':
        return Colors.blue;
      case 'personal':
        return Colors.green;
      case 'kairoz':
        return Colors.purple;
      default:
        return Colors.orange;
    }
  }

  void _showDataDetails(DataItem item, Map<String, Color> themeColors) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          constraints: const BoxConstraints(maxWidth: 600),
          decoration: BoxDecoration(
            color: themeColors['surface'],
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: _getOrbColor(item.constellation).withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            _getOrbColor(item.constellation),
                            _getOrbColor(item.constellation).withOpacity(0.7),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _getOrbColor(item.constellation).withOpacity(0.3),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        _getDataIcon(item.type),
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: TextStyle(
                              color: themeColors['text'],
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getOrbColor(item.constellation).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  item.type.toUpperCase(),
                                  style: TextStyle(
                                    color: _getOrbColor(item.constellation),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: themeColors['textSecondary']!.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  item.constellation,
                                  style: TextStyle(
                                    color: themeColors['textSecondary'],
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(
                        Icons.close,
                        color: themeColors['textSecondary'],
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Content',
                        style: TextStyle(
                          color: themeColors['text'],
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: themeColors['background'],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: themeColors['textSecondary']!.withOpacity(0.1),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          item.content,
                          style: TextStyle(
                            color: themeColors['textSecondary'],
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Metadata
                      Text(
                        'Details',
                        style: TextStyle(
                          color: themeColors['text'],
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: themeColors['background'],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            _buildMetadataRow('Created', _formatDate(item.createdAt), themeColors),
                            const SizedBox(height: 8),
                            _buildMetadataRow('Path', item.path, themeColors),
                            if (item.relevance > 0) ...[
                              const SizedBox(height: 8),
                              _buildMetadataRow('Relevance', '${(item.relevance * 100).toInt()}%', themeColors),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Actions
              Container(
                padding: const EdgeInsets.all(24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'Close',
                        style: TextStyle(
                          color: themeColors['textSecondary'],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () async {
                        await _openFile(item);
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeColors['primary'],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.open_in_new, size: 18),
                      label: const Text('Open'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetadataRow(String label, String value, Map<String, Color> themeColors) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(
              color: themeColors['textSecondary'],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: themeColors['text'],
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openFile(DataItem item) async {
    try {
      // Show content dialog for demo mode
      _showContentDialog(item);
    } catch (e) {
      // Show content in a dialog as fallback
      _showContentDialog(item);
    }
  }

  /*
  Widget _buildKnowledgeGraphView(MyAIDataProvider provider, Map<String, Color> themeColors) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            themeColors['background']!,
            themeColors['background']!.withOpacity(0.8),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Knowledge Graph
          KnowledgeGraphWidget(
            showMiniMap: true,
            onSelectionChanged: (selectedIds) {
              setState(() {
                _selectedDocuments = selectedIds;
                if (selectedIds.isNotEmpty && !_showLLMPanel) {
                  _showLLMPanel = true;
                }
              });
            },
          ),
          
          // View Controls
          Positioned(
            top: 16,
            right: _showLLMPanel ? 420 : 16,
            child: _buildViewControls(provider, themeColors),
          ),
          
          // Status info
          Positioned(
            bottom: 16,
            right: _showLLMPanel ? 420 : 16,
            child: _buildGraphStatus(provider, themeColors),
          ),
        ],
      ),
    );
  }
  */
  
  /*
  Widget _buildViewControls(MyAIDataProvider provider, Map<String, Color> themeColors) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: themeColors['surface']!.withOpacity(0.9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: themeColors['primary']!.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Toggle between cosmic and graph view
          IconButton(
            icon: Icon(
              _showKnowledgeGraph ? Icons.account_tree : Icons.bubble_chart,
              color: themeColors['primary'],
              size: 16,
            ),
            tooltip: _showKnowledgeGraph ? 'Switch to Cosmic View' : 'Switch to Graph View',
            onPressed: () {
              setState(() {
                _showKnowledgeGraph = !_showKnowledgeGraph;
              });
            },
          ),
          
          const SizedBox(width: 8),
          
          // Toggle LLM panel
          IconButton(
            icon: Icon(
              Icons.psychology,
              color: _showLLMPanel ? themeColors['primary'] : themeColors['textSecondary'],
              size: 16,
            ),
            tooltip: _showLLMPanel ? 'Hide AI Panel' : 'Show AI Panel',
            onPressed: () {
              setState(() {
                _showLLMPanel = !_showLLMPanel;
              });
            },
          ),
          
          const SizedBox(width: 8),
          
          // Clear selection
          if (_selectedDocuments.isNotEmpty)
            IconButton(
              icon: Icon(
                Icons.clear,
                color: themeColors['textSecondary'],
                size: 16,
              ),
              tooltip: 'Clear Selection',
              onPressed: () {
                setState(() {
                  _selectedDocuments.clear();
                });
              },
            ),
        ],
      ),
    );
  }
  
  Widget _buildGraphStatus(MyAIDataProvider provider, Map<String, Color> themeColors) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: themeColors['surface']!.withOpacity(0.9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: themeColors['primary']!.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.analytics,
                color: themeColors['primary'],
                size: 14,
              ),
              const SizedBox(width: 6),
              Text(
                'Knowledge Graph',
                style: TextStyle(
                  color: themeColors['text'],
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${provider.dataItems.length} documents • ${_selectedDocuments.length} selected',
            style: TextStyle(
              color: themeColors['textSecondary'],
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
  */

  void _showContentDialog(DataItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Content:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(item.content),
              const SizedBox(height: 16),
              Text(
                'Path:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(item.path),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }
}
