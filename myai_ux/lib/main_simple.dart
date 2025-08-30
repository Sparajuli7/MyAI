import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'dart:math' as math;
import 'dart:async';
import 'services/demo_data.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MyAI Test',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('MyAI Simple Test'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'MyAI is working!',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            SizedBox(height: 20),
            Text('Demo data items: ${DemoData.richDemoData.length}'),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                print('Button pressed!');
              },
              child: Text('Test Button'),
            ),
          ],
        ),
      ),
    );
  }
}