import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/ollama_client.dart';
import '../main.dart';

class LLMExportPanel extends StatefulWidget {
  final Set<String> selectedDocumentIds;
  final Function(Set<String>) onSelectionChanged;
  
  const LLMExportPanel({
    super.key,
    required this.selectedDocumentIds,
    required this.onSelectionChanged,
  });

  @override
  State<LLMExportPanel> createState() => _LLMExportPanelState();
}

class _LLMExportPanelState extends State<LLMExportPanel> {
  final LLMService _llmService = LLMService();
  final TextEditingController _queryController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();
  
  bool _isLLMAvailable = false;
  bool _isInitializing = true;
  bool _isGenerating = false;
  String? _selectedModel;
  List<ChatMessage> _chatHistory = [];
  String _currentResponse = '';
  
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
      
      // Check if gemma3:270m is available, if not try to pull it
      if (success && !await _llmService.ensureModel('gemma3:270m')) {
        // Try to pull the model
        _showModelPullDialog('gemma3:270m');
      }
    } catch (e) {
      print('Error initializing LLM: $e');
    } finally {
      setState(() {
        _isInitializing = false;
      });
    }
  }
  
  void _showModelPullDialog(String modelName) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Download Model'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('The model "$modelName" is not available locally.'),
            const SizedBox(height: 16),
            const Text('Would you like to download it? This may take several minutes.'),
            const SizedBox(height: 16),
            const LinearProgressIndicator(),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _pullModel(modelName);
            },
            child: const Text('Download'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _pullModel(String modelName) async {
    setState(() {
      _isInitializing = true;
    });
    
    try {
      final success = await _llmService.ensureModel(modelName);
      if (success) {
        setState(() {
          _selectedModel = modelName;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to download model: $e')),
      );
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
      _chatHistory.add(ChatMessage.user(query));
    });
    
    _queryController.clear();
    _scrollToBottom();
    
    try {
      await for (final chunk in _llmService.queryDocumentsStream(
        documents: selectedDocs,
        userQuery: query,
        model: _selectedModel,
      )) {
        setState(() {
          _currentResponse += chunk;
        });
        _scrollToBottom();
      }
      
      setState(() {
        _chatHistory.add(ChatMessage.assistant(_currentResponse));
        _currentResponse = '';
      });
    } catch (e) {
      setState(() {
        _chatHistory.add(ChatMessage.assistant('Sorry, I encountered an error: $e'));
        _currentResponse = '';
      });
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }
  
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
        );
      }
    });
  }
  
  Future<void> _generateSummary() async {
    if (widget.selectedDocumentIds.isEmpty || _selectedModel == null) return;
    
    final provider = Provider.of<MyAIDataProvider>(context, listen: false);
    final selectedDocs = provider.dataItems
        .where((doc) => widget.selectedDocumentIds.contains(doc.id))
        .toList();
    
    setState(() {
      _isGenerating = true;
      _chatHistory.add(ChatMessage.user('Please summarize these documents'));
    });
    
    try {
      final summary = await _llmService.summarizeDocuments(
        documents: selectedDocs,
        model: _selectedModel,
      );
      
      setState(() {
        _chatHistory.add(ChatMessage.assistant(summary));
      });
    } catch (e) {
      setState(() {
        _chatHistory.add(ChatMessage.assistant('Sorry, I encountered an error generating the summary: $e'));
      });
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
    
    _scrollToBottom();
  }
  
  Future<void> _generateInsights() async {
    if (widget.selectedDocumentIds.isEmpty || _selectedModel == null) return;
    
    final provider = Provider.of<MyAIDataProvider>(context, listen: false);
    final selectedDocs = provider.dataItems
        .where((doc) => widget.selectedDocumentIds.contains(doc.id))
        .toList();
    
    setState(() {
      _isGenerating = true;
      _chatHistory.add(ChatMessage.user('What insights can you provide from these documents?'));
    });
    
    try {
      final insights = await _llmService.generateInsights(
        documents: selectedDocs,
        model: _selectedModel,
      );
      
      final insightText = insights.map((insight) => '• $insight').join('\n');
      
      setState(() {
        _chatHistory.add(ChatMessage.assistant('Here are key insights from your documents:\n\n$insightText'));
      });
    } catch (e) {
      setState(() {
        _chatHistory.add(ChatMessage.assistant('Sorry, I encountered an error generating insights: $e'));
      });
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
    
    _scrollToBottom();
  }
  
  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }
  
  String _prepareDocumentsAsText() {
    final provider = Provider.of<MyAIDataProvider>(context, listen: false);
    final selectedDocs = provider.dataItems
        .where((doc) => widget.selectedDocumentIds.contains(doc.id))
        .toList();
    
    final buffer = StringBuffer();
    buffer.writeln('Selected Documents (${selectedDocs.length}):\n');
    
    for (int i = 0; i < selectedDocs.length; i++) {
      final doc = selectedDocs[i];
      buffer.writeln('Document ${i + 1}: ${doc.title}');
      buffer.writeln('Type: ${doc.type}');
      buffer.writeln('Created: ${doc.createdAt.toString().substring(0, 10)}');
      buffer.writeln('Path: ${doc.path}');
      buffer.writeln('Content: ${doc.content}');
      buffer.writeln('${'=' * 50}');
      buffer.writeln();
    }
    
    return buffer.toString();
  }
  
  @override
  Widget build(BuildContext context) {
    return Consumer<MyAIDataProvider>(
      builder: (context, provider, child) {
        final themeColors = MyAITheme.themes[provider.selectedTheme]!;
        
        return Container(
          width: 400,
          height: double.infinity,
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
            children: [
              // Header
              _buildHeader(themeColors),
              
              // Selected documents
              _buildSelectedDocuments(provider, themeColors),
              
              // LLM Status and Controls
              _buildLLMControls(themeColors),
              
              // Chat interface
              Expanded(
                child: _buildChatInterface(themeColors),
              ),
              
              // Input area
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
          Icon(
            Icons.psychology,
            color: themeColors['primary'],
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'AI Assistant',
              style: TextStyle(
                color: themeColors['text'],
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (_isInitializing)
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: themeColors['primary'],
              ),
            )
          else if (_isLLMAvailable)
            Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 16,
            )
          else
            Icon(
              Icons.error,
              color: Colors.red,
              size: 16,
            ),
        ],
      ),
    );
  }
  
  Widget _buildSelectedDocuments(MyAIDataProvider provider, Map<String, Color> themeColors) {
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
              Icon(
                Icons.folder_open,
                color: themeColors['textSecondary'],
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'Selected (${selectedDocs.length})',
                style: TextStyle(
                  color: themeColors['text'],
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              if (selectedDocs.isNotEmpty)
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    color: themeColors['textSecondary'],
                    size: 16,
                  ),
                  onSelected: (value) {
                    switch (value) {
                      case 'copy':
                        _copyToClipboard(_prepareDocumentsAsText());
                        break;
                      case 'clear':
                        widget.onSelectionChanged({});
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'copy',
                      child: Row(
                        children: [
                          Icon(Icons.copy, size: 16),
                          SizedBox(width: 8),
                          Text('Copy as Text'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'clear',
                      child: Row(
                        children: [
                          Icon(Icons.clear, size: 16),
                          SizedBox(width: 8),
                          Text('Clear Selection'),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          if (selectedDocs.isEmpty)
            Text(
              'Select documents from the knowledge graph to analyze them with AI',
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
                  Icon(
                    doc.type == 'email' ? Icons.email :
                    doc.type == 'image' ? Icons.image :
                    doc.type == 'message' ? Icons.message :
                    Icons.description,
                    color: themeColors['primary'],
                    size: 12,
                  ),
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
                fontSize: 10,
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildLLMControls(Map<String, Color> themeColors) {
    if (!_isLLMAvailable) {
      return Container(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(
              Icons.warning,
              color: Colors.orange,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              'Ollama not available',
              style: TextStyle(
                color: themeColors['text'],
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Make sure Ollama is installed and running on localhost:11434',
              style: TextStyle(
                color: themeColors['textSecondary'],
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _initializeLLM,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: themeColors['primary'],
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: themeColors['textSecondary']!.withOpacity(0.2),
          ),
          bottom: BorderSide(
            color: themeColors['textSecondary']!.withOpacity(0.2),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Model selection
          Row(
            children: [
              Icon(
                Icons.memory,
                color: themeColors['textSecondary'],
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButton<String>(
                  value: _selectedModel,
                  isExpanded: true,
                  underline: Container(),
                  style: TextStyle(
                    color: themeColors['text'],
                    fontSize: 12,
                  ),
                  dropdownColor: themeColors['surface'],
                  items: _llmService.availableModels.map((model) => DropdownMenuItem(
                    value: model.name,
                    child: Text(
                      '${model.displayName} (${model.sizeFormatted})',
                      style: TextStyle(fontSize: 11),
                    ),
                  )).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedModel = value;
                    });
                  },
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Quick actions
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              _buildQuickActionButton(
                'Summary',
                Icons.summarize,
                themeColors,
                widget.selectedDocumentIds.isNotEmpty ? _generateSummary : null,
              ),
              _buildQuickActionButton(
                'Insights',
                Icons.lightbulb,
                themeColors,
                widget.selectedDocumentIds.isNotEmpty ? _generateInsights : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildQuickActionButton(
    String label,
    IconData icon,
    Map<String, Color> themeColors,
    VoidCallback? onPressed,
  ) {
    return OutlinedButton.icon(
      onPressed: _isGenerating ? null : onPressed,
      icon: Icon(icon, size: 12),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: themeColors['primary'],
        side: BorderSide(color: themeColors['primary']!.withOpacity(0.3)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        minimumSize: Size.zero,
        textStyle: const TextStyle(fontSize: 10),
      ),
    );
  }
  
  Widget _buildChatInterface(Map<String, Color> themeColors) {
    return Container(
      decoration: BoxDecoration(
        color: themeColors['background'],
      ),
      child: ListView.builder(
        controller: _chatScrollController,
        padding: const EdgeInsets.all(12),
        itemCount: _chatHistory.length + (_currentResponse.isNotEmpty ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _chatHistory.length && _currentResponse.isNotEmpty) {
            // Show current streaming response
            return _buildChatMessage(
              ChatMessage.assistant(_currentResponse),
              themeColors,
              isStreaming: true,
            );
          }
          
          return _buildChatMessage(_chatHistory[index], themeColors);
        },
      ),
    );
  }
  
  Widget _buildChatMessage(ChatMessage message, Map<String, Color> themeColors, {bool isStreaming = false}) {
    final isUser = message.role == 'user';
    
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: isUser 
            ? themeColors['primary']!.withOpacity(0.1)
            : themeColors['surface']!.withOpacity(0.7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isUser 
              ? themeColors['primary']!.withOpacity(0.3)
              : themeColors['textSecondary']!.withOpacity(0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isUser ? Icons.person : Icons.smart_toy,
                  size: 14,
                  color: isUser ? themeColors['primary'] : themeColors['textSecondary'],
                ),
                const SizedBox(width: 6),
                Text(
                  isUser ? 'You' : 'MyAI',
                  style: TextStyle(
                    color: isUser ? themeColors['primary'] : themeColors['textSecondary'],
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (!isUser && !isStreaming)
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_horiz,
                      size: 12,
                      color: themeColors['textSecondary'],
                    ),
                    onSelected: (value) {
                      if (value == 'copy') {
                        _copyToClipboard(message.content);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'copy',
                        child: Row(
                          children: [
                            Icon(Icons.copy, size: 14),
                            SizedBox(width: 6),
                            Text('Copy'),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              message.content,
              style: TextStyle(
                color: themeColors['text'],
                fontSize: 12,
                height: 1.4,
              ),
            ),
            if (isStreaming)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: themeColors['primary'],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInputArea(Map<String, Color> themeColors) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: themeColors['surface'],
        border: Border(
          top: BorderSide(
            color: themeColors['textSecondary']!.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _queryController,
              style: TextStyle(
                color: themeColors['text'],
                fontSize: 12,
              ),
              decoration: InputDecoration(
                hintText: widget.selectedDocumentIds.isEmpty
                    ? 'Select documents first...'
                    : 'Ask about your documents...',
                hintStyle: TextStyle(
                  color: themeColors['textSecondary'],
                  fontSize: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: themeColors['textSecondary']!.withOpacity(0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: themeColors['primary']!,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                filled: true,
                fillColor: themeColors['background'],
              ),
              enabled: !_isGenerating && widget.selectedDocumentIds.isNotEmpty && _selectedModel != null,
              onSubmitted: (_) => _sendQuery(),
              maxLines: 3,
              minLines: 1,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: (!_isGenerating && widget.selectedDocumentIds.isNotEmpty && 
                        _selectedModel != null && _queryController.text.trim().isNotEmpty)
                ? _sendQuery 
                : null,
            icon: _isGenerating
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: themeColors['primary'],
                    ),
                  )
                : Icon(
                    Icons.send,
                    color: themeColors['primary'],
                    size: 16,
                  ),
            style: IconButton.styleFrom(
              backgroundColor: themeColors['primary']!.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              padding: EdgeInsets.all(8),
            ),
          ),
        ],
      ),
    );
  }
}