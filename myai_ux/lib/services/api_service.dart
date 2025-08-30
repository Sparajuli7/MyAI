import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:7777/api';
  static Process? _backendProcess;
  
  // Start the embedded Rust backend
  static Future<bool> startBackend() async {
    if (_backendProcess != null) return true;
    
    try {
      // Get the executable directory
      final exeDir = path.dirname(Platform.resolvedExecutable);
      final backendPath = path.join(exeDir, 'data', 
        Platform.isWindows ? 'myai_backend.exe' : 'myai_backend');
      
      if (!File(backendPath).existsSync()) {
        print('Backend executable not found at: $backendPath');
        return false;
      }
      
      // Start the backend process
      _backendProcess = await Process.start(backendPath, []);
      
      // Wait a moment for startup
      await Future.delayed(Duration(seconds: 2));
      
      // Check if backend is running
      return await isBackendRunning();
    } catch (e) {
      print('Failed to start backend: $e');
      return false;
    }
  }
  
  // Check if backend is accessible
  static Future<bool> isBackendRunning() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/status'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
  
  // Search query
  static Future<List<SearchResult>> search(String query) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/query'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'query': query,
          'k': 10,
          'stream': false,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = (data['results'] as List)
            .map((item) => SearchResult.fromJson(item))
            .toList();
        return results;
      }
      return [];
    } catch (e) {
      print('Search error: $e');
      return [];
    }
  }
  
  // Upload file
  static Future<bool> uploadFile(String filePath) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/ingest/file'),
      );
      
      request.files.add(await http.MultipartFile.fromPath('file', filePath));
      
      final response = await request.send();
      return response.statusCode == 200;
    } catch (e) {
      print('Upload error: $e');
      return false;
    }
  }
  
  // Upload text
  static Future<bool> uploadText(String title, String content) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/ingest/text'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'title': title,
          'text': content,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Text upload error: $e');
      return false;
    }
  }
  
  // Get status
  static Future<BackendStatus?> getStatus() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/status'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        return BackendStatus.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      print('Status error: $e');
      return null;
    }
  }
  
  // Stop backend when app closes
  static void stopBackend() {
    _backendProcess?.kill();
    _backendProcess = null;
  }
}

class SearchResult {
  final String title;
  final String content;
  final String? snippet;
  final double score;
  final String? filePath;
  final DateTime? createdAt;
  
  SearchResult({
    required this.title,
    required this.content,
    this.snippet,
    required this.score,
    this.filePath,
    this.createdAt,
  });
  
  factory SearchResult.fromJson(Map<String, dynamic> json) {
    return SearchResult(
      title: json['title'] ?? 'Untitled',
      content: json['content'] ?? '',
      snippet: json['snippet'],
      score: (json['score'] ?? 0.0).toDouble(),
      filePath: json['file_path'],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }
}

class BackendStatus {
  final int documentCount;
  final int chunkCount;
  final String status;
  
  BackendStatus({
    required this.documentCount,
    required this.chunkCount,
    required this.status,
  });
  
  factory BackendStatus.fromJson(Map<String, dynamic> json) {
    return BackendStatus(
      documentCount: json['document_count'] ?? 0,
      chunkCount: json['chunk_count'] ?? 0,
      status: json['status'] ?? 'unknown',
    );
  }
}