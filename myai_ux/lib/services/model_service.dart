import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

class ModelService {
  static const Map<String, ModelInfo> requiredModels = {
    'miniLM': ModelInfo(
      name: 'all-MiniLM-L6-v2.onnx',
      url: 'https://huggingface.co/sentence-transformers/all-MiniLM-L6-v2/resolve/main/onnx/model.onnx',
      size: 90 * 1024 * 1024, // ~90MB
    ),
    'miniLM-tokenizer': ModelInfo(
      name: 'all-MiniLM-L6-v2-tokenizer.json',
      url: 'https://huggingface.co/sentence-transformers/all-MiniLM-L6-v2/resolve/main/tokenizer.json',
      size: 500 * 1024, // ~500KB
    ),
    'bge-reranker': ModelInfo(
      name: 'bge-small-cross-encoder.onnx',
      url: 'https://huggingface.co/BAAI/bge-reranker-base/resolve/main/onnx/model.onnx',
      size: 110 * 1024 * 1024, // ~110MB
    ),
    'bge-tokenizer': ModelInfo(
      name: 'bge-small-tokenizer.json',
      url: 'https://huggingface.co/BAAI/bge-reranker-base/resolve/main/tokenizer.json',
      size: 700 * 1024, // ~700KB
    ),
  };

  static String get modelDirectory {
    if (Platform.isWindows) {
      return path.join(Platform.environment['USERPROFILE']!, '.myai-mvp', 'models');
    } else {
      return path.join(Platform.environment['HOME']!, '.myai-mvp', 'models');
    }
  }

  // Check if all models are downloaded
  static Future<bool> areModelsReady() async {
    final dir = Directory(modelDirectory);
    if (!dir.existsSync()) return false;

    for (final model in requiredModels.values) {
      final file = File(path.join(modelDirectory, model.name));
      if (!file.existsSync()) return false;
      
      // Check file size is reasonable
      final stat = await file.stat();
      if (stat.size < model.size * 0.8) return false; // Allow 20% variance
    }
    return true;
  }

  // Download all missing models
  static Future<void> downloadModels({
    required Function(String modelName, double progress) onProgress,
    required Function(String modelName) onModelComplete,
    required Function() onAllComplete,
    required Function(String error) onError,
  }) async {
    try {
      // Create models directory
      final dir = Directory(modelDirectory);
      if (!dir.existsSync()) {
        await dir.create(recursive: true);
      }

      // Download each model
      for (final entry in requiredModels.entries) {
        final modelKey = entry.key;
        final model = entry.value;
        final filePath = path.join(modelDirectory, model.name);
        final file = File(filePath);

        // Skip if already exists and correct size
        if (file.existsSync()) {
          final stat = await file.stat();
          if (stat.size >= model.size * 0.8) {
            onModelComplete(modelKey);
            continue;
          }
        }

        // Download the model
        await _downloadFile(
          url: model.url,
          filePath: filePath,
          onProgress: (progress) => onProgress(modelKey, progress),
        );
        
        onModelComplete(modelKey);
      }

      onAllComplete();
    } catch (e) {
      onError('Failed to download models: $e');
    }
  }

  static Future<void> _downloadFile({
    required String url,
    required String filePath,
    required Function(double progress) onProgress,
  }) async {
    final request = http.Request('GET', Uri.parse(url));
    final response = await http.Client().send(request);

    if (response.statusCode != 200) {
      throw Exception('Failed to download: ${response.statusCode}');
    }

    final contentLength = response.contentLength ?? 0;
    int downloadedBytes = 0;
    final chunks = <int>[];

    await response.stream.listen((chunk) {
      chunks.addAll(chunk);
      downloadedBytes += chunk.length;
      
      if (contentLength > 0) {
        final progress = downloadedBytes / contentLength;
        onProgress(progress);
      }
    }).asFuture();

    // Write to file
    final file = File(filePath);
    await file.writeAsBytes(Uint8List.fromList(chunks));
  }

  // Get total download size
  static int get totalDownloadSize {
    return requiredModels.values.fold(0, (sum, model) => sum + model.size);
  }

  // Format bytes for display
  static String formatBytes(int bytes) {
    if (bytes < 1024) return '${bytes} B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

class ModelInfo {
  final String name;
  final String url;
  final int size; // Size in bytes

  const ModelInfo({
    required this.name,
    required this.url,
    required this.size,
  });
}