import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../main.dart';

class GraphNode {
  final String id;
  final DataItem data;
  final Offset position;
  final double size;
  final Color color;
  final Set<String> connectedNodes;
  bool isSelected;
  bool isHovered;
  
  GraphNode({
    required this.id,
    required this.data,
    required this.position,
    required this.size,
    required this.color,
    this.connectedNodes = const {},
    this.isSelected = false,
    this.isHovered = false,
  });
  
  GraphNode copyWith({
    Offset? position,
    bool? isSelected,
    bool? isHovered,
    Set<String>? connectedNodes,
  }) {
    return GraphNode(
      id: id,
      data: data,
      position: position ?? this.position,
      size: size,
      color: color,
      connectedNodes: connectedNodes ?? this.connectedNodes,
      isSelected: isSelected ?? this.isSelected,
      isHovered: isHovered ?? this.isHovered,
    );
  }
}

class GraphEdge {
  final String fromNodeId;
  final String toNodeId;
  final double weight; // Connection strength 0.0 to 1.0
  final EdgeType type;
  final Color color;
  
  GraphEdge({
    required this.fromNodeId,
    required this.toNodeId,
    required this.weight,
    required this.type,
    required this.color,
  });
}

enum EdgeType {
  semantic,    // Similar content/keywords
  temporal,    // Created around same time
  reference,   // Documents mention each other
  entity,      // Shared people/places/projects
}

class KnowledgeGraph {
  final Map<String, GraphNode> nodes;
  final List<GraphEdge> edges;
  final Set<String> selectedNodes;
  
  KnowledgeGraph({
    required this.nodes,
    required this.edges,
    this.selectedNodes = const {},
  });
  
  // Get all nodes connected to a given node
  Set<String> getConnectedNodes(String nodeId) {
    final connected = <String>{};
    for (final edge in edges) {
      if (edge.fromNodeId == nodeId) {
        connected.add(edge.toNodeId);
      } else if (edge.toNodeId == nodeId) {
        connected.add(edge.fromNodeId);
      }
    }
    return connected;
  }
  
  // Get subgraph of selected nodes and their connections
  KnowledgeGraph getSelectedSubgraph() {
    if (selectedNodes.isEmpty) return this;
    
    final subgraphNodes = <String, GraphNode>{};
    final subgraphEdges = <GraphEdge>[];
    
    // Add all selected nodes
    for (final nodeId in selectedNodes) {
      if (nodes.containsKey(nodeId)) {
        subgraphNodes[nodeId] = nodes[nodeId]!;
      }
    }
    
    // Add edges between selected nodes
    for (final edge in edges) {
      if (selectedNodes.contains(edge.fromNodeId) && 
          selectedNodes.contains(edge.toNodeId)) {
        subgraphEdges.add(edge);
      }
    }
    
    return KnowledgeGraph(
      nodes: subgraphNodes,
      edges: subgraphEdges,
      selectedNodes: selectedNodes,
    );
  }
  
