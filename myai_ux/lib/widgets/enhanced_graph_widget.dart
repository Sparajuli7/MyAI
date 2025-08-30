import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../main.dart';

class EnhancedGraphWidget extends StatefulWidget {
  final Function(Set<String> selectedNodeIds)? onSelectionChanged;
  
  const EnhancedGraphWidget({
    super.key,
    this.onSelectionChanged,
  });

  @override
  State<EnhancedGraphWidget> createState() => _EnhancedGraphWidgetState();
}

class _EnhancedGraphWidgetState extends State<EnhancedGraphWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  Set<String> _selectedNodes = {};
  Map<String, Offset> _nodePositions = {};
  Map<String, List<String>> _relationships = {};
  String? _draggedNode;
  Offset? _dragOffset;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _calculateRelationships(List<DataItem> dataItems) {
    _relationships.clear();
    
    for (int i = 0; i < dataItems.length; i++) {
      final item1 = dataItems[i];
      _relationships[item1.id] = [];
      
      for (int j = 0; j < dataItems.length; j++) {
        if (i == j) continue;
        final item2 = dataItems[j];
        
        // Check for relationships
        if (_hasRelationship(item1, item2)) {
          _relationships[item1.id]!.add(item2.id);
        }
      }
    }
  }

  bool _hasRelationship(DataItem item1, DataItem item2) {
    // Same constellation (strong relationship)
    if (item1.constellation == item2.constellation) return true;
    
    // Shared entities/concepts
    final content1 = '${item1.title} ${item1.content}'.toLowerCase();
    final content2 = '${item2.title} ${item2.content}'.toLowerCase();
    
    // Key entity matching
    final sharedEntities = [
      // Visa/Immigration entities
      ['visa', 'uscis', 'msc2310312345', 'embassy', 'biometrics'],
      // Kairoz project entities
      ['kairoz', 'myai', 'pitch', 'investor', 'a16z', 'series a'],
      // Personal entities
      ['james', 'school', 'budget', 'bank', 'chase'],
      // Temporal relationships
      ['august 2025', 'october 2025', 'november 2025'],
    ];
    
    for (final entityGroup in sharedEntities) {
      int matches = 0;
      for (final entity in entityGroup) {
        if (content1.contains(entity) && content2.contains(entity)) {
          matches++;
        }
      }
      if (matches >= 1) return true; // At least one shared entity
    }
    
    // Temporal proximity (within 30 days)
    final timeDiff = item1.createdAt.difference(item2.createdAt).inDays.abs();
    if (timeDiff <= 30 && item1.constellation == item2.constellation) return true;
    
    return false;
  }

  void _calculateLayout(List<DataItem> dataItems, Size size) {
    if (_nodePositions.isEmpty || dataItems.isEmpty) {
      _initializePositions(dataItems, size);
    }
    
    // Force-directed layout algorithm with stronger forces
    const iterations = 10;
    const repulsiveForce = 2000.0;
    const attractiveForce = 0.3;
    const damping = 0.9;
    
    for (int iter = 0; iter < iterations; iter++) {
      Map<String, Offset> forces = {};
      
      // Initialize forces
      for (final item in dataItems) {
        forces[item.id] = Offset.zero;
      }
      
      // Repulsive forces between all nodes
      for (int i = 0; i < dataItems.length; i++) {
        for (int j = i + 1; j < dataItems.length; j++) {
          final node1 = dataItems[i];
          final node2 = dataItems[j];
          
          final pos1 = _nodePositions[node1.id]!;
          final pos2 = _nodePositions[node2.id]!;
          
          final diff = pos1 - pos2;
          final distance = diff.distance;
          
          if (distance > 0) {
            final force = diff * (repulsiveForce / (distance * distance));
            forces[node1.id] = forces[node1.id]! + force;
            forces[node2.id] = forces[node2.id]! - force;
          }
        }
      }
      
      // Attractive forces between connected nodes
      for (final item in dataItems) {
        final connections = _relationships[item.id] ?? [];
        final pos1 = _nodePositions[item.id]!;
        
        for (final connectedId in connections) {
          final pos2 = _nodePositions[connectedId];
          if (pos2 != null) {
            final diff = pos2 - pos1;
            final distance = diff.distance;
            final force = diff * (attractiveForce * distance);
            forces[item.id] = forces[item.id]! + force;
          }
        }
      }
      
      // Apply forces with bounds checking
      for (final item in dataItems) {
        final force = forces[item.id]!;
        final currentPos = _nodePositions[item.id]!;
        final newPos = currentPos + (force * damping);
        
        // Keep nodes within bounds
        final boundedPos = Offset(
          math.max(50, math.min(size.width - 50, newPos.dx)),
          math.max(50, math.min(size.height - 50, newPos.dy)),
        );
        
        _nodePositions[item.id] = boundedPos;
      }
    }
  }

  void _initializePositions(List<DataItem> dataItems, Size size) {
    final random = math.Random(42); // Consistent seed
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    
    print('Initializing graph with ${dataItems.length} items, size: ${size.width} x ${size.height}');
    
    // Group by constellation for better initial layout
    final constellationGroups = <String, List<DataItem>>{};
    for (final item in dataItems) {
      constellationGroups.putIfAbsent(item.constellation, () => []).add(item);
    }
    
    print('Constellation groups: ${constellationGroups.keys.toList()}');
    
    int groupIndex = 0;
    for (final entry in constellationGroups.entries) {
      final constellation = entry.key;
      final items = entry.value;
      
      // Position each constellation in a different area - spread them out more
      final angle = (groupIndex * 2 * math.pi) / constellationGroups.length;
      final groupDistance = math.min(size.width, size.height) * 0.25; // Use 25% of screen
      final groupCenterX = centerX + math.cos(angle) * groupDistance;
      final groupCenterY = centerY + math.sin(angle) * groupDistance;
      
      print('Group $constellation: ${items.length} items at (${groupCenterX.toInt()}, ${groupCenterY.toInt()})');
      
      for (int i = 0; i < items.length; i++) {
        final item = items[i];
        final localAngle = (i * 2 * math.pi) / items.length;
        final radius = 60 + random.nextDouble() * 80; // Larger spread within group
        
        final x = math.max(50.0, math.min(size.width - 50, 
            groupCenterX + math.cos(localAngle) * radius));
        final y = math.max(50.0, math.min(size.height - 50,
            groupCenterY + math.sin(localAngle) * radius));
        
        _nodePositions[item.id] = Offset(x.toDouble(), y.toDouble());
      }
      
      groupIndex++;
    }
    
    print('Positioned ${_nodePositions.length} nodes');
  }
  
  @override
  Widget build(BuildContext context) {
    return Consumer<MyAIDataProvider>(
      builder: (context, provider, child) {
        final themeColors = MyAITheme.themes[provider.selectedTheme]!;
        
        // Calculate relationships and layout
        _calculateRelationships(provider.dataItems);
        
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
              // Graph visualization
              LayoutBuilder(
                builder: (context, constraints) {
                  _calculateLayout(provider.dataItems, constraints.biggest);
                  
                  return AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: EnhancedGraphPainter(
                          dataItems: provider.dataItems,
                          themeColors: themeColors,
                          animationValue: _animationController.value,
                          selectedNodes: _selectedNodes,
                          nodePositions: _nodePositions,
                          relationships: _relationships,
                        ),
                        size: constraints.biggest,
                      );
                    },
                  );
                },
              ),
              
              // Touch and drag handler
              Positioned.fill(
                child: GestureDetector(
                  onTapDown: (details) => _handleTap(details, provider),
                  onPanStart: (details) => _handleDragStart(details, provider),
                  onPanUpdate: (details) => _handleDragUpdate(details),
                  onPanEnd: (details) => _handleDragEnd(),
                ),
              ),
              
              // Legend and instructions
              Positioned(
                top: 16,
                left: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLegend(themeColors),
                    const SizedBox(height: 12),
                    _buildInstructions(themeColors),
                  ],
                ),
              ),
              
              // Selection info panel
              if (_selectedNodes.isNotEmpty)
                Positioned(
                  bottom: 16,
                  left: 16,
                  child: _buildInfoPanel(provider, themeColors),
                ),
                
              // Relationship insights
              if (_selectedNodes.length >= 2)
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: _buildRelationshipPanel(provider, themeColors),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLegend(Map<String, Color> themeColors) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: themeColors['surface']!.withOpacity(0.9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: themeColors['primary']!.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Knowledge Graph', style: TextStyle(
            color: themeColors['text'], fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 4),
          _buildLegendItem('Personal', themeColors['primary']!, themeColors),
          _buildLegendItem('Kairoz', Colors.purple, themeColors),
          _buildLegendItem('Work', themeColors['textSecondary']!, themeColors),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, Map<String, Color> themeColors) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8, height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: themeColors['textSecondary'], fontSize: 10)),
      ],
    );
  }

  Widget _buildInstructions(Map<String, Color> themeColors) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.info, color: Colors.blue, size: 12),
              const SizedBox(width: 4),
              Text('How to use:', style: TextStyle(
                color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 6),
          Text('1. Click nodes to select them', 
            style: TextStyle(color: themeColors['text'], fontSize: 10)),
          Text('2. Drag nodes to reposition', 
            style: TextStyle(color: themeColors['text'], fontSize: 10)),
          Text('3. AI panel opens automatically →', 
            style: TextStyle(color: themeColors['text'], fontSize: 10)),
          Text('4. Ask questions about selected docs', 
            style: TextStyle(color: themeColors['text'], fontSize: 10)),
        ],
      ),
    );
  }
  
  void _handleTap(TapDownDetails details, MyAIDataProvider provider) {
    // Only handle tap if we're not in the middle of a drag
    if (_draggedNode != null) return;
    
    final localPosition = details.localPosition;
    
    // Find closest node
    String? closestNode;
    double closestDistance = double.infinity;
    
    for (final item in provider.dataItems) {
      final position = _nodePositions[item.id];
      if (position != null) {
        final distance = (position - localPosition).distance;
        if (distance < 35 && distance < closestDistance) {
          closestDistance = distance;
          closestNode = item.id;
        }
      }
    }
    
    if (closestNode != null) {
      setState(() {
        if (_selectedNodes.contains(closestNode!)) {
          _selectedNodes.remove(closestNode!);
        } else {
          _selectedNodes.add(closestNode!);
        }
      });
      
      widget.onSelectionChanged?.call(_selectedNodes);
    }
  }

  void _handleDragStart(DragStartDetails details, MyAIDataProvider provider) {
    final localPosition = details.localPosition;
    
    // Find node to drag
    for (final item in provider.dataItems) {
      final position = _nodePositions[item.id];
      if (position != null) {
        final distance = (position - localPosition).distance;
        if (distance < 35) {
          setState(() {
            _draggedNode = item.id;
            _dragOffset = localPosition - position;
          });
          break;
        }
      }
    }
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (_draggedNode != null && _dragOffset != null) {
      setState(() {
        _nodePositions[_draggedNode!] = details.localPosition - _dragOffset!;
      });
    }
  }

  void _handleDragEnd() {
    setState(() {
      _draggedNode = null;
      _dragOffset = null;
    });
  }

  Widget _buildInfoPanel(MyAIDataProvider provider, Map<String, Color> themeColors) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 300),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: themeColors['surface']!.withOpacity(0.9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: themeColors['primary']!.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Selected Documents (${_selectedNodes.length})',
            style: TextStyle(
              color: themeColors['text'],
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          for (final nodeId in _selectedNodes.take(4))
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '• ${provider.dataItems.firstWhere((item) => item.id == nodeId).title}',
                style: TextStyle(
                  color: themeColors['textSecondary'],
                  fontSize: 10,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          if (_selectedNodes.length > 4)
            Text(
              '... and ${_selectedNodes.length - 4} more',
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

  Widget _buildRelationshipPanel(MyAIDataProvider provider, Map<String, Color> themeColors) {
    final connections = <String>{};
    for (final nodeId in _selectedNodes) {
      final nodeConnections = _relationships[nodeId] ?? [];
      for (final connection in nodeConnections) {
        if (_selectedNodes.contains(connection)) {
          connections.add('$nodeId-$connection');
        }
      }
    }
    
    return Container(
      constraints: const BoxConstraints(maxWidth: 250),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: themeColors['surface']!.withOpacity(0.9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.withOpacity(0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.link, color: Colors.green, size: 14),
              const SizedBox(width: 4),
              Text(
                'Relationships',
                style: TextStyle(
                  color: themeColors['text'],
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${connections.length} connections found',
            style: TextStyle(
              color: Colors.green,
              fontSize: 10,
            ),
          ),
          Text(
            'Ready for AI analysis',
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
}

class EnhancedGraphPainter extends CustomPainter {
  final List<DataItem> dataItems;
  final Map<String, Color> themeColors;
  final double animationValue;
  final Set<String> selectedNodes;
  final Map<String, Offset> nodePositions;
  final Map<String, List<String>> relationships;
  
  EnhancedGraphPainter({
    required this.dataItems,
    required this.themeColors,
    required this.animationValue,
    required this.selectedNodes,
    required this.nodePositions,
    required this.relationships,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    // Draw relationships first (behind nodes)
    _drawRelationships(canvas);
    
    // Draw nodes
    for (final item in dataItems) {
      final position = nodePositions[item.id];
      if (position != null) {
        _drawNode(canvas, item, position);
      }
    }
  }

  void _drawRelationships(Canvas canvas) {
    for (final item in dataItems) {
      final pos1 = nodePositions[item.id];
      if (pos1 == null) continue;
      
      final connections = relationships[item.id] ?? [];
      for (final connectedId in connections) {
        final pos2 = nodePositions[connectedId];
        if (pos2 == null) continue;
        
        // Determine relationship strength
        bool isStrong = _isStrongRelationship(item.id, connectedId);
        bool isSelected = selectedNodes.contains(item.id) && selectedNodes.contains(connectedId);
        
        final paint = Paint()
          ..color = isSelected 
              ? Colors.yellow.withOpacity(0.8)
              : (isStrong ? Colors.white.withOpacity(0.4) : Colors.white.withOpacity(0.2))
          ..strokeWidth = isSelected ? 3 : (isStrong ? 2 : 1);
        
        canvas.drawLine(pos1, pos2, paint);
        
        // Draw relationship label for selected connections
        if (isSelected) {
          final midPoint = Offset(
            (pos1.dx + pos2.dx) / 2,
            (pos1.dy + pos2.dy) / 2,
          );
          
          final textPainter = TextPainter(
            text: TextSpan(
              text: '●',
              style: TextStyle(
                color: Colors.yellow,
                fontSize: 8,
              ),
            ),
            textDirection: TextDirection.ltr,
          );
          textPainter.layout();
          textPainter.paint(canvas, midPoint - Offset(textPainter.width / 2, textPainter.height / 2));
        }
      }
    }
  }

  bool _isStrongRelationship(String id1, String id2) {
    final item1 = dataItems.firstWhere((item) => item.id == id1);
    final item2 = dataItems.firstWhere((item) => item.id == id2);
    return item1.constellation == item2.constellation;
  }

  void _drawNode(Canvas canvas, DataItem item, Offset position) {
    // Determine node color based on constellation
    Color nodeColor;
    switch (item.constellation) {
      case 'personal':
        nodeColor = themeColors['primary']!;
        break;
      case 'kairoz':
        nodeColor = Colors.purple;
        break;
      default:
        nodeColor = themeColors['textSecondary']!;
    }
    
    final isSelected = selectedNodes.contains(item.id);
    final radius = isSelected ? 30.0 : 25.0;
    
    // Animated pulse for all nodes
    final pulseRadius = radius + 8 * math.sin(animationValue * 2 * math.pi);
    final pulsePaint = Paint()
      ..color = nodeColor.withOpacity(0.2 * (1 - animationValue));
    canvas.drawCircle(position, pulseRadius, pulsePaint);
    
    // Main node circle
    final nodePaint = Paint()
      ..color = nodeColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(position, radius, nodePaint);
    
    // Selection ring
    if (isSelected) {
      final ringPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      canvas.drawCircle(position, radius + 5, ringPaint);
    }
    
    // Type icon
    final iconPaint = Paint()..color = Colors.white;
    _drawTypeIcon(canvas, item.type, position, iconPaint);
    
    // Node label
    if (isSelected || selectedNodes.isEmpty) {
      _drawNodeLabel(canvas, item.title, position, radius);
    }
  }

  void _drawTypeIcon(Canvas canvas, String type, Offset center, Paint paint) {
    final iconSize = 16.0;
    IconData iconData;
    
    switch (type) {
      case 'email':
        iconData = Icons.email;
        break;
      case 'file':
        iconData = Icons.description;
        break;
      case 'image':
        iconData = Icons.image;
        break;
      case 'message':
        iconData = Icons.message;
        break;
      default:
        iconData = Icons.description;
    }
    
    final textPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(iconData.codePoint),
        style: TextStyle(
          fontSize: iconSize,
          color: Colors.white,
          fontFamily: 'MaterialIcons',
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout();
    textPainter.paint(
      canvas,
      center - Offset(textPainter.width / 2, textPainter.height / 2),
    );
  }

  void _drawNodeLabel(Canvas canvas, String title, Offset center, double radius) {
    final shortTitle = title.length > 20 ? '${title.substring(0, 20)}...' : title;
    
    final textPainter = TextPainter(
      text: TextSpan(
        text: shortTitle,
        style: TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    );
    
    textPainter.layout(maxWidth: 100);
    
    final labelPosition = center + Offset(-textPainter.width / 2, radius + 8);
    
    // Background for label
    final bgPaint = Paint()
      ..color = Colors.black.withOpacity(0.7);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          labelPosition.dx - 4,
          labelPosition.dy - 2,
          textPainter.width + 8,
          textPainter.height + 4,
        ),
        const Radius.circular(4),
      ),
      bgPaint,
    );
    
    textPainter.paint(canvas, labelPosition);
  }
  
  @override
  bool shouldRepaint(covariant EnhancedGraphPainter oldDelegate) {
    return animationValue != oldDelegate.animationValue ||
        selectedNodes != oldDelegate.selectedNodes ||
        nodePositions != oldDelegate.nodePositions;
  }
}