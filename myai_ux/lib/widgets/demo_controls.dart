import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../services/demo_data.dart';

class DemoControls extends StatelessWidget {
  const DemoControls({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MyAIDataProvider>(
      builder: (context, provider, child) {
        final themeColors = MyAITheme.themes[provider.selectedTheme]!;
        
        return Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: themeColors['surface']!.withOpacity(0.9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: themeColors['primary']!.withOpacity(0.3),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Demo mode toggle
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    provider.isDemoMode ? Icons.visibility : Icons.visibility_off,
                    color: provider.isDemoMode 
                        ? themeColors['primary'] 
                        : themeColors['textSecondary'],
                    size: 16,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Demo Mode',
                    style: TextStyle(
                      color: themeColors['text'],
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                  SizedBox(width: 8),
                  Switch(
                    value: provider.isDemoMode,
                    onChanged: (value) => provider.toggleDemoMode(),
                    activeColor: themeColors['primary'],
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ],
              ),
              
              if (provider.isDemoMode) ...[
                SizedBox(height: 12),
                Divider(color: themeColors['textSecondary']!.withOpacity(0.3)),
                SizedBox(height: 8),
                
                // Quick demo queries
                Text(
                  'Try These Demo Queries:',
                  style: TextStyle(
                    color: themeColors['text'],
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
                
                SizedBox(height: 8),
                
                ...DemoData.mindBlowingQueries.take(3).map((demoQuery) => 
                  Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: InkWell(
                      onTap: () => provider.search(demoQuery.query),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: themeColors['primary']!.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: themeColors['primary']!.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.search,
                              size: 12,
                              color: themeColors['primary'],
                            ),
                            SizedBox(width: 4),
                            Text(
                              '"${demoQuery.query}"',
                              style: TextStyle(
                                color: themeColors['primary'],
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                
                SizedBox(height: 8),
                
                // Demo stats
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Demo Data:',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${provider.dataItems.length} items',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Search Speed:',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '<50ms ⚡',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class DemoScenarioSelector extends StatelessWidget {
  const DemoScenarioSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MyAIDataProvider>(
      builder: (context, provider, child) {
        final themeColors = MyAITheme.themes[provider.selectedTheme]!;
        
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            constraints: BoxConstraints(maxWidth: 600),
            decoration: BoxDecoration(
              color: themeColors['surface'],
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: themeColors['primary']!.withOpacity(0.1),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        color: themeColors['primary'],
                        size: 28,
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Demo Scenarios',
                              style: TextStyle(
                                color: themeColors['text'],
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Mind-blowing features to showcase',
                              style: TextStyle(
                                color: themeColors['textSecondary'],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(
                          Icons.close,
                          color: themeColors['textSecondary'],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Scenarios list
                Container(
                  constraints: BoxConstraints(maxHeight: 500),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      children: DemoData.impressiveScenarios.map((scenario) =>
                        Container(
                          margin: EdgeInsets.only(bottom: 16),
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: themeColors['background'],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: themeColors['textSecondary']!.withOpacity(0.2),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                scenario.title,
                                style: TextStyle(
                                  color: themeColors['text'],
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                scenario.description,
                                style: TextStyle(
                                  color: themeColors['textSecondary'],
                                  fontSize: 14,
                                  height: 1.4,
                                ),
                              ),
                              SizedBox(height: 12),
                              Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: themeColors['surface']!.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Try: ${scenario.sampleQuery}',
                                      style: TextStyle(
                                        color: themeColors['primary'],
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Impact: ${scenario.impact}',
                                      style: TextStyle(
                                        color: themeColors['textSecondary'],
                                        fontSize: 12,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ).toList(),
                    ),
                  ),
                ),
                
                // Footer
                Padding(
                  padding: EdgeInsets.all(24),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      // Start the first demo query
                      provider.search(DemoData.mindBlowingQueries.first.query);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeColors['primary'],
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: Icon(Icons.play_arrow),
                    label: Text('Start Demo'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}