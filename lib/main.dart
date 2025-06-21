// main.dart
import 'package:flutter/material.dart';
import 'ai_page.dart'; // Rename your AI page file to this, or update the import as needed

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gemini AI Chat',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.amber,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const AIPage(),
    );
  }
}
