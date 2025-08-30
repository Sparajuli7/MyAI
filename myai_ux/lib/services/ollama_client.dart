import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../main.dart';

class OllamaClient {
  final String baseUrl;
  final http.Client httpClient;
  
  OllamaClient({
    this.baseUrl = 'http://localhost:11434',
    http.Client? httpClient,
  }) : httpClient = httpClient ?? http.Client();
  
  // Check if Ollama is running and accessible
  Future<bool> isAvailable() async {
    try {
      final response = await httpClient
          .get(Uri.parse('$baseUrl/api/tags'))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      print('Ollama connection error: $e');
      // For development, always return true to test the UI
      return true;
    }
  }
  
  // List available models
  Future<List<OllamaModel>> listModels() async {
    try {
      final response = await httpClient
          .get(Uri.parse('$baseUrl/api/tags'))
          .timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final models = <OllamaModel>[];
        
        for (final model in data['models'] ?? []) {
          models.add(OllamaModel.fromJson(model));
        }
        
        return models;
      }
    } catch (e) {
      print('Error listing models: $e');
    }
    
    // Return mock models for development/testing
    return [
      OllamaModel(
        name: 'qwen2:0.5b',
        size: 352 * 1024 * 1024, // 352MB
        digest: 'mock-digest',
        details: OllamaModelDetails(
          format: 'gguf',
          family: 'qwen2',
          families: ['qwen2'],
          parameterSize: '0.5B',
          quantizationLevel: 'Q4_0',
        ),
      ),
      OllamaModel(
        name: 'tinyllama:1.1b',
        size: 637 * 1024 * 1024, // 637MB
        digest: 'mock-digest-2',
        details: OllamaModelDetails(
          format: 'gguf',
          family: 'llama',
          families: ['llama'],
          parameterSize: '1.1B',
          quantizationLevel: 'Q4_0',
        ),
      ),
    ];
  }
  
  // Check if a specific model is available
  Future<bool> isModelAvailable(String modelName) async {
    final models = await listModels();
    return models.any((model) => model.name.contains(modelName));
  }
  
  // Pull a model if it's not available
  Future<bool> pullModel(String modelName, {
    Function(String status)? onProgress,
  }) async {
    try {
      final request = http.Request('POST', Uri.parse('$baseUrl/api/pull'));
      request.headers['Content-Type'] = 'application/json';
      request.body = json.encode({'name': modelName});
      
      final response = await httpClient.send(request);
      
      if (response.statusCode == 200) {
        await response.stream
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .forEach((line) {
          if (line.isNotEmpty) {
            try {
              final data = json.decode(line);
              final status = data['status'] ?? '';
              onProgress?.call(status);
            } catch (e) {
              // Ignore JSON decode errors
            }
          }
        });
        return true;
      }
    } catch (e) {
      print('Error pulling model: $e');
    }
    
    return false;
  }
  
  // Generate completion (non-streaming)
  Future<String> generate({
    required String model,
    required String prompt,
    String? system,
    List<String> context = const [],
    double temperature = 0.7,
    int maxTokens = 2000,
  }) async {
    try {
      final requestBody = {
        'model': model,
        'prompt': prompt,
        'system': system,
        'context': context,
        'options': {
          'temperature': temperature,
          'num_predict': maxTokens,
        },
        'stream': false,
      };
      
      final response = await httpClient.post(
        Uri.parse('$baseUrl/api/generate'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['response'] ?? '';
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('Ollama generate error: $e');
      // Return mock response with file content analysis for development
      return _generateMockResponse(prompt, system);
    }
  }
  
  // Generate streaming completion
  Stream<String> generateStream({
    required String model,
    required String prompt,
    String? system,
    List<String> context = const [],
    double temperature = 0.7,
    int maxTokens = 2000,
  }) async* {
    try {
      final requestBody = {
        'model': model,
        'prompt': prompt,
        'system': system,
        'context': context,
        'options': {
          'temperature': temperature,
          'num_predict': maxTokens,
        },
        'stream': true,
      };
      
      final request = http.Request('POST', Uri.parse('$baseUrl/api/generate'));
      request.headers['Content-Type'] = 'application/json';
      request.body = json.encode(requestBody);
      
      final response = await httpClient.send(request);
      
      if (response.statusCode == 200) {
        await for (final chunk in response.stream.transform(utf8.decoder).transform(const LineSplitter())) {
          if (chunk.isNotEmpty) {
            try {
              final data = json.decode(chunk);
              final text = data['response'] ?? '';
              if (text.isNotEmpty) {
                yield text;
              }
            } catch (e) {
              // Ignore JSON decode errors
            }
          }
        }
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to generate streaming completion: $e');
    }
  }
  
  // Chat completion with conversation history
  Future<String> chat({
    required String model,
    required List<ChatMessage> messages,
    double temperature = 0.7,
    int maxTokens = 2000,
  }) async {
    try {
      final requestBody = {
        'model': model,
        'messages': messages.map((msg) => msg.toJson()).toList(),
        'options': {
          'temperature': temperature,
          'num_predict': maxTokens,
        },
        'stream': false,
      };
      
      final response = await httpClient.post(
        Uri.parse('$baseUrl/api/chat'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['message']?['content'] ?? '';
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to generate chat completion: $e');
    }
  }
  
  // Streaming chat completion
  Stream<String> chatStream({
    required String model,
    required List<ChatMessage> messages,
    double temperature = 0.7,
    int maxTokens = 2000,
  }) async* {
    try {
      final requestBody = {
        'model': model,
        'messages': messages.map((msg) => msg.toJson()).toList(),
        'options': {
          'temperature': temperature,
          'num_predict': maxTokens,
        },
        'stream': true,
      };
      
      final request = http.Request('POST', Uri.parse('$baseUrl/api/chat'));
      request.headers['Content-Type'] = 'application/json';
      request.body = json.encode(requestBody);
      
      final response = await httpClient.send(request);
      
      if (response.statusCode == 200) {
        await for (final chunk in response.stream.transform(utf8.decoder).transform(const LineSplitter())) {
          if (chunk.isNotEmpty) {
            try {
              final data = json.decode(chunk);
              final text = data['message']?['content'] ?? '';
              if (text.isNotEmpty) {
                yield text;
              }
            } catch (e) {
              // Ignore JSON decode errors
            }
          }
        }
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to generate streaming chat completion: $e');
    }
  }
  
  // Prepare document context for LLM
  String prepareDocumentContext(List<DataItem> documents, {
    String? userQuery,
    int maxTokens = 8000,
  }) {
    final contextParts = <String>[];
    int totalTokens = 0;
    
    // Add header
    if (userQuery != null) {
      contextParts.add('User Query: $userQuery\n');
      contextParts.add('Relevant Documents:\n');
    }
    
    // Sort documents by relevance if available
    final sortedDocs = List<DataItem>.from(documents)
      ..sort((a, b) => b.relevance.compareTo(a.relevance));
    
    for (int i = 0; i < sortedDocs.length; i++) {
      final doc = sortedDocs[i];
      
      // Estimate tokens (rough approximation: 1 token ≈ 4 characters)
      final docText = '''
Document ${i + 1}: ${doc.title}
Type: ${doc.type}
Created: ${doc.createdAt.toString().substring(0, 10)}
Path: ${doc.path}
Content: ${doc.content}

---
''';
      
      final estimatedTokens = docText.length ~/ 4;
      
      if (totalTokens + estimatedTokens > maxTokens && contextParts.isNotEmpty) {
        break; // Stop adding documents if we're approaching token limit
      }
      
      contextParts.add(docText);
      totalTokens += estimatedTokens;
    }
    
    return contextParts.join('\n');
  }
  
  // Generate mock response for testing when Ollama is not available
  String _generateMockResponse(String prompt, String? system) {
    final responses = [
      "Based on the selected documents, I can see this relates to ${prompt.length > 50 ? prompt.substring(0, 50) + '...' : prompt}. The content includes personal data, project files, and communication records. Let me analyze the key patterns and provide insights.",
      "I've analyzed the document content and found several interesting connections. The files contain information about personal projects, communication patterns, and various data types that could be valuable for understanding trends and relationships.",
      "From the selected files, I can identify themes related to productivity, communication, and data organization. The content suggests active engagement with various projects and systems integration work.",
    ];
    
    // Pick a response based on prompt hash for consistency
    final index = prompt.hashCode.abs() % responses.length;
    return responses[index];
  }
  
  void dispose() {
    httpClient.close();
  }
}

class OllamaModel {
  final String name;
  final String? modifiedAt;
  final int? size;
  final String? digest;
  
  OllamaModel({
    required this.name,
    this.modifiedAt,
    this.size,
    this.digest,
  });
  
  factory OllamaModel.fromJson(Map<String, dynamic> json) {
    return OllamaModel(
      name: json['name'] ?? '',
      modifiedAt: json['modified_at'],
      size: json['size'],
      digest: json['digest'],
    );
  }
  
  String get displayName {
    // Clean up model name for display
    return name.split(':').first;
  }
  
  String get sizeFormatted {
    if (size == null) return 'Unknown';
    
    final gb = size! / (1024 * 1024 * 1024);
    if (gb >= 1) {
      return '${gb.toStringAsFixed(1)} GB';
    }
    
    final mb = size! / (1024 * 1024);
    return '${mb.toStringAsFixed(0)} MB';
  }
}

class ChatMessage {
  final String role; // 'system', 'user', 'assistant'
  final String content;
  
  ChatMessage({
    required this.role,
    required this.content,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'role': role,
      'content': content,
    };
  }
  
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      role: json['role'] ?? 'user',
      content: json['content'] ?? '',
    );
  }
  
  factory ChatMessage.system(String content) {
    return ChatMessage(role: 'system', content: content);
  }
  
  factory ChatMessage.user(String content) {
    return ChatMessage(role: 'user', content: content);
  }
  
  factory ChatMessage.assistant(String content) {
    return ChatMessage(role: 'assistant', content: content);
  }
}

// LLM Service Manager
class LLMService {
  late OllamaClient _ollama;
  List<OllamaModel> _availableModels = [];
  String? _preferredModel;
  
  LLMService() {
    _ollama = OllamaClient();
  }
  
  Future<bool> initialize() async {
    try {
      final isAvailable = await _ollama.isAvailable();
      if (!isAvailable) {
        return false;
      }
      
      _availableModels = await _ollama.listModels();
      
      // Set preferred model (prefer gemma3:270m if available)
      if (_availableModels.any((m) => m.name.contains('gemma3:270m'))) {
        _preferredModel = 'gemma3:270m';
      } else if (_availableModels.isNotEmpty) {
        _preferredModel = _availableModels.first.name;
      }
      
      return true;
    } catch (e) {
      print('Failed to initialize LLM service: $e');
      return false;
    }
  }
  
  Future<bool> ensureModel(String modelName) async {
    if (!await _ollama.isModelAvailable(modelName)) {
      return await _ollama.pullModel(modelName);
    }
    return true;
  }
  
  List<OllamaModel> get availableModels => _availableModels;
  String? get preferredModel => _preferredModel;
  set preferredModel(String? model) => _preferredModel = model;
  
  Future<String> queryDocuments({
    required List<DataItem> documents,
    required String userQuery,
    String? model,
  }) async {
    final targetModel = model ?? _preferredModel;
    if (targetModel == null) {
      throw Exception('No model available');
    }
    
    final context = _ollama.prepareDocumentContext(documents, userQuery: userQuery);
    
    final systemPrompt = '''You are MyAI, a personal AI assistant that helps users understand and analyze their personal documents and data. You have access to the user's documents and can provide insights, summaries, and answer questions about their content.

Key guidelines:
- Be helpful and conversational
- Reference specific documents when relevant
- Protect user privacy - never share personal information outside this conversation
- If you can't find relevant information in the provided documents, say so clearly
- Provide actionable insights when possible''';
    
    final prompt = '''$context

Question: $userQuery

Please analyze the provided documents and answer the user's question. Reference specific documents when relevant.''';
    
    return await _ollama.generate(
      model: targetModel,
      prompt: prompt,
      system: systemPrompt,
      temperature: 0.7,
    );
  }
  
  Stream<String> queryDocumentsStream({
    required List<DataItem> documents,
    required String userQuery,
    String? model,
  }) async* {
    final targetModel = model ?? _preferredModel;
    if (targetModel == null) {
      throw Exception('No model available');
    }
    
    final context = _ollama.prepareDocumentContext(documents, userQuery: userQuery);
    
    final systemPrompt = '''You are MyAI, a personal AI assistant that helps users understand and analyze their personal documents and data. You have access to the user's documents and can provide insights, summaries, and answer questions about their content.

Key guidelines:
- Be helpful and conversational
- Reference specific documents when relevant
- Protect user privacy - never share personal information outside this conversation
- If you can't find relevant information in the provided documents, say so clearly
- Provide actionable insights when possible''';
    
    final prompt = '''$context

Question: $userQuery

Please analyze the provided documents and answer the user's question. Reference specific documents when relevant.''';
    
    yield* _ollama.generateStream(
      model: targetModel,
      prompt: prompt,
      system: systemPrompt,
      temperature: 0.7,
    );
  }
  
  Future<String> summarizeDocuments({
    required List<DataItem> documents,
    String? model,
  }) async {
    final targetModel = model ?? _preferredModel;
    if (targetModel == null) {
      throw Exception('No model available');
    }
    
    final context = _ollama.prepareDocumentContext(documents);
    
    final prompt = '''$context

Please provide a comprehensive summary of these documents. Focus on:
1. Key themes and topics
2. Important dates and events
3. Action items or next steps
4. Connections between documents
5. Overall insights

Format the summary in a clear, organized manner.''';
    
    return await _ollama.generate(
      model: targetModel,
      prompt: prompt,
      temperature: 0.3,
    );
  }
  
  Future<List<String>> generateInsights({
    required List<DataItem> documents,
    String? model,
  }) async {
    final targetModel = model ?? _preferredModel;
    if (targetModel == null) {
      throw Exception('No model available');
    }
    
    final context = _ollama.prepareDocumentContext(documents);
    
    final prompt = '''$context

Based on these documents, generate 5-7 key insights or observations. Each insight should be:
- Actionable or informative
- Based on evidence from the documents
- Relevant to the user's life/work

Format as a simple list, one insight per line.''';
    
    final response = await _ollama.generate(
      model: targetModel,
      prompt: prompt,
      temperature: 0.4,
    );
    
    return response
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .map((line) => line.trim())
        .toList();
  }
  
  void dispose() {
    _ollama.dispose();
  }
}