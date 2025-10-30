import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'food_provider.dart'; // for ApiConfig and FoodItem

/// Details screen
/// - Fetches key nutrients for a given FDC ID from our backend
/// - Displays a simple two-column table
class DetailScreen extends StatefulWidget {
  final FoodItem foodItem;
  const DetailScreen({super.key, required this.foodItem});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late Future<Map<String, dynamic>> _detailFuture;

  Future<Map<String, dynamic>> _fetchDetails(int fdcId) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/food/$fdcId');
    final resp = await http.get(uri);
    if (resp.statusCode == 200) {
      return json.decode(resp.body) as Map<String, dynamic>;
    }
    throw Exception('Server error: ${resp.statusCode}');
  }

  @override
  void initState() {
    super.initState();
    _detailFuture = _fetchDetails(widget.foodItem.fdcId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.foodItem.description)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<Map<String, dynamic>>(
          future: _detailFuture,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return Center(
                child: Text(
                  'Error: ${snap.error}',
                  style: const TextStyle(color: Colors.red),
                ),
              );
            }

            final data = snap.data!;
            final nutrients = (data['nutrients'] as Map<String, dynamic>? ?? {});
            final cal = _asDouble(nutrients['calories']);
            final pro = _asDouble(nutrients['protein']);
            final fat = _asDouble(nutrients['fat']);
            final carb = _asDouble(nutrients['carbs']);
            final fib = _asDouble(nutrients['fiber']);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['description'] as String? ?? 'Food Details',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Table(
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  columnWidths: const {
                    0: IntrinsicColumnWidth(),
                    1: FlexColumnWidth(),
                  },
                  children: [
                    _row('Calories ', _fmt(cal), unit: 'kcal'),
                    _row('Protein ', _fmt(pro), unit: 'g'),
                    _row('Fat ', _fmt(fat), unit: 'g'),
                    _row('Carbs ', _fmt(carb), unit: 'g'),
                    _row('Fiber ', _fmt(fib), unit: 'g'),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  static TableRow _row(String name, String value, {String unit = ''}) {
    final display = unit.isEmpty || value == 'N/A' ? value : '$value $unit';
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(name),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            display,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  static String _fmt(double? v) {
  if (v == null) return 'N/A';

  // Round to 2 decimals
  final s = v.toStringAsFixed(2);

  // Trim trailing zeros and decimal
  final trimmed = s
      .replaceFirst(RegExp(r'\.00$'), '')
      .replaceFirst(RegExp(r'(\.\d)0$'), '\1');

  // Remove any accidental leading zero like 01
  return double.parse(trimmed).toString();
}


  static double? _asDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }
}
