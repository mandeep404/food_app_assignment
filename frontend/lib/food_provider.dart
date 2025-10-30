import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Central place to set the backend base URL.
/// Android Emulator -> http://10.0.2.2:8000
/// iOS Simulator or macOS or Web -> http://127.0.0.1:8000
/// Physical device -> http://<your-computer-LAN-IP>:8000  and run uvicorn with --host 0.0.0.0
class ApiConfig {
  static const String baseUrl = 'http://127.0.0.1:8000';
}

/// Minimal model for a search result row returned by our FastAPI /search endpoint.
class FoodItem {
  final int fdcId;
  final String description;

  FoodItem({required this.fdcId, required this.description});

  factory FoodItem.fromJson(Map<String, dynamic> json) {
    return FoodItem(
      fdcId: json['fdcId'] as int,
      description: (json['description'] as String?)?.trim().isNotEmpty == true
          ? json['description'] as String
          : 'Unknown item',
    );
  }
}

/// Provider to manage search state: results, loading, and errors.
/// Keep it simple and predictable.
class FoodSearchProvider extends ChangeNotifier {
  List<FoodItem> _results = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<FoodItem> get results => _results;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Execute a search against our backend.
  /// page is future friendly if you add pagination to the UI.
  Future<void> searchFoods(String query, {int page = 1}) async {
    final q = query.trim();
    if (q.isEmpty) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/search?query=${Uri.encodeQueryComponent(q)}&page=$page',
      );

      final resp = await http.get(uri);
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body) as Map<String, dynamic>;
        final foods = (data['foods'] as List<dynamic>? ?? [])
            .map((e) => FoodItem.fromJson(e as Map<String, dynamic>))
            .toList();
        _results = foods;
      } else {
        _results = [];
        _errorMessage = 'Server error: ${resp.statusCode}';
      }
    } catch (e) {
      _results = [];
      _errorMessage = 'Failed to connect. Is the backend running?';
      if (kDebugMode) {
        // Helpful during dev, silent in release.
        print('Search error: $e');
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Clear current results and error message.
  void clear() {
    _results = [];
    _errorMessage = null;
    notifyListeners();
  }
}
