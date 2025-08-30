import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../services/ollama_client.dart';

class SimpleLLMPanel extends StatefulWidget {
  final Set<String> selectedDocumentIds;
  
  const SimpleLLMPanel({
    super.key,
    required this.selectedDocumentIds,
  });

  @override
  State<SimpleLLMPanel> createState() => _SimpleLLMPanelState();
}

class _SimpleLLMPanelState extends State<SimpleLLMPanel> {
  final LLMService _llmService = LLMService();
  final TextEditingController _queryController = TextEditingController();
  
  bool _isLLMAvailable = false;
  bool _isInitializing = true;
  bool _isGenerating = false;
  String? _selectedModel;
  List<String> _chatHistory = [];
  String _currentResponse = '';
  
  @override
  void initState() {
    super.initState();
    _initializeLLM();
  }
  
  @override
  void dispose() {
    _queryController.dispose();
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
      _chatHistory.add('You: $query');
    });
    
    _queryController.clear();
    
    try {
      final response = await _llmService.queryDocuments(
        documents: selectedDocs,
        userQuery: query,
        model: _selectedModel,
      );
      
      setState(() {
        _chatHistory.add('MyAI: $response');
      });
    } catch (e) {
      setState(() {
        _chatHistory.add('MyAI: Sorry, I encountered an error: $e');
      });
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Consumer<MyAIDataProvider>(
      builder: (context, provider, child) {
        final themeColors = MyAITheme.themes[provider.selectedTheme]!;
        
        return Container(
          width: 350,
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
              
              // LLM Status
              _buildLLMStatus(themeColors),
              
              // Chat history
              Expanded(
                child: _buildChatHistory(themeColors),
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
          Text(
            'AI Assistant',
            style: TextStyle(
              color: themeColors['text'],
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
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
          Text(
            'Selected Documents (${selectedDocs.length})',
            style: TextStyle(
              color: themeColors['text'],
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
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
              child: Text(
                '• ${doc.title}',
                style: TextStyle(
                  color: themeColors['textSecondary'],
                  fontSize: 10,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            )),
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
            Icon(
              Icons.warning,
              color: Colors.orange,
              size: 24,
            ),
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
              'Make sure Ollama is running',
              style: TextStyle(
                color: themeColors['textSecondary'],
                fontSize: 10,
              ),
            ),
          ],
        ),
      );
    }
    
    return Container(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(
            Icons.memory,
            color: themeColors['textSecondary'],
            size: 14,
          ),
          const SizedBox(width: 8),
          Text(
            _selectedModel ?? 'No model',
            style: TextStyle(
              color: themeColors['text'],
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildChatHistory(Map<String, Color> themeColors) {
    return Container(
      padding: const EdgeInsets.all(12),
      child: ListView.builder(
        itemCount: _chatHistory.length,
        itemBuilder: (context, index) {
          final message = _chatHistory[index];
          final isUser = message.startsWith('You:');
          
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isUser
                  ? themeColors['primary']!.withOpacity(0.1)
                  : themeColors['surface']!.withOpacity(0.7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              message,
              style: TextStyle(
                color: themeColors['text'],
                fontSize: 11,
              ),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildInputArea(Map<String, Color> themeColors) {
    return Container(
      padding: const EdgeInsets.all(12),
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
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              enabled: !_isGenerating && widget.selectedDocumentIds.isNotEmpty && _selectedModel != null,
              onSubmitted: (_) => _sendQuery(),
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
          ),
        ],
      ),
    );
  }
}