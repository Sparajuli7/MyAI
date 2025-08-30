import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/model_service.dart';
import '../main.dart';

class StartupScreen extends StatefulWidget {
  const StartupScreen({super.key});

  @override
  State<StartupScreen> createState() => _StartupScreenState();
}

class _StartupScreenState extends State<StartupScreen> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _progressController;
  
  String _status = 'Initializing MyAI...';
  double _progress = 0.0;
  bool _isDownloadingModels = false;
  String _currentModel = '';
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _initializeApp();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    try {
      // Step 1: Check if models are ready
      setState(() {
        _status = 'Checking AI models...';
        _progress = 0.1;
      });
      _progressController.animateTo(0.1);

      final modelsReady = await ModelService.areModelsReady();
      
      if (!modelsReady) {
        // Download models
        setState(() {
          _isDownloadingModels = true;
          _status = 'Downloading AI models (first time only)...';
        });
        
        await ModelService.downloadModels(
          onProgress: (modelName, progress) {
            setState(() {
              _currentModel = modelName;
              _progress = 0.1 + (progress * 0.6); // 10% to 70%
            });
            _progressController.animateTo(_progress);
          },
          onModelComplete: (modelName) {
            setState(() {
              _status = 'Downloaded $modelName model ✓';
            });
          },
          onAllComplete: () {
            setState(() {
              _isDownloadingModels = false;
              _status = 'All models ready ✓';
              _progress = 0.7;
            });
            _progressController.animateTo(0.7);
          },
          onError: (error) {
            setState(() {
              _hasError = true;
              _errorMessage = error;
              _status = 'Model download failed';
            });
            return;
          },
        );
      } else {
        setState(() {
          _status = 'AI models ready ✓';
          _progress = 0.7;
        });
        _progressController.animateTo(0.7);
      }

      // Step 2: Start backend
      setState(() {
        _status = 'Starting AI engine...';
        _progress = 0.8;
      });
      _progressController.animateTo(0.8);

      final backendStarted = await ApiService.startBackend();
      
      if (!backendStarted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Failed to start AI engine. Please try restarting the app.';
          _status = 'AI engine failed to start';
        });
        return;
      }

      // Step 3: Verify connection
      setState(() {
        _status = 'Connecting to AI engine...';
        _progress = 0.9;
      });
      _progressController.animateTo(0.9);

      // Wait a moment for backend to fully initialize
      await Future.delayed(Duration(seconds: 3));
      
      final isRunning = await ApiService.isBackendRunning();
      
      if (!isRunning) {
        setState(() {
          _hasError = true;
          _errorMessage = 'AI engine is not responding. Please try restarting the app.';
          _status = 'Connection failed';
        });
        return;
      }

      // Step 4: Complete
      setState(() {
        _status = 'Ready! Welcome to MyAI ✓';
        _progress = 1.0;
      });
      _progressController.animateTo(1.0);

      // Navigate to main app
      await Future.delayed(Duration(milliseconds: 500));
      _navigateToMain();

    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Initialization error: $e';
        _status = 'Startup failed';
      });
    }
  }

  void _navigateToMain() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const MyAIDashboard()),
    );
  }

  void _retry() {
    setState(() {
      _hasError = false;
      _errorMessage = '';
      _progress = 0.0;
      _status = 'Retrying...';
    });
    _progressController.reset();
    _initializeApp();
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
            child: Center(
              child: Container(
                constraints: BoxConstraints(maxWidth: 500),
                padding: EdgeInsets.all(40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo animation
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Container(
                          width: 120 + _pulseController.value * 20,
                          height: 120 + _pulseController.value * 20,
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
                                blurRadius: 30 + _pulseController.value * 15,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.psychology,
                            color: Colors.white,
                            size: 60,
                          ),
                        );
                      },
                    ),
                    
                    SizedBox(height: 40),
                    
                    // Title
                    Text(
                      'MyAI',
                      style: TextStyle(
                        color: themeColors['text'],
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                    SizedBox(height: 8),
                    
                    Text(
                      'Personal AGI with Privacy',
                      style: TextStyle(
                        color: themeColors['textSecondary'],
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    
                    SizedBox(height: 60),
                    
                    // Status and progress
                    if (!_hasError) ...[
                      // Progress bar
                      Container(
                        width: double.infinity,
                        height: 6,
                        decoration: BoxDecoration(
                          color: themeColors['surface'],
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: AnimatedBuilder(
                            animation: _progressController,
                            builder: (context, child) {
                              return LinearProgressIndicator(
                                value: _progressController.value,
                                backgroundColor: Colors.transparent,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  themeColors['primary']!,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      
                      SizedBox(height: 20),
                      
                      // Status text
                      Text(
                        _status,
                        style: TextStyle(
                          color: themeColors['text'],
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      if (_isDownloadingModels && _currentModel.isNotEmpty) ...[
                        SizedBox(height: 8),
                        Text(
                          'Downloading $_currentModel...',
                          style: TextStyle(
                            color: themeColors['textSecondary'],
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                      
                      SizedBox(height: 8),
                      
                      // Progress percentage
                      Text(
                        '${(_progress * 100).toInt()}%',
                        style: TextStyle(
                          color: themeColors['textSecondary'],
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ] else ...[
                      // Error state
                      Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 48,
                      ),
                      
                      SizedBox(height: 20),
                      
                      Text(
                        _status,
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      SizedBox(height: 12),
                      
                      Text(
                        _errorMessage,
                        style: TextStyle(
                          color: themeColors['textSecondary'],
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      SizedBox(height: 30),
                      
                      ElevatedButton(
                        onPressed: _retry,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeColors['primary'],
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text('Try Again'),
                      ),
                    ],
                    
                    SizedBox(height: 60),
                    
                    // Privacy notice
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.green.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.shield,
                            color: Colors.green,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            '100% Private • Your data never leaves this device',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}