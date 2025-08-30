import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../services/ollama_client.dart';

class EnhancedLLMPanel extends StatefulWidget {
  final Set<String> selectedDocumentIds;
  
  const EnhancedLLMPanel({
    super.key,
    required this.selectedDocumentIds,
  });

  @override
  State<EnhancedLLMPanel> createState() => _EnhancedLLMPanelState();
}

class _EnhancedLLMPanelState extends State<EnhancedLLMPanel> {
  final LLMService _llmService = LLMService();
  final TextEditingController _queryController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();
  
  bool _isLLMAvailable = false;
  bool _isInitializing = true;
  bool _isGenerating = false;
  String? _selectedModel;
  List<ChatMessage> _chatHistory = [];
  String _currentResponse = '';
  String _lastExportedData = '';
  
  @override
  void initState() {
    super.initState();
    _initializeLLM();
  }
  
  @override
  void dispose() {
    _queryController.dispose();
    _chatScrollController.dispose();
    _llmService.dispose();
    super.dispose();
  }
  
  Future<void> _initializeLLM() async {
    setState(() {
      _isInitializing = true;
    });
    
    try {
      final success = await _llmService.initialize();
      setState(() {
        _isLLMAvailable = success;
        if (success) {
          _selectedModel = _llmService.preferredModel;
        }
      });
    } catch (e) {
      print('Error initializing LLM: $e');
    } finally {
      setState(() {
        _isInitializing = false;
      });
    }
  }
  
