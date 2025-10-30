import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'food_provider.dart';
import 'search_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => FoodSearchProvider(),
      child: const FoodApp(),
    ),
  );
}

/// Thin app shell that wires up Provider and sets a simple theme.
class FoodApp extends StatelessWidget {
  const FoodApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Food Info App',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.green,
      ),
      home: const SearchScreen(),
    );
  }
}
