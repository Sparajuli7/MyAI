import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../models/knowledge_graph.dart';
import '../main.dart';

class KnowledgeGraphWidget extends StatefulWidget {
  final bool showMiniMap;
  final Function(Set<String> selectedNodeIds)? onSelectionChanged;
  
  const KnowledgeGraphWidget({
    super.key,
    this.showMiniMap = false,
    this.onSelectionChanged,
  });

  @override
  State<KnowledgeGraphWidget> createState() => _KnowledgeGraphWidgetState();
}

class _KnowledgeGraphWidgetState extends State<KnowledgeGraphWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  KnowledgeGraph? _graph;
  Offset _panOffset = Offset.zero;
  double _zoomLevel = 1.0;
  Offset? _panStart;
  Set<String> _selectedNodes = {};
  String? _hoveredNode;
  bool _isDragging = false;
  String? _draggedNode;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  void _updateGraph(MyAIDataProvider provider, Size canvasSize) {
    if (_graph == null || provider.dataItems.length != _graph!.nodes.length) {
      final themeColors = MyAITheme.themes[provider.selectedTheme]!;
      _graph = GraphLayoutHelper.createFromDataItems(
        provider.dataItems,
        canvasSize,
        themeColors,
      );
      
      // Apply force-directed layout
      _graph = _graph!.applyForceDirectedLayout(canvasSize: canvasSize);
    }
  }
  
  void _handlePanStart(DragStartDetails details) {
    _panStart = details.localPosition;
    
    // Check if we're starting to drag a node
    final nodeId = _getNodeAtPosition(details.localPosition);
    if (nodeId != null) {
      _draggedNode = nodeId;
      _isDragging = true;
    }
  }
  
  void _handlePanUpdate(DragUpdateDetails details) {
    if (_isDragging && _draggedNode != null && _graph != null) {
      // Drag individual node
      final currentNode = _graph!.nodes[_draggedNode!]!;
      final newPosition = details.localPosition;
      
      final updatedNodes = Map<String, GraphNode>.from(_graph!.nodes);
      updatedNodes[_draggedNode!] = currentNode.copyWith(position: newPosition);
      
      setState(() {
        _graph = KnowledgeGraph(
          nodes: updatedNodes,
          edges: _graph!.edges,
          selectedNodes: _graph!.selectedNodes,
        );
      });
    } else if (_panStart != null) {
      // Pan the entire graph
      setState(() {
        _panOffset += details.delta;
      });
    }
  }
  
  void _handlePanEnd(DragEndDetails details) {
    _panStart = null;
    _isDragging = false;
    _draggedNode = null;
  }
  
  void _handleTap(TapDownDetails details) {
    final nodeId = _getNodeAtPosition(details.localPosition);
    
    if (nodeId != null) {
      setState(() {
        if (_selectedNodes.contains(nodeId)) {
          _selectedNodes.remove(nodeId);
        } else {
          _selectedNodes.add(nodeId);
        }
        
        // Update graph selection state
        if (_graph != null) {
          final updatedNodes = <String, GraphNode>{};
          for (final entry in _graph!.nodes.entries) {
            updatedNodes[entry.key] = entry.value.copyWith(
              isSelected: _selectedNodes.contains(entry.key),
            );
          }
          
          _graph = KnowledgeGraph(
            nodes: updatedNodes,
            edges: _graph!.edges,
            selectedNodes: _selectedNodes,
          );
        }
      });
      
      // Notify parent of selection change
      widget.onSelectionChanged?.call(_selectedNodes);
    } else {
      // Clear selection if tapping empty space
      setState(() {
        _selectedNodes.clear();
        if (_graph != null) {
          final updatedNodes = <String, GraphNode>{};
          for (final entry in _graph!.nodes.entries) {
            updatedNodes[entry.key] = entry.value.copyWith(isSelected: false);
          }
          
          _graph = KnowledgeGraph(
            nodes: updatedNodes,
            edges: _graph!.edges,
            selectedNodes: {},
          );
        }
      });
      widget.onSelectionChanged?.call({});
    }
  }
  
  void _handleHover(PointerHoverEvent event) {
    final nodeId = _getNodeAtPosition(event.localPosition);
    
    if (_hoveredNode != nodeId) {
      setState(() {
        _hoveredNode = nodeId;
        
        if (_graph != null) {
          final updatedNodes = <String, GraphNode>{};
          for (final entry in _graph!.nodes.entries) {
            updatedNodes[entry.key] = entry.value.copyWith(
              isHovered: entry.key == nodeId,
            );
          }
          
          _graph = KnowledgeGraph(
            nodes: updatedNodes,
            edges: _graph!.edges,
            selectedNodes: _graph!.selectedNodes,
          );
        }
      });
    }
  }
  
  String? _getNodeAtPosition(Offset position) {
    if (_graph == null) return null;
    
    for (final node in _graph!.nodes.values) {
      final nodePosition = node.position + _panOffset;
      final distance = (nodePosition - position).distance;
      
      if (distance <= node.size) {
        return node.id;
      }
    }
    
    return null;
  }
  
  @override
  Widget build(BuildContext context) {
    return Consumer<MyAIDataProvider>(
      builder: (context, provider, child) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final canvasSize = Size(constraints.maxWidth, constraints.maxHeight);
            _updateGraph(provider, canvasSize);
            
            return Stack(
              children: [
                // Main graph canvas
                Positioned.fill(
                  child: GestureDetector(
                    onPanStart: _handlePanStart,
                    onPanUpdate: _handlePanUpdate,
                    onPanEnd: _handlePanEnd,
                    onTapDown: _handleTap,
                    child: MouseRegion(
                      onHover: _handleHover,
                      child: AnimatedBuilder(
                        animation: _animationController,
                        builder: (context, child) {
                          return CustomPaint(
                            painter: KnowledgeGraphPainter(
                              graph: _graph,
                              panOffset: _panOffset,
                              zoomLevel: _zoomLevel,
                              animationValue: _animationController.value,
                              hoveredNode: _hoveredNode,
                            ),
                            size: canvasSize,
                          );
                        },
                      ),
                    ),
                  ),
                ),
                
                // Graph controls
                Positioned(
                  top: 16,
                  left: 16,
                  child: _buildGraphControls(provider),
                ),
                
                // Selection info
                if (_selectedNodes.isNotEmpty)
                  Positioned(
                    bottom: 16,
                    left: 16,
                    child: _buildSelectionInfo(provider),
                  ),
                
                // Mini map
                if (widget.showMiniMap)
                  Positioned(
                    top: 16,
                    right: 16,
                    child: _buildMiniMap(canvasSize),
                  ),
              ],
            );
          },
        );
      },
    );
  }
  
  Widget _buildGraphControls(MyAIDataProvider provider) {
    final themeColors = MyAITheme.themes[provider.selectedTheme]!;
    
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: themeColors['surface']!.withOpacity(0.9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: themeColors['primary']!.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Zoom controls
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.zoom_out, color: themeColors['text'], size: 16),
                onPressed: () {
                  setState(() {
                    _zoomLevel = math.max(0.5, _zoomLevel - 0.1);
                  });
                },
              ),
              Text(
                '${(_zoomLevel * 100).toInt()}%',
                style: TextStyle(
                  color: themeColors['text'],
                  fontSize: 12,
                ),
              ),
              IconButton(
                icon: Icon(Icons.zoom_in, color: themeColors['text'], size: 16),
                onPressed: () {
                  setState(() {
                    _zoomLevel = math.min(2.0, _zoomLevel + 0.1);
                  });
                },
              ),
            ],
          ),
          
          // Reset view
          TextButton(
            onPressed: () {
              setState(() {
                _panOffset = Offset.zero;
                _zoomLevel = 1.0;
              });
            },
            child: Text(
              'Reset View',
              style: TextStyle(
                color: themeColors['primary'],
                fontSize: 10,
              ),
            ),
          ),
          
          // Layout refresh
          IconButton(
            icon: Icon(Icons.refresh, color: themeColors['primary'], size: 16),
            tooltip: 'Recalculate Layout',
            onPressed: () {
              setState(() {
                _graph = null; // Force rebuild
              });
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildSelectionInfo(MyAIDataProvider provider) {
    final themeColors = MyAITheme.themes[provider.selectedTheme]!;
    
    return Container(
      padding: const EdgeInsets.all(12),
      constraints: const BoxConstraints(maxWidth: 300),
      decoration: BoxDecoration(
        color: themeColors['surface']!.withOpacity(0.95),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: themeColors['primary']!.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.check_circle,
                color: themeColors['primary'],
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'Selected (${_selectedNodes.length})',
                style: TextStyle(
                  color: themeColors['text'],
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedNodes.clear();
                    if (_graph != null) {
                      final updatedNodes = <String, GraphNode>{};
                      for (final entry in _graph!.nodes.entries) {
                        updatedNodes[entry.key] = entry.value.copyWith(isSelected: false);
                      }
                      
                      _graph = KnowledgeGraph(
                        nodes: updatedNodes,
                        edges: _graph!.edges,
                        selectedNodes: {},
                      );
                    }
                  });
                  widget.onSelectionChanged?.call({});
                },
                child: Text(
                  'Clear',
                  style: TextStyle(
                    color: themeColors['primary'],
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Show first few selected items
          for (final nodeId in _selectedNodes.take(3))
            if (_graph?.nodes.containsKey(nodeId) == true)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '• ${_graph!.nodes[nodeId]!.data.title}',
                  style: TextStyle(
                    color: themeColors['textSecondary'],
                    fontSize: 10,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              
          if (_selectedNodes.length > 3)
            Text(
              '... and ${_selectedNodes.length - 3} more',
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
  
  Widget _buildMiniMap(Size canvasSize) {
    return Container(
      width: 150,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: CustomPaint(
        painter: MiniMapPainter(
          graph: _graph,
          fullCanvasSize: canvasSize,
          panOffset: _panOffset,
          zoomLevel: _zoomLevel,
        ),
      ),
    );
  }
}

class KnowledgeGraphPainter extends CustomPainter {
  final KnowledgeGraph? graph;
  final Offset panOffset;
  final double zoomLevel;
  final double animationValue;
  final String? hoveredNode;
  
  KnowledgeGraphPainter({
    required this.graph,
    required this.panOffset,
    required this.zoomLevel,
    required this.animationValue,
    this.hoveredNode,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    if (graph == null) return;
    
    canvas.save();
    
    // Apply zoom and pan
    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(zoomLevel);
    canvas.translate(-size.width / 2 + panOffset.dx, -size.height / 2 + panOffset.dy);
    
    // Draw edges first (so they appear behind nodes)
    _drawEdges(canvas);
    
    // Draw nodes
    _drawNodes(canvas);
    
    canvas.restore();
  }
  
  void _drawEdges(Canvas canvas) {
    for (final edge in graph!.edges) {
      final fromNode = graph!.nodes[edge.fromNodeId];
      final toNode = graph!.nodes[edge.toNodeId];
      
      if (fromNode == null || toNode == null) continue;
      
      // Animate edge opacity based on connection strength
      final opacity = (0.3 + 0.4 * edge.weight * (0.5 + 0.5 * math.sin(animationValue * 2 * math.pi)));
      
      final paint = Paint()
        ..color = edge.color.withOpacity(opacity)
        ..strokeWidth = math.max(1.0, edge.weight * 3.0)
        ..style = PaintingStyle.stroke;
      
      // Draw curved edge for better visibility
      final path = Path();
      path.moveTo(fromNode.position.dx, fromNode.position.dy);
      
      // Create control point for curve
      final midX = (fromNode.position.dx + toNode.position.dx) / 2;
      final midY = (fromNode.position.dy + toNode.position.dy) / 2;
      final offsetX = (toNode.position.dy - fromNode.position.dy) * 0.2;
      final offsetY = (fromNode.position.dx - toNode.position.dx) * 0.2;
      
      path.quadraticBezierTo(
        midX + offsetX,
        midY + offsetY,
        toNode.position.dx,
        toNode.position.dy,
      );
      
      canvas.drawPath(path, paint);
      
      // Draw edge type indicator
      _drawEdgeTypeIndicator(canvas, edge, midX + offsetX, midY + offsetY);
    }
  }
  
  void _drawEdgeTypeIndicator(Canvas canvas, GraphEdge edge, double x, double y) {
    IconData icon;
    switch (edge.type) {
      case EdgeType.semantic:
        icon = Icons.psychology;
        break;
      case EdgeType.temporal:
        icon = Icons.access_time;
        break;
      case EdgeType.reference:
        icon = Icons.link;
        break;
      case EdgeType.entity:
        icon = Icons.person;
        break;
    }
    
    // Draw small icon at edge midpoint
    final iconPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: 8,
          fontFamily: icon.fontFamily,
          color: edge.color,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    
    iconPainter.layout();
    iconPainter.paint(canvas, Offset(x - iconPainter.width / 2, y - iconPainter.height / 2));
  }
  
  void _drawNodes(Canvas canvas) {
    for (final node in graph!.nodes.values) {
      _drawNode(canvas, node);
    }
  }
  
  void _drawNode(Canvas canvas, GraphNode node) {
    final center = node.position;
    var radius = node.size;
    
    // Animate selected and hovered nodes
    if (node.isSelected) {
      radius *= 1.2;
    }
    
    if (node.isHovered) {
      radius *= 1.1;
    }
    
    // Draw node shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    
    canvas.drawCircle(center + const Offset(2, 2), radius, shadowPaint);
    
    // Draw main node
    final gradient = RadialGradient(
      colors: [
        node.color,
        node.color.withOpacity(0.8),
        node.color.withOpacity(0.4),
      ],
    );
    
    final paint = Paint()
      ..shader = gradient.createShader(Rect.fromCircle(center: center, radius: radius));
    
    canvas.drawCircle(center, radius, paint);
    
    // Draw selection ring
    if (node.isSelected) {
      final ringPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
        
      canvas.drawCircle(center, radius + 3, ringPaint);
    }
    
    // Draw node type icon
    _drawNodeTypeIcon(canvas, node, center, radius * 0.6);
    
    // Draw node label
    _drawNodeLabel(canvas, node, center, radius);
  }
  
  void _drawNodeTypeIcon(Canvas canvas, GraphNode node, Offset center, double size) {
    IconData icon;
    switch (node.data.type) {
      case 'email':
        icon = Icons.email;
        break;
      case 'file':
        icon = Icons.description;
        break;
      case 'image':
        icon = Icons.image;
        break;
      case 'message':
        icon = Icons.message;
        break;
      default:
        icon = Icons.description;
    }
    
    final iconPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: size,
          fontFamily: icon.fontFamily,
          color: Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    
    iconPainter.layout();
    iconPainter.paint(
      canvas,
      Offset(
        center.dx - iconPainter.width / 2,
        center.dy - iconPainter.height / 2,
      ),
    );
  }
  
  void _drawNodeLabel(Canvas canvas, GraphNode node, Offset center, double radius) {
    if (!node.isHovered && !node.isSelected) return;
    
    final labelText = node.data.title;
    final textPainter = TextPainter(
      text: TextSpan(
        text: labelText,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 2,
    );
    
    textPainter.layout(maxWidth: 120);
    
    // Draw label background
    final labelRect = Rect.fromCenter(
      center: Offset(center.dx, center.dy - radius - textPainter.height / 2 - 8),
      width: textPainter.width + 8,
      height: textPainter.height + 4,
    );
    
    final labelPaint = Paint()
      ..color = Colors.black.withOpacity(0.8);
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(labelRect, const Radius.circular(4)),
      labelPaint,
    );
    
    // Draw label text
    textPainter.paint(
      canvas,
      Offset(
        labelRect.left + 4,
        labelRect.top + 2,
      ),
    );
  }
  
  @override
  bool shouldRepaint(covariant KnowledgeGraphPainter oldDelegate) {
    return graph != oldDelegate.graph ||
        panOffset != oldDelegate.panOffset ||
        zoomLevel != oldDelegate.zoomLevel ||
        animationValue != oldDelegate.animationValue ||
        hoveredNode != oldDelegate.hoveredNode;
  }
}

class MiniMapPainter extends CustomPainter {
  final KnowledgeGraph? graph;
  final Size fullCanvasSize;
  final Offset panOffset;
  final double zoomLevel;
  
  MiniMapPainter({
    required this.graph,
    required this.fullCanvasSize,
    required this.panOffset,
    required this.zoomLevel,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    if (graph == null) return;
    
    final scale = math.min(size.width / fullCanvasSize.width, size.height / fullCanvasSize.height);
    
    canvas.save();
    canvas.scale(scale);
    
    // Draw simplified nodes
    for (final node in graph!.nodes.values) {
      final paint = Paint()..color = node.color.withOpacity(0.7);
      canvas.drawCircle(node.position, 3, paint);
    }
    
    // Draw viewport indicator
    final viewportRect = Rect.fromCenter(
      center: Offset(-panOffset.dx, -panOffset.dy),
      width: fullCanvasSize.width / zoomLevel,
      height: fullCanvasSize.height / zoomLevel,
    );
    
    final viewportPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    
    canvas.drawRect(viewportRect, viewportPaint);
    
    canvas.restore();
  }
  
  @override
  bool shouldRepaint(covariant MiniMapPainter oldDelegate) {
    return graph != oldDelegate.graph ||
        panOffset != oldDelegate.panOffset ||
        zoomLevel != oldDelegate.zoomLevel;
  }
}