  Future<void> _sendQuery() async {
    final query = _queryController.text.trim();
    if (query.isEmpty || widget.selectedDocumentIds.isEmpty || _selectedModel == null) {
      return;
    }
    
    final provider = Provider.of<MyAIDataProvider>(context, listen: false);
    final selectedDocs = provider.dataItems
        .where((doc) => widget.selectedDocumentIds.contains(doc.id))
        .toList();
    
    if (selectedDocs.isEmpty) return;
    
    setState(() {
      _isGenerating = true;
      _currentResponse = '';
      _chatHistory.add(ChatMessage(
        content: query,
        isUser: true,
        timestamp: DateTime.now(),
      ));
    });
    
    _queryController.clear();
    _scrollToBottom();
    
    try {
      final response = await _llmService.queryDocuments(
        documents: selectedDocs,
        userQuery: query,
        model: _selectedModel,
      );
      
      setState(() {
        _chatHistory.add(ChatMessage(
          content: response,
          isUser: false,
          timestamp: DateTime.now(),
          documentIds: widget.selectedDocumentIds.toList(),
        ));
      });
      
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _chatHistory.add(ChatMessage(
          content: 'Sorry, I encountered an error: $e',
          isUser: false,
          timestamp: DateTime.now(),
          isError: true,
        ));
      });
    } finally {
      setState(() {
        _isGenerating = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _exportSelectedData() async {
    final provider = Provider.of<MyAIDataProvider>(context, listen: false);
    final selectedDocs = provider.dataItems
        .where((doc) => widget.selectedDocumentIds.contains(doc.id))
        .toList();

    if (selectedDocs.isEmpty) return;

    // Create comprehensive data export
    final exportData = _createDataExport(selectedDocs);
    
    setState(() {
      _lastExportedData = exportData;
    });

    // Copy to clipboard
    await Clipboard.setData(ClipboardData(text: exportData));
    
    // Show confirmation
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Data exported to clipboard (${exportData.length} characters)'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  String _createDataExport(List<DataItem> documents) {
    final buffer = StringBuffer();
    
    buffer.writeln('=== MyAI Data Export ===');
    buffer.writeln('Generated: ${DateTime.now().toIso8601String()}');
    buffer.writeln('Documents: ${documents.length}');
    buffer.writeln('Format: JSON-Compatible structured data for LLM ingestion');
    buffer.writeln();
    
    // Document relationships analysis
    buffer.writeln('=== RELATIONSHIP ANALYSIS ===');
    final relationships = _analyzeRelationships(documents);
    buffer.writeln('Key Connections: ${relationships.length}');
    for (final relationship in relationships) {
      buffer.writeln('- $relationship');
    }
    buffer.writeln();
    
    // Documents with full context
    buffer.writeln('=== DOCUMENT COLLECTION ===');
    for (int i = 0; i < documents.length; i++) {
      final doc = documents[i];
      buffer.writeln('[DOCUMENT ${i + 1}]');
      buffer.writeln('ID: ${doc.id}');
      buffer.writeln('Title: ${doc.title}');
      buffer.writeln('Type: ${doc.type}');
      buffer.writeln('Constellation: ${doc.constellation}');
      buffer.writeln('Created: ${doc.createdAt.toIso8601String()}');
      buffer.writeln('Path: ${doc.path}');
      buffer.writeln('Content:');
      buffer.writeln(doc.content);
      buffer.writeln();
      buffer.writeln('---');
      buffer.writeln();
    }
    
    // Metadata for LLM consumption
    buffer.writeln('=== METADATA FOR LLM ===');
    buffer.writeln('Total tokens (estimated): ${_estimateTokenCount(documents)}');
    buffer.writeln('Primary themes: ${_extractThemes(documents).join(', ')}');
    buffer.writeln('Time span: ${_getTimeSpan(documents)}');
    buffer.writeln('Document types: ${_getDocumentTypes(documents).join(', ')}');
    buffer.writeln();
    
    buffer.writeln('=== SUGGESTED QUERIES ===');
    final suggestions = _generateQuerySuggestions(documents);
    for (final suggestion in suggestions) {
      buffer.writeln('- $suggestion');
    }
    
    return buffer.toString();
  }

  List<String> _analyzeRelationships(List<DataItem> documents) {
    final relationships = <String>[];
    
    for (int i = 0; i < documents.length; i++) {
      for (int j = i + 1; j < documents.length; j++) {
        final doc1 = documents[i];
        final doc2 = documents[j];
        
        // Same constellation
        if (doc1.constellation == doc2.constellation) {
          relationships.add('${doc1.title} ↔ ${doc2.title} (${doc1.constellation} cluster)');
        }
        
        // Temporal proximity
        final daysDiff = doc1.createdAt.difference(doc2.createdAt).inDays.abs();
        if (daysDiff <= 7) {
          relationships.add('${doc1.title} ↔ ${doc2.title} (created within ${daysDiff} days)');
        }
        
        // Content similarity (simple keyword matching)
        final content1 = '${doc1.title} ${doc1.content}'.toLowerCase();
        final content2 = '${doc2.title} ${doc2.content}'.toLowerCase();
        
        final sharedKeywords = _findSharedKeywords(content1, content2);
        if (sharedKeywords.length >= 2) {
          relationships.add('${doc1.title} ↔ ${doc2.title} (shared: ${sharedKeywords.take(3).join(', ')})');
        }
      }
    }
    
    return relationships.take(10).toList(); // Limit to top 10 relationships
  }

  List<String> _findSharedKeywords(String content1, String content2) {
    // Important keywords to look for
    final keywords = [
      'visa', 'uscis', 'immigration', 'embassy', 'biometrics', 'passport',
      'kairoz', 'myai', 'pitch', 'investor', 'series a', 'funding', 'a16z',
      'james', 'school', 'budget', 'bank', 'statement', 'meeting',
      'august', 'september', 'october', 'november', '2025',
      'email', 'document', 'file', 'image', 'photo',
    ];
    
    final shared = <String>[];
    for (final keyword in keywords) {
      if (content1.contains(keyword) && content2.contains(keyword)) {
        shared.add(keyword);
      }
    }
    
    return shared;
  }

  int _estimateTokenCount(List<DataItem> documents) {
    int totalChars = 0;
    for (final doc in documents) {
      totalChars += doc.title.length + doc.content.length;
    }
    return (totalChars / 4).round(); // Rough estimate: 4 chars per token
  }

  List<String> _extractThemes(List<DataItem> documents) {
    final themes = <String>{};
    
    for (final doc in documents) {
      themes.add(doc.constellation);
      
      final content = '${doc.title} ${doc.content}'.toLowerCase();
      if (content.contains('visa') || content.contains('immigration')) {
        themes.add('Immigration');
      }
      if (content.contains('kairoz') || content.contains('myai')) {
        themes.add('Startup');
      }
      if (content.contains('school') || content.contains('james')) {
        themes.add('Family');
      }
      if (content.contains('budget') || content.contains('bank')) {
        themes.add('Finance');
      }
    }
    
    return themes.toList();
  }

  String _getTimeSpan(List<DataItem> documents) {
    if (documents.isEmpty) return 'N/A';
    
    final dates = documents.map((d) => d.createdAt).toList()..sort();
    final earliest = dates.first;
    final latest = dates.last;
    
    final span = latest.difference(earliest).inDays;
    return '${earliest.year}-${earliest.month.toString().padLeft(2, '0')}-${earliest.day.toString().padLeft(2, '0')} to ${latest.year}-${latest.month.toString().padLeft(2, '0')}-${latest.day.toString().padLeft(2, '0')} (${span} days)';
  }

  List<String> _getDocumentTypes(List<DataItem> documents) {
    return documents.map((d) => d.type).toSet().toList();
  }

  List<String> _generateQuerySuggestions(List<DataItem> documents) {
    final suggestions = <String>[];
    
    // Theme-based suggestions
    final themes = _extractThemes(documents);
    if (themes.contains('Immigration')) {
      suggestions.addAll([
        'What is my current visa status?',
        'When do my immigration documents expire?',
        'What are the next steps for my visa process?',
      ]);
    }
    
    if (themes.contains('Startup')) {
      suggestions.addAll([
        'Summarize the Kairoz project status',
        'What are the key points from investor meetings?',
        'What is the technical architecture of MyAI?',
      ]);
    }
    
    if (themes.contains('Family')) {
      suggestions.addAll([
        'What is James\' school schedule?',
        'Summarize family activities and events',
      ]);
    }
    
    if (themes.contains('Finance')) {
      suggestions.addAll([
        'What is my current financial status?',
        'Summarize recent financial transactions',
      ]);
    }
    
    // Generic suggestions
    suggestions.addAll([
      'Find all documents from the last 30 days',
      'What are the key action items across all documents?',
      'Create a timeline of events',
      'Identify the most important documents',
    ]);
    
    return suggestions.take(8).toList();
  }
  
  @override
  Widget build(BuildContext context) {
    return Consumer<MyAIDataProvider>(
      builder: (context, provider, child) {
        final themeColors = MyAITheme.themes[provider.selectedTheme]!;
        
        return Container(
            width: MediaQuery.of(context).size.width > 800 ? 400 : 300,
            decoration: BoxDecoration(
              color: themeColors['surface']!.withOpacity(0.95),
              border: Border(
                left: BorderSide(
                  color: themeColors['primary']!.withOpacity(0.3),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
              // Enhanced header
              _buildHeader(themeColors),
              
              // Selected documents with export
              _buildDocumentSection(provider, themeColors),
              
              // LLM Status
              _buildLLMStatus(themeColors),
              
              // Quick actions
              _buildQuickActions(themeColors),
              
              // Chat history
              Expanded(
                child: _buildChatHistory(themeColors),
              ),
              
              // Enhanced input area
              _buildInputArea(themeColors),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(Map<String, Color> themeColors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeColors['primary']!.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(
            color: themeColors['primary']!.withOpacity(0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.psychology, color: themeColors['primary'], size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Assistant',
                  style: TextStyle(
                    color: themeColors['text'],
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_selectedModel != null)
                  Text(
                    'Model: $_selectedModel',
                    style: TextStyle(
                      color: themeColors['textSecondary'],
                      fontSize: 10,
                    ),
                  ),
              ],
            ),
          ),
          if (_isInitializing)
            SizedBox(
              width: 16, height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2, color: themeColors['primary'],
              ),
            )
          else if (_isLLMAvailable)
            Icon(Icons.check_circle, color: Colors.green, size: 16)
          else
            Icon(Icons.error, color: Colors.red, size: 16),
        ],
      ),
    );
  }

  Widget _buildDocumentSection(MyAIDataProvider provider, Map<String, Color> themeColors) {
    final selectedDocs = provider.dataItems
        .where((doc) => widget.selectedDocumentIds.contains(doc.id))
        .toList();
    
    return Container(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Selected Documents (${selectedDocs.length})',
                  style: TextStyle(
                    color: themeColors['text'],
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
              if (selectedDocs.isNotEmpty)
                IconButton(
                  onPressed: _exportSelectedData,
                  icon: Icon(Icons.file_download, size: 16, color: themeColors['primary']),
                  tooltip: 'Export data for external LLM',
                  constraints: BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: EdgeInsets.all(4),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (selectedDocs.isEmpty)
            Text(
              'Select documents from the graph to analyze them',
              style: TextStyle(
                color: themeColors['textSecondary'],
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
            )
          else
            ...selectedDocs.take(3).map((doc) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Icon(_getDocumentIcon(doc.type), size: 12, color: themeColors['textSecondary']),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      doc.title,
                      style: TextStyle(
                        color: themeColors['textSecondary'],
                        fontSize: 10,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            )),
          if (selectedDocs.length > 3)
            Text(
              '... and ${selectedDocs.length - 3} more',
              style: TextStyle(
                color: themeColors['textSecondary'],
                fontSize: 9,
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }

  IconData _getDocumentIcon(String type) {
    switch (type) {
      case 'email': return Icons.email;
      case 'file': return Icons.description;
      case 'image': return Icons.image;
      case 'message': return Icons.message;
      default: return Icons.description;
    }
  }

  Widget _buildQuickActions(Map<String, Color> themeColors) {
    final quickQueries = [
      'Summarize selected documents',
      'Find key dates and deadlines',
      'What are the main topics?',
      'Create action item list',
    ];
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Queries:',
            style: TextStyle(
              color: themeColors['text'],
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: quickQueries.map((query) => 
              InkWell(
                onTap: widget.selectedDocumentIds.isNotEmpty 
                    ? () {
                        _queryController.text = query;
                        _sendQuery();
                      } 
                    : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: widget.selectedDocumentIds.isNotEmpty 
                        ? themeColors['primary']!.withOpacity(0.1)
                        : themeColors['textSecondary']!.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: widget.selectedDocumentIds.isNotEmpty 
                          ? themeColors['primary']!.withOpacity(0.3)
                          : themeColors['textSecondary']!.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    query,
                    style: TextStyle(
                      color: widget.selectedDocumentIds.isNotEmpty 
                          ? themeColors['primary']
                          : themeColors['textSecondary'],
                      fontSize: 9,
                    ),
                  ),
                ),
              ),
            ).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLLMStatus(Map<String, Color> themeColors) {
    if (!_isLLMAvailable) {
      return Container(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(Icons.warning, color: Colors.orange, size: 24),
            const SizedBox(height: 8),
            Text(
              'Ollama not available',
              style: TextStyle(
                color: themeColors['text'],
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Make sure Ollama is running and gemma3:270m is installed',
              style: TextStyle(
                color: themeColors['textSecondary'],
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _initializeLLM,
              style: ElevatedButton.styleFrom(
                backgroundColor: themeColors['primary'],
                minimumSize: Size(80, 24),
              ),
              child: Text('Retry', style: TextStyle(fontSize: 10)),
            ),
          ],
        ),
      );
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Icon(Icons.memory, color: themeColors['textSecondary'], size: 14),
          const SizedBox(width: 8),
          Text(
            'Connected • Ready for queries',
            style: TextStyle(
              color: Colors.green,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatHistory(Map<String, Color> themeColors) {
    return Container(
      padding: const EdgeInsets.all(12),
      child: _chatHistory.isEmpty 
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat, size: 32, color: themeColors['textSecondary']),
                  const SizedBox(height: 8),
                  Text(
                    'No conversations yet',
                    style: TextStyle(
                      color: themeColors['textSecondary'],
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Select documents and ask questions',
                    style: TextStyle(
                      color: themeColors['textSecondary'],
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              controller: _chatScrollController,
              itemCount: _chatHistory.length,
              itemBuilder: (context, index) {
                final message = _chatHistory[index];
                return _buildChatMessage(message, themeColors);
              },
            ),
    );
  }

  Widget _buildChatMessage(ChatMessage message, Map<String, Color> themeColors) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Message header
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!message.isUser) ...[
                Icon(Icons.psychology, size: 12, color: themeColors['primary']),
                const SizedBox(width: 4),
                Text(
                  'MyAI',
                  style: TextStyle(
                    color: themeColors['primary'],
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ] else ...[
                Text(
                  'You',
                  style: TextStyle(
                    color: themeColors['text'],
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.person, size: 12, color: themeColors['text']),
              ],
              const SizedBox(width: 8),
              Text(
                '${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}',
                style: TextStyle(
                  color: themeColors['textSecondary'],
                  fontSize: 9,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          
          // Message content
          Container(
            constraints: BoxConstraints(maxWidth: 300),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: message.isUser
                  ? themeColors['primary']!.withOpacity(0.1)
                  : message.isError
                      ? Colors.red.withOpacity(0.1)
                      : themeColors['surface']!.withOpacity(0.7),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: message.isError 
                    ? Colors.red.withOpacity(0.3)
                    : themeColors['primary']!.withOpacity(0.2),
              ),
            ),
            child: Text(
              message.content,
              style: TextStyle(
                color: message.isError 
                    ? Colors.red
                    : themeColors['text'],
                fontSize: 11,
              ),
            ),
          ),
          
          // Document context indicator
          if (message.documentIds != null && message.documentIds!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Based on ${message.documentIds!.length} selected document${message.documentIds!.length == 1 ? '' : 's'}',
                style: TextStyle(
                  color: themeColors['textSecondary'],
                  fontSize: 9,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInputArea(Map<String, Color> themeColors) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: themeColors['primary']!.withOpacity(0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _queryController,
              style: TextStyle(color: themeColors['text'], fontSize: 12),
              decoration: InputDecoration(
                hintText: widget.selectedDocumentIds.isEmpty
                    ? 'Select documents first...'
                    : 'Ask about your documents...',
                hintStyle: TextStyle(
                  color: themeColors['textSecondary'],
                  fontSize: 12,
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                suffixIcon: _isGenerating
                    ? Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: SizedBox(
                          width: 16, height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2, color: themeColors['primary'],
                          ),
                        ),
                      )
                    : null,
              ),
              enabled: !_isGenerating && widget.selectedDocumentIds.isNotEmpty && _selectedModel != null,
              onSubmitted: (_) => _sendQuery(),
              maxLines: 3,
              minLines: 1,
            ),
          ),
          const SizedBox(width: 8),
          Column(
            children: [
              IconButton(
                onPressed: (!_isGenerating && widget.selectedDocumentIds.isNotEmpty && 
                            _selectedModel != null && _queryController.text.trim().isNotEmpty)
                    ? _sendQuery 
                    : null,
                icon: Icon(
                  Icons.send,
                  color: themeColors['primary'],
                  size: 18,
                ),
                constraints: BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ChatMessage {
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final List<String>? documentIds;
  final bool isError;

  ChatMessage({
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.documentIds,
    this.isError = false,
  });
}