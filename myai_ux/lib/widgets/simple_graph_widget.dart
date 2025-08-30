import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart';

class SimpleGraphWidget extends StatefulWidget {
  final Function(Set<String> selectedNodeIds)? onSelectionChanged;
  
  const SimpleGraphWidget({
    super.key,
    this.onSelectionChanged,
  });

  @override
  State<SimpleGraphWidget> createState() => _SimpleGraphWidgetState();
}

class _SimpleGraphWidgetState extends State<SimpleGraphWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  Set<String> _selectedNodes = {};
  
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
  
  @override
  Widget build(BuildContext context) {
    return Consumer<MyAIDataProvider>(
      builder: (context, provider, child) {
        final themeColors = MyAITheme.themes[provider.selectedTheme]!;
        
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
              // Simple node visualization
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: SimpleGraphPainter(
                      dataItems: provider.dataItems,
                      themeColors: themeColors,
                      animationValue: _animationController.value,
                      selectedNodes: _selectedNodes,
                    ),
                    size: Size.infinite,
                  );
                },
              ),
              
              // Touch handler
              Positioned.fill(
                child: GestureDetector(
                  onTapDown: (details) => _handleTap(details, provider),
                ),
              ),
              
              // Instructions panel (always visible)
              Positioned(
                top: 16,
                left: 16,
                child: _buildInstructionsPanel(themeColors),
              ),
              
              // Info panel
              if (_selectedNodes.isNotEmpty)
                Positioned(
                  bottom: 16,
                  left: 16,
                  child: _buildInfoPanel(provider, themeColors),
                ),
            ],
          ),
        );
      },
    );
  }
  
  void _handleTap(TapDownDetails details, MyAIDataProvider provider) {
    // Simple tap handling - find nearest node
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final localPosition = renderBox.globalToLocal(details.globalPosition);
    
    // Group by constellation (same logic as painter)
    final constellationGroups = <String, List<DataItem>>{};
    for (final item in provider.dataItems) {
      constellationGroups.putIfAbsent(item.constellation, () => []).add(item);
    }
    
    // Find closest node
    String? closestNode;
    double closestDistance = double.infinity;
    
    int groupIndex = 0;
    for (final entry in constellationGroups.entries) {
      final items = entry.value;
      final groupStartX = 100.0 + (groupIndex * 250.0);
      final groupStartY = 150.0;
      
      for (int i = 0; i < items.length; i++) {
        final item = items[i];
        final x = groupStartX + (i % 3) * 80.0;
        final y = groupStartY + (i ~/ 3) * 80.0;
        
        final distance = (Offset(x, y) - localPosition).distance;
        if (distance < 40 && distance < closestDistance) {
          closestDistance = distance;
          closestNode = item.id;
        }
      }
      groupIndex++;
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
  
  Widget _buildInstructionsPanel(Map<String, Color> themeColors) {
    return Container(
      constraints: BoxConstraints(maxWidth: 280),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info, color: Colors.blue, size: 14),
              const SizedBox(width: 4),
              Text(
                'How to Use:',
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '1. Click nodes to select • 2. Ask AI questions',
            style: TextStyle(color: themeColors['text'], fontSize: 10),
          ),
          Text(
            '3. Click 📥 to export for other LLMs',
            style: TextStyle(color: themeColors['text'], fontSize: 10),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.2),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              '🟢 Ready for AI queries',
              style: TextStyle(color: Colors.green, fontSize: 9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoPanel(MyAIDataProvider provider, Map<String, Color> themeColors) {
    return Container(
      constraints: BoxConstraints(maxWidth: 280),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: themeColors['surface']!.withOpacity(0.9),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: themeColors['primary']!.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 14),
              const SizedBox(width: 4),
              Text(
                'Selected: ${_selectedNodes.length}',
                style: TextStyle(
                  color: themeColors['text'],
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Ready for AI analysis →',
            style: TextStyle(
              color: Colors.green,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          for (final nodeId in _selectedNodes.take(2))
            Padding(
              padding: const EdgeInsets.only(bottom: 1),
              child: Text(
                '• ${provider.dataItems.firstWhere((item) => item.id == nodeId).title}',
                style: TextStyle(
                  color: themeColors['textSecondary'],
                  fontSize: 9,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          if (_selectedNodes.length > 2)
            Text(
              '... and ${_selectedNodes.length - 2} more',
              style: TextStyle(
                color: themeColors['textSecondary'],
                fontSize: 8,
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }
}

class SimpleGraphPainter extends CustomPainter {
  final List<DataItem> dataItems;
  final Map<String, Color> themeColors;
  final double animationValue;
  final Set<String> selectedNodes;
  
  SimpleGraphPainter({
    required this.dataItems,
    required this.themeColors,
    required this.animationValue,
    required this.selectedNodes,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    // Group by constellation for better layout
    final constellationGroups = <String, List<DataItem>>{};
    for (final item in dataItems) {
      constellationGroups.putIfAbsent(item.constellation, () => []).add(item);
    }
    
    // Draw nodes grouped by constellation
    int groupIndex = 0;
    for (final entry in constellationGroups.entries) {
      final constellation = entry.key;
      final items = entry.value;
      
      // Position each group in different areas
      final groupStartX = 100.0 + (groupIndex * 250.0);
      final groupStartY = 150.0;
      
      for (int i = 0; i < items.length; i++) {
        final item = items[i];
        final x = groupStartX + (i % 3) * 80.0;
        final y = groupStartY + (i ~/ 3) * 80.0;
        
        if (x > size.width - 50 || y > size.height - 50) continue;
        
        // Determine node color
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
        
        // Draw connection lines within group
        if (i > 0) {
          final prevX = groupStartX + ((i - 1) % 3) * 80.0;
          final prevY = groupStartY + ((i - 1) ~/ 3) * 80.0;
          final paint = Paint()
            ..color = nodeColor.withOpacity(0.3)
            ..strokeWidth = 2;
          canvas.drawLine(Offset(prevX, prevY), Offset(x, y), paint);
        }
        
        // Draw constellation label
        if (i == 0) {
          final textPainter = TextPainter(
            text: TextSpan(
              text: constellation.toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                color: nodeColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            textDirection: TextDirection.ltr,
          );
          textPainter.layout();
          textPainter.paint(canvas, Offset(x - 20, y - 40));
        }
        
        // Draw node
        final radius = selectedNodes.contains(item.id) ? 25.0 : 20.0;
        
        // Animated pulse
        final pulseRadius = radius + 5 * animationValue;
        final pulsePaint = Paint()
          ..color = nodeColor.withOpacity(0.3 * (1 - animationValue));
        canvas.drawCircle(Offset(x, y), pulseRadius, pulsePaint);
        
        // Main node
        final nodePaint = Paint()
          ..color = nodeColor
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(x, y), radius, nodePaint);
        
        // Selection ring
        if (selectedNodes.contains(item.id)) {
          final ringPaint = Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2;
          canvas.drawCircle(Offset(x, y), radius + 3, ringPaint);
        }
        
        // Type icon
        final iconSize = 12.0;
        final textPainter = TextPainter(
          text: TextSpan(
            text: _getTypeIcon(item.type),
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
          Offset(x - textPainter.width / 2, y - textPainter.height / 2),
        );
      }
      groupIndex++;
    }
  }
  
  String _getTypeIcon(String type) {
    switch (type) {
      case 'email':
        return String.fromCharCode(Icons.email.codePoint);
      case 'file':
        return String.fromCharCode(Icons.description.codePoint);
      case 'image':
        return String.fromCharCode(Icons.image.codePoint);
      case 'message':
        return String.fromCharCode(Icons.message.codePoint);
      default:
        return String.fromCharCode(Icons.description.codePoint);
    }
  }
  
  @override
  bool shouldRepaint(covariant SimpleGraphPainter oldDelegate) {
    return animationValue != oldDelegate.animationValue ||
        selectedNodes != oldDelegate.selectedNodes ||
        dataItems != oldDelegate.dataItems;
  }
}