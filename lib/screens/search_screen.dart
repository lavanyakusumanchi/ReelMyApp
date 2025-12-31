import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import '../services/search_repository.dart';
import '../widgets/search_widgets.dart';
import '../widgets/video_reel_item.dart';
import '../models/reel.dart';
import '../utils/api_config.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final SearchRepository _searchRepo = SearchRepository();
  Timer? _debounce;

  // State
  String _query = '';
  bool _isSearching = false;
  bool _showResults = false;
  
  // Data
  List<Reel> _results = [];
  List<Map<String, dynamic>> _suggestions = [];
  List<String> _trending = [];
  
  // Filters
  String _selectedCategory = 'All';
  final List<String> _categories = ['All', 'Fashion', 'Food', 'Tech', 'Travel', 'Gaming', 'Education'];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  void _loadInitialData() async {
    final trending = await _searchRepo.getTrending();
    if (mounted) {
      setState(() {
        _trending = trending;
      });
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    debugPrint("🔍 [Search] onSearchChanged: '$query'");
    setState(() {
      _query = query;
      // We don't hide results immediately, we let them update live
      if (query.isEmpty) {
        _showResults = false;
        _isSearching = false;
        _results = [];
      } else {
        _isSearching = true; // Show loading while typing/debouncing
      }
    });

    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.isNotEmpty) {
        debugPrint("⏳ [Search] Debounce hit for: '$query' -> Performing Search");
        _performSearch(query);
      }
    });
  }

  void _performSearch(String query) async {
    if (query.isEmpty) return;
    
    debugPrint("🚀 [Search] Calling searchRepo with query: '$query'");
    setState(() {
       _showResults = true;
    });

    try {
      final data = await _searchRepo.search(query: query, category: _selectedCategory);
      debugPrint("✅ [Search] API Response Success. Results count: ${(data['results'] as List).length}");
      
      if (mounted) {
        setState(() {
          _results = (data['results'] as List).cast<Reel>();
          _isSearching = false;
        });
      }
    } catch (e) {
      debugPrint("❌ [Search] API Error: $e");
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _updateCategory(String category) {
    setState(() {
      _selectedCategory = category;
    });
    if (_query.isNotEmpty) {
      _performSearch(_query);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        titleSpacing: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.iconTheme.color),
          onPressed: () => Navigator.pop(context),
        ),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          style: theme.textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: 'Search reels, tags, or categories...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.grey[600]),
            suffixIcon: _query.isNotEmpty 
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged('');
                  },
                )
              : null,
          ),
          onChanged: _onSearchChanged,
          // onSubmitted: _performSearch, // No longer needed as typing triggers it
        ),
      ),
      body: Column(
        children: [
          // Filter Chips
          if (_query.isNotEmpty || _results.isNotEmpty)
            SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  return FilterChipWidget(
                    label: _categories[index],
                    isSelected: _selectedCategory == _categories[index],
                    onSelected: () => _updateCategory(_categories[index]),
                  );
                },
              ),
            ),
            
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    // 1. Loading State
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    // 2. Results State (Live)
    if (_query.isNotEmpty) {
      if (_results.isEmpty) {
        return const Center(child: Text("No results found."));
      }
      return GridView.builder(
        padding: const EdgeInsets.all(4),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
          childAspectRatio: 0.6,
        ),
        itemCount: _results.length,
        itemBuilder: (context, index) {
          final reel = _results[index];
          return GestureDetector(
            onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => Scaffold(
                            backgroundColor: Colors.black,
                            body: SafeArea(
                                child: Stack(
                                    children: [
                                        VideoReelItem(reel: reel, isVisible: true),
                                        Positioned(
                                            top: 10, left: 10,
                                            child: IconButton(
                                                icon: const Icon(Icons.arrow_back, color: Colors.white),
                                                onPressed: () => Navigator.pop(context),
                                            ),
                                        )
                                    ],
                                ),
                            ),
                        ),
                    ),
                );
            },
            child: Container(
              color: Colors.grey[900],
              child: Stack(
                fit: StackFit.expand,
                children: [
                   reel.thumbnailUrl != null
                    ? Image.network(ApiConfig.getFullUrl(reel.thumbnailUrl!), fit: BoxFit.cover)
                    : const Center(child: Icon(Icons.play_arrow, color: Colors.white)),
                   // View Count Overlay
                   Positioned(
                     bottom: 4,
                     left: 4,
                     child: Container(
                       padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                       decoration: BoxDecoration(
                         color: Colors.black54,
                         borderRadius: BorderRadius.circular(4),
                       ),
                       child: Row(
                         mainAxisSize: MainAxisSize.min,
                         children: [
                            const Icon(Icons.play_arrow_outlined, color: Colors.white, size: 14),
                            const SizedBox(width: 2),
                            Text(
                              '${reel.views}', 
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)
                            ),
                         ],
                       ),
                     ),
                   ),
                ],
              ),
            ),
          );
        },
      );
    }

    // 4. Initial State (Trending & History)
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_trending.isNotEmpty) ...[
          const Text("Trending", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 10),
          Wrap(
            children: _trending.map((tag) => TrendingTagChip(
              label: tag, 
              onTap: () => _performSearch(tag)
            )).toList(),
          ),
          const SizedBox(height: 20),
        ],
      ],
    );
  }
}