  // Calculate layout using force-directed algorithm
  KnowledgeGraph applyForceDirectedLayout({
    required Size canvasSize,
    int iterations = 50,
    double repulsionStrength = 1000.0,
    double attractionStrength = 0.1,
    double damping = 0.9,
  }) {
    final updatedNodes = Map<String, GraphNode>.from(nodes);
    final nodeVelocities = <String, Offset>{};
    
    // Initialize velocities
    for (final nodeId in nodes.keys) {
      nodeVelocities[nodeId] = Offset.zero;
    }
    
    for (int i = 0; i < iterations; i++) {
      final forces = <String, Offset>{};
      
      // Initialize forces
      for (final nodeId in nodes.keys) {
        forces[nodeId] = Offset.zero;
      }
      
      // Calculate repulsion forces (nodes push each other away)
      final nodeIds = nodes.keys.toList();
      for (int j = 0; j < nodeIds.length; j++) {
        for (int k = j + 1; k < nodeIds.length; k++) {
          final nodeA = updatedNodes[nodeIds[j]]!;
          final nodeB = updatedNodes[nodeIds[k]]!;
          
          final distance = (nodeA.position - nodeB.position).distance;
          if (distance == 0) continue;
          
          final force = repulsionStrength / (distance * distance);
          final direction = (nodeA.position - nodeB.position) / distance;
          
          forces[nodeIds[j]] = forces[nodeIds[j]]! + direction * force;
          forces[nodeIds[k]] = forces[nodeIds[k]]! - direction * force;
        }
      }
      
      // Calculate attraction forces (connected nodes pull together)
      for (final edge in edges) {
        final nodeA = updatedNodes[edge.fromNodeId];
        final nodeB = updatedNodes[edge.toNodeId];
        
        if (nodeA == null || nodeB == null) continue;
        
        final distance = (nodeA.position - nodeB.position).distance;
        if (distance == 0) continue;
        
        final force = attractionStrength * edge.weight * distance;
        final direction = (nodeB.position - nodeA.position) / distance;
        
        forces[edge.fromNodeId] = forces[edge.fromNodeId]! + direction * force;
        forces[edge.toNodeId] = forces[edge.toNodeId]! - direction * force;
      }
      
      // Update positions
      for (final nodeId in nodes.keys) {
        final currentVelocity = nodeVelocities[nodeId]!;
        final force = forces[nodeId]!;
        
        // Update velocity with damping
        final newVelocity = (currentVelocity + force) * damping;
        nodeVelocities[nodeId] = newVelocity;
        
        // Update position
        final currentNode = updatedNodes[nodeId]!;
        var newPosition = currentNode.position + newVelocity;
        
        // Keep nodes within canvas bounds
        newPosition = Offset(
          math.max(50, math.min(canvasSize.width - 50, newPosition.dx)),
          math.max(50, math.min(canvasSize.height - 50, newPosition.dy)),
        );
        
        updatedNodes[nodeId] = currentNode.copyWith(position: newPosition);
      }
    }
    
    return KnowledgeGraph(
      nodes: updatedNodes,
      edges: edges,
      selectedNodes: selectedNodes,
    );
  }
}

class GraphLayoutHelper {
  // Create knowledge graph from data items
  static KnowledgeGraph createFromDataItems(
    List<DataItem> dataItems,
    Size canvasSize,
    Map<String, Color> themeColors,
  ) {
    final nodes = <String, GraphNode>{};
    final edges = <GraphEdge>[];
    
    // Create nodes
    for (int i = 0; i < dataItems.length; i++) {
      final item = dataItems[i];
      
      // Position nodes in a circle initially
      final angle = (2 * math.pi * i) / dataItems.length;
      final radius = math.min(canvasSize.width, canvasSize.height) * 0.3;
      final position = Offset(
        canvasSize.width / 2 + radius * math.cos(angle),
        canvasSize.height / 2 + radius * math.sin(angle),
      );
      
      // Determine node color based on constellation
      Color nodeColor;
      switch (item.constellation) {
        case 'personal':
          nodeColor = themeColors['primary']!;
          break;
        case 'kairoz':
          nodeColor = Colors.purple;
          break;
        case 'work':
          nodeColor = Colors.orange;
          break;
        default:
          nodeColor = themeColors['textSecondary']!;
      }
      
      // Size based on content length or relevance
      final size = math.max(20.0, math.min(50.0, item.content.length / 50.0 + 20.0));
      
      nodes[item.id] = GraphNode(
        id: item.id,
        data: item,
        position: position,
        size: size,
        color: nodeColor,
      );
    }
    
    // Create edges based on relationships
    edges.addAll(_detectSemanticRelationships(dataItems, themeColors));
    edges.addAll(_detectTemporalRelationships(dataItems, themeColors));
    edges.addAll(_detectEntityRelationships(dataItems, themeColors));
    
    return KnowledgeGraph(nodes: nodes, edges: edges);
  }
  
