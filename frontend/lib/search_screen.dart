import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'food_provider.dart';
import 'detail_screen.dart';

/// Search screen
/// - Text input to enter a query
/// - Loading, error, and empty states
/// - Scrollable list of results
/// - Tap to navigate to details
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _performSearch() {
    final q = _controller.text;
    if (q.trim().isEmpty) return;
    context.read<FoodSearchProvider>().searchFoods(q);
    FocusScope.of(context).unfocus(); // dismiss keyboard
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FoodSearchProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Food Search')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Input + action
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _performSearch(),
                    decoration: const InputDecoration(
                      labelText: 'Search foods...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Search',
                  onPressed: _performSearch,
                  icon: const Icon(Icons.search),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Loading
            if (provider.isLoading) const LinearProgressIndicator(),

            // Error
            if (!provider.isLoading && provider.errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  provider.errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),

            // Empty state after a search
            if (!provider.isLoading &&
                provider.errorMessage == null &&
                provider.results.isEmpty &&
                _controller.text.trim().isNotEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Text('No results found'),
              ),

            // Results
            if (!provider.isLoading && provider.results.isNotEmpty)
              Expanded(
                child: ListView.separated(
                  itemCount: provider.results.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = provider.results[index];
                    return ListTile(
                      title: Text(item.description),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => DetailScreen(foodItem: item),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