  // Detect semantic relationships (shared keywords)
  static List<GraphEdge> _detectSemanticRelationships(
    List<DataItem> dataItems,
    Map<String, Color> themeColors,
  ) {
    final edges = <GraphEdge>[];
    
    for (int i = 0; i < dataItems.length; i++) {
      for (int j = i + 1; j < dataItems.length; j++) {
        final itemA = dataItems[i];
        final itemB = dataItems[j];
        
        final similarity = _calculateTextSimilarity(
          itemA.title + " " + itemA.content,
          itemB.title + " " + itemB.content,
        );
        
        // Create edge if similarity is above threshold
        if (similarity > 0.2) {
          edges.add(GraphEdge(
            fromNodeId: itemA.id,
            toNodeId: itemB.id,
            weight: similarity,
            type: EdgeType.semantic,
            color: themeColors['primary']!.withOpacity(0.6),
          ));
        }
      }
    }
    
    return edges;
  }
  
  // Detect temporal relationships (created around same time)
  static List<GraphEdge> _detectTemporalRelationships(
    List<DataItem> dataItems,
    Map<String, Color> themeColors,
  ) {
    final edges = <GraphEdge>[];
    
    for (int i = 0; i < dataItems.length; i++) {
      for (int j = i + 1; j < dataItems.length; j++) {
        final itemA = dataItems[i];
        final itemB = dataItems[j];
        
        final timeDiff = itemA.createdAt.difference(itemB.createdAt).inDays.abs();
        
        // Create edge if created within 7 days of each other
        if (timeDiff <= 7) {
          final strength = math.max(0.1, 1.0 - (timeDiff / 7.0));
          
          edges.add(GraphEdge(
            fromNodeId: itemA.id,
            toNodeId: itemB.id,
            weight: strength,
            type: EdgeType.temporal,
            color: Colors.green.withOpacity(0.4),
          ));
        }
      }
    }
    
    return edges;
  }
  
  // Detect entity relationships (shared people, places, projects)
  static List<GraphEdge> _detectEntityRelationships(
    List<DataItem> dataItems,
    Map<String, Color> themeColors,
  ) {
    final edges = <GraphEdge>[];
    
    // Common entities to look for
    final entities = [
      'Kairoz', 'MyAI', 'visa', 'USCIS', 'James', 'school', 
      'budget', 'mortgage', 'Chase', 'embassy', 'demo'
    ];
    
    for (int i = 0; i < dataItems.length; i++) {
      for (int j = i + 1; j < dataItems.length; j++) {
        final itemA = dataItems[i];
        final itemB = dataItems[j];
        
        final sharedEntities = _findSharedEntities(
          itemA.title + " " + itemA.content,
          itemB.title + " " + itemB.content,
          entities,
        );
        
        if (sharedEntities.isNotEmpty) {
          final strength = math.min(1.0, sharedEntities.length / 3.0);
          
          edges.add(GraphEdge(
            fromNodeId: itemA.id,
            toNodeId: itemB.id,
            weight: strength,
            type: EdgeType.entity,
            color: Colors.orange.withOpacity(0.5),
          ));
        }
      }
    }
    
    return edges;
  }
  
  // Simple text similarity calculation
  static double _calculateTextSimilarity(String textA, String textB) {
    final wordsA = textA.toLowerCase().split(RegExp(r'\W+')).where((w) => w.length > 2).toSet();
    final wordsB = textB.toLowerCase().split(RegExp(r'\W+')).where((w) => w.length > 2).toSet();
    
    if (wordsA.isEmpty || wordsB.isEmpty) return 0.0;
    
    final intersection = wordsA.intersection(wordsB).length;
    final union = wordsA.union(wordsB).length;
    
    return intersection / union; // Jaccard similarity
  }
  
  // Find shared entities between two texts
  static Set<String> _findSharedEntities(String textA, String textB, List<String> entities) {
    final shared = <String>{};
    final lowerA = textA.toLowerCase();
    final lowerB = textB.toLowerCase();
    
    for (final entity in entities) {
      if (lowerA.contains(entity.toLowerCase()) && lowerB.contains(entity.toLowerCase())) {
        shared.add(entity);
      }
    }
    
    return shared;
  }
}